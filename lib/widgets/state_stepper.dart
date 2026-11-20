import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/ecoprint_state.dart';

/// Horizontal progress of the run: Prep → Fill → Fire → Heat → Steam → Done.
class StateStepper extends StatelessWidget {
  final MachineState? state;
  const StateStepper({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = MachineState.pipeline;
    final current = state == null ? -1 : steps.indexOf(state!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _Step(
              label: steps[i].shortLabel,
              isFirst: i == 0,
              isLast: i == steps.length - 1,
              isDone: i < current || (i == current && steps[i].isFinal),
              isCurrent: i == current && !steps[i].isFinal,
              leftActive: i <= current,
              rightActive: i < current,
              color: cs.primary,
              idleColor: cs.outlineVariant,
              onColor: cs.onPrimary,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool isDone;
  final bool isCurrent;
  final bool leftActive;
  final bool rightActive;
  final Color color;
  final Color idleColor;
  final Color onColor;

  const _Step({
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.isDone,
    required this.isCurrent,
    required this.leftActive,
    required this.rightActive,
    required this.color,
    required this.idleColor,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = isDone || isCurrent;

    Widget line(bool visible, bool active) => Expanded(
      child: Container(
        height: 3,
        color: visible ? (active ? color : idleColor) : Colors.transparent,
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            line(!isFirst, leftActive),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 26 : 20,
              height: isCurrent ? 26 : 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached ? color : Colors.transparent,
                border: Border.all(
                  color: reached ? color : idleColor,
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isDone
                  ? Icon(Icons.check, size: 13, color: onColor)
                  : isCurrent
                  ? Icon(Icons.circle, size: 8, color: onColor)
                  : null,
            ),
            line(!isLast, rightActive),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: reached
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
