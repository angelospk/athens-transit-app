// «Δημοτικά»: municipal bus routes (backend /v2/municipal, OSM/ODbL data) and the timetables the
// municipalities publish. There is no live data here, so a wrong time must never show: a timetable
// that has any fault is dropped whole.

import 'athens_time.dart';
import 'geo.dart';
import 'nearby.dart' show fold;

class MuniRoute {
  final String id;
  final String? ref;
  final String name;
  final String municipality;
  final String? timetableUrl;
  final List<List<Pt>> shape;
  final List<String> stops;
  const MuniRoute({
    required this.id,
    required this.ref,
    required this.name,
    required this.municipality,
    required this.timetableUrl,
    required this.shape,
    required this.stops,
  });
}

class MuniStop {
  final String? name;
  final double lat, lon;
  const MuniStop({required this.name, required this.lat, required this.lon});
}

class Municipal {
  final List<MuniRoute> routes;
  final Map<String, MuniStop> stops; // insertion order kept
  final String attribution;
  const Municipal({required this.routes, required this.stops, required this.attribution});
}

// MM-DD, inclusive; from > to wraps the new year.
typedef Season = ({String from, String to});

class MuniService {
  final List<int> days; // ISO weekday, 1 = Monday … 7 = Sunday
  final Season? season;
  final String? label;
  final String? at; // the stop the times are timed at
  final List<String>? times; // exact departures, "HH:MM", strictly ascending
  final int? every; // or a frequency: every N minutes from first to last
  final String? first;
  final String? last;
  const MuniService({
    required this.days,
    this.season,
    this.label,
    this.at,
    this.times,
    this.every,
    this.first,
    this.last,
  });
}

class MuniLine {
  final List<String> routes;
  final String? ref;
  final String name;
  final List<MuniService> services;
  final String? group;
  final String? note;
  const MuniLine({
    required this.routes,
    required this.ref,
    required this.name,
    required this.services,
    this.group,
    this.note,
  });
}

class MuniTable {
  final String municipality;
  final String checked;
  final String? valid;
  final String source;
  final List<MuniLine> lines;
  const MuniTable({
    required this.municipality,
    required this.checked,
    required this.valid,
    required this.source,
    required this.lines,
  });
}

class MuniCard {
  final String id;
  final String? ref;
  final String name;
  final String municipality;
  final List<MuniRoute> routes;
  final MuniTable? table;
  final List<MuniLine> lines;
  const MuniCard({
    required this.id,
    required this.ref,
    required this.name,
    required this.municipality,
    required this.routes,
    required this.table,
    required this.lines,
  });

  /// Every stop of its routes, in route order, each once.
  List<String> get stopIds {
    final out = <String>[];
    for (final r in routes) {
      for (final id in r.stops) {
        if (!out.contains(id)) out.add(id);
      }
    }
    return out;
  }
}

bool _isStr(Object? v) => v is String;

/// A non-empty string after trimming.
bool _isText(Object? v) => v is String && v.trim().isNotEmpty;

bool _isPt(Object? v) =>
    v is List &&
    v.length == 2 &&
    v.every((n) => n is num && n.isFinite);

double _d(Object? v) => (v as num).toDouble();

/// An integral JSON number as int (JS Number.isInteger).
int? _intOf(Object? v) {
  if (v is int) return v;
  if (v is double && v.isFinite && v == v.truncateToDouble()) return v.toInt();
  return null;
}

const _defaultAttribution = '© OpenStreetMap contributors (ODbL)';
final _webLink = RegExp(r'^https?://');

MuniRoute? _readRoute(Object? v) {
  if (v is! Map) return null;
  final m = v;
  if (!_isStr(m['id']) || !_isStr(m['name']) || !_isStr(m['municipality'])) return null;
  if (!m.containsKey('ref') || !(m['ref'] == null || _isStr(m['ref']))) return null;
  if (!m.containsKey('timetable_url') || !(m['timetable_url'] == null || _isStr(m['timetable_url']))) {
    return null;
  }
  final rawStops = m['stops'], rawShape = m['shape'];
  if (rawStops is! List || rawStops.any((s) => !_isStr(s))) return null;
  if (rawShape is! List) return null;
  final shape = <List<Pt>>[];
  for (final line in rawShape) {
    if (line is! List || line.any((p) => !_isPt(p))) return null;
    shape.add([for (final p in line) (_d((p as List)[0]), _d(p[1]))]);
  }
  final url = m['timetable_url'];
  return MuniRoute(
    id: m['id'] as String,
    ref: m['ref'] as String?,
    name: m['name'] as String,
    municipality: m['municipality'] as String,
    // Only a web link goes into an href.
    timetableUrl: url is String && _webLink.hasMatch(url) ? url : null,
    shape: shape,
    stops: [for (final s in rawStops) s as String],
  );
}

/// The body when it has routes; null for anything else (no data yet, an error, an older backend's 404).
Municipal? parseMunicipal(Object? json) {
  if (json is! Map) return null;
  final rawRoutes = json['routes'], rawStops = json['stops'];
  if (rawRoutes is! List || rawStops is! Map) return null;
  final routes = <MuniRoute>[];
  for (final r in rawRoutes) {
    final route = _readRoute(r);
    if (route != null) routes.add(route);
  }
  if (routes.isEmpty) return null;
  final stops = <String, MuniStop>{};
  for (final entry in rawStops.entries) {
    final id = entry.key;
    final s = entry.value;
    if (id is! String || s is! Map) continue;
    final lat = s['lat'], lon = s['lon'];
    if (lat is num && lon is num) {
      stops[id] = MuniStop(name: _isStr(s['name']) ? s['name'] as String : null, lat: _d(lat), lon: _d(lon));
    }
  }
  final attribution = json['attribution'];
  return Municipal(
    routes: routes,
    stops: stops,
    attribution: _isStr(attribution) ? attribution as String : _defaultAttribution,
  );
}

final _hhmmRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
final _mdRe = RegExp(r'^(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$');
final _ymdRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

int _min(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3));

String _hhmm(int m) =>
    '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

/// A real "MM-DD": 02-30 is a typo, not a season start (2000 is a leap year, so 02-29 is fine).
bool _isMD(String v) {
  if (!_mdRe.hasMatch(v)) return false;
  final m = int.parse(v.substring(0, 2)), d = int.parse(v.substring(3));
  return DateTime.utc(2000, m, d).day == d;
}

bool _isDate(Object? v) {
  if (v is! String || !_ymdRe.hasMatch(v)) return false;
  final s = v;
  final y = int.parse(s.substring(0, 4)), m = int.parse(s.substring(5, 7)), d = int.parse(s.substring(8));
  final dt = DateTime.utc(y, m, d);
  return dt.year == y && dt.month == m && dt.day == d;
}

Season? _readSeason(Object? v) {
  if (v is! Map) return null;
  final from = v['from'], to = v['to'];
  if (from is! String || to is! String || !_isMD(from) || !_isMD(to)) return null;
  return (from: from, to: to);
}

MuniService? _readService(Object? v) {
  if (v is! Map) return null;
  final rawDays = v['days'];
  if (rawDays is! List || rawDays.isEmpty) return null;
  final days = <int>[];
  for (final d in rawDays) {
    final n = _intOf(d);
    if (n == null || n < 1 || n > 7 || days.contains(n)) return null;
    days.add(n);
  }
  Season? season;
  if (v.containsKey('season')) {
    season = _readSeason(v['season']);
    if (season == null) return null;
  }
  String? label, at;
  if (v.containsKey('label')) {
    if (!_isText(v['label'])) return null;
    label = v['label'] as String;
  }
  if (v.containsKey('at')) {
    if (!_isText(v['at'])) return null;
    at = v['at'] as String;
  }
  // Exactly one of times/every.
  if (v.containsKey('times') == v.containsKey('every')) return null;
  List<String>? times;
  int? every;
  String? first, last;
  if (v.containsKey('times')) {
    if (v.containsKey('first') || v.containsKey('last')) return null;
    final raw = v['times'];
    if (raw is! List || raw.isEmpty) return null;
    times = <String>[];
    for (final t in raw) {
      if (t is! String || !_hhmmRe.hasMatch(t)) return null;
      if (times.isNotEmpty && _min(t) <= _min(times.last)) return null; // strictly ascending
      times.add(t);
    }
  } else {
    final e = _intOf(v['every']);
    if (e == null || e <= 0) return null;
    final f = v['first'], l = v['last'];
    if (f is! String || !_hhmmRe.hasMatch(f) || l is! String || !_hhmmRe.hasMatch(l)) return null;
    if (_min(f) > _min(l)) return null;
    every = e;
    first = f;
    last = l;
  }
  return MuniService(
    days: days,
    season: season,
    label: label,
    at: at,
    times: times,
    every: every,
    first: first,
    last: last,
  );
}

MuniLine? _readLine(Object? v) {
  if (v is! Map || !_isText(v['name'])) return null;
  final rawRoutes = v['routes'];
  if (rawRoutes is! List || rawRoutes.isEmpty) return null;
  final routes = <String>[];
  for (final r in rawRoutes) {
    if (!_isText(r)) return null;
    routes.add(r as String);
  }
  if (v.containsKey('ref') && v['ref'] != null && !_isText(v['ref'])) return null;
  final rawServices = v['services'];
  if (rawServices is! List || rawServices.isEmpty) return null;
  final services = <MuniService>[];
  for (final raw in rawServices) {
    final s = _readService(raw);
    if (s == null) return null;
    services.add(s);
  }
  String? group, note;
  if (v.containsKey('group')) {
    if (!_isText(v['group'])) return null;
    group = v['group'] as String;
  }
  if (v.containsKey('note')) {
    if (!_isText(v['note'])) return null;
    note = v['note'] as String;
  }
  return MuniLine(
    routes: routes,
    ref: _isText(v['ref']) ? v['ref'] as String : null,
    name: v['name'] as String,
    services: services,
    group: group,
    note: note,
  );
}

/// One table, when every field is right; null for anything else. The `watch` field is not needed here.
MuniTable? _readTable(Object? x) {
  if (x is! Map || !_isText(x['municipality']) || !_isDate(x['checked']) || !_isText(x['source'])) {
    return null;
  }
  if (x.containsKey('valid') && x['valid'] != null && !_isText(x['valid'])) return null;
  final rawLines = x['lines'];
  if (rawLines is! List || rawLines.isEmpty) return null;
  final lines = <MuniLine>[];
  for (final raw in rawLines) {
    final line = _readLine(raw);
    if (line == null) return null;
    lines.add(line);
  }
  return MuniTable(
    municipality: x['municipality'] as String,
    checked: x['checked'] as String,
    valid: _isText(x['valid']) ? x['valid'] as String : null,
    source: x['source'] as String,
    lines: lines,
  );
}

/// The file's tables, each validated whole. A table with any fault is dropped, never the others.
List<MuniTable> parseMuniTimes(Object? json) {
  if (json is! Map) return const [];
  final v = json['v'];
  final ok = v is int ? v == 1 : (v is double && v == 1);
  if (!ok) return const [];
  final raw = json['tables'];
  if (raw is! List) return const [];
  final out = <MuniTable>[];
  for (final t in raw) {
    final table = _readTable(t);
    if (table != null) out.add(table);
  }
  return out;
}

typedef MuniClock = ({String md, int weekday, int minutes});

/// The wall clock of Athens at [utc]: its "MM-DD", the ISO weekday and the minute of the day.
MuniClock muniClock(DateTime utc) {
  final w = athensWall(utc);
  final md = '${w.month.toString().padLeft(2, '0')}-${w.day.toString().padLeft(2, '0')}';
  return (md: md, weekday: w.weekday, minutes: w.hour * 60 + w.minute);
}

bool _inSeason(Season s, String md) =>
    s.from.compareTo(s.to) <= 0 ? (s.from.compareTo(md) <= 0 && md.compareTo(s.to) <= 0) : (md.compareTo(s.from) >= 0 || md.compareTo(s.to) <= 0);

/// The services of that weekday, when their season (if any) holds on that "MM-DD".
List<MuniService> activeServices(MuniLine line, MuniClock clock) => [
      for (final s in line.services)
        if (s.days.contains(clock.weekday) && (s.season == null || _inSeason(s.season!, clock.md))) s,
    ];

typedef _Departure = ({int min, String time, String? at, bool approx});

/// The next [n] departures from now, earliest first, one entry per time and stop.
List<({String time, String? at, bool approx})> _nextDepartures(
  List<MuniService> services,
  MuniClock clock,
  int n,
) {
  final all = <_Departure>[];
  for (final s in services) {
    final at = s.at;
    final times = s.times;
    if (times != null) {
      for (final t in times) {
        final m = _min(t);
        if (m >= clock.minutes) all.add((min: m, time: t, at: at, approx: false));
      }
    } else if (s.every != null && s.first != null && s.last != null) {
      for (var m = _min(s.first!); m <= _min(s.last!); m += s.every!) {
        if (m >= clock.minutes) all.add((min: m, time: _hhmm(m), at: at, approx: true));
      }
    }
  }
  // Stable by minute, so services keep the order they are listed in on a tie.
  final sorted = List<int>.generate(all.length, (i) => i)
    ..sort((a, b) {
      final c = all[a].min.compareTo(all[b].min);
      return c != 0 ? c : a.compareTo(b);
    });
  final out = <({String time, String? at, bool approx})>[];
  for (final i in sorted) {
    final d = all[i];
    if (out.any((o) => o.time == d.time && o.at == d.at)) continue;
    out.add((time: d.time, at: d.at, approx: d.approx));
    if (out.length == n) break;
  }
  return out;
}

/// The next departures per stop they are timed at, in the order the services give them: a time is never
/// shown as leaving from another stop.
List<({String? at, bool approx, List<String> times})> nextByStop(MuniLine line, MuniClock clock, {int n = 3}) {
  final active = activeServices(line, clock);
  final ats = <String?>[];
  for (final s in active) {
    final at = s.at;
    if (!ats.contains(at)) ats.add(at);
  }
  final out = <({String? at, bool approx, List<String> times})>[];
  for (final at in ats) {
    final next = _nextDepartures(
      [for (final s in active) if (s.at == at) s],
      clock,
      n,
    );
    if (next.isEmpty) continue;
    out.add((
      at: at,
      approx: next.any((d) => d.approx),
      times: [for (final d in next) d.time],
    ));
  }
  return out;
}

// "Δημοτικό Λεωφορείο 010: Α → Β" names the service, not the road: a card shows what is left.
final _prefix = RegExp(r'^(Δημοτικό Λεωφορείο|Γραμμή)[^:]*:\s*');

String _bare(String name) => name.replaceFirst(_prefix, '').trim();

int _byId(MuniRoute a, MuniRoute b) => a.id.compareTo(b.id);

/// One card per line: the two directions of a line, found by ref (inside one municipality), by the
/// timetable line that lists them, and by the ref or group that two timetable lines share.
List<MuniCard> muniCards(Municipal d, List<MuniTable> tables) {
  final routes = d.routes;
  final parent = List<int>.generate(routes.length, (i) => i);
  int root(int i) => parent[i] == i ? i : (parent[i] = root(parent[i]));
  void join(int a, int b) {
    final ra = root(a), rb = root(b);
    if (ra != rb) parent[ra > rb ? ra : rb] = ra < rb ? ra : rb;
  }

  final seen = <String, int>{};
  void at(String key, int i) {
    final j = seen[key];
    if (j == null) {
      seen[key] = i;
    } else {
      join(i, j);
    }
  }

  for (var i = 0; i < routes.length; i++) {
    final ref = routes[i].ref;
    if (ref != null) at('ref|${routes[i].municipality}|$ref', i);
  }
  for (var ti = 0; ti < tables.length; ti++) {
    final table = tables[ti];
    for (var li = 0; li < table.lines.length; li++) {
      final line = table.lines[li];
      for (final rid in line.routes) {
        final i = routes.indexWhere((r) => r.id == rid);
        if (i >= 0) at('line|$ti|$li', i); // every route of one line joins the others
      }
      final first = routes.indexWhere((r) => line.routes.contains(r.id));
      if (first < 0) continue;
      if (line.ref != null) at('tref|$ti|${line.ref}', first);
      if (line.group != null) at('tgroup|$ti|${line.group}', first);
    }
  }

  final groups = <int, List<MuniRoute>>{};
  for (var i = 0; i < routes.length; i++) {
    (groups[root(i)] ??= <MuniRoute>[]).add(routes[i]);
  }

  final out = <MuniCard>[];
  for (final list in groups.values) {
    MuniTable? table;
    for (final t in tables) {
      if (t.lines.any((l) => l.routes.any((rid) => list.any((r) => r.id == rid)))) {
        table = t;
        break;
      }
    }
    final ids = {for (final r in list) r.id};
    final lines = table == null
        ? <MuniLine>[]
        : [for (final l in table.lines) if (l.routes.any(ids.contains)) l];

    final ordered = <MuniRoute>[];
    for (final l in lines) {
      for (final rid in l.routes) {
        for (final r in list) {
          if (r.id == rid && !ordered.contains(r)) ordered.add(r);
        }
      }
    }
    final rest = [for (final r in list) if (!ordered.contains(r)) r]..sort(_byId);
    final cardRoutes = [...ordered, ...rest];

    final ref = (lines.where((l) => l.ref != null).firstOrNull?.ref) ??
        (cardRoutes.where((r) => r.ref != null).firstOrNull?.ref);
    final idsSorted = [for (final r in cardRoutes) r.id]..sort();
    final smallest = idsSorted.first.replaceFirst(RegExp(r'^osm:'), '');
    final group = lines.where((l) => l.group != null).firstOrNull?.group;
    final name = group ??
        (lines.length == 1
            ? lines[0].name
            : lines.isNotEmpty
                ? lines[0].name.replaceAll('→', '↔')
                : _bare(cardRoutes[0].name));

    out.add(MuniCard(
      id: 'muni:$smallest',
      ref: ref,
      name: name,
      municipality: cardRoutes[0].municipality,
      routes: cardRoutes,
      table: table,
      lines: lines,
    ));
  }
  return out;
}

// For search: case and accent folded, final sigma as σ.
String _norm(String s) => fold(s).replaceAll('ς', 'σ');

// A query word of 5+ letters matches by its stem (the last 2 letters cut), so the nominative finds
// the genitive: «Χολαργός» finds «Δήμος Παπάγου-Χολαργού».
final _wordSplit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

List<String> _stems(String query) {
  final out = <String>[];
  for (final w in _norm(query.trim()).split(_wordSplit)) {
    if (w.isEmpty) continue;
    out.add(w.length >= 5 ? w.substring(0, w.length - 2) : w);
  }
  return out;
}

bool _hasAll(String text, List<String> words) {
  final t = _norm(text);
  return words.every(t.contains);
}

/// Finder search by ref first, then municipality, then name; a stable order within each rank.
List<MuniCard> findMuniCards(List<MuniCard> cards, String query) {
  final words = _stems(query);
  if (words.isEmpty) return const [];
  final qid = _norm(query.trim());
  int rank(MuniCard c) {
    final ref = c.ref == null ? '' : _norm(c.ref!.trim());
    if (ref.isNotEmpty && ref == qid) return 0;
    if (ref.isNotEmpty && ref.startsWith(qid)) return 1;
    if (_hasAll(c.municipality, words)) return 2;
    if (_hasAll(c.name, words)) return 3;
    return -1;
  }

  final ranked = <(int, int, MuniCard)>[];
  for (var i = 0; i < cards.length; i++) {
    final r = rank(cards[i]);
    if (r >= 0) ranked.add((r, i, cards[i]));
  }
  ranked.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [for (final x in ranked) x.$3];
}

/// The cards whose routes list [stopId], in card order.
List<MuniCard> cardsAtStop(List<MuniCard> cards, String stopId) =>
    [for (final c in cards) if (c.routes.any((r) => r.stops.contains(stopId))) c];
