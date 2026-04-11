import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<ThemeData> {
  final SharedPreferences prefs;
  static const String themeKey = 'elite_theme_index';

  ThemeNotifier(this.prefs) : super(_loadTheme(prefs));

  static ThemeData _loadTheme(SharedPreferences prefs) {
    int index = prefs.getInt(themeKey) ?? 0;
    return _getThemeFromIndex(index);
  }

  static ThemeData _getThemeFromIndex(int index) {
    switch (index) {
      case 0:
        return AppTheme.eliteLight;
      case 1:
        return AppTheme.midnightElite;
      case 2:
        return AppTheme.royalPrestige;
      default:
        return AppTheme.eliteLight;
    }
  }

  int get currentThemeIndex => prefs.getInt(themeKey) ?? 0;

  void setTheme(int index) {
    state = _getThemeFromIndex(index);
    prefs.setInt(themeKey, index);
  }
}
