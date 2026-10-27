// The map's search: lines and stops by name, accents and case ignored. A line or a stop opens in the
// map's sheet.

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/nearby.dart';
import 'map_sel.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.ix});
  final TripIndex? ix;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _c = TextEditingController();
  final _focus = FocusNode();
  List<LineInfo> _lines = [];
  List<LineInfo> _lineHits = [];
  List<NearbyStop> _stopHits = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lines.isEmpty) Deps.of(context).api.lines().then((l) => mounted ? setState(() => _lines = l) : null).ignore();
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    final f = fold(q.trim());
    final ix = widget.ix;
    if (f.isEmpty) {
      setState(() {
        _lineHits = [];
        _stopHits = [];
      });
      return;
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Material(
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
            hintText: 'Γραμμή ή στάση',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      if (_lineHits.isNotEmpty || _stopHits.isNotEmpty)
        Material(
          color: t.ground,
          elevation: 3,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  leading: const Icon(Icons.place_outlined),
                  title: Text(titleCase(s.name)),
                  subtitle: Text(s.lines.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _clear();
                    mapSel.value = StopSel(StopRef(name: s.name, lat: s.lat, lon: s.lon, lines: linesAt(widget.ix!, s.name, s.lat, s.lon)));
                  },
                ),
            ]),
          ),
        ),
    ]);
  }
}
