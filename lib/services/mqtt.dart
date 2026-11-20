import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:first_mqtt_app/services/time_service.dart';

/// A received message with its real topic.
class MqttIncoming {
  final String topic;
  final String payload;
  final DateTime receivedAt; // NTP-corrected UTC, captured on arrival
  const MqttIncoming(this.topic, this.payload, this.receivedAt);
}

enum MqttLink { connected, reconnecting, disconnected }

class MqttManager {
  MqttServerClient? _client;
  final String brokerHost;
  final String clientId;
  final int port;

  /// Called whenever the connection state changes.
  void Function(MqttLink link)? onConnectionChanged;

  MqttManager({
    required this.brokerHost,
    required this.clientId,
    required this.port,
  });

  final StreamController<MqttIncoming> _messageStreamController =
      StreamController<MqttIncoming>.broadcast();
  Stream<MqttIncoming> get messageStream => _messageStreamController.stream;

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect({String? username, String? password}) async {
    final client = MqttServerClient.withPort(brokerHost, clientId, port);
    _client = client;

    // core configuration
    client.logging(on: false);
    client.keepAlivePeriod = 60; // seconds
    client.autoReconnect = true; // auto reconnect when drop

    // callback event triggers
    client.onConnected = () => _emit(MqttLink.connected);
    client.onAutoReconnect = () => _emit(MqttLink.reconnecting);
    client.onAutoReconnected = () => _emit(MqttLink.connected);
    client.onDisconnected = () => _emit(MqttLink.disconnected);
    client.onSubscribed = _onSubscribed;

    final connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    if (username != null && password != null) {
      connectionMessage.authenticateAs(username, password);
    }
    client.connectionMessage = connectionMessage;

    try {
      await client.connect();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MQTT Connection failure: $e');
      }
      client.disconnect();
      return false;
    }

    final connected =
        client.connectionStatus!.state == MqttConnectionState.connected;

    if (connected) {
      // Listen to incoming messages ONCE, for all subscriptions.
      _updatesSub?.cancel();
      _updatesSub = client.updates!.listen((
        List<MqttReceivedMessage<MqttMessage>> events,
      ) {
        final receivedAt = TimeService.instance
            .nowUtc(); // first thing, before decoding
        for (final event in events) {
          final recMessage = event.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message,
          );
          _messageStreamController.add(
            MqttIncoming(event.topic, payload, receivedAt),
          );
        }
      });
    }

    return connected;
  }

  void _emit(MqttLink link) => onConnectionChanged?.call(link);

  MqttQos? _toQos(int qos) {
    switch (qos) {
      case 0:
        return MqttQos.atMostOnce;
      case 1:
        return MqttQos.atLeastOnce;
      case 2:
        return MqttQos.exactlyOnce;
      default:
        return null;
    }
  }

  // Subscribe to a topic with a certain qos
  void subscribe(String topic, int qos) {
    final qosLevel = _toQos(qos);
    if (qosLevel == null) {
      if (kDebugMode) {
        debugPrint(
          '[MQTT] Failed to subscribe to topic $topic with wrong qos $qos',
        );
      }
      return;
    }

    if (isConnected) {
      _client!.subscribe(topic, qosLevel);
    }
  }

  // Publish a message with a certain qos to the broker. Returns false if it
  // could not be sent.
  bool publish(String topic, String message, int qos) {
    final qosLevel = _toQos(qos);
    if (qosLevel == null || !isConnected) {
      if (kDebugMode) {
        debugPrint('[MQTT] Failed to publish to $topic (qos $qos)');
      }
      return false;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, qosLevel, builder.payload!);
    return true;
  }

  // Disconnect from the MQTT broker
  void disconnect() {
    onConnectionChanged = null;
    _client?.disconnect();
  }

  void dispose() {
    onConnectionChanged = null;
    _updatesSub?.cancel();
    _messageStreamController.close();
  }

  void _onSubscribed(String topic) {
    if (kDebugMode) {
      debugPrint('Subscribed cleanly to topic: $topic');
    }
  }
}
