import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

/// What's stored on disk: the raw forecast JSON plus the place it belongs to.
/// Keeping the raw body (instead of the parsed model) means model changes
/// don't invalidate the cache.
class CachedForecast {
  const CachedForecast({
    required this.place,
    required this.json,
    required this.fetchedAt,
  });

  final Place place;
  final String json;
  final DateTime fetchedAt;
}

/// Persists the last successful forecast response per place (keyed by
/// [Place.id]) in SharedPreferences.
class CacheService {
  CacheService({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  // Separate keys per place, so pages saving at the same time don't clobber
  // each other the way a shared read-modify-write map would.
  static String _kJson(String id) => 'forecast.$id.json';
  static String _kPlace(String id) => 'forecast.$id.place';
  static String _kFetchedAt(String id) => 'forecast.$id.fetchedAt';

  Future<CachedForecast?> load(String placeId) async {
    try {
      final json = await _prefs.getString(_kJson(placeId));
      final placeRaw = await _prefs.getString(_kPlace(placeId));
      final fetchedAtMs = await _prefs.getInt(_kFetchedAt(placeId));
      if (json == null || placeRaw == null || fetchedAtMs == null) return null;

      final place = Place.fromJson(jsonDecode(placeRaw));
      if (place == null) return null;

      return CachedForecast(
        place: place,
        json: json,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAtMs),
      );
    } catch (_) {
      // Corrupt cache is not fatal; behave as if empty.
      return null;
    }
  }

  Future<void> save(CachedForecast entry) async {
    final id = entry.place.id;
    await _prefs.setString(_kJson(id), entry.json);
    await _prefs.setString(_kPlace(id), jsonEncode(entry.place.toJson()));
    await _prefs.setInt(_kFetchedAt(id), entry.fetchedAt.millisecondsSinceEpoch);
  }

  Future<void> remove(String placeId) =>
      _prefs.clear(allowList: {_kJson(placeId), _kPlace(placeId), _kFetchedAt(placeId)});
}
