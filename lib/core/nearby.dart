import 'dart:math';

import 'geo.dart';
import 'models.dart';

class NearbyStop {
  final String name;
  final double lat, lon, distM;
  final List<int> stopIndexes;
  final List<String> lines;
  const NearbyStop({
    required this.name,
    required this.lat,
    required this.lon,
    required this.distM,
    required this.stopIndexes,
    required this.lines,
  });
}

const _mergeM = 150.0;

/// Natural sort: numeric-leading ids by number then suffix, before letter-leading ids
/// (compared by code unit, digit runs by value).
List<String> sortLines(Iterable<String> lines) => lines.toList()..sort(_cmpLine);

int _cmpLine(String a, String b) {
  final na = _lead(a), nb = _lead(b);
  if (na != null && nb != null) {
    if (na.$1 != nb.$1) return na.$1.compareTo(nb.$1);
    return _natural(na.$2, nb.$2);
  }
  if (na != null) return -1;
  if (nb != null) return 1;
  return _natural(a, b);
}

(int, String)? _lead(String s) {
  final m = RegExp(r'^(\d+)(.*)$', dotAll: true).firstMatch(s);
  return m == null ? null : (int.parse(m.group(1)!), m.group(2)!);
}

int _natural(String a, String b) {
  final re = RegExp(r'\d+|\D+');
  final pa = re.allMatches(a).map((m) => m.group(0)!).toList();
  final pb = re.allMatches(b).map((m) => m.group(0)!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final x = pa[i], y = pb[i];
    final dx = int.tryParse(x), dy = int.tryParse(y);
    final c = dx != null && dy != null ? dx.compareTo(dy) : x.compareTo(y);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

final _linesOf = Expando<List<Set<String>>>();

List<Set<String>> _linesPerStop(TripIndex ix) {
  var m = _linesOf[ix];
  if (m == null) {
    m = [for (var _ in ix.s) <String>{}];
    for (final e in ix.l.entries) {
      for (final seq in e.value.values) {
        for (final k in seq) {
          if (k >= 0 && k < m.length) m[k].add(e.key);
        }
      }
    }
    _linesOf[ix] = m;
  }
  return m;
}

/// Stops within [radiusM] of [p], nearest first. Stops of one name within 150 m merge into one entry.
List<NearbyStop> nearbyStops(TripIndex ix, Pt p, {double radiusM = 600, int max = 8}) {
  final found = <(int, double)>[];
  for (var k = 0; k < ix.s.length; k++) {
    final d = distM(p, (ix.s[k].$2, ix.s[k].$3));
    if (d <= radiusM) found.add((k, d));
  }
  found.sort((a, b) => a.$2.compareTo(b.$2));

  final groups = <({String name, int seed, double dist, List<int> members})>[];
  for (final (k, d) in found) {
    final name = ix.s[k].$1;
    final here = (ix.s[k].$2, ix.s[k].$3);
    final g = groups.where((g) => g.name == name && distM((ix.s[g.seed].$2, ix.s[g.seed].$3), here) <= _mergeM);
    if (g.isEmpty) {
      groups.add((name: name, seed: k, dist: d, members: [k]));
    } else {
      g.first.members.add(k);
    }
  }

  final perStop = _linesPerStop(ix);
  return [
    for (final g in groups.take(max))
      NearbyStop(
        name: g.name,
        lat: ix.s[g.seed].$2,
        lon: ix.s[g.seed].$3,
        distM: g.dist,
        stopIndexes: g.members,
        lines: sortLines({for (final k in g.members) ...perStop[k]}),
      ),
  ];
}

const _plain = {'ά': 'α', 'έ': 'ε', 'ή': 'η', 'ί': 'ι', 'ϊ': 'ι', 'ΐ': 'ι', 'ό': 'ο', 'ύ': 'υ', 'ϋ': 'υ', 'ΰ': 'υ', 'ώ': 'ω', 'ς': 'σ'};

/// For search: lower case, no Greek accents, final sigma as σ.
String fold(String s) => s.toLowerCase().split('').map((c) => _plain[c] ?? c).join();

// Greek to the Latin letters people type for it, loosely: the i sounds, o and ω, ch/h are one each; ου is ou.
const _latin = {
  'α': 'a', 'β': 'v', 'γ': 'g', 'δ': 'd', 'ε': 'e', 'ζ': 'z', 'η': 'i', 'θ': 'th', 'ι': 'i', 'κ': 'k', 'λ': 'l', 'μ': 'm',
  'ν': 'n', 'ξ': 'x', 'ο': 'o', 'π': 'p', 'ρ': 'r', 'σ': 's', 'τ': 't', 'υ': 'i', 'φ': 'f', 'χ': 'h', 'ψ': 'ps', 'ω': 'o',
};
final _latinLetter = RegExp('[a-z]');

String _loose(String s) => fold(s)
    .replaceAll('ου', 'ou') // «Μαρούσι» is «marousi»
    .split('')
    .map((c) => _latin[c] ?? c)
    .join()
    .replaceAll('ch', 'h')
    .replaceAll('y', 'i')
    .replaceAll('w', 'o');

/// For search: [query] is in [name] without accents and case; a query in Latin letters («syntagma»)
/// also matches the Greek name.
bool nameMatches(String name, String query) => fold(name).contains(fold(query.trim())) || latinMatches(name, query);

/// A query in Latin letters («syntagma») in a Greek name; false for a Greek query.
bool latinMatches(String name, String query) {
  final q = fold(query.trim());
  return _latinLetter.hasMatch(q) && _loose(name).contains(_loose(q));
}

/// Every line that stops at a stop named [name] within 200 m of the point (both sides of the street,
/// and same-name stops the 150 m merge keeps apart).
List<String> linesAt(TripIndex ix, String name, double lat, double lon) {
  final per = _linesPerStop(ix);
  final out = <String>{};
  for (var i = 0; i < ix.s.length; i++) {
    final s = ix.s[i];
    if (s.$1 == name && distM((s.$2, s.$3), (lat, lon)) <= 200) out.addAll(per[i]);
  }
  return sortLines(out);
}

Pt _at(TripIndex ix, int k) => (ix.s[k].$2, ix.s[k].$3);

// Degrees clockwise from north. marker.dart has this, but nearby -> marker -> models -> nearby is a cycle.
double _bearing(Pt a, Pt b) {
  final dx = (b.$2 - a.$2) * cos(a.$1 * pi / 180), dy = b.$1 - a.$1;
  return (atan2(dx, dy) * 180 / pi + 360) % 360;
}

double _angleDiff(double a, double b) => ((a - b + 540) % 360 - 180).abs();

// Which way each line runs at stop [k]: per line, the bearing from the stop before to the stop after, per pass.
Map<String, List<double>> _headingsAt(TripIndex ix, int k) {
  final out = <String, List<double>>{};
  for (final e in ix.l.entries) {
    for (final seq in e.value.values) {
      if (seq.length < 2) continue;
      for (var p = 0; p < seq.length; p++) {
        if (seq[p] != k) continue;
        final a = seq[max(0, p - 1)], b = seq[min(seq.length - 1, p + 1)];
        if (a == b || a < 0 || a >= ix.s.length || b < 0 || b >= ix.s.length) continue;
        (out[e.key] ??= <double>[]).add(_bearing(_at(ix, a), _at(ix, b)));
      }
    }
  }
  return out;
}

// One stop right after the other on some variant: the next stop the same way, never the one across.
bool _adjacent(TripIndex ix, int a, int b) {
  for (final vs in ix.l.values) {
    for (final seq in vs.values) {
      for (var p = 1; p < seq.length; p++) {
        final x = seq[p], y = seq[p - 1];
        if ((x == a && y == b) || (x == b && y == a)) return true;
      }
    }
  }
  return false;
}

/// The stop across the road from the card of [name] at (lat, lon), when OASA gives it another name (a loop
/// line's «1η/2η ΚΟΜΒΟΣ»): another name within 100 m, not the next stop on any variant, where a line of both
/// runs the other way. As on the web (twins, v0.2.6). m is the distance, in metres.
({String name, double lat, double lon, int m})? acrossStop(TripIndex ix, String name, double lat, double lon) {
  final key = fold(name);
  final members = <int>[];
  for (var k = 0; k < ix.s.length; k++) {
    final s = ix.s[k];
    if (s.$1 == name && distM((s.$2, s.$3), (lat, lon)) <= 200) members.add(k);
  }
  if (members.isEmpty) return null;

  var bestJ = -1;
  var bestM = double.infinity;
  final memberHeads = <int, Map<String, List<double>>>{};
  for (var j = 0; j < ix.s.length; j++) {
    if (members.contains(j)) continue; // the same name is this card already
    final sj = ix.s[j];
    if (fold(sj.$1) == key) continue;
    final pj = (sj.$2, sj.$3);
    var near = double.infinity;
    for (final k in members) {
      final d = distM(_at(ix, k), pj);
      if (d < near) near = d;
    }
    if (near > 100) continue; // the check below is costly: distance first
    if (near >= bestM) continue; // a nearer one is across the road already
    // The card's stops are one place: a next stop of any of them runs the same way, not across.
    var nextSameWay = false;
    for (final k in members) {
      if (_adjacent(ix, k, j)) {
        nextSameWay = true;
        break;
      }
    }
    if (nextSameWay) continue;
    Map<String, List<double>>? theirs;
    var opposite = false;
    for (final k in members) {
      if (distM(_at(ix, k), pj) > 100) continue;
      theirs ??= _headingsAt(ix, j);
      final mine = memberHeads[k] ??= _headingsAt(ix, k);
      for (final e in mine.entries) {
        final other = theirs[e.key];
        if (other == null) continue;
        if (e.value.any((a) => other.any((b) => _angleDiff(a, b) > 120))) {
          opposite = true;
          break;
        }
      }
      if (opposite) break;
    }
    if (!opposite) continue;
    bestJ = j;
    bestM = near;
  }
  if (bestJ < 0) return null;
  final s = ix.s[bestJ];
  return (name: s.$1, lat: s.$2, lon: s.$3, m: bestM.round());
}

