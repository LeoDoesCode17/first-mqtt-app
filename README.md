# Ecoprint app v3

Monitoring + remote control app for the Ecoprint ESP32 system.

Drop `lib/` and `pubspec.yaml` into your Flutter project (package name is still
`first_mqtt_app`), delete the old `lib/` files that are no longer used, then:

    flutter pub get
    flutter run

## Structure

    lib/
      main.dart                    app + light/dark theme
      core/                        enums (state machine), theme, formatting, JSON helpers
      models/                      SensorData, ActuatorData, DeviceStatus, RunEvent, TrendPoint, TopicStats
      services/                    mqtt.dart, time_service.dart, settings_store.dart
      state/ecoprint_controller.dart   one ChangeNotifier: MQTT in/out, history, commands
      screens/                     dashboard, trends, control, settings, diagnostics, home_shell
      widgets/                     arc gauge, state stepper, trend chart, cards, pills

## Removed from v2
lib/ui/mqtt_screen.dart, lib/screens/home_screen.dart,
lib/screens/topic_detail_screen.dart, lib/services/mqtt_monitor.dart
(latency / packet-loss stats live on in the Diagnostics screen)
