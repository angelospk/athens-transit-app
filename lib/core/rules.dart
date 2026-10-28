import 'athens_time.dart';
import 'eta.dart';
import 'models.dart';

enum AlertMode { minutes, stops }

/// What the alert is for: the bus reaching the stop, time to leave for it (screen 16), getting off
/// there (screen 17), or a followed trip («Ακολούθησέ με»): the service looks for the bus the phone
/// rides, then alerts as [ride] for that bus. It changes only the words; when it fires is set by mode
/// and n.
enum RuleKind { arrive, leave, ride, board }

class Rule {
  final String id, line, variant, stopId, stopName;
  final int stopIndex, n;
  final AlertMode mode;

  /// bit0 = Monday .. bit6 = Sunday.
  final int days, startMin, endMin;

  /// Unix s. A one-off rule (ignores days and minutes) is active until then.
  final int? untilS;
  final bool live, enabled;
  final int? pausedUntilS;
  final RuleKind kind;
  final String? vehicle; // only this bus ("Είμαι μέσα"); null: any bus of the line

  /// "Πες μου και αν αργεί": also alert once per bus whose delay reaches these minutes. null: no.
  final int? lateMin;

  const Rule({
    required this.id,
    required this.line,
    required this.variant,
    required this.stopIndex,
    required this.stopId,
    required this.stopName,
    required this.mode,
    required this.n,
    required this.days,
    required this.startMin,
    required this.endMin,
    this.untilS,
    this.live = true,
    this.enabled = true,
    this.pausedUntilS,
    this.kind = RuleKind.arrive,
    this.vehicle,
    this.lateMin,
  });

  Rule copyWith({
    String? id,
    String? line,
    String? variant,
    int? stopIndex,
    String? stopId,
    String? stopName,
    AlertMode? mode,
    int? n,
    int? days,
    int? startMin,
    int? endMin,
    int? untilS,
    bool? live,
    bool? enabled,
    int? pausedUntilS,
    RuleKind? kind,
    String? vehicle,
    int? lateMin,
  }) =>
      Rule(
        id: id ?? this.id,
        line: line ?? this.line,
        variant: variant ?? this.variant,
        stopIndex: stopIndex ?? this.stopIndex,
        stopId: stopId ?? this.stopId,
        stopName: stopName ?? this.stopName,
        mode: mode ?? this.mode,
        n: n ?? this.n,
        days: days ?? this.days,
        startMin: startMin ?? this.startMin,
        endMin: endMin ?? this.endMin,
        untilS: untilS ?? this.untilS,
        live: live ?? this.live,
        enabled: enabled ?? this.enabled,
        pausedUntilS: pausedUntilS ?? this.pausedUntilS,
        kind: kind ?? this.kind,
        vehicle: vehicle ?? this.vehicle,
        lateMin: lateMin ?? this.lateMin,
      );

  bool activeAt(DateTime utc) {
    final nowS = utc.millisecondsSinceEpoch ~/ 1000;
    if (!enabled) return false;
    if (pausedUntilS != null && pausedUntilS! > nowS) return false;
    if (untilS != null) return nowS <= untilS!;
    final w = athensWall(utc);
    if (days & (1 << (w.weekday - 1)) == 0) return false;
    final m = w.hour * 60 + w.minute;
    return startMin <= m && m < endMin;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'line': line,
        'variant': variant,
        'stopIndex': stopIndex,
        'stopId': stopId,
        'stopName': stopName,
        'mode': mode.name,
        'n': n,
        'days': days,
        'startMin': startMin,
        'endMin': endMin,
        'untilS': untilS,
        'live': live,
        'enabled': enabled,
        'pausedUntilS': pausedUntilS,
        if (kind != RuleKind.arrive) 'kind': kind.name,
        'vehicle': ?vehicle,
        'lateMin': ?lateMin,
      };

  factory Rule.fromJson(Map<String, dynamic> j) => Rule(
        id: j['id'] as String,
        line: j['line'] as String,
        variant: j['variant'] as String,
        stopIndex: (j['stopIndex'] as num).toInt(),
        stopId: j['stopId'] as String,
        stopName: (j['stopName'] as String?) ?? '',
        mode: AlertMode.values.firstWhere((m) => m.name == j['mode'], orElse: () => AlertMode.minutes),
        n: (j['n'] as num).toInt(),
        days: (j['days'] as num?)?.toInt() ?? 0,
        startMin: (j['startMin'] as num?)?.toInt() ?? 0,
        endMin: (j['endMin'] as num?)?.toInt() ?? 0,
        untilS: (j['untilS'] as num?)?.toInt(),
        live: j['live'] as bool? ?? true,
        enabled: j['enabled'] as bool? ?? true,
        pausedUntilS: (j['pausedUntilS'] as num?)?.toInt(),
        kind: RuleKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => RuleKind.arrive),
        vehicle: j['vehicle'] as String?,
        lateMin: (j['lateMin'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is Rule &&
      other.id == id &&
      other.line == line &&
      other.variant == variant &&
      other.stopIndex == stopIndex &&
      other.stopId == stopId &&
      other.stopName == stopName &&
      other.mode == mode &&
      other.n == n &&
      other.days == days &&
      other.startMin == startMin &&
      other.endMin == endMin &&
      other.untilS == untilS &&
      other.live == live &&
      other.enabled == enabled &&
      other.pausedUntilS == pausedUntilS &&
      other.kind == kind &&
      other.vehicle == vehicle &&
      other.lateMin == lateMin;

  @override
  int get hashCode => Object.hashAll([
        id, line, variant, stopIndex, stopId, stopName, mode, n, days, startMin, endMin, untilS, live, enabled, pausedUntilS, kind, vehicle, lateMin,
      ]);
}

/// The rules the watcher checks: a followed trip once its bus is known ([boarded]: rule id to
/// vehicle id) as the ride alert of that bus; before that it alerts nothing.
List<Rule> watchedRules(List<Rule> active, Map<String, String> boarded) => [
      for (final r in active)
        if (r.kind != RuleKind.board)
          r
        else if (boarded[r.id] case final v?)
          r.copyWith(kind: RuleKind.ride, vehicle: v),
    ];

/// The followed trips still looking for their bus.
List<Rule> lookingRules(List<Rule> active, Map<String, String> boarded) =>
    [for (final r in active) if (r.kind == RuleKind.board && !boarded.containsKey(r.id)) r];

class RuleHit {
  final String ruleId, line, vehicleId;
  final int? stopsLeft, etaS, delayS;
  final bool late; // the delay alert of [Rule.lateMin], not the arrival
  const RuleHit({
    required this.ruleId,
    required this.line,
    required this.vehicleId,
    required this.stopsLeft,
    required this.etaS,
    required this.delayS,
    this.late = false,
  });
}

/// Fires once per rule for each run of a bus to the stop. The bus (vehicle id) is the identity, so a
/// trip id that shows up mid-trip changes nothing; seeing the bus past the stop or on another variant
/// ends the run, so its next one alerts again. A bus missing from a poll keeps its run.
class RuleWatcher {
  static const _keepS = 2 * 3600;
  final Map<String, int> _fired; // key -> when fired (s)

  RuleWatcher([Map<String, int>? fired]) : _fired = fired ?? {};

  factory RuleWatcher.fromJson(Map<String, dynamic> j) => RuleWatcher({
        for (final e in (j['fired'] as Map? ?? const {}).entries) e.key as String: (e.value as num).toInt(),
      });

  Map<String, dynamic> toJson() => {'fired': Map<String, int>.of(_fired)};

  /// [rules] are the ones active now (the caller filters).
  List<RuleHit> check(List<Rule> rules, Map<String, LineStatic> statics, Map<String, LineLive> lives, int nowS) {
    _fired.removeWhere((_, at) => nowS - at > _keepS);
    final hits = <RuleHit>[];
    for (final r in rules) {
      final st = statics[r.line];
      final stops = st?.variants[r.variant]?.stops;
      if (st == null || stops == null) continue;
      for (final v in lives[r.line]?.vehicles ?? const <Vehicle>[]) {
        if (nowS - v.positionAt > maxFixAgeS) continue;
        if (r.vehicle != null && v.id != r.vehicle) continue;
        final key = '${r.id}|${v.id}';
        if (v.variant == null) continue; // unknown: neither a hit nor the end of the run
        if (v.variant != r.variant || _pastStop(st, stops, r.stopIndex, v)) {
          _fired.remove(key);
          _fired.remove('late|$key');
          continue;
        }
        final left = stopsLeft(stops, r.stopIndex, v, nowS);
        final eta = etaSeconds(st, v, r.stopIndex, nowS);
        final lateMin = r.lateMin;
        // Within the hour only: a bus waiting at its start grows a delay long before it matters.
        if (lateMin != null && eta != null && eta <= 3600 && (v.delayS ?? 0) >= lateMin * 60 && !_fired.containsKey('late|$key')) {
          _fired['late|$key'] = nowS;
          hits.add(RuleHit(ruleId: r.id, line: r.line, vehicleId: v.id, stopsLeft: left, etaS: eta, delayS: v.delayS, late: true));
        }
        final fire = switch (r.mode) {
          AlertMode.minutes => eta != null && eta <= r.n * 60,
          AlertMode.stops => left != null && left >= 1 && left <= r.n,
        };
        if (!fire) continue;
        if (_fired.containsKey(key)) continue;
        _fired[key] = nowS;
        hits.add(RuleHit(ruleId: r.id, line: r.line, vehicleId: v.id, stopsLeft: left, etaS: eta, delayS: v.delayS));
      }
    }
    return hits;
  }
}

// Past stops[i] by both the next stop and the position, so one noisy next_stop_id does not end a run.
// A next stop the variant passes twice (loops) says nothing about which pass it is: never past.
bool _pastStop(LineStatic st, List<String> stops, int i, Vehicle v) {
  final next = v.nextStopId;
  if (next == null) return false;
  final k = stops.indexOf(next);
  return k > i && stops.indexOf(next, k + 1) < 0 && pastByPosition(st, v, i);
}

/// "Το 622 είναι 2 στάσεις πριν από ΑΓΟΡΑ (καθυστέρηση 3′), σε ~5′."
String hitText(RuleHit h, String stop) {
  final d = h.delayS;
  final late = d != null && d >= 60 ? ' (καθυστέρηση ${(d / 60).round()}′)' : '';
  final e = h.etaS;
  final inMin = e == null ? '' : ', σε ~${(e / 60).round()}′';
  final left = h.stopsLeft;
  if (left == 1) return 'Το ${h.line} έρχεται: επόμενη στάση του η $stop$late.';
  if (left == null) return 'Το ${h.line} φτάνει στη $stop$late${e == null ? '' : ' σε ~${(e / 60).round()}′'}.';
  return 'Το ${h.line} είναι $left στάσεις πριν από $stop$late$inMin.';
}

/// The notification's title and text for a hit of [r]: the arrival wording, or "leave now", or "get
/// off at the next stop".
(String, String) ruleHitText(Rule r, RuleHit h, String stop) => h.late
    ? (
        '${h.line} αργεί ${((h.delayS ?? 0) / 60).round()}′',
        'Για τη στάση $stop${h.etaS == null ? '' : ': φτάνει σε ~${(h.etaS! / 60).round()}′'}${h.stopsLeft == null ? '' : ' (${h.stopsLeft} ${h.stopsLeft == 1 ? 'στάση' : 'στάσεις'})'}.'
      )
    : switch (r.kind) {
      RuleKind.arrive => ('${h.line} → $stop', hitText(h, stop)),
      RuleKind.leave => ('Φύγε τώρα για το ${h.line}', 'Για να είσαι στη στάση $stop πριν έρθει${h.etaS == null ? '' : ' (σε ~${(h.etaS! / 60).round()}′)'}.'),
      RuleKind.ride || RuleKind.board => ('Κατέβα στην επόμενη', 'Η επόμενη στάση του ${h.line} είναι η $stop.'),
    };

/// When a weekly rule next starts (strictly after [nowUtc]), or null for one-off and disabled rules.
DateTime? nextStartUtc(Rule r, DateTime nowUtc) {
  if (!r.enabled || r.untilS != null || r.days == 0) return null;
  final wall = athensWall(nowUtc);
  for (var k = 0; k <= 7; k++) {
    final day = DateTime.utc(wall.year, wall.month, wall.day + k);
    if (r.days & (1 << (day.weekday - 1)) == 0) continue;
    final wallStart = day.add(Duration(minutes: r.startMin));
    // The offset at that moment: try EET first, then EEST.
    var utc = wallStart.subtract(const Duration(hours: 2));
    if (athensOffsetHours(utc) == 3) utc = wallStart.subtract(const Duration(hours: 3));
    final paused = r.pausedUntilS;
    if (utc.isAfter(nowUtc) && (paused == null || utc.millisecondsSinceEpoch ~/ 1000 >= paused)) return utc;
  }
  return null;
}

/// Until when "Σταμάτα" on the live card stops a rule: a one-off rule for good (its own end), a weekly
/// rule for the rest of the Athens day, so tomorrow's run alerts again.
int stopUntilS(Rule r, DateTime utc) {
  if (r.untilS != null) return r.untilS!;
  final w = athensWall(utc);
  // Midnight on the Athens wall clock, at the offset of that moment (a DST change may lie between).
  final wall = DateTime.utc(w.year, w.month, w.day + 1);
  var at = wall.subtract(const Duration(hours: 2));
  if (athensOffsetHours(at) == 3) at = wall.subtract(const Duration(hours: 3));
  return at.millisecondsSinceEpoch ~/ 1000;
}

/// The rule ids of stop entries ("id|untilS") still in force at [nowS].
Set<String> stoppedIds(Iterable<String> entries, int nowS) => {
      for (final e in entries)
        if (e.split('|') case [final id, final until] when (int.tryParse(until) ?? 0) > nowS) id,
    };
