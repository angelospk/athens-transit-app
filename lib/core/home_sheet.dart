// The home sheet (docs/DESIGN-home.md): the stops grouped by stop, the kind of each in words, the walk
// button's link, and which smart card shows.

import 'athens_time.dart';
import 'geo.dart';
import 'near_home.dart';

/// The near places in the sheet's order: first the nearest bus stop that serves one of [myLines] (else
/// the nearest bus stop), then the nearest rail station (metro, tram or suburban), then the rest by
/// distance; at most [max]. A bus stop and a station never merge, even with one name.
List<NearPlace> homeGroups(List<NearPlace> near, Iterable<String> myLines, {int max = 8}) {
  final mine = myLines.toSet();
  final bus = near.where((p) => p.kind == NearKind.bus);
  final first = bus.where((p) => p.lines.any(mine.contains)).firstOrNull ?? bus.firstOrNull;
  final rail = near.where((p) => p.kind != NearKind.bus).firstOrNull;
  return [?first, ?rail, for (final p in near) if (!identical(p, first) && !identical(p, rail)) p].take(max).toList();
}

String kindLabel(NearKind k) => switch (k) {
      NearKind.bus => 'στάση λεωφορείων',
      NearKind.metro => 'σταθμός μετρό',
      NearKind.tram => 'στάση τραμ',
      NearKind.rail => 'σταθμός προαστιακού',
    };

/// Google Maps walking directions to a point (the app); [walkWebUri] when the app is missing.
Uri walkUri(double lat, double lon) => Uri.parse('google.navigation:q=$lat,$lon&mode=w');
Uri walkWebUri(double lat, double lon) => Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=walking');

enum Smart { toWork, goHome, askHome, nextFav, none }

const homeNearM = 500.0; // closer than this the user is home

/// The one smart card: a weekday morning (06:00-10:00) at home with a «Δουλειά» place, to work; away
/// from home, home; otherwise the next bus of a favourite stop. Without «Σπίτι» and favourites the card
/// asks where home is.
Smart pickSmart({required DateTime utc, required Pt? me, required Pt? home, required Pt? work, required bool hasFav}) {
  final rest = hasFav ? Smart.nextFav : Smart.none;
  if (me == null) return rest;
  if (home == null) return hasFav ? Smart.nextFav : Smart.askHome;
  if (distM(me, home) >= homeNearM) return Smart.goHome;
  final w = athensWall(utc);
  if (work != null && w.weekday <= DateTime.friday && w.hour >= 6 && w.hour < 10) return Smart.toWork;
  return rest;
}
