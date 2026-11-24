// The favourite stops for the watch apps (Wear OS, Apple Watch). The watches fetch the arrivals
// themselves; the phone only tells them which stops: the stop id (from the stop index), its name and the
// lines chosen there. No places (home/work), no location. Android: the Wearable Data Layer
// (MainActivity.kt); iOS: WatchConnectivity (AppDelegate.swift). Contract: docs/WATCH.md.

import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/city.dart';
import '../core/geo.dart';
import '../core/models.dart';
import '../data/store.dart';

const watchChannel = MethodChannel('gr.staseis.app/watch');
const watchPayloadVersion = 1;
const watchMaxFavs = 20;

/// The stop id of a favourite: the stop of the index with its name within 200 m (the index is what the
/// backend's `/v1/stops/{id}` knows). null when none matches.
String? stopIdOf(FavStop f, TripIndex idx) {
  String? best;
  var bestM = 200.0;
  for (var i = 0; i < idx.s.length && i < idx.ids.length; i++) {
    final (name, lat, lon) = idx.s[i];
    if (name != f.name || idx.ids[i].isEmpty) continue;
    final m = distM((f.lat, f.lon), (lat, lon));
    if (m <= bestM) (best, bestM) = (idx.ids[i], m);
  }
  return best;
}

/// The payload the watches validate (docs/WATCH.md): `{v, city, favs: [{id, name, lines}]}`.
String watchPayload(City city, List<FavStop> favs, TripIndex idx) {
  final out = <Map<String, Object>>[];
  for (final f in favs) {
    final id = stopIdOf(f, idx);
    if (id == null) continue;
    out.add({'id': id, 'name': f.name, 'lines': f.lines.take(12).toList()});
    if (out.length == watchMaxFavs) break;
  }
  return jsonEncode({'v': watchPayloadVersion, 'city': city.id, 'favs': out});
}

String? _sent;

/// Sends the favourites of [store]'s city when they changed since the last send. Quiet on a phone without
/// a watch side (no Google Play services, no paired watch, a platform without the channel).
Future<void> syncWatch(AppStore store, Future<TripIndex> Function() trips) async {
  try {
    final json = watchPayload(store.city, store.favs, await trips());
    if (json == _sent) return;
    await watchChannel.invokeMethod<void>('sync', json);
    _sent = json;
  } catch (_) {/* the watch gets it next time */}
}
