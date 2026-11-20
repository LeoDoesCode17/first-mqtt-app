import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/format.dart';
import 'package:first_mqtt_app/models/topic_stats.dart';
import 'package:first_mqtt_app/state/ecoprint_controller.dart';
import 'package:first_mqtt_app/widgets/surface_card.dart';

/// The original latency / packet-loss measurements, kept as a diagnostics page.
class DiagnosticsScreen extends StatelessWidget {
  final EcoprintController c;
  const DiagnosticsScreen({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Reset all stats',
            icon: const Icon(Icons.restart_alt),
            onPressed: c.resetDiagnostics,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([c, ...c.topics]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                c.time.isSynced
                    ? 'Clock synced with NTP (offset ${c.time.offsetMs} ms)'
                    : 'Clock not synced with NTP — latency is unavailable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final t in c.topics) ...[
                _TopicCard(stats: t, mac: c.settings.mac),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicStats stats;
  final String mac;
  const _TopicCard({required this.stats, required this.mac});

  String _ms(num? v, {int digits = 0}) =>
      v == null ? '--' : '${v.toStringAsFixed(digits)} ms';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget cell(String label, String value) => Expanded(
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
            value,
            style: theme.textTheme.titleSmall?.copyWith(
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
          SectionTitle(
            stats.config.title,
            icon: stats.config.icon,
            trailing: Text(
              'QoS ${stats.config.qos}',
              style: theme.textTheme.labelSmall,
            ),
          ),
          Text(
            'esp/$mac/${stats.config.suffix}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              cell('Received', '${stats.uniqueReceived}'),
              cell(
                'Lost',
                '${stats.lost} (${stats.lossPercent.toStringAsFixed(2)}%)',
              ),
              cell('Last seq_id', '${stats.lastSeq ?? '--'}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              cell('Min latency', _ms(stats.minLatency)),
              cell('Avg latency', _ms(stats.avgLatency, digits: 1)),
              cell('Max latency', _ms(stats.maxLatency)),
            ],
          ),
          if (stats.messages.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Last message ${fmtClock(stats.messages.first.receivedAt)}',
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
