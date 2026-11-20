import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/theme.dart';
import 'package:first_mqtt_app/screens/home_shell.dart';

void main() {
  runApp(const EcoprintApp());
}

class EcoprintApp extends StatelessWidget {
  const EcoprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecoprint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
