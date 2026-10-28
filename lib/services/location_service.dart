import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/place.dart';

enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.reason);
  final LocationFailure reason;

  String get message => switch (reason) {
        LocationFailure.serviceDisabled => 'Location services are turned off',
        LocationFailure.denied => 'Location permission denied',
        LocationFailure.deniedForever =>
          'Location permission permanently denied. Enable it in app settings.',
        LocationFailure.unavailable => 'Could not determine your location',
      };

  @override
  String toString() => message;
}

/// Wraps geolocator: permission handling + a single low-accuracy fix.
/// City-level accuracy is plenty for weather and is faster / cheaper on battery.
class LocationService {
  Future<Place> currentPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      pos = await Geolocator.getLastKnownPosition();
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) {
      throw const LocationException(LocationFailure.unavailable);
    }

    return Place(
      name: 'My location',
      latitude: pos.latitude,
      longitude: pos.longitude,
      isCurrentLocation: true,
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
