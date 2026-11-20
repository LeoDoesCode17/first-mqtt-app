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
class _ConnectionBadge extends StatelessWidget {
  final EcoprintController c;
  const _ConnectionBadge({required this.c});

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
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: retry ? c.reconnect : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
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
                Text(
                  c.linkLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
