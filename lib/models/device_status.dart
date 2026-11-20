import 'package:first_mqtt_app/core/ecoprint_state.dart';
import 'package:first_mqtt_app/core/json_utils.dart';

/// `esp/{mac}/telemetry/status`
class DeviceStatus {
  final MachineState? state;
  final int? rawState;
  final int? seqId;
  final DateTime at;

  const DeviceStatus({this.state, this.rawState, this.seqId, required this.at});

  factory DeviceStatus.fromJson(Map<String, dynamic> j, DateTime at) {
    final raw = asInt(j['state_machine']);
    return DeviceStatus(
      state: MachineState.fromCode(raw),
      rawState: raw,
      seqId: asInt(j['seq_id']),
      at: at,
    );
  }
}
