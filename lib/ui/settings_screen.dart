// Screen 6 · Περισσότερα: theme, walking time to the home stop, live cards, how the map reads, network
// statistics, links (ideas, wrong stop, API).

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../background/widget.dart';
import 'help.dart';
import 'stats_screen.dart';
import 'theme.dart';
import 'widgets.dart';

const _links = [
  ('Πρότεινε μια ιδέα', 'https://docs.google.com/forms/d/e/1FAIpQLSdBJSeu7xzH0ma5GWn7hIlcaaPPmOSTP9bD5D_NA-f1FhHyLQ/viewform', Icons.lightbulb_outline),
  ('Λάθος θέση στάσης; Πες μας', 'https://github.com/angelospk/athens-transit-map/issues/new', Icons.wrong_location_outlined),
  ('Σχετικά · δεδομένα · ανοιχτό API', 'https://angelospk.github.io/athens-transit-rt/', Icons.info_outline),
  ('Ο χάρτης στο web', 'https://bus.haroldpoi.dev', Icons.public),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final t = context.tones;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
          Text('Περισσότερα', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28)),
          const SizedBox(height: 20),
          const Text('Θέμα', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Σύστημα')),
                ButtonSegment(value: ThemeMode.light, label: Text('Ανοιχτό')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Σκούρο')),
              ],
              selected: {store.theme},
              onSelectionChanged: (s) => store.setTheme(s.first),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Text('Περπάτημα ως τη στάση του σπιτιού', style: TextStyle(fontWeight: FontWeight.w600))),
            IconButton(tooltip: 'Λιγότερο', onPressed: () => store.setWalkMin(store.walkMin - 1), icon: const Icon(Icons.remove)),
            Text('${store.walkMin}′', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(tooltip: 'Περισσότερο', onPressed: () => store.setWalkMin(store.walkMin + 1), icon: const Icon(Icons.add)),
          ]),
          Text('Για τον κανόνα «πότε να φύγω».', style: TextStyle(fontSize: 13, color: t.muted)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.widgets_outlined),
            title: const Text('Widget «Η στάση μου» στην αρχική οθόνη'),
            onTap: () async {
              await pushWidget(store, Deps.of(context).live, force: true);
              await HomeWidget.requestPinWidget(androidName: 'StopWidgetProvider');
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_clock_outlined),
            title: const Text('Live κάρτα στις νέες ειδοποιήσεις'),
            subtitle: const Text('Η πορεία του λεωφορείου στην οθόνη κλειδώματος. Αλλάζει και σε κάθε ειδοποίηση.'),
            value: store.liveDefault,
            onChanged: store.setLiveDefault,
          ),
          Divider(color: t.rule),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text('Πώς διαβάζεται ο χάρτης'),
            subtitle: const Text('Χρώματα, σύμβολα, από πού έρχονται οι χρόνοι'),
            onTap: () => showMapHelp(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.query_stats),
            title: const Text('Στατιστικά δικτύου'),
            subtitle: const Text('Χθες: δρομολόγια που έγιναν, οι πιο αργές γραμμές'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StatsScreen())),
          ),
          Divider(color: t.rule),
          for (final (label, url, icon) in _links)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          const SizedBox(height: 12),
          Text('Δεδομένα: ΟΑΣΑ (GTFS, telematics) · Χάρτης: OpenFreeMap, © OpenStreetMap contributors',
              style: TextStyle(fontSize: 12, color: t.muted)),
        ]),
      ),
    );
  }
}
