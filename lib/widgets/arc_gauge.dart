import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 270° arc gauge with an optional setpoint marker. [child] is drawn in the
/// centre (usually the big value text).
class ArcGauge extends StatelessWidget {
  final double? value;
  final double min;
  final double max;
  final double? setpoint;
  final Color color;
  final Widget child;
  final double size;

  const ArcGauge({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.setpoint,
    required this.color,
    required this.child,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value ?? min),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) {
          return CustomPaint(
            painter: _ArcPainter(
              value: value == null ? null : animated,
              min: min,
              max: max,
              setpoint: setpoint,
              color: color,
              track: cs.surfaceContainerHighest,
              marker: cs.onSurface,
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double? value;
  final double min;
  final double max;
  final double? setpoint;
  final Color color;
  final Color track;
  final Color marker;

  _ArcPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.setpoint,
    required this.color,
    required this.track,
    required this.marker,
  });

  static const double _start = 3 * math.pi / 4;
  static const double _sweep = 3 * math.pi / 2;
  static const double _stroke = 18;

  double _fraction(double v) =>
      ((v - min) / (max - min)).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (side - _stroke) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, _start, _sweep, false, trackPaint);

    if (value != null) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      final f = _fraction(value!);
      if (f > 0) canvas.drawArc(rect, _start, _sweep * f, false, progress);
    }

    if (setpoint != null) {
      final angle = _start + _sweep * _fraction(setpoint!);
      final dir = Offset(math.cos(angle), math.sin(angle));
      final inner = center + dir * (radius - _stroke / 2 - 4);
      final outer = center + dir * (radius + _stroke / 2 + 4);
      final tick = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = marker;
      canvas.drawLine(inner, outer, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.value != value ||
      old.min != min ||
      old.max != max ||
      old.setpoint != setpoint ||
      old.color != color ||
      old.track != track ||
      old.marker != marker;
}
