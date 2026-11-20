/// One sample of the sensor history used by the Trends charts.
class TrendPoint {
  final DateTime time;
  final double? water;
  final double? air;
  final double? humidity;
  const TrendPoint(this.time, this.water, this.air, this.humidity);
}
