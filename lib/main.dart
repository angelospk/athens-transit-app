import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background/service.dart';
import 'background/widget.dart';
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
  final prefs = await SharedPreferences.getInstance();
  final api = Api();
  final store = AppStore(prefs);
  final live = LiveHub(api)..watch(store.myLines);
  await AlertService.init(store, onOpen: (o) => openBus(api, o));
  live.addListener(() => pushWidget(store, live));
  store.addListener(() => pushWidget(store, live, force: true)); // a removed or reordered stop shows at once
  runApp(Deps(store: store, live: live, api: api, child: TransitApp(prefs: prefs, welcome: needsWelcome(prefs))));
}

// A tapped notification: its bus on the map, on the way to the alert's stop (back opens the stop).
Future<void> openBus(Api api, OpenBus o) async {
  var lines = [o.line];
  try {
    final all = linesAt(await api.trips(), o.stop, o.lat, o.lon);
    if (all.isNotEmpty) lines = all;
  } catch (_) {/* the stop opens with the alert's line only */}
  final at = o.busLat == null || o.busLon == null ? null : (o.busLat!, o.busLon!);
  showOnMap(BusSel(o.line, o.vehicleId, at: at, variant: o.variant, stop: StopRef(name: o.stop, lat: o.lat, lon: o.lon, lines: lines)));
}

class TransitApp extends StatelessWidget {
  const TransitApp({super.key, required this.prefs, required this.welcome});
  final SharedPreferences prefs;
  final bool welcome; // a new install: the welcome first, then the map

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
        home: welcome ? _Welcome(prefs) : const Shell(),
      ),
    );
  }
}

// The welcome, then the map. The map starts only after it, so it finds the location just allowed.
class _Welcome extends StatefulWidget {
  const _Welcome(this.prefs);
  final SharedPreferences prefs;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => _done
      ? const Shell()
      : WelcomeScreen(onDone: () {
          markWelcomed(widget.prefs);
          setState(() => _done = true);
        });
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
      AlertService.takeOpen((o) => openBus(d.api, o));
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
