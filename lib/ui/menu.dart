// The menu from the left (docs/DESIGN-home.md): every page that is not the map. Each opens over the
// map with a back arrow. «Διαδρομή» is here too: the planner had its own tab before.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/city.dart';
import '../background/widget.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../data/store.dart';
import '../l10n/l10n.dart';
import 'map_sel.dart';
import 'planner_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'theme.dart';
import 'welcome.dart';
import 'widgets.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final city = store.city;
    final l = context.l10n;
    void go(String title, Widget page) {
      Scaffold.of(context).closeDrawer();
      openPage(title, page);
    }

    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
          minTileHeight: 52,
          leading: Icon(icon),
          title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          onTap: onTap,
        );

    return Drawer(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text(l.appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            minTileHeight: 52,
            leading: const Icon(Icons.location_city_outlined),
            title: Text(l.menuCity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(city.localName),
            onTap: () {
              Scaffold.of(context).closeDrawer();
              pickCity(context);
            },
          ),
          // What only Athens has (City flags): the planner, OASA's notices, stop alerts, the statistics.
          if (city.plan) item(Icons.directions, l.menuPlanner, () => go(l.menuPlanner, const PlannerScreen())),
          item(Icons.format_list_bulleted, l.menuLines, () => go(l.menuLines, const LinesScreen())),
          if (city == City.athens) item(Icons.campaign_outlined, l.menuUpdates, () => go(l.menuUpdates, const _Updates())),
          if (city.alerts) item(Icons.notifications_outlined, l.menuAlerts, () => go(l.menuAlerts, const RulesScreen())),
          item(Icons.place_outlined, l.menuPlaces, () => go(l.menuPlaces, const PlacesScreen())),
          // Home-screen widgets exist only on Android.
          // The widget shows Athens's saved stops (pushWidget), like the alerts.
          if (defaultTargetPlatform == TargetPlatform.android && city == City.athens)
            item(Icons.widgets_outlined, l.menuWidgets, () => go(l.menuWidgets, const _Widgets())),
          if (city.stats)
            item(Icons.query_stats, l.menuStats, () {
            Scaffold.of(context).closeDrawer();
            navKey.currentState?.push(MaterialPageRoute<void>(
              settings: RouteSettings(name: l.menuStats),
              builder: (_) => const StatsScreen(), // its own bar, with tabs
            ));
          }),
          item(Icons.settings_outlined, l.menuSettings, () => go(l.menuSettings, const SettingsScreen())),
          item(Icons.info_outline, l.menuAbout, () => go(l.menuAbout, const AboutScreen())),
          item(Icons.help_outline, l.menuHowItWorks, () {
            Scaffold.of(context).closeDrawer();
            navKey.currentState?.push(MaterialPageRoute<void>(
              settings: RouteSettings(name: l.menuHowItWorks),
              builder: (c) => WelcomeScreen(onDone: () => Navigator.pop(c)), // full screen, no bar
            ));
          }),
        ]),
      ),
    );
  }
}

/// «Πόλη»: the cities the app knows. A pick opens the map of that city (main.dart CityRoot).
Future<void> pickCity(BuildContext context) async {
  final store = Deps.of(context).store;
  final c = await showModalBottomSheet<City>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text(c.l10n.menuCity, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        ),
        for (final city in City.values)
          ListTile(
            leading: Icon(city == store.city ? Icons.radio_button_checked : Icons.radio_button_unchecked),
            title: Text(city.localName),
            subtitle: Text(city.rail
                ? '${city.localAgency} · ${c.l10n.commonMetro} · ${c.l10n.commonTram} · ${c.l10n.commonSuburban}'
                : '${city.localAgency} · ${c.l10n.menuCityBuses}'),
            onTap: () => Navigator.pop(c, city),
          ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (c != null && c != store.city) store.setCity(c);
}

// Every line, with a filter; a tap opens the line on the map.
class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});
  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  Future<List<LineInfo>>? _all;
  String _q = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _all ??= Deps.of(context).api.lines();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return FutureBuilder<List<LineInfo>>(
      future: _all,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: TextButton(onPressed: () => setState(() => _all = Deps.of(context).api.lines()), child: Text(context.l10n.menuLinesError)),
          );
        }
        final all = snap.data;
        if (all == null) return const Center(child: CircularProgressIndicator());
        final f = fold(_q.trim());
        final shown = f.isEmpty ? all : all.where((l) => fold(l.id).startsWith(f) || nameMatches(l.name, _q)).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (q) => setState(() => _q = q),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.menuLinesHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: t.rule),
              itemBuilder: (context, i) => ListTile(
                leading: LineBadge(shown[i].id),
                title: Text(shown[i].name, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => showOnMap(LineSel(shown[i].id)),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

// OASA announcements (strikes, changed routes) need the backend's /v2/alerts (rt#43): until then a
// note only.
class _Updates extends StatelessWidget {
  const _Updates();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(context.l10n.menuUpdatesSoon,
            style: TextStyle(fontSize: 15, height: 1.4, color: context.tones.muted)),
      );
}

/// «Μέρη»: Σπίτι, Δουλειά and any other named place. They stay on the phone.
class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  Future<void> _addOther(BuildContext context) async {
    final name = await showDialog<String>(context: context, builder: (_) => const _NewPlace());
    if (name == null || name.isEmpty || !context.mounted) return;
    await askPlace(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final t = context.tones;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // Σπίτι and Δουλειά are stored under their Greek names: shown in the app's language.
        String shown(String name) => name == homeName ? l.commonHome : name == workName ? l.commonWork : name;
        Widget row(String name, IconData icon, SavedPlace? p) => ListTile(
              leading: Icon(icon),
              title: Text(shown(name), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(p == null ? l.menuPlaceAdd : '${p.label}${p.approx ? ' · ${l.menuPlaceApprox}' : ''}'),
              trailing: p == null
                  ? const Icon(Icons.add)
                  : IconButton(tooltip: '${l.commonDelete}: ${shown(name)}', icon: const Icon(Icons.close), onPressed: () => store.removePlace(name)),
              onTap: () => askPlace(context, name),
            );
        return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          row(homeName, Icons.home_outlined, store.home),
          row(workName, Icons.work_outline, store.work),
          for (final p in store.places)
            if (p.name != homeName && p.name != workName) row(p.name, Icons.place_outlined, p),
          ListTile(leading: const Icon(Icons.add_location_alt_outlined), title: Text(l.menuOtherPlace), onTap: () => _addOther(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l.menuPlacesNote,
                style: TextStyle(fontSize: 13, color: t.muted)),
          ),
        ]);
      },
    );
  }
}

// The new place's name. The field's controller lives as long as the dialog, its closing animation too.
class _NewPlace extends StatefulWidget {
  const _NewPlace();
  @override
  State<_NewPlace> createState() => _NewPlaceState();
}

class _NewPlaceState extends State<_NewPlace> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.l10n.menuNewPlace),
        content: TextField(controller: _c, autofocus: true, decoration: InputDecoration(hintText: context.l10n.menuNewPlaceHint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, _c.text.trim()), child: Text(context.l10n.commonNext)),
        ],
      );
}

class _Widgets extends StatelessWidget {
  const _Widgets();
  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final l = context.l10n;
    return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
      ListTile(
        leading: const Icon(Icons.widgets_outlined),
        title: Text(l.menuWidgetStop),
        subtitle: Text(l.menuWidgetStopBody),
        trailing: const Icon(Icons.add),
        onTap: () async {
          await pushWidget(d.store, d.live, force: true);
          await HomeWidget.requestPinWidget(androidName: 'StopWidgetProvider');
        },
      ),
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: Text(l.menuWidgetHome),
        subtitle: Text(l.menuWidgetHomeBody),
        trailing: const Icon(Icons.add),
        onTap: () => HomeWidget.requestPinWidget(androidName: 'HomeLastWidgetProvider'),
      ),
    ]);
  }
}

List<(String, String, IconData)> _links(AppLocalizations l) => [
      (l.menuLinkIdea, 'https://docs.google.com/forms/d/e/1FAIpQLSdBJSeu7xzH0ma5GWn7hIlcaaPPmOSTP9bD5D_NA-f1FhHyLQ/viewform', Icons.lightbulb_outline),
      (l.menuLinkWrongStop, 'https://github.com/angelospk/athens-transit-map/issues/new', Icons.wrong_location_outlined),
      (l.menuLinkAbout, 'https://angelospk.github.io/staseis-rt/', Icons.info_outline),
      (l.menuLinkWeb, 'https://bus.haroldpoi.dev', Icons.public),
    ];

// The site's legal pages (athens-transit-map: staseis.gr).
const termsUrl = 'https://staseis.gr/terms/', privacyUrl = 'https://staseis.gr/privacy/';

/// «Σχετικά»: the version, links, the terms, the privacy policy and the open-source licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final l = context.l10n;
    Widget link(String label, String url, IconData icon) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        );
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final v = snap.data == null ? null : '${snap.data!.version} (${snap.data!.buildNumber})';
        return ListView(padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.appName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(v == null ? ' ' : l.menuVersion(v), style: TextStyle(fontSize: 14, color: t.muted)),
            ]),
          ),
          for (final (label, url, icon) in _links(l)) link(label, url, icon),
          Divider(color: t.rule),
          link(l.menuTerms, termsUrl, Icons.description_outlined),
          link(l.menuPrivacy, privacyUrl, Icons.lock_outline),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l.menuLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(context: context, applicationName: l.appName, applicationVersion: v),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                '${l.menuUnofficialNote}\n\n'
                '${l.menuDataSources}\n\n'
                '© 2026 Άγγελος Παπαμιχαήλ & Antonios Freris',
                style: TextStyle(fontSize: 12, color: t.muted)),
          ),
        ]);
      },
    );
  }
}
