import 'package:flutter/material.dart';

class AppColors {
  static const ok = Color(0xFF2E9E5B);
  static const warn = Color(0xFFF59E0B);
  static const hot = Color(0xFFEF6C00);
  static const water = Color(0xFF1E88E5);
  static const air = Color(0xFF8E24AA);
  static const humidity = Color(0xFF00ACC1);
}

class AppTheme {
  static const Color seed = Color(0xFF00897B);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
    );
  }
}
