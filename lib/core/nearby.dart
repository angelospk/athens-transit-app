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
