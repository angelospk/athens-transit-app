// How a bus is drawn on the map, as on the web (format.ts, MapView.svelte): its colour by delay, the
// arrow of its heading, and whether the map's filters keep it.

import 'dart:math';

import 'geo.dart';
import 'models.dart';

const staleS = 90; // an older position is drawn faded, with its age

/// What the other buses do while one bus or line is open ("Όταν πατάς ένα, τα άλλα").
enum Others { normal, dim, hide }

/// The web's delay classes: up to 2′ late (or early), 2–5′, 5–10′, over 10′, and no trip.
String delayHex(int? delayS) => switch (delayS) {
      null => '#6C757D',
      <= 120 => '#1A7F37',
      <= 300 => '#A87C00',
      <= 600 => '#D9480F',
      _ => '#C92A2A',
    };

/// Degrees clockwise from north: the bus's own bearing, else the direction of its path where it is
/// drawn, else null (no arrow).
double? headingOf(Vehicle v, Pt at) {
  if (v.bearing case final b?) return b % 360;
  final path = v.path;
  if (path == null || path.length < 2) return null;
  final len = shapeLength(path);
  if (len < 5) return null;
  final s = (project(path, at)?.s ?? 0.0).clamp(0.0, max(0.0, len - 15)).toDouble();
  return bearingDeg(pointAt(path, s), pointAt(path, min(len, s + 15)));
}

double bearingDeg(Pt a, Pt b) {
  final dx = (b.$2 - a.$2) * cos(a.$1 * pi / 180), dy = b.$1 - a.$1;
  return (atan2(dx, dy) * 180 / pi + 360) % 360;
}

/// The map's filters: "Μόνο με πρόσφατη θέση" (≤ 1½′) and "Μόνο στην ώρα τους" (≤ 5′ late).
bool keptBy(Vehicle v, int nowS, {required bool fresh, required bool onTime}) =>
    (!fresh || nowS - v.positionAt <= staleS) && (!onTime || (v.delayS != null && v.delayS! <= 300));
