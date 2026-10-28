import 'package:flutter/material.dart';

import '../../models/forecast.dart';
import '../format.dart';
import 'wind_arrow.dart';

/// 14-day forecast. Tapping a row expands extra details.
class DailyList extends StatelessWidget {
  const DailyList({super.key, required this.days});

  final List<DailyWeather> days;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _DayTile(day: days[i], label: _label(i, days[i].date)),
          ],
        ],
      ),
    );
  }

  // daily[0] is "today" in the location's timezone, so label by index rather
  // than comparing with the device clock.
  static String _label(int i, DateTime date) => switch (i) {
        0 => 'Today',
        1 => 'Tomorrow',
        _ => Fmt.day(date),
      };
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.label});

  final DailyWeather day;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      shape: const Border(),
      leading: Icon(day.condition.dayIcon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: Text(
        '${day.condition.description} · ${Fmt.percent(day.precipitationProbabilityMax)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        '${Fmt.temp(day.temperatureMax)} / ${Fmt.temp(day.temperatureMin)}',
        style: theme.textTheme.titleMedium,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Feels like',
            '${Fmt.temp(day.apparentTemperatureMax)} / ${Fmt.temp(day.apparentTemperatureMin)}'),
        _row('Precipitation',
            '${Fmt.mm(day.precipitationSum)} (${Fmt.percent(day.precipitationProbabilityMax)})'),
        _row('Max wind', Fmt.wind(day.windSpeedMax, day.windDirectionDominant),
            WindArrow(direction: day.windDirectionDominant, size: 14)),
        _row('Humidity (mean)', Fmt.percent(day.humidityMean)),
      ],
    );
  }

  Widget _row(String label, String value, [Widget? trailing]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value),
            if (trailing != null) ...[const SizedBox(width: 4), trailing],
          ],
        ),
      );
}
