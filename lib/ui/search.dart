// The map's search: lines and stops by name, accents and case ignored, metro, tram and suburban rail
// stations, and places and addresses from OpenStreetMap. What you pick opens in the map's sheet.
// Chips under the field pick the modes (Λεωφορεία, Μετρό, Τραμ, Προαστιακός): they filter the results
// and show or hide that mode on the map. A query whose only hits are in a hidden mode says so.

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api.dart';
import '../core/map_geo.dart' show isTram;
import '../core/models.dart';
import '../core/nearby.dart';
import 'map_sel.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.ix, this.trailing});
  final TripIndex? ix;
  final Widget? trailing; // beside the field, in the same row

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _c = TextEditingController();
  final _focus = FocusNode();
  List<LineInfo> _lines = [];
  List<LineInfo> _lineHits = [];
  List<NearbyStop> _stopHits = [];
  List<Place> _placeHits = [];
  List<_Station> _stations = [];
  List<_Station> _stationHits = [];
  int _hidden = 0; // hits left out because their mode is off
  bool _buses = true; // bus lines and stops in the results (the map always shows buses)
  Timer? _wait; // places are asked once typing pauses
  int _asked = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = Deps.of(context).api;
    if (_lines.isEmpty) api.lines().then((l) => mounted ? setState(() => _lines = l) : null).ignore();
    if (_stations.isEmpty) {
      Future.wait([
        api.metro().then((j) => [
              for (final st in j['stations'] as List)
                () {
                  final ls = [for (final l in st['lines'] as List) l as String];
                  return _Station(st['name'] as String, (st['lat'] as num).toDouble(), (st['lon'] as num).toDouble(), ls, ls.every(isTram) ? _Mode.tram : _Mode.metro);
                }(),
            ]),
        api.suburban().then((sub) => [for (final st in sub.stations.values) _Station(st.name, st.lat, st.lon, st.corridors, _Mode.rail, railId: st.id)]),
      ]).then((all) {
        if (mounted) setState(() => _stations = [for (final l in all) ...l]);
      }).catchError((_) {});
    }
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  bool _on(_Mode m) {
    final store = Deps.of(context).store;
    return switch (m) { _Mode.bus => _buses, _Mode.metro => store.showMetro, _Mode.tram => store.showTram, _Mode.rail => store.showRail };
  }

  void _toggle(_Mode m) {
    final store = Deps.of(context).store;
    switch (m) {
      case _Mode.bus:
        _buses = !_buses;
      case _Mode.metro:
        store.setRail(metro: !store.showMetro);
      case _Mode.tram:
        store.setRail(tram: !store.showTram);
      case _Mode.rail:
        store.setRail(rail: !store.showRail);
    }
    _search(_c.text);
  }

  // Turn on every mode: a query found only hidden ones.
  void _showAll() {
    _buses = true;
    Deps.of(context).store.setRail(metro: true, tram: true, rail: true);
    _search(_c.text);
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    final f = fold(q.trim());
    final ix = widget.ix;
    _wait?.cancel();
    final n = ++_asked;
    _placeHits = []; // never offer the places of an earlier query
    if (f.isEmpty) {
      setState(() {
        _lineHits = [];
        _stopHits = [];
        _placeHits = [];
        _stationHits = [];
        _hidden = 0;
      });
      return;
    }
    if (q.trim().length >= 3) {
      _wait = Timer(const Duration(milliseconds: 400), () async {
        try {
          final ps = await Deps.of(context).api.places(q.trim());
          if (mounted && n == _asked) setState(() => _placeHits = ps.take(4).toList());
        } catch (_) {/* offline: lines and stops still work */}
      });
    }
    final lines = _lines.where((l) => fold(l.id).startsWith(f) || (f.length > 2 && nameMatches(l.name, q))).take(5).toList();
    final stations = f.length > 1 ? _stations.where((st) => nameMatches(st.name, q)).toList() : <_Station>[];
    final stops = <NearbyStop>[];
    if (ix != null && f.length > 2) {
      final seen = <String>{};
      for (var i = 0; i < ix.s.length && stops.length < 6; i++) {
        final s = ix.s[i];
        if (nameMatches(s.$1, q) && seen.add(s.$1)) stops.addAll(nearbyStops(ix, (s.$2, s.$3), radiusM: 50, max: 1));
      }
    }
    final shownStations = [for (final st in stations) if (_on(st.mode)) st];
    setState(() {
      _lineHits = _buses ? lines : [];
      _stopHits = _buses ? stops : [];
      _stationHits = shownStations.take(5).toList();
      _hidden = (_buses ? 0 : lines.length + stops.length) + stations.length - shownStations.length;
    });
  }

  void _clear() {
    _c.clear();
    _focus.unfocus();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final store = Deps.of(context).store;
    final field = Material(
        color: t.ground,
        elevation: 3,
        shadowColor: const Color(0x33000000),
        borderRadius: BorderRadius.circular(28),
        child: TextField(
          controller: _c,
          focusNode: _focus,
          onChanged: _search,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _c.text.isEmpty ? null : IconButton(tooltip: 'Καθαρισμός', icon: const Icon(Icons.close), onPressed: _clear),
            hintText: 'Στάση, γραμμή ή μέρος',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: field), if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!]]),
      const SizedBox(height: 6),
      if (_focus.hasFocus || _c.text.isNotEmpty)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final m in _Mode.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: Icon(m.icon, size: 18),
                  label: Text(m.label),
                  selected: _on(m),
                  showCheckmark: false,
                  backgroundColor: t.ground,
                  onSelected: (_) => _toggle(m),
                ),
              ),
          ]),
        ),
      if (_hidden > 0 && _lineHits.isEmpty && _stopHits.isEmpty && _stationHits.isEmpty)
        Material(
          color: t.ground,
          elevation: 3,
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text('$_hidden ${_hidden == 1 ? 'αποτέλεσμα' : 'αποτελέσματα'} σε κρυμμένα μέσα'),
            trailing: TextButton(onPressed: _showAll, child: const Text('Εμφάνιση')),
          ),
        ),
      if (_lineHits.isNotEmpty || _stopHits.isNotEmpty || _placeHits.isNotEmpty || _stationHits.isNotEmpty)
        // Above the keyboard, and scrolls when lines, stops and places do not fit: the room left in the
        // map's body, which the Scaffold already shrinks for the keyboard (viewInsets read 0 here).
        Flexible(
          child: Material(
          color: t.ground,
          elevation: 3,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 6), children: [
              for (final l in _lineHits)
                ListTile(
                  leading: LineBadge(l.id),
                  title: Text(titleCase(l.name), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Icon(store.myLines.contains(l.id) ? Icons.star : Icons.star_outline),
                  onTap: () {
                    _clear();
                    mapSel.value = LineSel(l.id);
                  },
                ),
              for (final st in _stationHits)
                ListTile(
                  leading: Icon(st.mode.icon),
                  title: Text(titleCase(st.name)),
                  subtitle: Text('${st.mode.label} · ${st.lines.join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _clear();
                    mapSel.value = StationSel(st.name, (st.lat, st.lon), lines: st.lines, railId: st.railId);
                  },
                ),
              for (final s in _stopHits)
                ListTile(
                  leading: const Icon(Icons.directions_bus_outlined),
                  title: Text(titleCase(s.name)),
                  subtitle: Text(s.lines.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _clear();
                    mapSel.value = StopSel(StopRef(name: s.name, lat: s.lat, lon: s.lon, lines: linesAt(widget.ix!, s.name, s.lat, s.lon)));
                  },
                ),
              for (final p in _placeHits)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: p.detail.isEmpty ? null : Text(p.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _clear();
                    mapSel.value = PlaceSel(p.name, (p.lat, p.lon));
                  },
                ),
            ]),
        )),
    ]);
  }
}

enum _Mode {
  bus('Λεωφορεία', Icons.directions_bus_outlined),
  metro('Μετρό', Icons.subway_outlined),
  tram('Τραμ', Icons.tram_outlined),
  rail('Προαστιακός', Icons.train_outlined);

  const _Mode(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _Station {
  const _Station(this.name, this.lat, this.lon, this.lines, this.mode, {this.railId});
  final String name;
  final double lat, lon;
  final List<String> lines;
  final _Mode mode;
  final String? railId;
}
