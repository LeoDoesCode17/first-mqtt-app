import 'package:first_mqtt_app/core/json_utils.dart';

/// `esp/{mac}/telemetry/sensor`
class SensorData {
  final double? waterTemperature;
  final double? airTemperature;
  final double? humidity;
  final bool? isWaterSufficient;
  final bool? isFireOn;
  final int? seqId;
  final DateTime at; // phone clock, when the message arrived

  const SensorData({
    this.waterTemperature,
    this.airTemperature,
    this.humidity,
    this.isWaterSufficient,
    this.isFireOn,
    this.seqId,
    required this.at,
  });

  factory SensorData.fromJson(Map<String, dynamic> j, DateTime at) =>
      SensorData(
        waterTemperature: asDouble(j['water_temperature']),
        airTemperature: asDouble(j['air_temperature']),
        humidity: asDouble(j['humidity']),
        isWaterSufficient: asBool(j['is_water_sufficient']),
        isFireOn: asBool(j['is_fire_on']),
        seqId: asInt(j['seq_id']),
        at: at,
      );
}
