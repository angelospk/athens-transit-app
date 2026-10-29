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
  runApp(Deps(store: store, live: live, api: api, child: const TransitApp()));
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
  const TransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Athens Transit',
        navigatorKey: navKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: store.theme,
        locale: const Locale('el'),
        supportedLocales: const [Locale('el'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Shell(), // no first-run screen: the map asks for location with a reason
      ),
    );
  }
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
