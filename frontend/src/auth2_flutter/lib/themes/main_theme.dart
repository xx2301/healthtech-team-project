import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

ThemeData mainTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2F7D63),
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  ),

  iconTheme: const IconThemeData(
    color: Colors.black,
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black,
    textColor: Colors.black,
  ),

  dividerColor: Colors.grey,

  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF2F7D63);
      }
      return Colors.grey.shade400;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF2F7D63).withOpacity(0.5);
      }
      return Colors.grey.shade300;
    }),
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2F7D63),
    onPrimary: Colors.white,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
  ),

  iconTheme: const IconThemeData(
    color: Colors.white,
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: Colors.white,
    textColor: Colors.white,
  ),

  dividerColor: Colors.white24,

  // 👇 ADD THIS
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF2F7D63);
      }
      return Colors.grey.shade500;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF2F7D63).withOpacity(0.6);
      }
      return Colors.grey.shade700;
    }),
  ),
);

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
