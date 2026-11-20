import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/ecoprint_state.dart';
import 'package:first_mqtt_app/core/format.dart';
import 'package:first_mqtt_app/core/theme.dart';
import 'package:first_mqtt_app/state/ecoprint_controller.dart';
import 'package:first_mqtt_app/widgets/arc_gauge.dart';
import 'package:first_mqtt_app/widgets/metric_tile.dart';
import 'package:first_mqtt_app/widgets/state_stepper.dart';
import 'package:first_mqtt_app/widgets/status_pill.dart';
import 'package:first_mqtt_app/widgets/surface_card.dart';

class DashboardScreen extends StatelessWidget {
  final EcoprintController c;
  const DashboardScreen({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([c, c.now]),
      builder: (context, _) {
        final now = c.now.value;
        final online = c.deviceOnline(now);
        final sensor = c.sensor;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (c.link == LinkState.failed || c.link == LinkState.disconnected)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LinkBanner(c: c),
              ),
            _StatusCard(c: c, now: now, online: online),
            const SizedBox(height: 12),
            _WaterCard(c: c, dimmed: !online),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.air,
                      label: 'Air temperature',
                      value: fmtNum(sensor?.airTemperature),
                      unit: '°C',
                      color: AppColors.air,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.water_drop_outlined,
                      label: 'Humidity',
                      value: fmtNum(sensor?.humidity),
                      unit: '%',
                      color: AppColors.humidity,
                      footer: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: sensor?.humidity == null
                              ? 0
                              : (sensor!.humidity! / 100)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                          minHeight: 6,
                          color: AppColors.humidity,
                          backgroundColor: AppColors.humidity.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ActuatorCard(c: c),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- link banner

class _LinkBanner extends StatelessWidget {
  final EcoprintController c;
  const _LinkBanner({required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SurfaceCard(
      color: cs.errorContainer,
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cannot reach ${c.settings.host}:${c.settings.port}',
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
          TextButton(onPressed: c.reconnect, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- status card

class _StatusCard extends StatelessWidget {
  final EcoprintController c;
  final DateTime now;
  final bool online;
  const _StatusCard({required this.c, required this.now, required this.online});

  Color _stateColor(MachineState? s, ColorScheme cs) {
    if (s == null || s == MachineState.idle) return cs.outline;
    if (s.isFault) return cs.error;
    if (s == MachineState.completed) return AppColors.ok;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = c.machineState;
    final color = online ? _stateColor(state, cs) : cs.outline;
    final run = c.activeRun;

    final String subtitle;
    if (c.lastTelemetryAt == null) {
      subtitle = 'Waiting for data…';
    } else if (online) {
      subtitle = 'Updated ${fmtAgo(now.difference(c.lastTelemetryAt!))}';
    } else {
      subtitle = 'Last seen ${fmtAgo(now.difference(c.lastTelemetryAt!))}';
    }

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state?.icon ?? Icons.help_outline,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state?.label ?? 'No status',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                icon: online ? Icons.wifi : Icons.wifi_off,
                label: online ? 'Online' : 'Offline',
                color: online ? AppColors.ok : cs.outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          StateStepper(state: online ? state : null),
          if (state != null && state.isFault && online) ...[
            const SizedBox(height: 14),
            Text(
              state == MachineState.failed
                  ? 'The last run failed.'
                  : 'The device reported an error.',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
            ),
          ],
          if (run != null) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 14),
            Row(
              children: [
                _RunFact(
                  label: 'Setpoint',
                  value: '${run.setpoint ?? '--'} °C',
                ),
                _RunFact(
                  label: 'Timer',
                  value: '${run.timerMinutes ?? '--'} min',
                ),
                _RunFact(
                  label: 'Elapsed',
                  value: fmtDuration(now.difference(run.at)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              run.isRemote ? 'Started from the app' : 'Started on the device',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RunFact extends StatelessWidget {
  final String label;
  final String value;
  const _RunFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- water card

class _WaterCard extends StatelessWidget {
  final EcoprintController c;
  final bool dimmed;
  const _WaterCard({required this.c, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = c.sensor;
    final temp = s?.waterTemperature;
    final setpoint = c.activeRun?.setpoint?.toDouble();

    Color gaugeColor = AppColors.water;
    if (setpoint != null && temp != null && temp >= setpoint - 1) {
      gaugeColor = AppColors.ok;
    } else if (temp != null && temp >= 60) {
      gaugeColor = AppColors.hot;
    }
    if (dimmed) gaugeColor = cs.outline;

    final water = s?.isWaterSufficient;
    final fire = s?.isFireOn;

    return SurfaceCard(
      child: Column(
        children: [
          const SectionTitle('Water temperature', icon: Icons.thermostat),
          const SizedBox(height: 8),
          ArcGauge(
            value: temp,
            max: 100,
            setpoint: setpoint,
            color: gaugeColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmtNum(temp),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('°C', style: theme.textTheme.titleLarge),
                    ),
                  ],
                ),
                Text(
                  setpoint == null
                      ? 'No active run'
                      : 'Setpoint ${setpoint.toStringAsFixed(0)} °C',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              StatusPill(
                icon: Icons.water,
                label: water == null
                    ? 'Water --'
                    : (water ? 'Water OK' : 'Water low'),
                color: water == null
                    ? cs.outline
                    : (water ? AppColors.ok : cs.error),
              ),
              StatusPill(
                icon: Icons.local_fire_department,
                label: fire == null
                    ? 'Fire --'
                    : (fire ? 'Fire on' : 'Fire off'),
                color: fire == null
                    ? cs.outline
                    : (fire ? AppColors.hot : cs.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- actuator card

class _ActuatorCard extends StatelessWidget {
  final EcoprintController c;
  const _ActuatorCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final a = c.actuator;
    final cs = Theme.of(context).colorScheme;

    Widget tile(
      IconData icon,
      String label,
      bool? on,
      String onText,
      String offText, {
      String? detail,
      double angle = 0,
    }) {
      return _ActuatorTile(
        icon: icon,
        label: label,
        value: on == null ? '--' : (on ? onText : offText),
        detail: detail,
        active: on ?? false,
        unknown: on == null,
        angle: angle,
      );
    }

    return SurfaceCard(
      child: Column(
        children: [
          const SectionTitle('Actuators', icon: Icons.settings_input_component),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              tile(
                Icons.settings,
                'Valve',
                a?.isValveOpen,
                'Open',
                'Closed',
                detail: a?.valveDegree == null ? null : '${a!.valveDegree}°',
                angle: (a?.valveDegree ?? 0) * 3.14159265 / 180,
              ),
              tile(
                Icons.vertical_align_top,
                'Valve limit',
                a?.isMaxValveOpening,
                'At maximum',
                'Normal',
              ),
              tile(Icons.water_damage, 'Pump', a?.isPumpOn, 'On', 'Off'),
              tile(Icons.flash_on, 'Lighter', a?.isLighterOn, 'On', 'Off'),
            ],
          ),
          if (a == null) ...[
            const SizedBox(height: 10),
            Text(
              'Waiting for actuator data…',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActuatorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final bool active;
  final bool unknown;
  final double angle;

  const _ActuatorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
    required this.unknown,
    this.detail,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = unknown
        ? cs.outline
        : (active ? cs.primary : cs.onSurfaceVariant);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active && !unknown
            ? cs.primary.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AnimatedRotation(
            turns: angle / 6.28318531,
            duration: const Duration(milliseconds: 400),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  detail == null ? value : '$value · $detail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: unknown ? cs.outline : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
