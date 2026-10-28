// "Am I on a bus?" from the phone's own track: a bus whose shown position stayed within reach of
// the phone for a minute while both moved. The app samples both while it is open (the map); the
// background service does too for a followed trip («Ακολούθησέ με», BoardWatch).

import 'dart:math';

import 'geo.dart';
import 'models.dart';

typedef Fix = ({int t, Pt at}); // t: seconds

const _withinM = 45.0; // GPS of the phone and of the bus, both a little off
const _spanS = 55; // a minute of travel together
const _movedM = 150.0; // and the phone really moved (not standing at a stop beside a bus)

/// The id of the bus the phone rides, or null. [buses]: each bus's positions at the phone's times
/// (the same t), the newest last.
String? boardedOn(List<Fix> me, Map<String, List<Fix>> buses, {double withinM = _withinM}) {
  if (me.length < 2 || me.last.t - me.first.t < _spanS) return null;
  if (distM(me.first.at, me.last.at) < _movedM) return null;
  String? best;
  var bestM = double.infinity;
  for (final e in buses.entries) {
    final at = {for (final f in e.value) f.t: f.at};
    var sum = 0.0;
    var ok = true;
    for (final f in me) {
      final b = at[f.t];
      if (b == null) {
        ok = false;
        break;
      }
      final d = distM(f.at, b);
      if (d > withinM) {
        ok = false;
        break;
      }
      sum += d;
    }
    if (!ok) continue;
    final mean = sum / me.length;
    if (mean < bestM) {
      bestM = mean;
      best = e.key;
    }
  }
  return best;
}

/// Where a bus is at [t] (s) by its last fix moved on along its path at its speed, never past the
/// path's end; the fix itself without a path or speed.
Pt predictAt(Vehicle v, int t) {
  final path = v.path, speed = v.speed;
  if (path == null || path.length < 2 || speed == null || t <= v.positionAt) return (v.lat, v.lon);
  return pointAt(path, min(shapeLength(path), speed * (t - v.positionAt)));
}

/// The phone's fixes and the buses near them, as the background service gets them (the phone every
/// few seconds, the buses as polled, their fixes up to a minute old): [add] says which bus the phone
/// rides once it does. Looser than the map's [boardedOn] check: moved-on fixes are rougher.
class BoardWatch {
  BoardWatch({this.withinM = 80});
  final double withinM;
  final _me = <Fix>[];
  final _buses = <String, List<Fix>>{};

  String? add(int t, Pt at, Iterable<Vehicle> vehicles) {
    if (_me.isNotEmpty && t - _me.last.t > 40) {
      _me.clear(); // a gap: the minute together starts again
      _buses.clear();
    }
    _me
      ..add((t: t, at: at))
      ..removeWhere((f) => t - f.t > 90);
    for (final v in vehicles) {
      final p = predictAt(v, t);
      if (distM(p, at) <= 400) (_buses[v.id] ??= []).add((t: t, at: p));
    }
    for (final l in _buses.values) {
      l.removeWhere((f) => t - f.t > 90);
    }
    _buses.removeWhere((_, l) => l.isEmpty);
    return boardedOn(_me, _buses, withinM: withinM);
  }
}
