import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/saved_places_service.dart';
import '../services/weather_repository.dart';
import 'about_screen.dart';
import 'forecast_page.dart';
import 'search_screen.dart';

/// Swipeable forecast pages: the device location first, then each saved place.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.location,
    required this.geocoding,
    required this.savedPlaces,
  });

  final WeatherRepository repository;
  final LocationService location;
  final GeocodingService geocoding;
  final SavedPlacesService savedPlaces;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Null until the saved places have loaded (the initial page depends on them).
  PageController? _pages;
  List<Place> _saved = const [];
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  /// Reopen on the page that was shown last.
  Future<void> _init() async {
    final saved = await widget.savedPlaces.load();
    final lastShown = await widget.savedPlaces.loadLastShown();
    if (!mounted) return;
    // indexWhere gives -1 when not found, which maps to page 0 (My location).
    final page = saved.indexWhere((p) => p.id == lastShown) + 1;
    setState(() {
      _saved = saved;
      _page = page;
      _pages = PageController(initialPage: page);
    });
  }

  /// Page 0 is the device location; saved places follow in order.
  String _idAt(int page) => page == 0 ? Place.currentLocationId : _saved[page - 1].id;

  String _titleAt(int page) => page == 0 ? 'My location' : _saved[page - 1].name;

  void _onPageChanged(int page) {
    setState(() => _page = page);
    widget.savedPlaces.saveLastShown(_idAt(page));
  }

  /// Shows [page], once the PageView has rebuilt with the current page list.
  void _goTo(int page) {
    setState(() => _page = page);
    widget.savedPlaces.saveLastShown(_idAt(page));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pages = _pages;
      if (pages != null && pages.hasClients) pages.jumpToPage(page);
    });
  }

  Future<void> _setSaved(List<Place> places) async {
    setState(() => _saved = places);
    try {
      await widget.savedPlaces.save(places);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not save locations')));
    }
  }

  /// Adds the searched city as a page (unless it already has one) and shows it.
  Future<void> _openSearch() async {
    final place = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => SearchScreen(geocoding: widget.geocoding)),
    );
    if (place == null || !mounted) return;
    var index = _saved.indexWhere((p) => p.id == place.id);
    if (index == -1) {
      index = _saved.length;
      _setSaved([..._saved, place]);
    }
    _goTo(index + 1);
  }

  void _remove(Place place) {
    final index = _saved.indexWhere((p) => p.id == place.id);
    if (index == -1) return;
    final removedPage = index + 1;
    // Keep showing the same place; if it was the removed one, show the page before it.
    final page = _page >= removedPage ? _page - 1 : _page;
    _setSaved([..._saved]..removeAt(index));
    widget.repository.forget(place.id);
    _goTo(page);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Removed ${place.name}'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (!mounted || _saved.any((p) => p.id == place.id)) return;
          final at = index.clamp(0, _saved.length);
          _setSaved([..._saved]..insert(at, place));
          _goTo(at + 1);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleAt(_page)),
        actions: [
          if (_page > 0)
            IconButton(
              tooltip: 'Remove location',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(_saved[_page - 1]),
            ),
          IconButton(
            tooltip: 'Add city',
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: pages == null
          ? const SizedBox.shrink()
          : PageView(
              controller: pages,
              onPageChanged: _onPageChanged,
              children: [
                // Keys keep each page's state when places are added or removed.
                ForecastPage(
                  key: const ValueKey(Place.currentLocationId),
                  place: null,
                  repository: widget.repository,
                  location: widget.location,
                  onSearch: _openSearch,
                ),
                for (final place in _saved)
                  ForecastPage(
                    key: ValueKey(place.id),
                    place: place,
                    repository: widget.repository,
                    location: widget.location,
                    onSearch: _openSearch,
                  ),
              ],
            ),
      bottomNavigationBar: _saved.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _PageDots(count: _saved.length + 1, current: _page),
              ),
            ),
    );
  }

  /// Lists every page for jumping straight to one, with remove buttons.
  Widget _buildDrawer() {
    void pick(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Locations', style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('My location'),
              selected: _page == 0,
              onTap: () => pick(() => _goTo(0)),
            ),
            for (final (i, place) in _saved.indexed)
              ListTile(
                leading: const Icon(Icons.place),
                title: Text(place.name),
                subtitle: place.subtitle.isEmpty ? null : Text(place.subtitle),
                selected: _page == i + 1,
                onTap: () => pick(() => _goTo(i + 1)),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => _remove(place),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Add city'),
              onTap: () => pick(_openSearch),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page indicator; the first page (device location) gets a small arrow icon.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color colorAt(int i) => i == current ? scheme.primary : scheme.outlineVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: i == 0
                ? Icon(Icons.near_me, size: 10, color: colorAt(i))
                : Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: colorAt(i)),
                  ),
          ),
      ],
    );
  }
}
