// The map's search: lines and stops by name, accents and case ignored, and places and addresses from
// OpenStreetMap. What you pick opens in the map's sheet.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/api.dart';
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
  Timer? _wait; // places are asked once typing pauses
  int _asked = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lines.isEmpty) Deps.of(context).api.lines().then((l) => mounted ? setState(() => _lines = l) : null).ignore();
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
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
    final lines = _lines.where((l) => fold(l.id).startsWith(f) || (f.length > 2 && fold(l.name).contains(f))).take(5).toList();
    final stops = <NearbyStop>[];
    if (ix != null && f.length > 2) {
      final seen = <String>{};
      for (var i = 0; i < ix.s.length && stops.length < 6; i++) {
        final s = ix.s[i];
        if (fold(s.$1).contains(f) && seen.add(s.$1)) stops.addAll(nearbyStops(ix, (s.$2, s.$3), radiusM: 50, max: 1));
      }
    }
    setState(() {
      _lineHits = lines;
      _stopHits = stops;
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
            hintText: 'Αναζήτηση',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: field), if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!]]),
      const SizedBox(height: 6),
      if (_lineHits.isNotEmpty || _stopHits.isNotEmpty || _placeHits.isNotEmpty)
        Material(
          color: t.ground,
          elevation: 3,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          // Above the keyboard, and scrolls when lines, stops and places do not fit.
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: max(0.0, MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom - 160)),
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
          ),
        ),
    ]);
  }
}
