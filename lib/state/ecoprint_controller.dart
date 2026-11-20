import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/ecoprint_state.dart';
import 'package:first_mqtt_app/core/json_utils.dart';
import 'package:first_mqtt_app/models/actuator_data.dart';
import 'package:first_mqtt_app/models/device_status.dart';
import 'package:first_mqtt_app/models/run_event.dart';
import 'package:first_mqtt_app/models/sensor_data.dart';
import 'package:first_mqtt_app/models/topic_stats.dart';
import 'package:first_mqtt_app/models/trend_point.dart';
import 'package:first_mqtt_app/services/mqtt.dart';
import 'package:first_mqtt_app/services/settings_store.dart';
import 'package:first_mqtt_app/services/time_service.dart';

enum LinkState { connecting, connected, reconnecting, disconnected, failed }

enum CommandKind { start, stop }

/// A short message the UI shows as a snackbar.
class Notice {
  final String message;
  final bool isError;
  const Notice(this.message, {this.isError = false});
}

/// Single source of truth for the UI: owns the MQTT connection, parses the
/// telemetry/event topics and sends commands.
class EcoprintController extends ChangeNotifier {
  static const int maxTrendPoints = 4000;
  static const int maxEvents = 60;
  static const Duration staleAfter = Duration(seconds: 15);
  static const Duration commandTimeout = Duration(seconds: 6);

  static const int minSetpoint = 40;
  static const int maxSetpoint = 100;
  static const int minTimer = 5;
  static const int maxTimer = 240;

  final SettingsStore _store = SettingsStore();
  final TimeService time = TimeService.instance;

  AppSettings settings = AppSettings.defaults;
  LinkState link = LinkState.connecting;

  MqttManager? _mqtt;
  StreamSubscription<MqttIncoming>? _sub;
  bool _disposed = false;

  /// Ticks every second so "x s ago" / elapsed time labels stay fresh without
  /// rebuilding the whole app.
  final ValueNotifier<DateTime> now = ValueNotifier(DateTime.now());
  Timer? _ticker;

  // Per-topic latency / packet loss stats (shown on the Diagnostics screen).
  final List<TopicStats> topics = [
    TopicStats(
      const TopicConfig('Sensor', 'telemetry/sensor', 0, Icons.thermostat),
    ),
    TopicStats(
      const TopicConfig(
        'Actuator',
        'telemetry/actuator',
        0,
        Icons.settings_input_component,
      ),
    ),
    TopicStats(
      const TopicConfig('Device status', 'telemetry/status', 0, Icons.info),
    ),
    TopicStats(const TopicConfig('Event', 'event', 1, Icons.event)),
  ];

  // Latest data
  SensorData? sensor;
  ActuatorData? actuator;
  DeviceStatus? status;
  DateTime? lastTelemetryAt;

  final List<TrendPoint> trend = []; // oldest first
  final List<RunEvent> events = []; // newest first
  RunEvent? activeRun; // last run_started that has not finished yet

  // Control inputs
  int setpointInput = AppSettings.defaults.setpoint;
  int timerInput = AppSettings.defaults.timerMinutes;
  CommandKind? pendingCommand;
  Timer? _pendingTimer;

  final StreamController<Notice> _notices = StreamController.broadcast();
  Stream<Notice> get notices => _notices.stream;

  // ---------------------------------------------------------------- getters

  MachineState? get machineState => status?.state;

  /// Prefer the device's own state machine; fall back to the last run event.
  bool get isRunning => machineState?.isRunning ?? (activeRun != null);

  bool get isLinkUp => link == LinkState.connected;

  bool deviceOnline(DateTime at) =>
      lastTelemetryAt != null && at.difference(lastTelemetryAt!) < staleAfter;

  String get commandTopic => 'esp/${settings.mac}/command';
  String _topicFor(TopicConfig c) => 'esp/${settings.mac}/${c.suffix}';

  String get linkLabel {
    switch (link) {
      case LinkState.connecting:
        return 'Connecting…';
      case LinkState.connected:
        return 'Connected';
      case LinkState.reconnecting:
        return 'Reconnecting…';
      case LinkState.disconnected:
        return 'Disconnected';
      case LinkState.failed:
        return 'Connection failed';
    }
  }

  // -------------------------------------------------------------- lifecycle

  Future<void> start() async {
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => now.value = DateTime.now(),
    );
    settings = await _store.load();
    setpointInput = settings.setpoint;
    timerInput = settings.timerMinutes;
    notifyListeners();

    // NTP is only needed for the latency diagnostics, so don't block on it.
    unawaited(_syncTime());
    await _connect();
  }

  Future<void> _syncTime() async {
    await time.sync();
    time.startPeriodicSync();
    notifyListeners();
  }

  Future<void> reconnect() => _connect();

  Future<void> applySettings(AppSettings s) async {
    settings = s;
    await _store.save(s);
    _resetData();
    await _connect();
  }

  void _teardown() {
    _sub?.cancel();
    _sub = null;
    _mqtt?.disconnect();
    _mqtt?.dispose();
    _mqtt = null;
  }

  Future<void> _connect() async {
    _teardown();
    link = LinkState.connecting;
    notifyListeners();

    final mqtt = MqttManager(
      brokerHost: settings.host,
      port: settings.port,
      clientId: 'ecoprint-app-${Random().nextInt(0xFFFFFF).toRadixString(16)}',
    );
    mqtt.onConnectionChanged = (l) {
      if (_mqtt != mqtt) return;
      switch (l) {
        case MqttLink.connected:
          link = LinkState.connected;
        case MqttLink.reconnecting:
          link = LinkState.reconnecting;
        case MqttLink.disconnected:
          link = LinkState.disconnected;
      }
      notifyListeners();
    };
    _mqtt = mqtt;

    final ok = await mqtt.connect();
    if (_disposed || _mqtt != mqtt) return; // superseded by a newer connect

    if (!ok) {
      link = LinkState.failed;
      notifyListeners();
      return;
    }

    _sub = mqtt.messageStream.listen(_onMessage);
    for (final t in topics) {
      mqtt.subscribe(_topicFor(t.config), t.config.qos);
    }
    link = LinkState.connected;
    notifyListeners();
  }

  // --------------------------------------------------------------- incoming

  void _onMessage(MqttIncoming msg) {
    final prefix = 'esp/${settings.mac}/';
    if (!msg.topic.startsWith(prefix)) return;
    final suffix = msg.topic.substring(prefix.length);

    for (final t in topics) {
      if (t.config.suffix == suffix) t.add(msg);
    }

    final json = decodeJsonObject(msg.payload);
    if (json == null) return;
    final at = DateTime.now();

    switch (suffix) {
      case 'telemetry/sensor':
        _onSensor(SensorData.fromJson(json, at));
      case 'telemetry/actuator':
        actuator = ActuatorData.fromJson(json, at);
        lastTelemetryAt = at;
        notifyListeners();
      case 'telemetry/status':
        _onStatus(DeviceStatus.fromJson(json, at));
      case 'event':
        _onEvent(RunEvent.fromJson(json, at));
    }
  }

  void _onSensor(SensorData s) {
    sensor = s;
    lastTelemetryAt = s.at;
    trend.add(
      TrendPoint(s.at, s.waterTemperature, s.airTemperature, s.humidity),
    );
    if (trend.length > maxTrendPoints) {
      trend.removeRange(0, trend.length - maxTrendPoints);
    }
    notifyListeners();
  }

  void _onStatus(DeviceStatus s) {
    status = s;
    lastTelemetryAt = s.at;
    // The run is over once the device reports a final state.
    if (s.state?.isFinal ?? false) activeRun = null;
    notifyListeners();
  }

  void _onEvent(RunEvent e) {
    events.insert(0, e);
    if (events.length > maxEvents) events.removeLast();

    switch (e.type) {
      case RunEventType.started:
        activeRun = e;
        _clearPending();
        _notify(
          e.isRemote ? 'Steaming started' : 'Steaming started from the device',
        );
      case RunEventType.finished:
        activeRun = null;
        _clearPending();
        _notify('Steaming finished');
      case RunEventType.rejected:
        _clearPending();
        _notify(
          'Command rejected: ${rejectReasonText(e.reason)}',
          isError: true,
        );
      case RunEventType.unknown:
        break;
    }
    notifyListeners();
  }

  // --------------------------------------------------------------- commands

  void setSetpoint(int v) {
    setpointInput = v.clamp(minSetpoint, maxSetpoint).toInt();
    notifyListeners();
  }

  void setTimer(int v) {
    // Keep timer on a 5 minute grid.
    final snapped = (v / 5).round() * 5;
    timerInput = snapped.clamp(minTimer, maxTimer).toInt();
    notifyListeners();
  }

  void sendCommand(CommandKind kind) {
    final mqtt = _mqtt;
    if (mqtt == null || !isLinkUp) {
      _notify('Not connected to the broker', isError: true);
      return;
    }

    final payload = jsonEncode({
      'setpoint': setpointInput,
      'timer_minutes': timerInput,
      'command': kind == CommandKind.start ? 1 : 0,
    });
    final sent = mqtt.publish(commandTopic, payload, 2);
    if (!sent) {
      _notify('Could not send the command', isError: true);
      return;
    }

    if (kind == CommandKind.start) {
      _store.save(
        settings.copyWith(setpoint: setpointInput, timerMinutes: timerInput),
      );
    }

    pendingCommand = kind;
    _pendingTimer?.cancel();
    _pendingTimer = Timer(commandTimeout, () {
      if (pendingCommand == null) return;
      pendingCommand = null;
      _notify(
        'No response from the device. Check that it is online.',
        isError: true,
      );
      notifyListeners();
    });
    notifyListeners();
  }

  void _clearPending() {
    pendingCommand = null;
    _pendingTimer?.cancel();
  }

  // ----------------------------------------------------------------- misc

  void _notify(String message, {bool isError = false}) {
    if (!_notices.isClosed) _notices.add(Notice(message, isError: isError));
  }

  void clearTrend() {
    trend.clear();
    notifyListeners();
  }

  void resetDiagnostics() {
    for (final t in topics) {
      t.reset();
    }
  }

  void _resetData() {
    sensor = null;
    actuator = null;
    status = null;
    lastTelemetryAt = null;
    activeRun = null;
    trend.clear();
    events.clear();
    _clearPending();
    resetDiagnostics();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _pendingTimer?.cancel();
    time.stopPeriodicSync();
    _teardown();
    _notices.close();
    now.dispose();
    for (final t in topics) {
      t.dispose();
    }
    super.dispose();
  }
}
