// The user's position in Attica, or null (no permission, location off, no fix within 10 s, or elsewhere).

import 'package:geolocator/geolocator.dart';

import '../core/geo.dart';

const athensCentre = (37.9755, 23.7348); // Syntagma

// fresh: a new fix, never the last known one (an old one may be far from here).
Future<Pt?> myPosition({bool fresh = false}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await _request();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
    final last = fresh ? null : await Geolocator.getLastKnownPosition();
    // An old last fix (yesterday, elsewhere) is not where the user is: then ask for a new one.
    final pos = last != null && DateTime.now().difference(last.timestamp) < lastFixMaxAge && _inAttica(last)
        ? last
        : await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)));
    // Outside Attica (an emulator's default, abroad) says nothing useful for this map.
    if (!_inAttica(pos)) return null;
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}

// One permission request at a time: the Android plugin keeps only the newest caller's callback, so the
// map and the planner asking together at start left the map waiting for ever.
Future<LocationPermission>? _asking;
Future<LocationPermission> _request() => _asking ??= Geolocator.requestPermission().whenComplete(() => _asking = null);

const lastFixMaxAge = Duration(minutes: 2);

bool _inAttica(Position p) => p.latitude >= 37.5 && p.latitude <= 38.5 && p.longitude >= 22.9 && p.longitude <= 24.5;

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

// A fresh fix only when the user already allowed location: never asks, for checks that run by
// themselves (is the user on a bus?).
Future<Pt?> quietPosition() async {
  try {
    final p = await Geolocator.checkPermission();
    if (p != LocationPermission.always && p != LocationPermission.whileInUse) return null;
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)));
    if (pos.latitude < 37.5 || pos.latitude > 38.5 || pos.longitude < 22.9 || pos.longitude > 24.5) return null;
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}
