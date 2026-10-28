import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/json_utils.dart';
import '../models/place.dart';

/// Persists the user's saved places (in page order) and which page was shown
/// last, in SharedPreferences.
class SavedPlacesService {
  SavedPlacesService({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _kPlaces = 'saved.places';
  static const _kLastShown = 'saved.lastShown';

  Future<List<Place>> load() async {
    try {
      final raw = await _prefs.getString(_kPlaces);
      if (raw == null) return const [];
      return asList(jsonDecode(raw)).map(Place.fromJson).whereType<Place>().toList();
    } catch (_) {
      // Corrupt data is not fatal; behave as if nothing is saved.
      return const [];
    }
  }

  Future<void> save(List<Place> places) =>
      _prefs.setString(_kPlaces, jsonEncode(places.map((p) => p.toJson()).toList()));

  /// [Place.id] of the page shown when the app was last used, if any.
  Future<String?> loadLastShown() async {
    try {
      return await _prefs.getString(_kLastShown);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastShown(String placeId) async {
    try {
      await _prefs.setString(_kLastShown, placeId);
    } catch (_) {
      // Only a convenience; not worth surfacing.
    }
  }
}
