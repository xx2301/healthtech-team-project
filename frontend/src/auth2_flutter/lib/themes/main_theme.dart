import 'package:flutter/material.dart';

ThemeData mainTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Colors.green.shade500,
    secondary: Colors.green.shade200,
    tertiary: Colors.white,
    inversePrimary: Colors.blue.shade500,
  ),
  scaffoldBackgroundColor: Colors.green.shade300,
  appBarTheme: AppBarTheme(backgroundColor: Colors.green.shade400, iconTheme: IconThemeData(color: Colors.white),),
);
