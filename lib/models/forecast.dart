import 'json_utils.dart';
import 'weather_code.dart';

/// Parsed Open-Meteo `/v1/forecast` response.
///
/// All times are the location's local wall-clock time (the request uses
/// `timezone=auto`, and Open-Meteo returns ISO strings without an offset).
/// Don't compare them directly with the device's `DateTime.now()` if the
/// location is in a different timezone.
class Forecast {
  const Forecast({
    required this.timezone,
    required this.utcOffsetSeconds,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final String? timezone;
  final int utcOffsetSeconds;
  final CurrentWeather? current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      timezone: asString(json['timezone']),
      utcOffsetSeconds: asInt(json['utc_offset_seconds']) ?? 0,
      current: CurrentWeather.fromJson(json['current']),
      hourly: HourlyWeather.listFromJson(json['hourly']),
      daily: DailyWeather.listFromJson(json['daily']),
    );
  }
}

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    this.temperature,
    this.apparentTemperature,
    this.precipitationProbability,
    this.precipitation,
    this.windSpeed,
    this.windDirection,
    this.humidity,
    this.weatherCode,
    this.isDay = true,
  });

  final DateTime time;
  final double? temperature; // °C
  final double? apparentTemperature; // °C
  final int? precipitationProbability; // %
  final double? precipitation; // mm
  final double? windSpeed; // km/h
  final int? windDirection; // degrees, direction the wind comes FROM
  final int? humidity; // %
  final int? weatherCode;
  final bool isDay;

  WeatherCode get condition => WeatherCode.fromCode(weatherCode);

  static CurrentWeather? fromJson(Object? json) {
    final m = asMap(json);
    final time = asDateTime(m['time']);
    if (time == null) return null;
    return CurrentWeather(
      time: time,
      temperature: asDouble(m['temperature_2m']),
      apparentTemperature: asDouble(m['apparent_temperature']),
      precipitationProbability: asInt(m['precipitation_probability']),
      precipitation: asDouble(m['precipitation']),
      windSpeed: asDouble(m['wind_speed_10m']),
      windDirection: asInt(m['wind_direction_10m']),
      humidity: asInt(m['relative_humidity_2m']),
      weatherCode: asInt(m['weather_code']),
      isDay: asInt(m['is_day']) != 0,
    );
  }
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    this.temperature,
    this.apparentTemperature,
    this.precipitationProbability,
    this.precipitation,
    this.windSpeed,
    this.windDirection,
    this.humidity,
    this.weatherCode,
    this.isDay = true,
  });

  final DateTime time;
  final double? temperature;
  final double? apparentTemperature;
  final int? precipitationProbability;
  final double? precipitation;
  final double? windSpeed;
  final int? windDirection;
  final int? humidity;
  final int? weatherCode;
  final bool isDay;

  WeatherCode get condition => WeatherCode.fromCode(weatherCode);

  /// Open-Meteo returns hourly data as parallel arrays keyed by variable.
  /// Rows with an unparseable time are skipped; shorter arrays yield nulls.
  static List<HourlyWeather> listFromJson(Object? json) {
    final m = asMap(json);
    final times = asList(m['time']);
    final temp = asList(m['temperature_2m']);
    final feels = asList(m['apparent_temperature']);
    final pop = asList(m['precipitation_probability']);
    final precip = asList(m['precipitation']);
    final wind = asList(m['wind_speed_10m']);
    final windDir = asList(m['wind_direction_10m']);
    final hum = asList(m['relative_humidity_2m']);
    final code = asList(m['weather_code']);
    final isDay = asList(m['is_day']);

    final result = <HourlyWeather>[];
    for (var i = 0; i < times.length; i++) {
      final time = asDateTime(times[i]);
      if (time == null) continue;
      result.add(HourlyWeather(
        time: time,
        temperature: asDouble(at(temp, i)),
        apparentTemperature: asDouble(at(feels, i)),
        precipitationProbability: asInt(at(pop, i)),
        precipitation: asDouble(at(precip, i)),
        windSpeed: asDouble(at(wind, i)),
        windDirection: asInt(at(windDir, i)),
        humidity: asInt(at(hum, i)),
        weatherCode: asInt(at(code, i)),
        isDay: asInt(at(isDay, i)) != 0,
      ));
    }
    return result;
  }
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    this.temperatureMax,
    this.temperatureMin,
    this.apparentTemperatureMax,
    this.apparentTemperatureMin,
    this.precipitationProbabilityMax,
    this.precipitationSum,
    this.windSpeedMax,
    this.windDirectionDominant,
    this.humidityMean,
    this.weatherCode,
  });

  final DateTime date;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? apparentTemperatureMax;
  final double? apparentTemperatureMin;
  final int? precipitationProbabilityMax;
  final double? precipitationSum;
  final double? windSpeedMax;
  final int? windDirectionDominant;
  final int? humidityMean;
  final int? weatherCode;

  WeatherCode get condition => WeatherCode.fromCode(weatherCode);

  static List<DailyWeather> listFromJson(Object? json) {
    final m = asMap(json);
    final times = asList(m['time']);
    final code = asList(m['weather_code']);
    final tMax = asList(m['temperature_2m_max']);
    final tMin = asList(m['temperature_2m_min']);
    final fMax = asList(m['apparent_temperature_max']);
    final fMin = asList(m['apparent_temperature_min']);
    final pop = asList(m['precipitation_probability_max']);
    final precip = asList(m['precipitation_sum']);
    final wind = asList(m['wind_speed_10m_max']);
    final windDir = asList(m['wind_direction_10m_dominant']);
    final hum = asList(m['relative_humidity_2m_mean']);

    final result = <DailyWeather>[];
    for (var i = 0; i < times.length; i++) {
      final date = asDateTime(times[i]);
      if (date == null) continue;
      result.add(DailyWeather(
        date: date,
        weatherCode: asInt(at(code, i)),
        temperatureMax: asDouble(at(tMax, i)),
        temperatureMin: asDouble(at(tMin, i)),
        apparentTemperatureMax: asDouble(at(fMax, i)),
        apparentTemperatureMin: asDouble(at(fMin, i)),
        precipitationProbabilityMax: asInt(at(pop, i)),
        precipitationSum: asDouble(at(precip, i)),
        windSpeedMax: asDouble(at(wind, i)),
        windDirectionDominant: asInt(at(windDir, i)),
        humidityMean: asInt(at(hum, i)),
      ));
    }
    return result;
  }
}
