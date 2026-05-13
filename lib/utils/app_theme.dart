import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Lexend',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1ABC9C)),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1ABC9C),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Lexend',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1ABC9C), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF181A20),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181A20),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1ABC9C),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
