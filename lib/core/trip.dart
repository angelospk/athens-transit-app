// Trip planner: which lines go from one place to another, with no change or one. Pure Dart port of
// the web planner (athens-transit-map, src/lib/trip.ts). Times are estimates: walking on streets a
// third longer than the straight line, riding at 15 km/h with the stops included.

import 'dart:math';

import 'geo.dart';
import 'models.dart';
import 'nearby.dart' show fold;

/// Metres from the start to the first stop, and from the last stop to the end.
const double walkM = 500;
/// Metres on foot between the two lines of a change.
const double xferM = 250;
/// Minutes waiting for the second bus.
const double xferMin = 5;
const double _walkMpm = 75; // 4.5 km/h
const double _detour = 1.3; // streets are longer than the straight line
const double _rideMpm = 250; // 15 km/h, stops included
const double _clusterM = 800;

/// A place to start or end at: stops of one name close together, an area or street (geocoder), the
/// user's location, or a metro station.
enum PlaceKind { stop, area, street, poi, me, metro, metroAny }

class Place {
  final String label;
  final String? hint;
  final List<Pt> pts;
  final List<String> lines;
  final PlaceKind? kind;
  const Place({
    required this.label,
    this.hint,
    required this.pts,
    required this.lines,
    this.kind,
  });
}

/// A metro, ISAP or tram station as the planner receives it.
typedef MetroStation = ({String name, double lat, double lon, List<String> lines});

class TripVariant {
  final String id;
  final int i, j; // board at stops[i], get off at stops[j] of the variant
  final int from, to; // the same stops, as indexes into the index's stop table
  final double walk; // metres in a straight line, to the first stop and from the last
  final int stops; // stops travelled
  final double ride; // metres on the bus, stop to stop in straight lines
  final double min; // estimated minutes, walking and riding
  const TripVariant({
    required this.id,
    required this.i,
    required this.j,
    required this.from,
    required this.to,
    required this.walk,
    required this.stops,
    required this.ride,
    required this.min,
  });
}

class TripLine {
  final String line;
  final double walk;
  final int stops;
  final double min;
  final List<TripVariant> variants;
  const TripLine({
    required this.line,
    required this.walk,
    required this.stops,
    required this.min,
    required this.variants,
  });
}

/// One bus ride inside a trip with a change.
class TripLeg {
  final String line, id;
  final int i, j, from, to, stops;
  final double ride;
  const TripLeg({
    required this.line,
    required this.id,
    required this.i,
    required this.j,
    required this.from,
    required this.to,
    required this.stops,
    required this.ride,
  });
}

class TripTransfer {
  final List<TripLeg> legs; // the first ride, then the second
  final double walk; // metres in a straight line, to the first stop and from the last
  final double xfer; // metres between the first leg's end stop and the second leg's start
  final double min;
  const TripTransfer({
    required this.legs,
    required this.walk,
    required this.xfer,
    required this.min,
  });
}

/// A stop of a line to board at, as a position in one variant.
class BoardAt {
  final String id;
  final int i, from;
  const BoardAt({required this.id, required this.i, required this.from});
}

class BoardLine {
  final String line;
  final List<BoardAt> variants;
  BoardLine(this.line, this.variants);
}

/// A stop near the start to wait at, with the lines that leave from there.
class Boarding {
  final String name;
  double walk;
  final List<BoardLine> lines;
  Boarding({required this.name, required this.walk, required this.lines});
}

// Distances come from geo.dart (haversine): within 0.1% of the web planner's flat estimate.

double _nearest(Pt p, List<Pt> pts) => pts.map((q) => distM(p, q)).reduce(min);

/// Centre of a set of points.
Pt centre(List<Pt> pts) {
  var lat = 0.0, lon = 0.0;
  for (final p in pts) {
    lat += p.$1;
    lon += p.$2;
  }
  return (lat / pts.length, lon / pts.length);
}

/// Natural line order: digit runs by value, so "2" < "10" and "A1" < "A2".
int _byLine(String a, String b) {
  final x = _chunks(a), y = _chunks(b);
  for (var i = 0; i < x.length && i < y.length; i++) {
    final np = int.tryParse(x[i]), nq = int.tryParse(y[i]);
    final c = np != null && nq != null ? np.compareTo(nq) : x[i].compareTo(y[i]);
    if (c != 0) return c;
  }
  if (x.length != y.length) return x.length.compareTo(y.length);
  return a.compareTo(b);
}

List<String> _chunks(String s) =>
    RegExp(r'\d+|\D+').allMatches(s).map((m) => m.group(0)!).toList();

class _Group {
  final Pt seed;
  final String label;
  final List<Pt> pts = [];
  final Set<String> lines = {};
  _Group(this.seed, this.label);
}

/// Stops grouped by name; one name far apart (ΕΚΚΛΗΣΙΑ) is several places. A stop joins a group only
/// near its first stop, so a chain of stops cannot stretch a place across a district. Stops are taken
/// south to north, so the result does not depend on their order in the index.
List<Place> places(TripIndex ix) {
  final lines = List.generate(ix.s.length, (_) => <String>{});
  for (final e in ix.l.entries) {
    for (final seq in e.value.values) {
      for (final k in seq) {
        if (k >= 0 && k < lines.length) lines[k].add(e.key);
      }
    }
  }
  final order = List.generate(ix.s.length, (k) => k)
    ..sort((a, b) {
      final c = ix.s[a].$2.compareTo(ix.s[b].$2);
      if (c != 0) return c;
      final d = ix.s[a].$3.compareTo(ix.s[b].$3);
      return d != 0 ? d : a.compareTo(b);
    });
  final groups = <String, List<_Group>>{};
  for (final k in order) {
    final (name, lat, lon) = ix.s[k];
    final p = (lat, lon);
    final list = groups.putIfAbsent(fold(name), () => []);
    _Group? g;
    for (final x in list) {
      if (distM(x.seed, p) <= _clusterM) {
        g = x;
        break;
      }
    }
    if (g == null) {
      g = _Group(p, name);
      list.add(g);
    }
    g.pts.add(p);
    g.lines.addAll(lines[k]);
  }
  return [
    for (final list in groups.values)
      for (final g in list)
        Place(
          label: g.label,
          pts: g.pts,
          lines: g.lines.toList()..sort(_byLine),
          kind: PlaceKind.stop,
        ),
  ];
}

final _folded = Expando<String>('folded');
final _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

bool _isWordChar(String c) => _wordChar.hasMatch(c);

/// Places whose name has the text at a word start ("ταυρ" is not in ΔΙΑΣΤΑΥΡΩΣΗ); whole name first,
/// then name start, then busier places.
List<Place> searchPlaces(List<Place> list, String query, [int max = 6]) {
  final q = fold(query.trim());
  if (q.isEmpty) return [];
  int rank(Place p) {
    var f = _folded[p];
    if (f == null) {
      f = fold(p.label);
      _folded[p] = f;
    }
    if (f == q) return 0;
    for (var at = f.indexOf(q); at >= 0; at = f.indexOf(q, at + 1)) {
      if (at == 0) return 1;
      if (!_isWordChar(f[at - 1])) return 2;
    }
    return -1;
  }

  final ranked = <(int, Place)>[];
  for (final p in list) {
    final r = rank(p);
    if (r >= 0) ranked.add((r, p));
  }
  ranked.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    final d = _metroScore(b.$2) - _metroScore(a.$2);
    if (d != 0) return d;
    final e = b.$2.lines.length.compareTo(a.$2.lines.length);
    if (e != 0) return e;
    return a.$2.label.compareTo(b.$2.label);
  });
  return [for (final r in ranked.take(max)) r.$2];
}

int _metroScore(Place p) => p.kind == PlaceKind.metro ? 1 : 0;

double _walkMin(double m) => m * _detour / _walkMpm;

/// Minutes on the bus for [metres] stop to stop in straight lines, stops included.
double rideMinutes(double metres) => metres / _rideMpm;

final _rides = Expando<Map<String, List<double>>>('rides');

/// Metres on the bus up to each stop of a variant (straight lines between stops), cached per index.
List<double> _cumulative(TripIndex ix, String line, String id, List<int> seq) {
  final m = _rides[ix] ??= {};
  final had = m['$line/$id'];
  if (had != null) return had;
  final c = <double>[0];
  for (var k = 1; k < seq.length; k++) {
    c.add(c[k - 1] + distM(_pt(ix, seq[k - 1]), _pt(ix, seq[k])));
  }
  return m['$line/$id'] = c;
}

Pt _pt(TripIndex ix, int k) => (ix.s[k].$2, ix.s[k].$3);

/// True when a start point is closer than [radius] to an end point: close enough to walk.
bool _closeEnough(List<Pt> from, List<Pt> to, double radius) {
  if (from.isEmpty || to.isEmpty) return false;
  for (final p in from) {
    if (_nearest(p, to) < radius) return true;
  }
  return false;
}

/// Every line with a variant that stops within [radius] of the start and later within [radius] of the
/// end. Per variant, the pair of stops with the least estimated time (walking and riding), then the
/// fewest stops. Lines come best first; [known] (the current line list) leaves out lines the index
/// has but OASA dropped.
List<TripLine> findTrips(TripIndex ix, List<Pt> from, List<Pt> to,
    [double radius = walkM, Set<String>? known]) {
  if (_closeEnough(from, to, radius)) return [];
  final dFrom = <int, double>{}, dTo = <int, double>{};
  double d(Map<int, double> cache, List<Pt> pts, int k) =>
      cache.putIfAbsent(k, () => _nearest(_pt(ix, k), pts));
  final out = <TripLine>[];
  for (final e in ix.l.entries) {
    if (known != null && !known.contains(e.key)) continue;
    final variants = <TripVariant>[];
    for (final v in e.value.entries) {
      final seq = v.value;
      final cum = _cumulative(ix, e.key, v.key, seq);
      TripVariant? best;
      for (var i = 0; i < seq.length; i++) {
        final a = d(dFrom, from, seq[i]);
        if (a > radius) continue;
        for (var j = i + 1; j < seq.length; j++) {
          final b = d(dTo, to, seq[j]);
          if (b > radius) continue;
          final ride = cum[j] - cum[i];
          final mn = _walkMin(a + b) + ride / _rideMpm;
          if (best == null || mn < best.min || (mn == best.min && j - i < best.stops)) {
            best = TripVariant(
                id: v.key,
                i: i,
                j: j,
                from: seq[i],
                to: seq[j],
                walk: a + b,
                stops: j - i,
                ride: ride,
                min: mn);
          }
        }
      }
      if (best != null) variants.add(best);
    }
    if (variants.isEmpty) continue;
    variants.sort((a, b) {
      final c = a.min.compareTo(b.min);
      if (c != 0) return c;
      final s = a.stops.compareTo(b.stops);
      return s != 0 ? s : a.id.compareTo(b.id);
    });
    out.add(TripLine(
      line: e.key,
      walk: variants[0].walk,
      stops: variants[0].stops,
      min: variants[0].min,
      variants: variants,
    ));
  }
  return out
    ..sort((a, b) {
      final c = a.min.compareTo(b.min);
      if (c != 0) return c;
      final s = a.stops.compareTo(b.stops);
      return s != 0 ? s : _byLine(a.line, b.line);
    });
}

/// The first line of a change as a trip of its own (to the change stop): what a stop alert watches.
TripLine legTrip(TripLeg a) => TripLine(
      line: a.line,
      walk: 0,
      stops: a.stops,
      min: 0,
      variants: [
        TripVariant(
          id: a.id,
          i: a.i,
          j: a.j,
          from: a.from,
          to: a.to,
          walk: 0,
          stops: a.stops,
          ride: a.ride,
          min: 0,
        ),
      ],
    );

class _Grid {
  final (int, int) Function(double lat, double lon) cell;
  final Map<(int, int), List<int>> at;
  _Grid(this.cell, this.at);
}

final _grids = Expando<_Grid>('grids');

/// Stops in a grid of [xferM] cells, cached per index: the stops near a stop without looking at all.
_Grid _gridOf(TripIndex ix) {
  final had = _grids[ix];
  if (had != null) return had;
  var lat0 = 38.0;
  if (ix.s.isNotEmpty) {
    var t = 0.0;
    for (final x in ix.s) {
      t += x.$2;
    }
    lat0 = t / ix.s.length;
  }
  final dLat = xferM / 111320, dLon = dLat / cos(lat0 * pi / 180);
  (int, int) cell(double lat, double lon) =>
      ((lat / dLat).floor(), (lon / dLon).floor());
  final at = <(int, int), List<int>>{};
  for (var k = 0; k < ix.s.length; k++) {
    at.putIfAbsent(cell(ix.s[k].$2, ix.s[k].$3), () => []).add(k);
  }
  return _grids[ix] = _Grid(cell, at);
}

class _Arrival {
  final double cost, walk;
  final TripLeg leg;
  _Arrival(this.cost, this.walk, this.leg);
}

/// Trips with one change: a first line from near the start, then on foot (at most [xferM]) to a stop
/// of another line that gets off near the end. Per pair of lines the quickest; the first [max]
/// overall.
List<TripTransfer> findTransfers(TripIndex ix, List<Pt> from, List<Pt> to,
    [double radius = walkM, Set<String>? known, int max = 3]) {
  if (_closeEnough(from, to, radius)) return [];
  final dFrom = <int, double>{}, dTo = <int, double>{};
  double d(Map<int, double> cache, List<Pt> pts, int k) =>
      cache.putIfAbsent(k, () => _nearest(_pt(ix, k), pts));
  TripLeg leg(String line, String id, List<int> seq, List<double> cum, int i, int j) =>
      TripLeg(
          line: line,
          id: id,
          i: i,
          j: j,
          from: seq[i],
          to: seq[j],
          stops: j - i,
          ride: cum[j] - cum[i]);

  // First leg: the quickest way to each stop, per line.
  final arrivals = <int, Map<String, _Arrival>>{};
  for (final e in ix.l.entries) {
    if (known != null && !known.contains(e.key)) continue;
    for (final v in e.value.entries) {
      final seq = v.value;
      final cum = _cumulative(ix, e.key, v.key, seq);
      var bestI = -1, bestV = double.infinity; // over boardings so far: walk minutes less the ride
      for (var j = 0; j < seq.length; j++) {
        if (bestI >= 0) {
          final cost = bestV + cum[j] / _rideMpm;
          final m = arrivals.putIfAbsent(seq[j], () => {});
          final had = m[e.key];
          if (had == null || cost < had.cost) {
            m[e.key] = _Arrival(
                cost, d(dFrom, from, seq[bestI]), leg(e.key, v.key, seq, cum, bestI, j));
          }
        }
        final a = d(dFrom, from, seq[j]);
        if (a <= radius && _walkMin(a) - cum[j] / _rideMpm < bestV) {
          bestV = _walkMin(a) - cum[j] / _rideMpm;
          bestI = j;
        }
      }
    }
  }
  if (arrivals.isEmpty) return [];

  // Second leg: from each boarding stop, the quickest way to the end; joined to the first legs that
  // arrive within walking distance.
  final grid = _gridOf(ix);
  final best = <String, TripTransfer>{};
  for (final e in ix.l.entries) {
    if (known != null && !known.contains(e.key)) continue;
    for (final v in e.value.entries) {
      final seq = v.value;
      final cum = _cumulative(ix, e.key, v.key, seq);
      var g = double.infinity, gJ = -1; // over alightings after the stop: walk minutes plus the ride
      for (var i = seq.length - 2; i >= 0; i--) {
        final b = d(dTo, to, seq[i + 1]);
        if (b <= radius && _walkMin(b) + cum[i + 1] / _rideMpm < g) {
          g = _walkMin(b) + cum[i + 1] / _rideMpm;
          gJ = i + 1;
        }
        if (gJ < 0) continue;
        final (r, c) = grid.cell(ix.s[seq[i]].$2, ix.s[seq[i]].$3);
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            for (final m in grid.at[(r + dr, c + dc)] ?? const <int>[]) {
              final arr = arrivals[m];
              if (arr == null) continue;
              final x = distM(_pt(ix, m), _pt(ix, seq[i]));
              if (x > xferM) continue;
              for (final a in arr.entries) {
                if (a.key == e.key) continue;
                final mn = a.value.cost + _walkMin(x) + xferMin + g - cum[i] / _rideMpm;
                final key = '${a.key}\n${e.key}';
                final had = best[key];
                if (had == null || mn < had.min) {
                  best[key] = TripTransfer(
                    legs: [a.value.leg, leg(e.key, v.key, seq, cum, i, gJ)],
                    walk: a.value.walk + d(dTo, to, seq[gJ]),
                    xfer: x,
                    min: mn,
                  );
                }
              }
            }
          }
        }
      }
    }
  }
  final list = best.values.toList()
    ..sort((a, b) {
      final c = a.min.compareTo(b.min);
      if (c != 0) return c;
      final f = _byLine(a.legs[0].line, b.legs[0].line);
      return f != 0 ? f : _byLine(a.legs[1].line, b.legs[1].line);
    });
  return list.take(max).toList();
}

class _Best {
  final BoardAt at;
  final double a, cost;
  final int stops;
  _Best(this.at, this.a, this.cost, this.stops);
}

/// A stop near the start to wait at: stops of one name, the walk to the nearest of them, and the
/// given [lines] that stop there and still reach the end (per variant, the occurrence with the least
/// walking, then the fewest stops, as in [findTrips]).
List<Boarding> boardings(TripIndex ix, List<Pt> from, List<Pt> to, double radius,
    List<String> lines, [int max = 4]) {
  double near(List<Pt> pts, int k) => _nearest(_pt(ix, k), pts);
  final out = <String, Boarding>{};
  for (final line in lines) {
    final vs = ix.l[line];
    if (vs == null) continue;
    for (final v in vs.entries) {
      final seq = v.value;
      final best = <String, _Best>{}; // per stop name
      for (var i = 0; i < seq.length; i++) {
        final a = near(from, seq[i]);
        if (a > radius) continue;
        var b = double.infinity, j = -1;
        for (var k = i + 1; k < seq.length; k++) {
          final dd = near(to, seq[k]);
          if (dd <= radius && dd < b) {
            b = dd;
            j = k;
          }
        }
        if (j < 0) continue;
        final key = fold(ix.s[seq[i]].$1);
        final had = best[key];
        if (had == null || a + b < had.cost || (a + b == had.cost && j - i < had.stops)) {
          best[key] = _Best(BoardAt(id: v.key, i: i, from: seq[i]), a, a + b, j - i);
        }
      }
      for (final e in best.entries) {
        final at = e.value.at, a = e.value.a;
        var g = out[e.key];
        if (g == null) {
          g = Boarding(name: ix.s[at.from].$1, walk: a, lines: []);
          out[e.key] = g;
        }
        if (a < g.walk) g.walk = a;
        BoardLine? l;
        for (final x in g.lines) {
          if (x.line == line) {
            l = x;
            break;
          }
        }
        if (l != null) {
          l.variants.add(at);
        } else {
          g.lines.add(BoardLine(line, [at]));
        }
      }
    }
  }
  final list = out.values.toList()
    ..sort((a, b) {
      final c = a.walk.compareTo(b.walk);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
  return list.take(max).toList();
}

/// Where the given variants of a line end (the stop names), once each: the way the line goes.
List<String> termini(TripIndex ix, String line, List<String> variantIds) {
  final out = <String>[];
  for (final id in variantIds) {
    final seq = ix.l[line]?[id];
    if (seq == null || seq.isEmpty) continue;
    final k = seq.last;
    if (k < 0 || k >= ix.s.length) continue;
    final name = ix.s[k].$1;
    if (name.isNotEmpty && !out.contains(name)) out.add(name);
  }
  return out;
}

/// Metro, ISAP and tram stations as places to start or end at, with their lines.
List<Place> metroPlaces(List<MetroStation> stations) => [
      for (final s in stations)
        Place(
          label: s.name,
          pts: [(s.lat, s.lon)],
          lines: s.lines,
          kind: PlaceKind.metro,
        ),
    ];

bool _isMetro(MetroStation s) => s.lines.any((l) => l.startsWith('M'));

/// One place for the nearest metro or ISAP station of all (the caller picks by the point it compares).
Place anyMetro(List<MetroStation> stations) => Place(
      label: 'Κοντινότερος σταθμός μετρό',
      pts: [
        for (final s in stations)
          if (_isMetro(s)) (s.lat, s.lon),
      ],
      lines: const [],
      kind: PlaceKind.metroAny,
    );

/// A metro or tram line with a station near the start and another near the end (the least walking):
/// the planner says so before the buses, which may take far longer.
({String line, String from, String to, double walk})? metroDirect(
    List<MetroStation> stations, List<Pt> from, List<Pt> to, double radius) {
  List<({MetroStation s, double d})> near(List<Pt> pts) {
    final out = <({MetroStation s, double d})>[];
    for (final s in stations) {
      final d = _nearest((s.lat, s.lon), pts);
      if (d <= radius) out.add((s: s, d: d));
    }
    return out;
  }
  final a = near(from), b = near(to);
  ({String line, String from, String to, double walk})? best;
  for (final x in a) {
    for (final y in b) {
      if (x.s.name == y.s.name) continue;
      String? line;
      for (final l in x.s.lines) {
        if (y.s.lines.contains(l)) {
          line = l;
          break;
        }
      }
      if (line != null && (best == null || x.d + y.d < best.walk)) {
        best = (line: line, from: x.s.name, to: y.s.name, walk: x.d + y.d);
      }
    }
  }
  return best;
}

/// The metro or ISAP station nearest a point, and the metres to it.
({String name, double d})? nearestStation(List<MetroStation> stations, Pt p) {
  ({String name, double d})? best;
  for (final s in stations) {
    if (!_isMetro(s)) continue;
    final d = distM(p, (s.lat, s.lon));
    if (best == null || d < best.d) best = (name: s.name, d: d);
  }
  return best;
}

/// A bus to a metro (or tram) station and the metro on to a station near the end, or the metro
/// first and a bus after it. Only the [tries] stations of the shared line nearest the other end
/// are tried, so it stays cheap. The quickest of both orders, or null.
({TripLine bus, String station, String metroLine, String metroTo, bool busFirst, double min})? busMetro(
    TripIndex ix, List<MetroStation> stations, List<Pt> from, List<Pt> to,
    {double radius = 900, Set<String>? known, int tries = 3}) {
  if (_closeEnough(from, to, radius)) return null;
  ({TripLine bus, String station, String metroLine, String metroTo, bool busFirst, double min})? best;
  final legs = <String, TripLine?>{}; // one bus search per station and order
  for (final busFirst in [true, false]) {
    // The metro end: every station within reach of the end (bus first) or of the start (metro first).
    final ends = busFirst ? to : from, other = busFirst ? from : to;
    for (final s in stations) {
      final walk = _nearest((s.lat, s.lon), ends);
      if (walk > radius) continue;
      final rs = [
        for (final r in stations)
          if (r.name != s.name && r.lines.any(s.lines.contains)) r,
      ]..sort((a, b) => _nearest((a.lat, a.lon), other).compareTo(_nearest((b.lat, b.lon), other)));
      for (final r in rs.take(tries)) {
        final rPt = <Pt>[(r.lat, r.lon)];
        final bus = legs.putIfAbsent('$busFirst|${r.lat},${r.lon}',
            () => (busFirst ? findTrips(ix, other, rPt, walkM, known) : findTrips(ix, rPt, other, walkM, known)).firstOrNull);
        if (bus == null) continue;
        final line = r.lines.firstWhere(s.lines.contains);
        // Metro at 30 km/h with the stops, five minutes to wait, and the walk at the metro end.
        final min = bus.min + distM((r.lat, r.lon), (s.lat, s.lon)) / 500 + 5 + _walkMin(walk);
        if (best == null || min < best.min) {
          best = busFirst
              ? (bus: bus, station: r.name, metroLine: line, metroTo: s.name, busFirst: true, min: min)
              : (bus: bus, station: s.name, metroLine: line, metroTo: r.name, busFirst: false, min: min);
        }
      }
    }
  }
  return best;
}
