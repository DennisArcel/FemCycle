import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Mallanna',
        scaffoldBackgroundColor: const Color(0xFFFBF7F1),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF84B2E9),
          secondary: Color(0xFFBC6B9C),
          surface: Colors.white,
          background: Color(0xFFFBF7F1),
        ),
        useMaterial3: true,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF84B2E9),
          foregroundColor: Colors.white,
        ),
      );

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Mallanna',
        scaffoldBackgroundColor: const Color(0xFF1A1D2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF84B2E9),
          secondary: Color(0xFFBC6B9C),
          surface: Color(0xFF252840),
          background: Color(0xFF1A1D2E),
        ),
        useMaterial3: true,
        cardColor: const Color(0xFF252840),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2235),
          foregroundColor: Colors.white,
        ),
      );
}

// ── Theme Color Helper ─────────────────────────────────────────────────────
// Use these in every screen instead of hardcoded colors
extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF1A1D2E) : const Color(0xFFFBF7F1);
  Color get cardColor => isDark ? const Color(0xFF252840) : Colors.white;
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF2B2638);
  Color get textSecondary => isDark ? const Color(0xFF888888) : const Color(0xFF6E677D);
  Color get textHint => isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
  Color get dividerColor => isDark ? const Color(0xFF333355) : const Color(0xFFF0EDE7);
  Color get inputFill => isDark ? const Color(0xFF1E2235) : const Color(0xFFFFFFFF);
}