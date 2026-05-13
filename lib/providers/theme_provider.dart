import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(themeKey, _isDarkMode);
  }

  void setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(themeKey, value);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(themeKey) ?? false;
    notifyListeners();
  }
}
