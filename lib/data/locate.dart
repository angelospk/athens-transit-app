// The user's position in Attica, or null (no permission, location off, no fix within 10 s, or elsewhere).

import 'package:geolocator/geolocator.dart';

import '../core/geo.dart';

const athensCentre = (37.9755, 23.7348); // Syntagma

// fresh: a new fix, never the last known one (an old one may be far from here).
Future<Pt?> myPosition({bool fresh = false}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
    final last = fresh ? null : await Geolocator.getLastKnownPosition();
    final pos = last ?? await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)));
    // Outside Attica (an emulator's default, abroad) says nothing useful for this map.
    if (pos.latitude < 37.5 || pos.latitude > 38.5 || pos.longitude < 22.9 || pos.longitude > 24.5) return null;
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
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
    if (pos.latitude < 37.5 || pos.latitude > 38.5 || pos.longitude < 22.9 || pos.longitude > 24.5) return null;
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}
