// The user's position in one of the app's cities, or null (no permission, location off, no fix within 10 s,
// or elsewhere).

import 'package:geolocator/geolocator.dart';

import '../core/city.dart';
import '../core/geo.dart';


// fresh: a new fix, never the last known one (an old one may be far from here).
Future<Pt?> myPosition({bool fresh = false}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await _request();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
    final last = fresh ? null : await Geolocator.getLastKnownPosition();
    // An old last fix (yesterday, elsewhere) is not where the user is: then ask for a new one.
    final pos = last != null && DateTime.now().difference(last.timestamp) < lastFixMaxAge && _inCity(last)
        ? last
        : await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)));
    // Outside the cities (an emulator's default, abroad) says nothing useful for this map.
    if (!_inCity(pos)) return null;
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}

// The position only when the user already allowed location: never shows the system question. The map
// asks with askPosition() after it says why.
Future<Pt?> knownPosition() async {
  try {
    final p = await Geolocator.checkPermission();
    if (p != LocationPermission.always && p != LocationPermission.whileInUse) return null;
  } catch (_) {
    return null;
  }
  return myPosition();
}

// One permission request at a time: the Android plugin keeps only the newest caller's callback, so the
// map and the planner asking together at start left the map waiting for ever.
Future<LocationPermission>? _asking;
Future<LocationPermission> _request() => _asking ??= Geolocator.requestPermission().whenComplete(() => _asking = null);

const lastFixMaxAge = Duration(minutes: 2);

bool _inCity(Position p) => inAnyCity(p.latitude, p.longitude);

// The user pressed "allow location": it asks again, and when Android no longer shows the question
// (refused for good: checkPermission still says "denied" then) or location is off, it opens the phone's
// settings instead.
Future<Pt?> askPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return null;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await _request();
    if (p == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }
    if (p == LocationPermission.denied) return null;
  } catch (_) {
    return null;
  }
  return myPosition(fresh: true);
}

// The welcome's «Επίτρεψε»: the system question only, no fix. When Android no longer asks (refused for
// good), it opens the app's settings. true: allowed.
Future<bool> askLocationPermission() async {
  try {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await _request();
    if (p == LocationPermission.deniedForever) await Geolocator.openAppSettings();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  } catch (_) {
    return false;
  }
}

// A fresh fix only when the user already allowed location: never asks, for checks that run by
// themselves (is the user on a bus?).
Future<Pt?> quietPosition() async {
  try {
    final p = await Geolocator.checkPermission();
    if (p != LocationPermission.always && p != LocationPermission.whileInUse) return null;
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)));
    if (!_inCity(pos)) return null;
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}
