import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background/service.dart';
import 'background/widget.dart';
import 'core/city.dart';
import 'core/names.dart';
import 'core/nearby.dart';
import 'data/api.dart';
import 'data/live.dart';
import 'data/store.dart';
import 'ui/map_screen.dart';
import 'ui/map_sel.dart';
import 'ui/menu.dart';
import 'ui/stop_screen.dart';
import 'ui/theme.dart';
import 'ui/welcome.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAccents(); // stop and line names with their accents from the first frame
  final prefs = await SharedPreferences.getInstance();
  final store = AppStore(prefs, city: cityOf(prefs));
  await AlertService.init(store, onOpen: (o) => openBus(store, o));
  showWelcome.value = needsWelcome(prefs);
  runApp(CityRoot(store: store, prefs: prefs));
}

// Alerts and their notifications are of Athens (City.alerts), whatever city is open.
final athensApi = Api();

// One Api and LiveHub per city. A switch builds new ones, closes the pages and the sheet, and the map
// starts again in the new city (TransitApp keys its home by the city).
class CityRoot extends StatefulWidget {
  const CityRoot({super.key, required this.store, required this.prefs});
  final AppStore store;
  final SharedPreferences prefs;

  @override
  State<CityRoot> createState() => _CityRootState();
}

class _CityRootState extends State<CityRoot> {
  late City _city = widget.store.city;
  late Api _api = _apiFor(_city);
  late LiveHub _live = _hub(_api);

  Api _apiFor(City c) => c == City.athens ? athensApi : Api(city: c);

  LiveHub _hub(Api api) {
    final store = widget.store;
    final live = LiveHub(api)..watch(store.myLines);
    live.addListener(() => pushWidget(store, live));
    return live;
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _live.dispose();
    super.dispose();
  }

  void _onStore() {
    final store = widget.store;
    if (store.city != _city) {
      final old = _live;
      _city = store.city;
      _api = _apiFor(_city);
      _live = _hub(_api);
      mapSel.value = null;
      homeTab.value = 0;
      navKey.currentState?.popUntil((r) => r.isFirst);
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose()); // after the old map let go of it
    }
    pushWidget(store, _live, force: true); // a removed or reordered stop shows at once
  }

  @override
  Widget build(BuildContext context) => Deps(store: widget.store, live: _live, api: _api, child: TransitApp(prefs: widget.prefs));
}

// A tapped notification: its bus on the map, on the way to the alert's stop (back opens the stop).
// From another city it opens Athens first.
Future<void> openBus(AppStore store, OpenBus o) async {
  if (store.city != City.athens) {
    store.setCity(City.athens);
    await WidgetsBinding.instance.endOfFrame;
  }
  final api = athensApi;
  var lines = [o.line];
  try {
    final all = linesAt(await api.trips(), o.stop, o.lat, o.lon);
    if (all.isNotEmpty) lines = all;
  } catch (_) {/* the stop opens with the alert's line only */}
  final at = o.busLat == null || o.busLon == null ? null : (o.busLat!, o.busLon!);
  showOnMap(BusSel(o.line, o.vehicleId, at: at, variant: o.variant, stop: StopRef(name: o.stop, lat: o.lat, lon: o.lon, lines: lines)));
}

class TransitApp extends StatelessWidget {
  const TransitApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Στάσεις',
        navigatorKey: navKey,
        navigatorObservers: [pageLog],
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: store.theme,
        locale: const Locale('el'),
        supportedLocales: const [Locale('el'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: _Start(prefs, key: ValueKey(store.city)), // a new city: a new map
      ),
    );
  }
}

// The welcome, then the map (showWelcome). The map starts only after it, so it finds the location
// just allowed. «Διαγραφή όλων» brings the welcome back.
class _Start extends StatelessWidget {
  const _Start(this.prefs, {super.key});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: showWelcome,
        builder: (context, welcome, _) => welcome
            ? WelcomeScreen(onDone: () {
                markWelcomed(prefs);
                showWelcome.value = false;
              })
            : const Shell(),
      );
}

// One screen (docs/DESIGN-home.md): the map with its sheet, and the menu from the left. No bottom bar.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final d = Deps.of(context);
    d.live.pause(s != AppLifecycleState.resumed);
    if (s == AppLifecycleState.resumed) {
      AlertService.sync(d.store);
      AlertService.syncNudge(d.store); // iOS sets the evening alarms ahead: renew them
      AlertService.takeOpen((o) => openBus(d.store, o));
    }
    if (s == AppLifecycleState.paused) pushWidget(d.store, d.live, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final live = Deps.of(context).live;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        live.watch(store.myLines);
        // Back walks back through the sheet (MapScreen); from the home sheet it leaves the app.
        return const Scaffold(drawer: AppMenu(), body: MapScreen());
      },
    );
  }
}
