// «Ρυθμίσεις» in the menu: theme, walking time to the home stop, live cards, how the map reads.

import 'package:flutter/material.dart';

import 'help.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final t = context.tones;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_clock_outlined),
            title: const Text('Live κάρτα στις νέες ειδοποιήσεις'),
            subtitle: const Text('Η πορεία του λεωφορείου στην οθόνη κλειδώματος. Αλλάζει και σε κάθε ειδοποίηση.'),
            value: store.liveDefault,
            onChanged: store.setLiveDefault,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.nightlight_outlined),
            title: const Text('Παρασκευή και Σάββατο βράδυ: το τελευταίο για το σπίτι'),
            subtitle: const Text('Στις 21:00 μια ειδοποίηση με το τελευταίο λεωφορείο της στάσης «Σπίτι»'),
            value: store.lastBusNudge,
            onChanged: store.setLastBusNudge, // the store listener moves the alarm (AlertService.init)
          ),
          Divider(color: t.rule),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text('Πώς διαβάζεται ο χάρτης'),
            subtitle: const Text('Χρώματα, σύμβολα, από πού έρχονται οι χρόνοι'),
            onTap: () => showMapHelp(context),
          ),
        ]),
      ),
    );
  }
}
