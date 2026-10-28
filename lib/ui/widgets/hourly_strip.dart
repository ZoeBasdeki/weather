import 'package:flutter/material.dart';

import '../../models/forecast.dart';
import '../format.dart';
import 'wind_arrow.dart';

/// Horizontally scrolling 48-hour forecast.
class HourlyStrip extends StatelessWidget {
  const HourlyStrip({super.key, required this.hours});

  final List<HourlyWeather> hours;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: hours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        // forecast_hours starts at the current hour, so index 0 is "now".
        itemBuilder: (context, i) => _HourTile(hour: hours[i], isNow: i == 0),
      ),
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({required this.hour, required this.isNow});

  final HourlyWeather hour;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDate = hour.time.hour == 0;
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            isNow ? 'Now' : (showDate ? Fmt.day(hour.time).split(' ').first : Fmt.hour(hour.time)),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isNow || showDate ? FontWeight.bold : null,
            ),
          ),
          Tooltip(
            message: hour.condition.description,
            child: Icon(hour.condition.icon(isDay: hour.isDay), color: theme.colorScheme.primary),
          ),
          Text(Fmt.temp(hour.temperature), style: theme.textTheme.titleMedium),
          Text(
            Fmt.percent(hour.precipitationProbability),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WindArrow(direction: hour.windDirection, size: 12),
              const SizedBox(width: 2),
              Text(hour.windSpeed?.round().toString() ?? Fmt.dash, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
