import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/geocoding_service.dart';

/// City search. Pops with the selected [Place], or null if cancelled.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.geocoding});

  final GeocodingService geocoding;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Timer? _debounce;
  List<Place> _results = const [];
  String? _error;
  bool _loading = false;
  bool _noMatches = false;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String text) async {
    // Ignore responses that arrive after a newer query was sent.
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.geocoding.search(text);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _noMatches = results.isEmpty && text.trim().length >= 2;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = const [];
        _noMatches = false;
        _error = e.toString();
      });
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search city',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (text) {
            _debounce?.cancel();
            _search(text);
          },
        ),
        // Always present: toggling `bottom` on/off makes AppBar restructure its
        // subtree, which recreates the TextField and wipes the typed text.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _loading
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox(height: 2),
        ),
      ),
      body: _error != null || _noMatches
          ? Center(child: Text(_error ?? 'No matching places'))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final place = _results[i];
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(place.name),
                  subtitle: place.subtitle.isEmpty ? null : Text(place.subtitle),
                  onTap: () => Navigator.of(context).pop(place),
                );
              },
            ),
    );
  }
}
