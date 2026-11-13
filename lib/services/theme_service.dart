import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the light/dark choice in SharedPreferences. Until the user picks
/// one, the app follows the system setting.
class ThemeService {
  ThemeService({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _kMode = 'theme.mode';

  Future<ThemeMode> load() async {
    try {
      final name = await _prefs.getString(_kMode);
      return ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) async {
    try {
      await _prefs.setString(_kMode, mode.name);
    } catch (_) {
      // Only a convenience; not worth surfacing.
    }
  }
}
