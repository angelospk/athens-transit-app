// Screen 4 · Οι στάσεις μου: saved stops, ordered by the time of day (home in the morning, work in the
// afternoon), each with its lines' next arrivals.

import 'package:flutter/material.dart';

import '../core/athens_time.dart';
import '../core/nearby.dart';
import '../data/store.dart';
import 'map_sel.dart';
import 'onboard_screen.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class FavsScreen extends StatelessWidget {
  const FavsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    return ListenableBuilder(
      listenable: Listenable.merge([d.store, d.live]),
      builder: (context, _) {
        final now = DateTime.now().toUtc();
        final favs = d.store.favsByTime(now);
        final morning = athensWall(now).hour < 15;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardScreen(adding: true))),
            icon: const Icon(Icons.add),
            label: const Text('Στάση'),
          ),
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Text('Οι στάσεις μου', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Row(children: [
                  Dot(t.onTime),
                  const SizedBox(width: 6),
                  Text(morning ? 'Πρωί: πρώτα η στάση του σπιτιού' : 'Απόγευμα: πρώτα η στάση της δουλειάς', style: TextStyle(fontSize: 13, color: t.muted)),
                ]),
              ),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Καμία αποθηκευμένη στάση ακόμη. Πάτα «+ Στάση».', style: TextStyle(color: t.muted)),
                ),
              for (final f in favs) _FavCard(fav: f),
            ]),
          ),
        );
      },
    );
  }
}

class _FavCard extends StatelessWidget {
  const _FavCard({required this.fav});
  final FavStop fav;

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final groups = groupArrivals(d.live.arrivalsNear(fav.name, fav.lat, fav.lon, only: fav.lines));
    final quiet = fav.lines.where((l) => !groups.any((g) => g.$1.line == l));
    final place = switch (fav.place) { Place.home => 'Σπίτι', Place.work => 'Δουλειά', null => null };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () async {
            final ix = await d.api.trips();
            final all = linesAt(ix, fav.name, fav.lat, fav.lon);
            showOnMap(StopSel(StopRef(name: fav.name, lat: fav.lat, lon: fav.lon, lines: all.isEmpty ? fav.lines : all)));
          },
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titleCase(fav.name), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                if (place != null) Text(place, style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
            ),
            PopupMenuButton<String>(
              tooltip: 'Επιλογές',
              onSelected: (v) => switch (v) {
                'home' => d.store.updateFav(fav.copyWith(place: Place.home)),
                'work' => d.store.updateFav(fav.copyWith(place: Place.work)),
                'none' => d.store.updateFav(fav.copyWith(clearPlace: true)),
                _ => d.store.removeFav(fav),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'home', child: Text('Είναι το σπίτι')),
                PopupMenuItem(value: 'work', child: Text('Είναι η δουλειά')),
                PopupMenuItem(value: 'none', child: Text('Ούτε σπίτι ούτε δουλειά')),
                PopupMenuItem(value: 'remove', child: Text('Αφαίρεση')),
              ],
            ),
          ]),
        ),
        for (final (first, then) in groups)
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.rule))),
            child: Padding(padding: const EdgeInsets.only(right: 8), child: ArrivalRow(first: first, then: then, big: true, estimate: d.live.isOffline)),
          ),
        if (quiet.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
            child: Text('Χωρίς λεωφορείο με GPS τώρα: ${quiet.join(', ')}', style: TextStyle(fontSize: 13, color: t.muted)),
          ),
      ]),
    );
  }
}
