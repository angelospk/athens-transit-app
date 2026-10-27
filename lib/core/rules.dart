import 'athens_time.dart';
import 'eta.dart';
import 'models.dart';

enum AlertMode { minutes, stops }

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
      other.pausedUntilS == pausedUntilS;

  @override
  int get hashCode => Object.hashAll([
        id, line, variant, stopIndex, stopId, stopName, mode, n, days, startMin, endMin, untilS, live, enabled, pausedUntilS,
      ]);
}

class RuleHit {
  final String ruleId, line, vehicleId;
  final int? stopsLeft, etaS, delayS;
  const RuleHit({
    required this.ruleId,
    required this.line,
    required this.vehicleId,
    required this.stopsLeft,
    required this.etaS,
    required this.delayS,
  });
}

/// Fires each trip once per rule.
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
        if (v.variant != r.variant || nowS - v.positionAt > maxFixAgeS) continue;
        final left = stopsLeft(stops, r.stopIndex, v, nowS);
        final eta = etaSeconds(st, v, r.stopIndex, nowS);
        final fire = switch (r.mode) {
          AlertMode.minutes => eta != null && eta <= r.n * 60,
          AlertMode.stops => left != null && left >= 1 && left <= r.n,
        };
        if (!fire) continue;
        final key = '${r.id}|${v.tripId ?? '${v.id}|${v.variant}'}';
        if (_fired.containsKey(key)) continue;
        _fired[key] = nowS;
        hits.add(RuleHit(ruleId: r.id, line: r.line, vehicleId: v.id, stopsLeft: left, etaS: eta, delayS: v.delayS));
      }
    }
    return hits;
  }
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
