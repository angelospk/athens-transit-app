// The line card's own stop (as the web's lineStop.ts): where the rider gets on the line in the chosen
// direction. The stop the card was opened from, when that direction serves it; else the direction's
// nearest stop to the user, within [nearM]; else none. Also the walking directions to it.

import 'geo.dart';
import 'models.dart';

const nearM = 1500.0;

/// [fromIds]: the line's stop ids at the stop the card came from. [pos]: the user. The id and the metres
/// from the user (null for the stop the card came from: the caller measures it when it knows the user).
({String id, int? m})? lineStopFor(LineStatic st, Set<String> variants, {Set<String> fromIds = const {}, Pt? pos, double maxM = nearM}) {
  final ids = <String>{
    for (final v in variants)
      if (st.variants[v] case final x?) ...x.stops,
  };
  for (final id in ids) {
    if (fromIds.contains(id)) return (id: id, m: null);
  }
  if (pos == null) return null;
  String? best;
  var bestM = double.infinity;
  for (final id in ids) {
    final s = st.stops[id];
    if (s == null) continue;
    final m = distM(pos, (s.lat, s.lon));
    if (m < bestM) {
      bestM = m;
      best = id;
    }
  }
  return best != null && bestM <= maxM ? (id: best, m: bestM.round()) : null;
}

/// Walking directions to a point in the phone's own map app: Apple Maps on iOS, Google Maps elsewhere
/// (its app on Android opens the link, with the site as the fallback).
Uri walkUrl(double lat, double lon, {required bool ios}) => ios
    ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lon&dirflg=w')
    : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=walking');
