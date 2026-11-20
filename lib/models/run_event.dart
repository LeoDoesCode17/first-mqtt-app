import 'package:first_mqtt_app/core/ecoprint_state.dart';
import 'package:first_mqtt_app/core/json_utils.dart';

enum RunEventType { started, finished, rejected, unknown }

/// `esp/{mac}/event`
class RunEvent {
  final RunEventType type;
  final String source; // "local" or "remote"
  final int? setpoint;
  final int? timerMinutes;
  final String? reason; // only for command_rejected
  final MachineState? state; // only for command_rejected
  final int? command; // only for command_rejected (0 stop / 1 start)
  final DateTime at;

  const RunEvent({
    required this.type,
    required this.source,
    this.setpoint,
    this.timerMinutes,
    this.reason,
    this.state,
    this.command,
    required this.at,
  });

  bool get isRemote => source == 'remote';

  factory RunEvent.fromJson(Map<String, dynamic> j, DateTime at) {
    final RunEventType type;
    switch (j['event']) {
      case 'run_started':
        type = RunEventType.started;
      case 'run_finished':
        type = RunEventType.finished;
      case 'command_rejected':
        type = RunEventType.rejected;
      default:
        type = RunEventType.unknown;
    }
    return RunEvent(
      type: type,
      source: (j['source'] as String?) ?? 'remote',
      setpoint: asInt(j['setpoint']),
      timerMinutes: asInt(j['timer_minutes']),
      reason: j['reason'] as String?,
      state: MachineState.fromCode(asInt(j['state_machine'])),
      command: asInt(j['command']),
      at: at,
    );
  }
}
