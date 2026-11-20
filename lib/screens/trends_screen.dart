import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/format.dart';
import 'package:first_mqtt_app/core/theme.dart';
import 'package:first_mqtt_app/models/trend_point.dart';
import 'package:first_mqtt_app/state/ecoprint_controller.dart';
import 'package:first_mqtt_app/widgets/surface_card.dart';
import 'package:first_mqtt_app/widgets/trend_chart.dart';

enum TrendWindow {
  m5('5 min', Duration(minutes: 5)),
  m15('15 min', Duration(minutes: 15)),
  h1('1 h', Duration(hours: 1)),
  all('All', null);

  final String label;
  final Duration? duration;
  const TrendWindow(this.label, this.duration);
}

class TrendsScreen extends StatefulWidget {
  final EcoprintController c;
  const TrendsScreen({super.key, required this.c});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendWindow _window = TrendWindow.m15;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final now = DateTime.now();
        final all = c.trend;

        // Time window
        final DateTime start;
        final DateTime end;
        if (_window.duration != null) {
          end = now;
          start = now.subtract(_window.duration!);
        } else {
          start = all.isEmpty ? now : all.first.time;
          end = all.isEmpty ? now : all.last.time;
        }
        final pts = all.where((p) => !p.time.isBefore(start)).toList();
        var span = end.difference(start).inMilliseconds / 1000.0;
        if (span < 60) span = 60;

        List<FlSpot> spotsOf(double? Function(TrendPoint) pick) => [
          for (final p in pts)
            if (pick(p) != null)
              FlSpot(
                p.time.difference(start).inMilliseconds / 1000.0,
                pick(p)!,
              ),
        ];

        final setpoint = c.activeRun?.setpoint?.toDouble();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<TrendWindow>(
                    showSelectedIcon: false,
                    segments: [
                      for (final w in TrendWindow.values)
                        ButtonSegment(value: w, label: Text(w.label)),
                    ],
                    selected: {_window},
                    onSelectionChanged: (s) =>
                        setState(() => _window = s.first),
                  ),
                ),
                IconButton(
                  tooltip: 'Clear history',
                  onPressed: all.isEmpty ? null : c.clearTrend,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TrendCard(
              title: 'Water temperature',
              unit: '°C',
              color: AppColors.water,
              spots: spotsOf((p) => p.water),
              start: start,
              span: span,
              referenceY: setpoint,
              referenceLabel: setpoint == null
                  ? null
                  : 'Setpoint ${setpoint.toStringAsFixed(0)}°',
            ),
            const SizedBox(height: 12),
            _TrendCard(
              title: 'Air temperature',
              unit: '°C',
              color: AppColors.air,
              spots: spotsOf((p) => p.air),
              start: start,
              span: span,
            ),
            const SizedBox(height: 12),
            _TrendCard(
              title: 'Humidity',
              unit: '%',
              color: AppColors.humidity,
              spots: spotsOf((p) => p.humidity),
              start: start,
              span: span,
              clampMin: 0,
              clampMax: 100,
            ),
          ],
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final List<FlSpot> spots;
  final DateTime start;
  final double span;
  final double? referenceY;
  final String? referenceLabel;
  final double? clampMin;
  final double? clampMax;

  const _TrendCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.spots,
    required this.start,
    required this.span,
    this.referenceY,
    this.referenceLabel,
    this.clampMin,
    this.clampMax,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    double? lo, hi, avg;
    if (spots.isNotEmpty) {
      final ys = spots.map((s) => s.y);
      lo = ys.reduce((a, b) => a < b ? a : b);
      hi = ys.reduce((a, b) => a > b ? a : b);
      avg = ys.reduce((a, b) => a + b) / spots.length;
    }
    final latest = spots.isEmpty ? null : spots.last.y;

    Widget stat(String label, double? v) => Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            '${fmtNum(v)} $unit',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${fmtNum(latest)} $unit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TrendChart(
            spots: spots,
            color: color,
            start: start,
            spanSeconds: span,
            referenceY: referenceY,
            referenceLabel: referenceLabel,
            clampMin: clampMin,
            clampMax: clampMax,
          ),
          const SizedBox(height: 10),
          Row(children: [stat('Min', lo), stat('Avg', avg), stat('Max', hi)]),
        ],
      ),
    );
  }
}
