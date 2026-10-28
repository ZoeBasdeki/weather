import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/location_service.dart';
import '../services/weather_repository.dart';
import 'format.dart';
import 'widgets/current_conditions.dart';
import 'widgets/daily_list.dart';
import 'widgets/hourly_strip.dart';

/// One swipeable page: the forecast for a single place. Owns its own loading /
/// error state and is kept alive while swiping so it doesn't refetch.
class ForecastPage extends StatefulWidget {
  const ForecastPage({
    super.key,
    required this.place,
    required this.repository,
    required this.location,
    required this.onSearch,
  });

  /// The place to show, or null for the device location.
  final Place? place;
  final WeatherRepository repository;
  final LocationService location;
  final VoidCallback onSearch;

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> with AutomaticKeepAliveClientMixin {
  ForecastResult? _result;
  String? _error;
  LocationException? _locationError;
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Show cached data immediately, then refresh in the background.
  Future<void> _start() async {
    final id = widget.place?.id ?? Place.currentLocationId;
    final cached = await widget.repository.loadCached(id);
    if (!mounted) return;
    if (cached != null) setState(() => _result = cached);
    await _refresh();
  }

  Future<void> _refresh() {
    final place = widget.place;
    return place == null ? _useCurrentLocation() : _load(place);
  }

  Future<void> _load(Place place) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.fetch(place);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Gets a GPS fix and loads weather for it. If location fails, any cached
  /// forecast for the last fix stays on screen.
  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _locationError = null;
    });
    try {
      final place = await widget.location.currentPlace();
      if (!mounted) return;
      await _load(place);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e;
        _loading = false;
      });
      if (_result != null) _showLocationSnack(e);
    }
  }

  VoidCallback? _settingsAction(LocationFailure? reason) => switch (reason) {
        LocationFailure.serviceDisabled => widget.location.openLocationSettings,
        LocationFailure.deniedForever => widget.location.openAppSettings,
        _ => null,
      };

  void _showLocationSnack(LocationException e) {
    final settings = _settingsAction(e.reason);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.message),
      action: settings == null ? null : SnackBarAction(label: 'Settings', onPressed: settings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final result = _result;
    return Column(
      children: [
        SizedBox(
          height: 2,
          child: _loading && result != null ? const LinearProgressIndicator(minHeight: 2) : null,
        ),
        Expanded(child: result == null ? _buildEmpty() : _buildForecast(result)),
      ],
    );
  }

  Widget _buildEmpty() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final message = _locationError?.message ?? _error ?? 'No data yet';
    final settings = _settingsAction(_locationError?.reason);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                if (settings != null)
                  OutlinedButton.icon(
                    onPressed: settings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                if (widget.place == null)
                  OutlinedButton.icon(
                    onPressed: widget.onSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('Search city'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast(ForecastResult result) {
    final f = result.forecast;
    final theme = Theme.of(context);
    final current = f.current;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Hidden during the startup refresh so cached data doesn't flash a warning.
          if (result.fromCache && !_loading)
            MaterialBanner(
              leading: const Icon(Icons.cloud_off),
              content: Text(
                'Showing saved data from ${Fmt.dateTime(result.fetchedAt)}'
                '${result.error == null ? '' : '\n${result.error}'}',
              ),
              actions: [TextButton(onPressed: _loading ? null : _refresh, child: const Text('Retry'))],
            ),
          if (result.place.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(result.place.subtitle, style: theme.textTheme.bodyMedium),
            ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: CurrentConditions(
                current: current,
                today: f.daily.isEmpty ? null : f.daily.first,
              ),
            ),
          if (f.hourly.isNotEmpty) ...[
            _SectionTitle('Next 48 hours'),
            HourlyStrip(hours: f.hourly),
          ],
          if (f.daily.isNotEmpty) ...[
            _SectionTitle('${f.daily.length}-day forecast'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DailyList(days: f.daily),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
