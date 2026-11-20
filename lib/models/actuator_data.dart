import 'package:first_mqtt_app/core/json_utils.dart';

/// `esp/{mac}/telemetry/actuator`
class ActuatorData {
  final int? valveDegree;
  final bool? isValveOpen;
  final bool? isMaxValveOpening;
  final bool? isPumpOn;
  final bool? isLighterOn;
  final int? seqId;
  final DateTime at;

  const ActuatorData({
    this.valveDegree,
    this.isValveOpen,
    this.isMaxValveOpening,
    this.isPumpOn,
    this.isLighterOn,
    this.seqId,
    required this.at,
  });

  factory ActuatorData.fromJson(Map<String, dynamic> j, DateTime at) =>
      ActuatorData(
        valveDegree: asInt(j['valve_degree']),
        isValveOpen: asBool(j['is_valve_open']),
        isMaxValveOpening: asBool(j['is_max_valve_opening']),
        isPumpOn: asBool(j['is_pump_on']),
        isLighterOn: asBool(j['is_lighter_on']),
        seqId: asInt(j['seq_id']),
        at: at,
      );
}
