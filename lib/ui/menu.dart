// The menu from the left (docs/DESIGN-home.md): every page that is not the map. Each opens over the
// map with a back arrow. «Διαδρομή» is here too: the planner had its own tab before.

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../background/widget.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../data/store.dart';
import 'map_sel.dart';
import 'planner_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text('Athens Transit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          item(Icons.directions, 'Διαδρομή', () => go('Διαδρομή', const PlannerScreen())),
          item(Icons.format_list_bulleted, 'Γραμμές', () => go('Γραμμές', const LinesScreen())),
          item(Icons.campaign_outlined, 'Ενημερώσεις', () => go('Ενημερώσεις', const _Updates())),
          item(Icons.notifications_outlined, 'Ειδοποιήσεις', () => go('Ειδοποιήσεις', const RulesScreen())),
          item(Icons.place_outlined, 'Μέρη', () => go('Μέρη', const PlacesScreen())),
          item(Icons.widgets_outlined, 'Widgets', () => go('Widgets', const _Widgets())),
          item(Icons.query_stats, 'Στατιστικά', () {
            Scaffold.of(context).closeDrawer();
            navKey.currentState?.push(MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'Στατιστικά'),
              builder: (_) => const StatsScreen(), // its own bar, with tabs
            ));
          }),
          item(Icons.settings_outlined, 'Ρυθμίσεις', () => go('Ρυθμίσεις', const SettingsScreen())),
          item(Icons.info_outline, 'Σχετικά', () => go('Σχετικά', const _About())),
        ]),
      ),
    );
  }
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
            child: TextButton(onPressed: () => setState(() => _all = Deps.of(context).api.lines()), child: const Text('Δεν φόρτωσαν. Ξανά')),
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
                hintText: 'Αριθμός ή όνομα γραμμής',
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
        child: Text('Εδώ θα βλέπεις τις ανακοινώσεις του ΟΑΣΑ: απεργίες, αλλαγές γραμμών. Έρχεται σύντομα.',
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
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        Widget row(String name, IconData icon, SavedPlace? p) => ListTile(
              leading: Icon(icon),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(p == null ? 'Πρόσθεσε διεύθυνση ή περιοχή' : '${p.label}${p.approx ? ' · περίπου' : ''}'),
              trailing: p == null
                  ? const Icon(Icons.add)
                  : IconButton(tooltip: 'Διαγραφή: $name', icon: const Icon(Icons.close), onPressed: () => store.removePlace(name)),
              onTap: () => askPlace(context, name),
            );
        return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          row(homeName, Icons.home_outlined, store.home),
          row(workName, Icons.work_outline, store.work),
          for (final p in store.places)
            if (p.name != homeName && p.name != workName) row(p.name, Icons.place_outlined, p),
          ListTile(leading: const Icon(Icons.add_location_alt_outlined), title: const Text('Άλλο μέρος'), onTap: () => _addOther(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Αρκεί μια περιοχή. Τα μέρη μένουν μόνο στο κινητό. Με «Σπίτι» βλέπεις πώς γυρνάς· με «Δουλειά», τα πρωινά, πώς πας.',
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
        title: const Text('Νέο μέρος'),
        content: TextField(controller: _c, autofocus: true, decoration: const InputDecoration(hintText: 'Όνομα, π.χ. Σχολείο')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Άκυρο')),
          TextButton(onPressed: () => Navigator.pop(context, _c.text.trim()), child: const Text('Επόμενο')),
        ],
      );
}

class _Widgets extends StatelessWidget {
  const _Widgets();
  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
      ListTile(
        leading: const Icon(Icons.widgets_outlined),
        title: const Text('«Η στάση μου»'),
        subtitle: const Text('Οι επόμενες αφίξεις στην αγαπημένη σου στάση.'),
        trailing: const Icon(Icons.add),
        onTap: () async {
          await pushWidget(d.store, d.live, force: true);
          await HomeWidget.requestPinWidget(androidName: 'StopWidgetProvider');
        },
      ),
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: const Text('«Γυρνάς σπίτι»'),
        subtitle: const Text('Τα τελευταία λεωφορεία για το σπίτι σήμερα. Γεμίζει όταν ανοίξεις την εφαρμογή μακριά από το σπίτι.'),
        trailing: const Icon(Icons.add),
        onTap: () => HomeWidget.requestPinWidget(androidName: 'HomeLastWidgetProvider'),
      ),
    ]);
  }
}

const _links = [
  ('Πρότεινε μια ιδέα', 'https://docs.google.com/forms/d/e/1FAIpQLSdBJSeu7xzH0ma5GWn7hIlcaaPPmOSTP9bD5D_NA-f1FhHyLQ/viewform', Icons.lightbulb_outline),
  ('Λάθος θέση στάσης; Πες μας', 'https://github.com/angelospk/athens-transit-map/issues/new', Icons.wrong_location_outlined),
  ('Σχετικά · δεδομένα · ανοιχτό API', 'https://angelospk.github.io/athens-transit-rt/', Icons.info_outline),
  ('Ο χάρτης στο web', 'https://bus.haroldpoi.dev', Icons.public),
];

class _About extends StatelessWidget {
  const _About();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), children: [
        for (final (label, url, icon) in _links)
          ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Δεδομένα: ΟΑΣΑ (GTFS, telematics) · Χάρτης: OpenFreeMap, © OpenStreetMap contributors',
              style: TextStyle(fontSize: 12, color: context.tones.muted)),
        ),
      ]);
}
