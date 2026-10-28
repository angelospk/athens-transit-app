// Live vehicles of the lines the app watches, polled as the contract asks: at next_update_at + 1..3 s,
// never faster than every 5 s, backing off at least 10 s after 429/5xx/network errors. Without a network
// it falls back to the last saved copy, and the screens show estimates (the "~" times).

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/eta.dart';
import '../core/models.dart';
import 'api.dart';

class LiveHub extends ChangeNotifier {
  LiveHub(this.api);

  final Api api;
  final lives = <String, LineLive>{};
  final statics = <String, LineStatic>{};
  final _timers = <String, Timer>{};
  final _backoff = <String, int>{};
  final _due = <String, int>{}; // ms epoch: the earliest next poll, kept across pause/resume
  final _inFlight = <String>{};
  final _rng = Random();
  Set<String> _watched = {};
  bool _paused = false;
  Timer? _recount; // the times count down between polls, as on the live card (every 10 s)

  // Lines whose last fetch failed and whose data is the saved copy.
  final offline = <String>{};
  int? lastOkAt; // Unix s of the last successful fetch

  bool get isOffline => _watched.isNotEmpty && offline.containsAll(_watched);

  int get nowS => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  void watch(Iterable<String> lines) {
    _recount ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_paused && lives.isNotEmpty) notifyListeners();
    });
    final next = lines.toSet();
    for (final l in _watched.difference(next)) {
      _timers.remove(l)?.cancel();
      lives.remove(l); // no longer polled: a screen showing it polls it itself
      offline.remove(l);
    }
    final added = next.difference(_watched);
    _watched = next;
    for (final l in added) {
      _start(l);
    }
  }

  // App in the background: stop polling (the foreground service watches alerts on its own).
  void pause(bool p) {
    if (p == _paused) return;
    _paused = p;
    if (p) {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    } else {
      for (final l in _watched) {
        _pollWhenDue(l);
      }
    }
  }

  Future<void> _start(String line) async {
    try {
      statics[line] ??= await api.lineStatic(line);
    } catch (_) {/* retried with the next poll */}
    if (!lives.containsKey(line)) {
      final saved = await api.savedLive(line);
      if (saved != null && !lives.containsKey(line)) {
        lives[line] = saved;
        notifyListeners();
      }
    }
    _pollWhenDue(line);
  }

  // Never before the line's deadline, so a quick pause/resume or re-watch stays within the contract.
  void _pollWhenDue(String line) {
    final wait = max(0, (_due[line] ?? 0) - DateTime.now().millisecondsSinceEpoch);
    _timers[line]?.cancel();
    _timers[line] = Timer(Duration(milliseconds: wait), () => _poll(line));
  }

  Future<void> _poll(String line) async {
    if (!_watched.contains(line) || _paused || !_inFlight.add(line)) return;
    int delayMs;
    try {
      statics[line] ??= await api.lineStatic(line);
      final l = await api.live(line);
      if (!_watched.contains(line)) return; // unwatched while the request ran: its screen polls it now
      lives[line] = l;
      offline.remove(line);
      _backoff.remove(line);
      lastOkAt = nowS;
      final wait = (l.nextUpdateAt - nowS) * 1000 + 1000 + _rng.nextInt(2000);
      delayMs = max(wait, 5000);
      if (delayMs > 300000) delayMs = 300000;
    } catch (e) {
      final warm = e is ApiError && e.warmingUp;
      if (!warm) offline.add(line);
      final b = _backoff[line] = min((_backoff[line] ?? 5000) * 2, 120000);
      delayMs = max(b, 10000);
    } finally {
      _inFlight.remove(line);
    }
    _due[line] = DateTime.now().millisecondsSinceEpoch + delayMs;
    notifyListeners();
    if (!_watched.contains(line) || _paused) return;
    _timers[line]?.cancel();
    _timers[line] = Timer(Duration(milliseconds: delayMs), () => _poll(line));
  }

  // Arrivals at a saved stop (matched by name and place in each line's static file).
  List<Arrival> arrivalsNear(String name, double lat, double lon, {Iterable<String>? only}) {
    final out = <Arrival>[];
    final seen = <String>{};
    for (final line in only ?? lives.keys) {
      final st = statics[line], live = lives[line];
      if (st == null || live == null) continue;
      for (final id in stopIdsNear(st, name, lat, lon)) {
        for (final a in arrivalsAt(id, {line: st}, {line: live}, nowS)) {
          if (seen.add('${a.line}|${a.vehicleId}')) out.add(a);
        }
      }
    }
    return out..sort((a, b) => a.etaS.compareTo(b.etaS));
  }

  // Static data of lines with no bus near: a stop's runs that have not started yet need the route.
  Future<void> loadStatics(Iterable<String> lines) => Future.wait([
        for (final l in lines.where((l) => !statics.containsKey(l)))
          api.lineStatic(l).then<void>((s) => statics[l] ??= s).catchError((_) {}),
      ]);

  // Every line near a point from the citywide snapshot tiles (z 13, ~3.9 km): arrivals for lines the
  // user does not watch, without asking the backend to watch them. No next_stop_id there, so the stop
  // counts are unknown and the ETA comes from the position alone.
  Future<Map<String, LineLive>> nearbyLives(double lat, double lon, Iterable<String> lines) async {
    final n = 1 << 13;
    final x = ((lon + 180) / 360 * n).floor();
    final latR = lat * pi / 180;
    final y = ((1 - log(tan(latR) + 1 / cos(latR)) / pi) / 2 * n).floor();
    final want = lines.toSet();
    final byLine = <String, List<Vehicle>>{};
    var updated = 0, next = 0;
    await Future.wait([
      for (var dx = -1; dx <= 1; dx++)
        for (var dy = -1; dy <= 1; dy++)
          api.tile(13, x + dx, y + dy).then((t) {
            updated = max(updated, t.updatedAt);
            next = max(next, t.nextUpdateAt);
            for (final v in t.vehicles) {
              if (want.contains(v.line)) (byLine[v.line!] ??= []).add(v);
            }
          }).catchError((_) {}),
    ]);
    for (final l in byLine.keys) {
      try {
        statics[l] ??= await api.lineStatic(l);
      } catch (_) {}
    }
    return {for (final e in byLine.entries) e.key: LineLive(line: e.key, updatedAt: updated, nextUpdateAt: next, vehicles: e.value)};
  }

  @override
  void dispose() {
    _recount?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

// Stop ids of a line at a named place: same name within 200 m (both sides of the street), else the
// nearest stop within 60 m (the trip index and the static file may spell a name differently).
List<String> stopIdsNear(LineStatic st, String name, double lat, double lon) {
  final n = name.trim();
  final same = <String>[];
  String? nearest;
  var best = 60.0;
  st.stops.forEach((id, s) {
    final d = _dist(lat, lon, s.lat, s.lon);
    if (s.name.trim() == n && d < 200) same.add(id);
    if (d < best) {
      best = d;
      nearest = id;
    }
  });
  return same.isNotEmpty ? same : [?nearest];
}

double _dist(double a, double b, double c, double d) {
  final dy = (a - c) * 111195, dx = (b - d) * 111195 * cos(a * pi / 180);
  return sqrt(dx * dx + dy * dy);
}
