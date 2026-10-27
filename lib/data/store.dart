// What the user chose: saved stops (home, work), their lines, theme and alert rules. One JSON blob in
// shared_preferences; the background service reads the rules from it too.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/athens_time.dart';
import '../core/geo.dart';
import '../core/rules.dart';
import '../core/nearby.dart';

const maxLines = 5; // the contract's per-client cap on watched lines
const stateKey = 'state_v1';

enum Place { home, work }

class FavStop {
  const FavStop({required this.name, required this.lat, required this.lon, this.place, this.lines = const []});

  final String name;
  final double lat, lon;
  final Place? place;
  final List<String> lines; // the lines the user cares about here

  FavStop copyWith({Place? place, bool clearPlace = false, List<String>? lines}) =>
      FavStop(name: name, lat: lat, lon: lon, place: clearPlace ? null : place ?? this.place, lines: lines ?? this.lines);

  String get key => '$name|${lat.toStringAsFixed(4)}|${lon.toStringAsFixed(4)}';

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lon': lon, 'place': place?.name, 'lines': lines};
  factory FavStop.fromJson(Map<String, dynamic> j) => FavStop(
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        place: Place.values.where((p) => p.name == j['place']).firstOrNull,
        lines: [for (final l in j['lines'] as List? ?? const []) l as String],
      );
}

class AppStore extends ChangeNotifier {
  AppStore(this._prefs) {
    final raw = _prefs.getString(stateKey);
    if (raw != null) {
      try {
        _load(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {/* an unreadable state starts fresh */}
    }
  }

  final SharedPreferences _prefs;

  bool onboarded = false;
  List<FavStop> favs = [];
  List<String> myLines = [];
  Set<String> hiddenLines = {};
  bool onlyMine = false;
  ThemeMode theme = ThemeMode.system;
  List<Rule> rules = [];
  int walkMin = 4; // to the home stop, for "when to leave"
  bool showMetro = true, showTram = true; // tracks and stations on the map

  void _load(Map<String, dynamic> j) {
    onboarded = j['onboarded'] == true;
    favs = [for (final f in j['favs'] as List? ?? const []) FavStop.fromJson(f as Map<String, dynamic>)];
    myLines = [for (final l in j['myLines'] as List? ?? const []) l as String];
    hiddenLines = {for (final l in j['hidden'] as List? ?? const []) l as String};
    onlyMine = j['onlyMine'] == true;
    theme = ThemeMode.values.where((t) => t.name == j['theme']).firstOrNull ?? ThemeMode.system;
    rules = [for (final r in j['rules'] as List? ?? const []) Rule.fromJson(r as Map<String, dynamic>)];
    walkMin = j['walkMin'] as int? ?? 4;
    showMetro = j['showMetro'] != false;
    showTram = j['showTram'] != false;
  }

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'favs': [for (final f in favs) f.toJson()],
        'myLines': myLines,
        'hidden': hiddenLines.toList(),
        'onlyMine': onlyMine,
        'theme': theme.name,
        'rules': [for (final r in rules) r.toJson()],
        'walkMin': walkMin,
        'showMetro': showMetro,
        'showTram': showTram,
      };

  void _save() {
    _prefs.setString(stateKey, jsonEncode(toJson()));
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    _save();
  }

  bool isFav(String name, double lat, double lon) => favs.any((f) => f.name == name && distTo(f, lat, lon) < 200);

  FavStop? favNear(String name, double lat, double lon) =>
      favs.where((f) => f.name == name && distTo(f, lat, lon) < 200).firstOrNull;

  void addFav(FavStop f) {
    favs = [...favs.where((x) => x.key != f.key), f];
    for (final l in f.lines) {
      _addLine(l);
    }
    _save();
  }

  void removeFav(FavStop f) {
    favs = favs.where((x) => x.key != f.key).toList();
    _save();
  }

  void updateFav(FavStop f) {
    favs = [for (final x in favs) x.key == f.key ? f : (f.place != null && x.place == f.place ? x.copyWith(clearPlace: true) : x)];
    for (final l in f.lines) {
      _addLine(l);
    }
    _save();
  }

  void _addLine(String l) {
    if (!myLines.contains(l) && myLines.length < maxLines) myLines = sortLines([...myLines, l]);
  }

  // false when the cap is reached
  bool toggleMyLine(String l) {
    if (myLines.contains(l)) {
      myLines = myLines.where((x) => x != l).toList();
      favs = [for (final f in favs) f.copyWith(lines: f.lines.where((x) => x != l).toList())];
    } else {
      if (myLines.length >= maxLines) return false;
      _addLine(l);
    }
    _save();
    return true;
  }

  void toggleHidden(String l) {
    hiddenLines = hiddenLines.contains(l) ? ({...hiddenLines}..remove(l)) : {...hiddenLines, l};
    _save();
  }

  void setOnlyMine(bool v) {
    onlyMine = v;
    _save();
  }

  void setRail({bool? metro, bool? tram}) {
    showMetro = metro ?? showMetro;
    showTram = tram ?? showTram;
    _save();
  }

  void setTheme(ThemeMode t) {
    theme = t;
    _save();
  }

  void setWalkMin(int m) {
    walkMin = m.clamp(0, 30);
    _save();
  }

  void putRule(Rule r) {
    rules = rules.any((x) => x.id == r.id) ? [for (final x in rules) x.id == r.id ? r : x] : [...rules, r];
    _save();
  }

  void removeRule(String id) {
    rules = rules.where((r) => r.id != id).toList();
    _save();
  }

  // Morning (before 15:00, Athens) the home stop comes first, afternoon the work stop.
  List<FavStop> favsByTime(DateTime utc) {
    final first = athensWall(utc).hour < 15 ? Place.home : Place.work;
    int rank(FavStop f) => f.place == first ? 0 : f.place == null ? 1 : 2;
    return [...favs]..sort((a, b) => rank(a).compareTo(rank(b)));
  }
}

double distTo(FavStop f, double lat, double lon) => distM((f.lat, f.lon), (lat, lon));
