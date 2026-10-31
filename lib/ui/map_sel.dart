// What the map's sheet shows: a stop, one bus, or a whole line. Any screen can open one on the map
// (a page from the menu, the search) instead of pushing a page: the map stays behind the sheet.
// The menu's pages open over the map (navKey); the map is the first route.

import 'package:flutter/material.dart';

import '../core/geo.dart';
import 'favs_screen.dart';
import 'planner_screen.dart';
import 'stop_screen.dart';
import 'widgets.dart' show titleCase;

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
// A page opened the first level (a step of a planned trip): back from that level reopens it.
typedef MapReturn = ({String label, VoidCallback open});
MapReturn? _return;

void _track() {
  final v = mapSel.value;
  final was = _last;
  _last = v;
  if (v == null) {
    _history.clear();
    _return = null;
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
bool canMapBack() => _history.isNotEmpty || _return != null || switch (mapSel.value) { BusSel(stop: _?) => true, _ => false };

/// What «‹ Πίσω» goes back to, in words: the level before, or the home sheet.
String backLabel() {
  final prev = _history.lastOrNull ?? switch (mapSel.value) { BusSel(stop: final s?) => StopSel(s), _ => null };
  return switch (prev) {
    null => _return?.label ?? 'Κοντά σου',
    StopSel(:final stop) => titleCase(stop.name),
    BusSel(:final line) || LineSel(:final line) => 'Γραμμή $line',
    StationSel(:final name) || PlaceSel(:final name) => titleCase(name),
  };
}

void mapBack() {
  _goingBack = true;
  try {
    if (_history.isNotEmpty) {
      mapSel.value = _history.removeLast();
    } else if (mapSel.value case BusSel(stop: final s?)) {
      mapSel.value = StopSel(s);
    } else {
      final r = _return;
      mapSel.value = null;
      r?.open();
    }
  } finally {
    _goingBack = false;
  }
}
final followBus = ValueNotifier(false); // the map keeps the open bus in view
final homeTab = ValueNotifier(0); // the home sheet's tab: 0 «Κοντά σου», 1 «Αγαπημένα»
final navKey = GlobalKey<NavigatorState>();

/// A page over the map, with its title and a back arrow.
Future<void> openPage(String title, Widget body) =>
    navKey.currentState?.push(MaterialPageRoute<void>(builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: body))) ?? Future.value();

void _toMap() => navKey.currentState?.popUntil((r) => r.isFirst);

/// A trip for the planner to plan: its ends (label and points); a null start keeps the planner's.
typedef PlanEnd = ({String label, List<Pt> pts});
final planRequest = ValueNotifier<({PlanEnd? from, PlanEnd to})?>(null);

void showPlanner({PlanEnd? from, required PlanEnd to}) {
  planRequest.value = (from: from, to: to);
  _toMap();
  openPage('Διαδρομή', const PlannerScreen());
}

void showOnMap(MapSel s, {MapReturn? back}) {
  _toMap();
  followBus.value = false;
  mapSel.value = s;
  if (back != null) {
    _history.clear(); // what was open before the page is not on the way back to it
    _return = back;
  }
}

/// The saved stops, full page (the evening notification: its last-bus card is there).
void showFavs() {
  if (navKey.currentState == null) {
    // A tapped notification at a cold start comes before the app is built: once it is.
    WidgetsBinding.instance.addPostFrameCallback((_) => showFavs());
    return;
  }
  _toMap();
  homeTab.value = 1;
  openPage('Αγαπημένα', const FavsScreen());
}
