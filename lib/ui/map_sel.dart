// What the map's sheet shows: a stop, one bus, or a whole line. Any screen can open one on the map
// (the Stops tab, the search) instead of pushing a page: the map stays behind the sheet.

import 'package:flutter/foundation.dart';

import '../core/geo.dart';
import 'stop_screen.dart';

sealed class MapSel {
  const MapSel();
}

class StopSel extends MapSel {
  const StopSel(this.stop);
  final StopRef stop;
}

class BusSel extends MapSel {
  const BusSel(this.line, this.vehicleId, {this.stop, this.at, this.variant});
  final String line, vehicleId;
  final StopRef? stop; // the stop it was opened from: its row is marked, and back returns to it
  final Pt? at; // where it was when opened, and its direction: for a bus outside the map's tiles
  final String? variant;
}

class LineSel extends MapSel {
  const LineSel(this.line, {this.variants});
  final String line;
  final Set<String>? variants; // one direction picked in the line's sheet; null: all
}

// A metro, ISAP or tram station (railId null), or a suburban rail station (railId: railway.gov.gr id).
class StationSel extends MapSel {
  const StationSel(this.name, this.at, {this.lines = const [], this.railId});
  final String name;
  final Pt at;
  final List<String> lines; // metro/tram line ids, or suburban corridor ids
  final String? railId;
}

class PlaceSel extends MapSel {
  const PlaceSel(this.name, this.at);
  final String name; // an address or a place from the search
  final Pt at;
}

final mapSel = ValueNotifier<MapSel?>(null)..addListener(_track);

// What was open before, for back (the sheet's arrow and the phone's back button). Another direction of
// the same line, or the same bus again, replaces the step instead of adding one; closing forgets all.
final _history = <MapSel>[];
MapSel? _last;
bool _goingBack = false;

void _track() {
  final v = mapSel.value;
  final was = _last;
  _last = v;
  if (v == null) {
    _history.clear();
  } else if (!_goingBack && was != null && !identical(was, v) && !_same(was, v)) {
    _history.add(was);
    if (_history.length > 30) _history.removeAt(0);
  }
}

bool _same(MapSel a, MapSel b) => switch ((a, b)) {
      (LineSel(line: final x), LineSel(line: final y)) => x == y,
      (BusSel(line: final l1, vehicleId: final v1), BusSel(line: final l2, vehicleId: final v2)) => l1 == l2 && v1 == v2,
      _ => false,
    };

// A bus opened with its stop (a tapped notification) goes back to that stop even without history.
bool canMapBack() => _history.isNotEmpty || switch (mapSel.value) { BusSel(stop: _?) => true, _ => false };

void mapBack() {
  _goingBack = true;
  try {
    if (_history.isNotEmpty) {
      mapSel.value = _history.removeLast();
    } else if (mapSel.value case BusSel(stop: final s?)) {
      mapSel.value = StopSel(s);
    } else {
      mapSel.value = null;
    }
  } finally {
    _goingBack = false;
  }
}
final followBus = ValueNotifier(false); // the map keeps the open bus in view
final appTab = ValueNotifier(0); // the bottom bar's tab

/// A trip for the planner tab to plan: its ends (label and points); a null start keeps the planner's.
typedef PlanEnd = ({String label, List<Pt> pts});
final planRequest = ValueNotifier<({PlanEnd? from, PlanEnd to})?>(null);

void showPlanner({PlanEnd? from, required PlanEnd to}) {
  planRequest.value = (from: from, to: to);
  appTab.value = 2;
}

void showOnMap(MapSel s) {
  followBus.value = false;
  mapSel.value = s;
  appTab.value = 0;
}
