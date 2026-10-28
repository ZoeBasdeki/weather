/// Null-safe helpers for reading loosely-typed JSON.
///
/// Open-Meteo may return `null` for individual values (e.g. precipitation
/// probability for days beyond the model horizon) and fields may be missing
/// entirely, so nothing here throws: bad or absent input yields `null`
/// (or an empty collection).
library;

double? asDouble(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };

int? asInt(Object? v) => switch (v) {
      int n => n,
      num n => n.round(),
      String s => int.tryParse(s),
      _ => null,
    };

String? asString(Object? v) => v is String ? v : null;

DateTime? asDateTime(Object? v) => v is String ? DateTime.tryParse(v) : null;

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : const {};

List<Object?> asList(Object? v) => v is List ? v : const [];

/// Safe index into a JSON list; returns null when out of range.
Object? at(List<Object?> list, int i) => i < list.length ? list[i] : null;
