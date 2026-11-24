// «Ρυθμίσεις» in the menu: theme, walking time to the home stop, live cards, how the map reads, and
// «Διαγραφή όλων των δεδομένων».

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../l10n/l10n.dart';
import 'help.dart';
import 'map_sel.dart';
import 'theme.dart';
import 'welcome.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final t = context.tones;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
          Text(l.settingsTheme, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.settingsThemeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.settingsThemeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.settingsThemeDark)),
              ],
              selected: {store.theme},
              onSelectionChanged: (s) => store.setTheme(s.first),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Text(l.settingsWalk, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(tooltip: l.commonLess, onPressed: () => store.setWalkMin(store.walkMin - 1), icon: const Icon(Icons.remove)),
            Text(l.minutesShort(store.walkMin), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(tooltip: l.commonMore, onPressed: () => store.setWalkMin(store.walkMin + 1), icon: const Icon(Icons.add)),
          ]),
          Text(l.settingsWalkNote, style: TextStyle(fontSize: 13, color: t.muted)),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_clock_outlined),
            title: Text(l.settingsLiveCard),
            subtitle: Text(l.settingsLiveCardBody),
            value: store.liveDefault,
            onChanged: store.setLiveDefault,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.nightlight_outlined),
            title: Text(l.settingsLastBus),
            subtitle: Text(l.settingsLastBusBody),
            value: store.lastBusNudge,
            // The store listener moves the alarm (AlertService.init). On: ask for notifications first.
            onChanged: (on) async {
              if (on && !await AlertService.ensurePermissions(context)) return;
              store.setLastBusNudge(on);
            },
          ),
          Divider(color: t.rule),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: Text(l.settingsMapHelp),
            subtitle: Text(l.settingsMapHelpBody),
            onTap: () => showMapHelp(context),
          ),
          Divider(color: t.rule),
          ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.error,
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(l.settingsDeleteAll),
            subtitle: Text(l.settingsDeleteAllBody),
            onTap: () => _deleteAll(context),
          ),
        ]),
      ),
    );
  }
}

// Asks first. Then: every saved choice, the rules and their alarms, our notifications and the saved
// network answers go, and the welcome opens as on a new install.
Future<void> _deleteAll(BuildContext context) async {
  final d = Deps.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(c.l10n.settingsDeleteAllTitle),
      content: Text(c.l10n.settingsDeleteAllWarning),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error, foregroundColor: Theme.of(c).colorScheme.onError),
          onPressed: () => Navigator.pop(c, true),
          child: Text(c.l10n.commonDelete),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await d.store.reset();
  try {
    await AlertService.forgetAll(d.store);
  } catch (_) {/* no notification plugins (tests): nothing runs */}
  await d.api.clearCache();
  navKey.currentState?.popUntil((r) => r.isFirst);
  showWelcome.value = true;
}
