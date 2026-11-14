// A stop's arrival board (backend GET /v1/stops/{id}, contract rev 8/18/21/22) and what the card shows of it. A
// port of the web's src/lib/stops.ts (arrivalGroups, arrivalNote, timeText, usualRows, headTo, signCode): the
// words and the rules are the web's. Pure: no widgets, no network.

import 'athens_time.dart';
import 'geo.dart';
import 'models.dart';
import 'nearby.dart' show fold;

int? _int(Object? v) => v is num && v.isFinite ? v.toInt() : null;
String? _str(Object? v) => v is String ? v : null;

/// One row of the board's `arrivals`. [live] false: a timetable trip with no bus yet (`source: schedule`).
class StopArrival {
  const StopArrival({
    required this.line,
    required this.headsign,
    required this.variant,
    required this.vehicle,
    required this.at,
    required this.delayS,
    this.live = true,
    this.tripIdKnown = true,
    this.stopsAway,
    this.distanceM,
    this.positionAt = 0,
  });
  final String line, headsign, variant, vehicle;
  final int at; // Unix s the bus is due
  final int delayS;
  final bool live;
  final bool tripIdKnown; // false: `trip_id: null`, an unmatched bus (a time from speed only)
  final int? stopsAway, distanceM;
  final int positionAt;

  static StopArrival? tryParse(Object? j) {
    if (j is! Map) return null;
    final line = _str(j['line']), headsign = _str(j['headsign']), at = _int(j['at']);
    if (line == null || headsign == null || at == null) return null;
    return StopArrival(
      line: line,
      headsign: headsign,
      variant: _str(j['variant']) ?? '',
      vehicle: j['vehicle'] == null ? '' : '${j['vehicle']}',
      at: at,
      delayS: _int(j['delay_s']) ?? 0,
      live: j['source'] != 'schedule',
      // `trip_id: null` is unmatched; a missing key is an older server (no estimate mark).
      tripIdKnown: !(j.containsKey('trip_id') && j['trip_id'] == null),
      stopsAway: _int(j['stops_away']),
      distanceM: _int(j['distance_m']),
      positionAt: _int(j['position_at']) ?? 0,
    );
  }
}

/// Contract rev 18: how often a line usually passes at this hour of this kind of day.
class Usual {
  const Usual({required this.line, required this.headsign, this.headwayMin, this.nextAt});
  final String line, headsign;
  final int? headwayMin;
  final int? nextAt;

  static Usual? tryParse(Object? j) {
    if (j is! Map) return null;
    final line = _str(j['line']), headsign = _str(j['headsign']);
    if (line == null || headsign == null) return null;
    return Usual(line: line, headsign: headsign, headwayMin: _int(j['headway_min']), nextAt: _int(j['next_at']));
  }
}

class StopBoard {
  const StopBoard({required this.id, required this.name, this.code, required this.lines, required this.arrivals, required this.usual, this.refreshing = false});
  final String id, name;
  final String? code; // rev 21: the code on the stop sign, OASA only
  final List<String> lines;
  final List<StopArrival> arrivals;
  final List<Usual> usual;
  final bool refreshing;

  /// Null when the body is not a board (an HTML page, a warming-up answer with no `arrivals`).
  static StopBoard? tryParse(Object? body) {
    if (body is! Map) return null;
    final stop = body['stop'], arrivals = body['arrivals'];
    if (stop is! Map || arrivals is! List) return null;
    final lines = body['lines'];
    return StopBoard(
      id: '${stop['id']}',
      name: _str(stop['name']) ?? '',
      code: _str(stop['code']),
      lines: [if (lines is List) for (final l in lines) if (l is String) l],
      arrivals: [for (final a in arrivals) ?StopArrival.tryParse(a)],
      usual: [if (body['usual'] is List) for (final u in body['usual'] as List) ?Usual.tryParse(u)],
      refreshing: body['refreshing'] == true,
    );
  }
}

/// Seconds to wait before the board is asked again: 20 s, or 2 s (at most 3 times in a row) while the server says
/// a new one is on its way. Returns (ms, quick count), as the web's `stopDelay`.
({int ms, int quick}) stopDelay(bool refreshing, int quick) => refreshing && quick < 3 ? (ms: 2000, quick: quick + 1) : (ms: 20000, quick: 0);

/// A time of one bus. here: at the stop (its next one, at most [hereM] away); away: stops to go, from 2; est: no trip,
/// a time from speed only. Each is left out when not so or not known.
class ArrivalTime {
  const ArrivalTime({required this.min, required this.vehicle, required this.late, this.here = false, this.away, this.est = false});
  final int min;
  final String vehicle;
  final int late; // whole minutes
  final bool here;
  final int? away;
  final bool est;

  @override
  bool operator ==(Object other) =>
      other is ArrivalTime && other.min == min && other.vehicle == vehicle && other.late == late && other.here == here && other.away == away && other.est == est;
  @override
  int get hashCode => Object.hash(min, vehicle, late, here, away, est);
  @override
  String toString() => 'ArrivalTime($min, $vehicle, late $late${here ? ', here' : ''}${away != null ? ', away $away' : ''}${est ? ', est' : ''})';
}

class ArrivalGroup {
  ArrivalGroup(this.line, this.headsign, this.variant) : times = [];
  final String line, headsign, variant;
  final List<ArrivalTime> times;
}

const goneMs = 60000;
const hereM = 50;

String timeText(ArrivalTime t) => t.here ? 'στη στάση' : '${t.est ? '~' : ''}${t.min == 0 ? 'τώρα' : '${t.min}′'}';

int _roundHalfUp(num x) => (x + 0.5).floor(); // JS Math.round

/// Arrivals by line and headsign, soonest first, each with up to 3 times in minutes from `at` (so an answer kept a
/// while still counts down); late: the delay in whole minutes. A bus more than [goneMs] past its time is left out,
/// and a timetable trip with no bus is not a bus.
List<ArrivalGroup> arrivalGroups(List<StopArrival> arrivals, int nowMs) {
  final groups = <String, ArrivalGroup>{};
  final sorted = [...arrivals]..sort((x, y) => x.at.compareTo(y.at));
  for (final a in sorted) {
    if (a.at * 1000 < nowMs - goneMs) continue;
    if (!a.live) continue;
    final g = groups.putIfAbsent('${a.line}|${a.headsign}', () => ArrivalGroup(a.line, a.headsign, a.variant));
    if (g.times.length >= 3) continue;
    final est = !a.tripIdKnown;
    g.times.add(ArrivalTime(
      min: _roundHalfUp((a.at * 1000 - nowMs) / 60000).clamp(0, 1 << 30),
      vehicle: a.vehicle,
      late: est ? 0 : _roundHalfUp(a.delayS / 60),
      here: a.stopsAway == 1 && a.distanceM != null && a.distanceM! <= hereM,
      away: a.stopsAway != null && a.stopsAway! >= 2 ? a.stopsAway : null,
      est: est,
    ));
  }
  return groups.values.toList();
}

enum NoteTone { ok, late, muted }

/// The line under an arrival's headsign: where the bus is (stops to go) and how it runs. est: no trip, so no delay to
/// tell; late of 2 minutes or more is late (an early bus is on time).
({String text, NoteTone tone}) arrivalNote(ArrivalTime t) {
  if (t.here) return (text: 'στη στάση', tone: NoteTone.ok);
  final where = t.away != null && t.away! > 0 ? ['${t.away} στάσεις πριν'] : <String>[];
  if (t.est) return (text: [...where, 'εκτίμηση'].join(' · '), tone: NoteTone.muted);
  if (t.late >= 2) return (text: [...where, 'αργεί ${t.late}′'].join(' · '), tone: NoteTone.late);
  return (text: [...where, 'στην ώρα του'].join(' · '), tone: NoteTone.ok);
}

String _clock(int unixS) {
  final w = athensWall(DateTime.fromMillisecondsSinceEpoch(unixS * 1000, isUtc: true));
  return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
}

/// The usual service of the lines with no bus on its way ([groups]: the live ones), one row per line and headsign
/// (web map#24, wording 2): the server's usual time while it is ahead, else the usual gap at this hour; rows with
/// neither are left out.
List<({String line, String headsign, String text})> usualRows(List<Usual> usual, List<ArrivalGroup> groups, int nowMs) {
  final out = <({String line, String headsign, String text})>[];
  for (final u in usual) {
    if (groups.any((g) => g.line == u.line)) continue;
    final next = u.nextAt;
    final text = next != null && next * 1000 > nowMs
        ? 'Συνήθως περνά ~${_clock(next)} (από τις προηγούμενες εβδομάδες)'
        : u.headwayMin != null
            ? 'Συνήθως περνά κάθε ~${u.headwayMin}′ τέτοια ώρα'
            : null;
    if (text != null) out.add((line: u.line, headsign: u.headsign, text: text));
  }
  return out;
}

/// The code on the stop sign: OASA's stop_code from the server (rev 21; it differs from the stop id for a third of the
/// stops), elsewhere the stop id.
String? signCode(String? code, String? id, {required bool athens}) {
  if (code != null && code.isNotEmpty) return code;
  return athens ? null : (id == null || id.isEmpty ? null : id);
}

/// The places of a headsign: split at " - ", but not inside brackets.
List<String> places(String headsign) {
  final out = <String>[];
  var depth = 0, from = 0;
  for (var i = 0; i < headsign.length; i++) {
    final c = headsign[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth = depth > 0 ? depth - 1 : 0;
    } else if (depth == 0 && headsign.startsWith(' - ', i)) {
      out.add(headsign.substring(from, i));
      from = i + 3;
      i += 2;
    }
  }
  out.add(headsign.substring(from));
  return out;
}

/// Where a bus runs to: the last place of an end-to-end headsign.
String toward(String headsign) {
  final t = places(headsign).last.trim();
  return t.isEmpty ? headsign : t;
}

/// The variant's end as the stop index has it (trips.json `d.h`), or null.
String? destinationOf(TripIndex ix, String line, String variant) {
  final k = ix.dh[line]?[variant];
  return k == null || k < 0 || k >= ix.dn.length ? null : ix.dn[k];
}

/// The end of a line at stop [k]: the end of its variants that pass there (not those that end there), when they all
/// have one and it is the same; else null. For a row with no variant.
String? lineTowardAt(TripIndex ix, String line, int k) {
  final names = <String?>{};
  for (final e in (ix.l[line] ?? const <String, List<int>>{}).entries) {
    final p = e.value.indexOf(k);
    if (p >= 0 && p < e.value.length - 1) names.add(destinationOf(ix, line, e.key));
  }
  return names.length == 1 ? names.first : null;
}

/// Where a bus of [line]/[variant] at stop [k] runs to. On a loop the headsign names the turn, the same on both sides
/// of a road; after the turn the bus runs back to the start: back, and to is the headsign's first place (or the first
/// stop). The turn: the stop named as the headsign's end, else the stop farthest from the start. Anything unknown: the
/// headsign's end.
({String to, bool back}) headTo(TripIndex ix, String line, String variant, int k, String headsign) {
  final end = toward(headsign);
  final plain = (to: destinationOf(ix, line, variant) ?? end, back: false);
  final seq = ix.l[line]?[variant];
  final p = seq == null ? -1 : seq.indexOf(k);
  if (seq == null || p < 0 || seq.length < 3) return plain;
  Pt pt(int x) => (ix.s[x].$2, ix.s[x].$3);
  final first = seq.first, last = seq.last;
  if (first != last) return plain; // a loop starts and ends at one stop
  final key = fold(end);
  var turn = seq.indexWhere((x) => fold(ix.s[x].$1) == key);
  if (turn < 0) {
    var far = -1.0;
    for (var q = 0; q < seq.length; q++) {
      final d = distM(pt(first), pt(seq[q]));
      if (d > far) {
        far = d;
        turn = q;
      }
    }
  }
  if (p <= turn) return plain;
  final parts = places(headsign);
  return (to: parts.length > 1 ? parts.first.trim() : ix.s[first].$1, back: true);
}
