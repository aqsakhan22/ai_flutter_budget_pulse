import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF4F46E5),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4F46E5),
        secondary: Color(0xFF10B981),
        error: Color(0xFFEF4444),
        surface: Color(0xFF1E293B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
      ),
    );
  }
}