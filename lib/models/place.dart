import 'json_utils.dart';

/// A location to fetch weather for: either a geocoded city or the device GPS fix.
class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
    this.isCurrentLocation = false,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? admin1;
  final String? country;
  final bool isCurrentLocation;

  /// e.g. "Athens, Attica, Greece"
  String get subtitle =>
      [admin1, country].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  /// [id] of the device location, whatever its current coordinates.
  static const currentLocationId = 'gps';

  /// Stable key for saved places and per-place cache entries. All GPS fixes
  /// share one id, since "My location" moves.
  String get id => isCurrentLocation ? currentLocationId : '$latitude,$longitude';

  /// Parses one entry of the Open-Meteo geocoding `results` array.
  /// Returns null if the entry lacks a name or coordinates.
  static Place? fromGeocodingJson(Object? json) {
    final m = asMap(json);
    final name = asString(m['name']);
    final lat = asDouble(m['latitude']);
    final lon = asDouble(m['longitude']);
    if (name == null || lat == null || lon == null) return null;
    return Place(
      name: name,
      latitude: lat,
      longitude: lon,
      admin1: asString(m['admin1']),
      country: asString(m['country']),
    );
  }

  /// Parses the format written by [toJson] (used by the local cache).
  static Place? fromJson(Object? json) {
    final m = asMap(json);
    final name = asString(m['name']);
    final lat = asDouble(m['latitude']);
    final lon = asDouble(m['longitude']);
    if (name == null || lat == null || lon == null) return null;
    return Place(
      name: name,
      latitude: lat,
      longitude: lon,
      admin1: asString(m['admin1']),
      country: asString(m['country']),
      isCurrentLocation: m['isCurrentLocation'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'admin1': admin1,
        'country': country,
        'isCurrentLocation': isCurrentLocation,
      };
}
