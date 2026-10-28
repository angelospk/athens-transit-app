// "Am I on a bus?" from the phone's own track: a bus whose shown position stayed within reach of
// the phone for a minute while both moved. The app samples both every few seconds while it is open;
// nothing here needs background location.

import 'geo.dart';

typedef Fix = ({int t, Pt at}); // t: seconds

const _withinM = 45.0; // GPS of the phone and of the bus, both a little off
const _spanS = 55; // a minute of travel together
const _movedM = 150.0; // and the phone really moved (not standing at a stop beside a bus)

/// The id of the bus the phone rides, or null. [buses]: each bus's positions at the phone's times
/// (the same t), the newest last.
String? boardedOn(List<Fix> me, Map<String, List<Fix>> buses) {
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
      if (d > _withinM) {
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
