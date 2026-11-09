// «Λάθος θέση στάσης;» on this phone: a random device id (so reports from one phone count once) and the
// stops already reported. Both in shared_preferences: «Διαγραφή όλων» clears them.

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _devKey = 'stopfix.dev', _sentKey = 'stopfix.sent';

String deviceId(SharedPreferences p) {
  final old = p.getString(_devKey);
  if (old != null && RegExp(r'^[a-f0-9]{12}$').hasMatch(old)) return old;
  final r = Random.secure();
  final id = [for (var i = 0; i < 6; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  p.setString(_devKey, id);
  return id;
}

bool reported(SharedPreferences p, String stop) => (p.getStringList(_sentKey) ?? const []).contains(stop);

Future<void> markReported(SharedPreferences p, String stop) {
  final all = {...?p.getStringList(_sentKey), stop}.toList();
  return p.setStringList(_sentKey, all.length > 500 ? all.sublist(all.length - 500) : all);
}
