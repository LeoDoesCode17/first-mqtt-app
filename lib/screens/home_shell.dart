import 'dart:async';

import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/theme.dart';
import 'package:first_mqtt_app/screens/control_screen.dart';
import 'package:first_mqtt_app/screens/dashboard_screen.dart';
import 'package:first_mqtt_app/screens/diagnostics_screen.dart';
import 'package:first_mqtt_app/screens/settings_screen.dart';
import 'package:first_mqtt_app/screens/trends_screen.dart';
import 'package:first_mqtt_app/state/ecoprint_controller.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final EcoprintController c = EcoprintController();
  StreamSubscription<Notice>? _noticeSub;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _noticeSub = c.notices.listen(_showNotice);
    c.start();
  }

  @override
  void dispose() {
    _noticeSub?.cancel();
    c.dispose();
    super.dispose();
  }

  void _showNotice(Notice n) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: n.isError ? cs.errorContainer : null,
        content: Text(
          n.message,
          style: n.isError ? TextStyle(color: cs.onErrorContainer) : null,
        ),
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.ok),
            SizedBox(width: 8),
            Text('Ecoprint', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          _ConnectionBadge(c: c),
          IconButton(
            tooltip: 'Diagnostics',
            icon: const Icon(Icons.speed),
            onPressed: () => _open(DiagnosticsScreen(c: c)),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => _open(SettingsScreen(c: c)),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(c: c),
          TrendsScreen(c: c),
          ControlScreen(c: c),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.stacked_line_chart),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune),
            label: 'Control',
          ),
        ],
      ),
    );
  }
}

/// Broker connection state; tap to retry when it is down.
/// Broker connection state; tap to retry when it is down.
class _ConnectionBadge extends StatelessWidget {
  final EcoprintController c;
  const _ConnectionBadge({required this.c});

  // Short labels so the badge fits next to the app bar icons.
  // The full text is still available as a tooltip (long-press).
  String _shortLabel(LinkState s) => switch (s) {
    LinkState.connected => 'Connected',
    LinkState.connecting => 'Connecting',
    LinkState.reconnecting => 'Retrying',
    LinkState.disconnected => 'Offline',
    LinkState.failed => 'Failed',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final Color color;
        switch (c.link) {
          case LinkState.connected:
            color = AppColors.ok;
          case LinkState.connecting:
          case LinkState.reconnecting:
            color = AppColors.warn;
          case LinkState.disconnected:
          case LinkState.failed:
            color = cs.error;
        }
        final retry =
            c.link == LinkState.failed || c.link == LinkState.disconnected;
        return Tooltip(
          message: retry ? '${c.linkLabel} - tap to retry' : c.linkLabel,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: retry ? c.reconnect : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _shortLabel(c.link),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
