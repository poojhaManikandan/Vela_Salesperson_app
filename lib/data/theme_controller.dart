import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted dark-mode toggle shared between Settings and the root app.
class ThemeController extends ValueNotifier<bool> {
  ThemeController(super.dark);

  static const String _prefsKey = 'velan_dark_mode';

  static ThemeController? _instance;

  static ThemeController get instance => _instance ??= ThemeController(false);

  static Future<ThemeController> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = ThemeController(prefs.getBool(_prefsKey) ?? false);
    return _instance!;
  }

  Future<void> setDark(bool value) async {
    if (value == this.value) return;
    this.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
