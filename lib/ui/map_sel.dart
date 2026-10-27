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
  const LineSel(this.line);
  final String line;
}

final mapSel = ValueNotifier<MapSel?>(null);
final followBus = ValueNotifier(false); // the map keeps the open bus in view
final appTab = ValueNotifier(0); // the bottom bar's tab

void showOnMap(MapSel s) {
  followBus.value = false;
  mapSel.value = s;
  appTab.value = 0;
}
