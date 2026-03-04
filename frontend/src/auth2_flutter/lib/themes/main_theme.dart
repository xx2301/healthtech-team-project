import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

ThemeData mainTheme = ThemeData(
brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2F7D63),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,));

ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2F7D63),
      onPrimary: Colors.white,
      surface: Color(0xFF121212),
      onSurface: Colors.white,
    ));

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
