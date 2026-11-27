import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/ecoprint_state.dart';
import 'package:first_mqtt_app/core/format.dart';
import 'package:first_mqtt_app/core/theme.dart';
import 'package:first_mqtt_app/models/run_event.dart';
import 'package:first_mqtt_app/state/ecoprint_controller.dart';
import 'package:first_mqtt_app/widgets/surface_card.dart';

class ControlScreen extends StatelessWidget {
  final EcoprintController c;
  const ControlScreen({super.key, required this.c});

  Future<void> _confirmStart(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.play_circle_outline),
        title: const Text('Start steaming?'),
        content: Text(
          'The device will heat to ${c.setpointInput} °C and steam for '
          '${c.timerInput} minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (ok == true) {
      c.sendCommand(CommandKind.start);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Banner(c: c),
            const SizedBox(height: 12),
            _ParamsCard(c: c),
            const SizedBox(height: 12),
            _Buttons(c: c, onStart: () => _confirmStart(context)),
            const SizedBox(height: 20),
            _EventLog(c: c),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------------- banner

class _Banner extends StatelessWidget {
  final EcoprintController c;
  const _Banner({required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = c.machineState;

    final IconData icon;
    final String text;
    Color color = cs.primary;

    if (!c.isLinkUp) {
      icon = Icons.cloud_off;
      text = 'Not connected to the broker. Commands cannot be sent.';
      color = cs.error;
    } else if (c.isRunning) {
      icon = Icons.autorenew;
      text =
          'A run is in progress (${state?.label ?? 'running'}). '
          'Stop it before starting a new one.';
    } else if (state != null && state.isFault) {
      icon = Icons.warning_amber;
      text =
          'The device is in ${state.label.toLowerCase()} state. '
          'A start command may be rejected.';
      color = AppColors.warn;
    } else {
      icon = Icons.check_circle_outline;
      text = 'Ready. Choose the setpoint and timer, then start.';
      color = AppColors.ok;
    }

    return SurfaceCard(
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- parameters

class _ParamsCard extends StatelessWidget {
  final EcoprintController c;
  const _ParamsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final enabled = !c.isRunning && c.pendingCommand == null;
    return SurfaceCard(
      child: Column(
        children: [
          const SectionTitle('Run parameters', icon: Icons.tune),
          const SizedBox(height: 12),
          _ParamRow(
            label: 'Target temperature',
            value: '${c.setpointInput}',
            unit: '°C',
            min: EcoprintController.minSetpoint.toDouble(),
            max: EcoprintController.maxSetpoint.toDouble(),
            divisions:
                EcoprintController.maxSetpoint - EcoprintController.minSetpoint,
            current: c.setpointInput.toDouble(),
            step: 1,
            enabled: enabled,
            onChanged: (v) => c.setSetpoint(v.round()),
          ),
          const SizedBox(height: 8),
          _ParamRow(
            label: 'Steaming time',
            value: '${c.timerInput}',
            unit: 'min',
            min: EcoprintController.minTimer.toDouble(),
            max: EcoprintController.maxTimer.toDouble(),
            divisions:
                (EcoprintController.maxTimer - EcoprintController.minTimer) ~/
                5,
            current: c.timerInput.toDouble(),
            step: 5,
            enabled: enabled,
            onChanged: (v) => c.setTimer(v.round()),
          ),
        ],
      ),
    );
  }
}

class _ParamRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double min;
  final double max;
  final int divisions;
  final double current;
  final double step;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _ParamRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.current,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: enabled && current - step >= min
                  ? () => onChanged(current - step)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(unit, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  Slider(
                    value: current.clamp(min, max).toDouble(),
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: enabled ? onChanged : null,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: enabled && current + step <= max
                  ? () => onChanged(current + step)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- buttons

class _Buttons extends StatelessWidget {
  final EcoprintController c;
  final VoidCallback onStart;
  const _Buttons({required this.c, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = c.pendingCommand;
    final canStart = c.isLinkUp && !c.isRunning && pending == null;
    final canStop = c.isLinkUp && pending == null;

    Widget spinner() => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: canStart ? onStart : null,
            icon: pending == CommandKind.start
                ? spinner()
                : const Icon(Icons.play_arrow),
            label: Text(
              pending == CommandKind.start ? 'Waiting…' : 'Start steaming',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: canStop ? () => c.sendCommand(CommandKind.stop) : null,
            icon: pending == CommandKind.stop
                ? spinner()
                : const Icon(Icons.stop),
            label: Text(pending == CommandKind.stop ? 'Waiting…' : 'Stop'),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ event log

class _EventLog extends StatelessWidget {
  final EcoprintController c;
  const _EventLog({required this.c});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final events = c.events;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Recent events', icon: Icons.history),
          const SizedBox(height: 8),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No events yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final e in events.take(15)) _EventTile(event: e),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final RunEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final IconData icon;
    final Color color;
    final String title;
    switch (event.type) {
      case RunEventType.started:
        icon = Icons.play_circle;
        color = AppColors.ok;
        title = 'Run started';
      case RunEventType.finished:
        icon = Icons.flag_circle;
        color = cs.primary;
        title = 'Run finished';
      case RunEventType.rejected:
        icon = Icons.block;
        color = cs.error;
        title = event.command == 0
            ? 'Stop command rejected'
            : 'Start command rejected';
      case RunEventType.unknown:
        icon = Icons.help_outline;
        color = cs.outline;
        title = 'Unknown event';
    }

    final details = <String>[
      event.isRemote ? 'From app' : 'On device',
      if (event.setpoint != null) '${event.setpoint} °C',
      if (event.timerMinutes != null) '${event.timerMinutes} min',
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        event.type == RunEventType.rejected
            ? '${rejectReasonText(event.reason)}'
                  '${event.state == null ? '' : ' (${event.state!.label})'}'
            : details.join(' · '),
      ),
      trailing: Text(
        fmtClock(event.at),
        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
