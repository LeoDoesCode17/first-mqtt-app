import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String host;
  final int port;
  final String mac;
  final int setpoint;
  final int timerMinutes;

  const AppSettings({
    required this.host,
    required this.port,
    required this.mac,
    required this.setpoint,
    required this.timerMinutes,
  });

  static const AppSettings defaults = AppSettings(
    host: 'broker.mqtt.cool',
    port: 1883,
    mac: '68:FE:71:0C:C3:E0',
    setpoint: 90,
    timerMinutes: 60,
  );

  AppSettings copyWith({
    String? host,
    int? port,
    String? mac,
    int? setpoint,
    int? timerMinutes,
  }) => AppSettings(
    host: host ?? this.host,
    port: port ?? this.port,
    mac: mac ?? this.mac,
    setpoint: setpoint ?? this.setpoint,
    timerMinutes: timerMinutes ?? this.timerMinutes,
  );
}

/// Persists broker/device settings and the last used run parameters.
class SettingsStore {
  static const _kHost = 'host';
  static const _kPort = 'port';
  static const _kMac = 'mac';
  static const _kSetpoint = 'setpoint';
  static const _kTimer = 'timer_minutes';

  Future<AppSettings> load() async {
    const d = AppSettings.defaults;
    try {
      final p = await SharedPreferences.getInstance();
      return AppSettings(
        host: p.getString(_kHost) ?? d.host,
        port: p.getInt(_kPort) ?? d.port,
        mac: p.getString(_kMac) ?? d.mac,
        setpoint: p.getInt(_kSetpoint) ?? d.setpoint,
        timerMinutes: p.getInt(_kTimer) ?? d.timerMinutes,
      );
    } catch (_) {
      return d;
    }
  }

  Future<void> save(AppSettings s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kHost, s.host);
      await p.setInt(_kPort, s.port);
      await p.setString(_kMac, s.mac);
      await p.setInt(_kSetpoint, s.setpoint);
      await p.setInt(_kTimer, s.timerMinutes);
    } catch (_) {
      // Settings are a convenience; never crash because of them.
    }
  }
}
