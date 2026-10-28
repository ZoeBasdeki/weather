import 'package:intl/intl.dart';

/// Display formatting. Every helper accepts null and renders a dash.
abstract final class Fmt {
  static const dash = '–';

  static String temp(double? c) => c == null ? dash : '${c.round()}°';
  static String percent(int? p) => p == null ? dash : '$p%';
  static String mm(double? v) => v == null ? dash : '${v.toStringAsFixed(1)} mm';
  static String kmh(double? v) => v == null ? dash : '${v.round()} km/h';

  static String wind(double? speed, int? dir) =>
      dir == null ? kmh(speed) : '${kmh(speed)} ${compass(dir)}';

  static const _points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  /// Meteorological direction (where the wind comes from) as an 8-point label.
  static String compass(int deg) => _points[((deg % 360) / 45).round() % 8];

  static final _hour = DateFormat.Hm();
  static final _day = DateFormat('EEE d MMM');
  static final _dateTime = DateFormat('d MMM, HH:mm');

  static String hour(DateTime t) => _hour.format(t);
  static String day(DateTime t) => _day.format(t);
  static String dateTime(DateTime t) => _dateTime.format(t);
}
