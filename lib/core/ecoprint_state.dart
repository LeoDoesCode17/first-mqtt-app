import 'package:flutter/material.dart';

/// Mirrors the `state_machine` integer sent by the ESP32 (see MQTT docs §1).
enum MachineState {
  idle(0, 'Idle', 'Idle', Icons.power_settings_new),
  preparation(1, 'Preparation', 'Prep', Icons.checklist),
  fillingWater(2, 'Filling water', 'Fill', Icons.water_drop),
  firing(3, 'Firing', 'Fire', Icons.local_fire_department),
  heating(4, 'Heating', 'Heat', Icons.thermostat),
  steaming(5, 'Steaming', 'Steam', Icons.cloud),
  completed(6, 'Completed', 'Done', Icons.check_circle),
  failed(7, 'Failed', 'Failed', Icons.cancel),
  error(8, 'Error', 'Error', Icons.error);

  final int code;
  final String label;
  final String shortLabel;
  final IconData icon;
  const MachineState(this.code, this.label, this.shortLabel, this.icon);

  /// The normal run sequence, shown as a progress stepper.
  static const List<MachineState> pipeline = [
    preparation,
    fillingWater,
    firing,
    heating,
    steaming,
    completed,
  ];

  static MachineState? fromCode(int? code) {
    if (code == null) return null;
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// A run is in progress (preparation .. steaming).
  bool get isRunning => code >= preparation.code && code <= steaming.code;

  /// The run has ended in one way or another.
  bool get isFinal => this == completed || this == failed || this == error;

  bool get isFault => this == failed || this == error;
}

/// Human readable text for the `reason` of a `command_rejected` event.
String rejectReasonText(String? reason) {
  switch (reason) {
    case 'already_running':
      return 'The device is already running';
    case 'device_error':
      return 'The device reported an error';
    case 'invalid_value':
      return 'Setpoint or timer value is invalid';
    default:
      return 'Unknown reason';
  }
}
