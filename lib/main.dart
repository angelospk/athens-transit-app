import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background/service.dart';
import 'background/widget.dart';
import 'data/api.dart';
import 'data/live.dart';
import 'data/store.dart';
import 'ui/favs_screen.dart';
import 'ui/island_nav.dart';
import 'ui/map_screen.dart';
import 'ui/map_sel.dart';
import 'ui/onboard_screen.dart';
import 'ui/rules_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final api = Api();
  final store = AppStore(prefs);
  final live = LiveHub(api)..watch(store.myLines);
  await AlertService.init(store);
  live.addListener(() => pushWidget(store, live));
  store.addListener(() => pushWidget(store, live, force: true)); // a removed or reordered stop shows at once
  runApp(Deps(store: store, live: live, api: api, child: const TransitApp()));
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
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: store.theme,
        locale: const Locale('el'),
        supportedLocales: const [Locale('el'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: store.onboarded ? const Shell() : const OnboardScreen(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  static final tab = appTab;

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
    if (s == AppLifecycleState.resumed) AlertService.sync(d.store);
    if (s == AppLifecycleState.paused) pushWidget(d.store, d.live, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final live = Deps.of(context).live;
    return ListenableBuilder(
      listenable: Listenable.merge([Shell.tab, store]),
      builder: (context, _) {
        live.watch(store.myLines);
        return Scaffold(
          body: IndexedStack(index: Shell.tab.value, children: const [MapScreen(), FavsScreen(), RulesScreen(), SettingsScreen()]),
          bottomNavigationBar: IslandNav(
            index: Shell.tab.value,
            onTap: (i) => Shell.tab.value = i,
            items: const [
              IslandItem(Icons.map_outlined, 'Χάρτης'),
              IslandItem(Icons.star_outline, 'Στάσεις'),
              IslandItem(Icons.notifications_outlined, 'Ειδοποιήσεις'),
              IslandItem(Icons.menu, 'Περισσότερα'),
            ],
          ),
        );
      },
    );
  }
}
