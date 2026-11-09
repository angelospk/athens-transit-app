// The first run: four short cards on what the app does, then the two permissions with a reason each.
// Only a new install sees it by itself; the menu's «Πώς δουλεύει» opens it again.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../background/service.dart';
import '../data/locate.dart';
import '../data/store.dart';
import 'theme.dart';

const welcomeKey = 'welcome_v1';

/// true: the app shows the welcome instead of the map (a new install, or after «Διαγραφή όλων»).
final showWelcome = ValueNotifier<bool>(false);

/// A new install: no saved state from before the welcome existed, and the welcome not finished yet.
bool needsWelcome(SharedPreferences p) => p.getBool(welcomeKey) != true && p.getString(stateKey) == null;

Future<void> markWelcomed(SharedPreferences p) => p.setBool(welcomeKey, true);

// A screenshot of the feature on each card (assets/welcome, from docs/store/screenshots/src), and the
// part of it to show: the map, or the sheet at the bottom.
const _cards = [
  ('home', Alignment.center, 'Καλώς ήρθες στις Στάσεις',
      'Κάθε λεωφορείο της Αθήνας στον χάρτη, ζωντανά. Το χρώμα του δείχνει αν αργεί σε σχέση με το πρόγραμμα.'),
  ('stop', Alignment.bottomCenter, 'Στάσεις και αγαπημένα',
      'Πάτα μια στάση για να δεις τι έρχεται και σε πόσα λεπτά. Με το αστέρι την κρατάς στα αγαπημένα.'),
  ('alert', Alignment.bottomCenter, 'Πες μου πότε να φύγω',
      'Πάτα το καμπανάκι δίπλα σε ένα λεωφορείο: σε ειδοποιώ λίγο πριν φτάσει. Ή φτιάξε κανόνα για κάθε πρωί.'),
  ('plan', Alignment.topCenter, 'Από εδώ ως εκεί',
      'Η «Διαδρομή» στο μενού βρίσκει πώς πας κάπου, με τις αλλαγές και τους χρόνους από τα λεωφορεία που κινούνται τώρα.'),
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onDone,
    this.askLocation = askLocationPermission,
    this.askNotifications = AlertService.askNotifications,
  });

  final VoidCallback onDone;
  final Future<bool> Function() askLocation, askNotifications; // true: allowed

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _at = 0;
  bool? _loc, _notes; // null: not asked yet

  static const _last = 4; // the permissions page

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) => _pages.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Scaffold(
      backgroundColor: t.ground,
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: _at < _last ? TextButton(onPressed: () => _go(_last), child: const Text('Παράλειψη')) : null,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _at = i),
              children: [
                for (final (shot, part, title, body) in _cards) _Card(shot: shot, part: part, title: title, body: body),
                _permissions(t),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(children: [
              for (var i = 0; i <= _last; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _at ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _at ? t.accent : t.rule, borderRadius: BorderRadius.circular(3)),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _at < _last ? () => _go(_at + 1) : widget.onDone,
                child: Text(_at < _last ? 'Επόμενο' : 'Ξεκίνα'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _permissions(Tones t) => ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
        const SizedBox(height: 24),
        const Text('Δύο άδειες', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Και οι δύο είναι προαιρετικές. Τις αλλάζεις όποτε θέλεις από τις ρυθμίσεις του κινητού.',
            style: TextStyle(fontSize: 15, height: 1.4, color: t.muted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: t.accent.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline, color: t.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Δεν κρατάμε τίποτα από σένα', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Χωρίς λογαριασμό, διαφημίσεις ή tracking. Η θέση σου, το σπίτι, η δουλειά και τα αγαπημένα μένουν μόνο στο κινητό σου.',
                    style: TextStyle(fontSize: 13.5, height: 1.35, color: t.muted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _Permission(
          key: const ValueKey('ask-location'),
          icon: Icons.my_location,
          title: 'Τοποθεσία',
          body: 'Για τις στάσεις κοντά σου και τον χρόνο περπατήματος. Η θέση μένει στο κινητό.',
          allowed: _loc,
          onAsk: () async {
            final ok = await widget.askLocation();
            if (mounted) setState(() => _loc = ok);
          },
        ),
        const SizedBox(height: 12),
        _Permission(
          key: const ValueKey('ask-notifications'),
          icon: Icons.notifications_outlined,
          title: 'Ειδοποιήσεις',
          body: 'Για να σου πω πότε να φύγεις και πότε φτάνει το λεωφορείο σου.',
          allowed: _notes,
          onAsk: () async {
            final ok = await widget.askNotifications();
            if (mounted) setState(() => _notes = ok);
          },
        ),
      ]);
}

class _Card extends StatelessWidget {
  const _Card({required this.shot, required this.part, required this.title, required this.body});
  final String shot, title, body;
  final Alignment part;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // A phone-shaped frame: as large as the screen allows above the text.
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: .62,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: t.rule, width: 1.5)),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/welcome/$shot.webp', fit: BoxFit.cover, alignment: part),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 10),
        Text(body, style: TextStyle(fontSize: 16, height: 1.45, color: t.muted)),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _Permission extends StatelessWidget {
  const _Permission({super.key, required this.icon, required this.title, required this.body, required this.allowed, required this.onAsk});
  final IconData icon;
  final String title, body;
  final bool? allowed;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: t.accent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(fontSize: 13.5, height: 1.35, color: t.muted)),
            const SizedBox(height: 10),
            switch (allowed) {
              true => Row(children: [
                  Icon(Icons.check_circle, size: 18, color: t.onTime),
                  const SizedBox(width: 6),
                  Text('Δόθηκε', style: TextStyle(fontWeight: FontWeight.w600, color: t.onTime)),
                ]),
              // Refused: another tap asks again, or opens the phone's settings when it no longer asks.
              false => OutlinedButton(onPressed: onAsk, child: const Text('Δεν δόθηκε · ξανά')),
              null => FilledButton.tonal(onPressed: onAsk, child: const Text('Επίτρεψε')),
            },
          ]),
        ),
      ]),
    );
  }
}
