import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/format.dart';

/// Line chart over time. X values are seconds since [start].
class TrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final DateTime start;
  final double spanSeconds;
  final double? referenceY;
  final String? referenceLabel;
  final double? clampMin;
  final double? clampMax;
  final double height;

  const TrendChart({
    super.key,
    required this.spots,
    required this.color,
    required this.start,
    required this.spanSeconds,
    this.referenceY,
    this.referenceLabel,
    this.clampMin,
    this.clampMax,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (spots.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data in this time range',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Y range with a little padding, on whole numbers so axis labels are clean.
    var lo = spots.map((s) => s.y).reduce(math.min);
    var hi = spots.map((s) => s.y).reduce(math.max);
    if (referenceY != null) {
      lo = math.min(lo, referenceY!);
      hi = math.max(hi, referenceY!);
    }
    var minY = (lo - 2).floorToDouble();
    var maxY = (hi + 2).ceilToDouble();
    if (clampMin != null) minY = math.max(minY, clampMin!);
    if (clampMax != null) maxY = math.min(maxY, clampMax!);
    if (maxY - minY < 6) maxY = minY + 6;
    final yInterval = math.max(1.0, ((maxY - minY) / 4).ceilToDouble());
    final xInterval = math.max(1.0, spanSeconds / 3);

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
    );

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spanSeconds,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: yInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(value.toStringAsFixed(0), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  final t = start.add(Duration(seconds: value.round()));
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(fmtClockShort(t), style: labelStyle),
                  );
                },
              ),
            ),
          ),
          extraLinesData: referenceY == null
              ? null
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: referenceY!,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: referenceLabel != null,
                        alignment: Alignment.topRight,
                        style: labelStyle,
                        labelResolver: (_) => referenceLabel ?? '',
                      ),
                    ),
                  ],
                ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
