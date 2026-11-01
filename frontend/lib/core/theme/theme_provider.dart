import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final v = _prefs!.getString('theme_mode');
    if (v == 'light') _mode = ThemeMode.light;
    if (v == 'dark') _mode = ThemeMode.dark;
    if (v == 'system') _mode = ThemeMode.system;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      'theme_mode',
      _mode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('theme_mode', m.name);
    notifyListeners();
  }
}
