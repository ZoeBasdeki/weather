import 'package:flutter/material.dart';

import '../../models/forecast.dart';
import '../format.dart';
import 'wind_arrow.dart';

class CurrentConditions extends StatelessWidget {
  const CurrentConditions({super.key, required this.current, this.today});

  final CurrentWeather current;

  /// Today's daily summary, for the high/low line. Optional.
  final DailyWeather? today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final condition = current.condition;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  condition.icon(isDay: current.isDay),
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(Fmt.temp(current.temperature), style: theme.textTheme.displayLarge),
              ],
            ),
            const SizedBox(height: 4),
            Text(condition.description, style: theme.textTheme.titleMedium),
            Text(
              'Feels like ${Fmt.temp(current.apparentTemperature)}'
              '${today == null ? '' : '  ·  H ${Fmt.temp(today!.temperatureMax)}  L ${Fmt.temp(today!.temperatureMin)}'}',
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 32),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 12,
              children: [
                _Stat(
                  icon: Icons.umbrella,
                  label: 'Precip.',
                  value: '${Fmt.percent(current.precipitationProbability)} · ${Fmt.mm(current.precipitation)}',
                ),
                _Stat(
                  icon: Icons.air,
                  label: 'Wind',
                  value: Fmt.wind(current.windSpeed, current.windDirection),
                  trailing: WindArrow(direction: current.windDirection, size: 14),
                ),
                _Stat(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: Fmt.percent(current.humidity),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: theme.textTheme.bodyMedium),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
      ],
    );
  }
}
