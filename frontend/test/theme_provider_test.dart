import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexus_ai/core/theme/theme_provider.dart';


void main() {
  test('ThemeProvider defaults to system and loads persisted value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);
    await provider.load();
    expect(provider.mode, ThemeMode.dark);
  });

  test('toggle switches dark<->light and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);
    await provider.load();
    // default system -> toggle makes dark
    await provider.toggle();
    expect(provider.mode, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
    await provider.toggle();
    expect(provider.mode, ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('setMode persists named mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);
    await provider.load();
    await provider.setMode(ThemeMode.dark);
    expect(provider.mode, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
