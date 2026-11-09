// The cities the app knows (as the web's cities.ts / cityBases.ts). Each city has its own backend, its
// own static files and its own stop index. Athens keeps the URLs it had; the others point elsewhere.
// The Athens-only features (metro/tram/rail, «Δημοτικά», the planner, stop alerts, the statistics) are
// hidden in the other cities, so their URLs stay in api.dart.

// `--dart-define=API_BASE=http://127.0.0.1:18095` points a debug build at a local backend (QA).
const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'https://transit.haroldpoi.dev');
const staticBase = 'https://angelospk.github.io/staseis-rt/static/v1';
const tripsUrl = 'https://bus.haroldpoi.dev/trips.json';

enum City {
  athens(
    id: 'athens',
    name: 'Αθήνα',
    agency: 'ΟΑΣΑ',
    inName: 'στην Αθήνα',
    centre: (37.9755, 23.7348),
    api: apiBase,
    static: staticBase,
    trips: tripsUrl,
    placesBox: '23.3,37.6,24.2,38.35',
    box: (s: 37.5, w: 22.9, n: 38.5, e: 24.5),
    rail: true,
    muni: true,
    plan: true,
    alerts: true,
    stats: true,
  ),
  thessaloniki(
    id: 'thessaloniki',
    name: 'Θεσσαλονίκη',
    agency: 'ΟΣΕΘ',
    inName: 'στη Θεσσαλονίκη',
    centre: (40.6325, 22.9409),
    api: 'https://transit-thess.haroldpoi.dev',
    static: 'https://transit-thess.haroldpoi.dev/static/v1',
    trips: 'https://staseis.gr/trips-thessaloniki.json',
    placesBox: '22.70,40.45,23.20,40.80',
    box: (s: 40.3, w: 22.6, n: 41.0, e: 23.4),
    rail: false,
    muni: false,
    plan: false,
    alerts: false,
    stats: false,
  );

  const City({
    required this.id,
    required this.name,
    required this.agency,
    required this.inName,
    required this.centre,
    required this.api,
    required this.static,
    required this.trips,
    required this.placesBox,
    required this.box,
    required this.rail,
    required this.muni,
    required this.plan,
    required this.alerts,
    required this.stats,
  });

  final String id, name, agency, inName;
  final (double, double) centre; // (lat, lon): where the map starts without a location
  final String api, static, trips; // backend, static files (GitHub Pages), stop index (trips.json)
  final String placesBox; // the search's bbox 'west,south,east,north' (Photon)
  final ({double s, double w, double n, double e}) box; // where its backend has vehicle tiles (web cities.ts)
  final bool rail, muni, plan, alerts, stats; // what only Athens has

  /// The city of a saved id; a city this version does not know is Athens.
  static City byId(String? id) => values.where((c) => c.id == id).firstOrNull ?? athens;
}
