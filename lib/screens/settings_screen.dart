import 'package:flutter/material.dart';

import 'package:first_mqtt_app/state/ecoprint_controller.dart';

class SettingsScreen extends StatefulWidget {
  final EcoprintController c;
  const SettingsScreen({super.key, required this.c});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _mac;

  static final RegExp _macRe = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');

  @override
  void initState() {
    super.initState();
    final s = widget.c.settings;
    _host = TextEditingController(text: s.host);
    _port = TextEditingController(text: '${s.port}');
    _mac = TextEditingController(text: s.mac);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _mac.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final s = widget.c.settings.copyWith(
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      mac: _mac.text.trim().toUpperCase(),
    );
    nav.pop();
    await widget.c.applySettings(s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('MQTT broker', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _host,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'raspberrypi.local or 192.168.1.42',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a host' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _port,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final p = int.tryParse((v ?? '').trim());
                return (p == null || p < 1 || p > 65535)
                    ? 'Enter a port between 1 and 65535'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            Text('Device', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mac,
              decoration: const InputDecoration(
                labelText: 'ESP32 MAC address',
                hintText: '68:FE:71:0C:C3:E0',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => _macRe.hasMatch((v ?? '').trim())
                  ? null
                  : 'Format: AA:BB:CC:DD:EE:FF',
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: _mac,
              builder: (context, _) => Text(
                'Topics: esp/${_mac.text.trim().toUpperCase()}/…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save & reconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
