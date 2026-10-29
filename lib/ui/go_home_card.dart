// The home sheet's smart card (docs/DESIGN-home.md), one at a time (core/home_sheet.dart pickSmart):
// «Πάμε δουλειά» on a weekday morning at home, «Γυρνάς σπίτι» away from home, else the next bus of a
// favourite stop; without «Σπίτι» and favourites it asks where home is. The trip cards show the next
// bus there is time to walk to; «Γυρνάς σπίτι» also the last runs home today, the first to go on top.
// A tap plans the trip.

import 'dart:async';

import 'package:flutter/material.dart';

import '../background/widget.dart' show clearHomeWidget, pushHomeWidget;
import '../core/eta.dart';
import '../core/geo.dart';
import '../core/go_home.dart';
import '../core/home_sheet.dart';
import '../core/leave.dart';
import '../core/models.dart';
import '../data/live.dart' show nextArrivalsAt;
import 'alert_sheet.dart' show dayClock;
import 'map_sel.dart';
import 'planner_screen.dart' show askHome;
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

const _lastSoonS = 30 * 60; // the first last run within this: the warning colour

class SmartCard extends StatefulWidget {
  const SmartCard({super.key, required this.me, required this.ix});
  final Pt? me;
  final TripIndex? ix;

  @override
  State<SmartCard> createState() => _SmartCardState();
}

class _SmartCardState extends State<SmartCard> {
  Timer? _clock; // the card changes at 06:00 and 10:00 even when nothing else redraws the sheet

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me, ix = widget.ix;
    final store = Deps.of(context).store;
    final home = store.homePt, work = store.workPt;
    final kind = pickSmart(utc: DateTime.now().toUtc(), me: me, home: home, work: work, hasFav: store.favs.any((f) => f.lines.isNotEmpty));
    return switch (kind) {
      Smart.toWork => TripCard(key: const ValueKey('work'), me: me!, ix: ix, to: work!, home: false),
      Smart.goHome => TripCard(key: const ValueKey('home'), me: me!, ix: ix, to: home!, home: true),
      Smart.askHome => SmartShell(
          onTap: () => askHome(context),
          kicker: 'ΓΥΡΝΑΣ ΣΠΙΤΙ',
          title: 'Πού είναι το σπίτι σου;',
          lines: const ['Αρκεί μια περιοχή. Ανώνυμο: μένει μόνο στο κινητό.'],
        ),
      Smart.nextFav => const _NextFav(),
      Smart.none => const SizedBox.shrink(),
    };
  }
}

// The next bus of the saved stop for this time of day (home in the morning, work in the afternoon).
class _NextFav extends StatelessWidget {
  const _NextFav();

  // Its own listener: a const card is not rebuilt with the sheet when new arrivals come.
  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    return ListenableBuilder(listenable: d.live, builder: (context, _) => _card(d));
  }

  Widget _card(Deps d) {
    final fav = d.store.favsByTime(DateTime.now().toUtc()).where((f) => f.lines.isNotEmpty).first;
    final a = d.live.arrivalsNear(fav.name, fav.lat, fav.lon, only: fav.lines).firstOrNull;
    return SmartShell(
      onTap: () => mapSel.value = StopSel(StopRef(name: fav.name, lat: fav.lat, lon: fav.lon, lines: fav.lines)),
      kicker: 'ΑΠΟ ${titleCase(fav.name).toUpperCase()}',
      title: a == null ? 'Κανένα από ${fav.lines.join(', ')} δεν έρχεται τώρα' : 'Το ${a.line} → ${titleCase(a.headsign)}',
      minutes: a == null ? null : '${d.live.isOffline ? '~' : ''}${mins(a.etaS)}',
    );
  }
}

/// The card's frame: a small kicker, a title, lines under it, and the minutes large on the right.
class SmartShell extends StatelessWidget {
  const SmartShell({super.key, required this.onTap, required this.kicker, required this.title, this.lines = const [], this.minutesLabel, this.minutes, this.foot});
  final VoidCallback onTap;
  final String kicker, title;
  final List<String> lines;
  final String? minutesLabel, minutes;
  final Widget? foot;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Material(
        color: t.ground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: t.outline)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kicker, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, letterSpacing: .3, fontWeight: FontWeight.w600, color: t.accent)),
                  const SizedBox(height: 2),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  for (final l in lines)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(l, style: TextStyle(fontSize: 12.5, color: t.muted))),
                  ?foot,
                ]),
              ),
              if (minutes != null) ...[
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (minutesLabel != null) Text(minutesLabel!, style: TextStyle(fontSize: 11, color: t.muted)),
                  Text(minutes!, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: t.accent, height: 1.1)),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// «Γυρνάς σπίτι» ([home]) or «Πάμε δουλειά»: the next bus to [to] there is time to walk to; home also
/// the last runs today, and the home widget gets them.
class TripCard extends StatefulWidget {
  const TripCard({super.key, required this.me, required this.ix, required this.to, required this.home});
  final Pt me, to;
  final TripIndex? ix;
  final bool home;

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  Object? _key; // what the ways home were found for: the position (to ~100 m), home and the index
  List<HomeBoard> _boards = [];
  List<HomeLast> _last = [];
  ({HomeBoard b, Arrival a, int leaveS})? _next;
  int _asked = 0; // the newest next-bus poll: an older, slower one must not overwrite it
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Every 5′ the timetables again (cached): one that failed offline comes back.
    _timer = Timer.periodic(const Duration(seconds: 30), (t) {
      if (_last.isEmpty || t.tick % 10 == 0) _loadLast();
      _loadNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh(Pt home) {
    final ix = widget.ix;
    if (ix == null) return;
    // A new timetable day (04:00) finds the ways and their last runs again.
    final key = ((widget.me.$1 * 1000).round(), (widget.me.$2 * 1000).round(), home, ix, serviceDay(DateTime.now().toUtc()));
    if (key == _key) return;
    _key = key;
    _boards = homeBoards(ix, widget.me, home);
    _last = [];
    _next = null;
    if (_boards.isEmpty && widget.home) clearHomeWidget();
    _loadLast();
    _loadNext();
  }

  Future<void> _loadLast() async {
    if (!widget.home) return; // to work: the next bus only
    final d = Deps.of(context);
    final boards = _boards;
    final lines = {for (final b in boards) b.line};
    try {
      await d.live.loadStatics(lines);
      final got = await Future.wait(lines.map(d.api.cachedSchedule));
      final sched = <String, Map<String, dynamic>>{
        for (final (k, l) in lines.indexed) l: ?got[k],
      };
      if (!mounted || !identical(boards, _boards)) return;
      setState(() => _last = lastHome(boards, sched, d.live.statics));
      if (_last.isNotEmpty) pushHomeWidget(d.store, _last, from: boards.first.stop);
    } catch (_) {/* offline: the card shows the next bus only */}
  }

  // The first bus of any way home that the user can still walk to its stop for.
  Future<void> _loadNext() async {
    if (!mounted || _boards.isEmpty) return;
    final d = Deps.of(context);
    final boards = _boards;
    final n = ++_asked;
    try {
      await d.live.loadStatics({for (final b in boards) b.line});
      ({HomeBoard b, Arrival a, int leaveS})? best;
      for (final b in boards) {
        final walkS = walkMinutes(distM(widget.me, b.at)) * 60;
        for (final a in await nextArrivalsAt(d.live, b.line, b.variant, (b.stop, b.at.$1, b.at.$2))) {
          if (a.etaS < walkS) continue;
          if (best == null || a.etaS - walkS < best.leaveS) best = (b: b, a: a, leaveS: a.etaS - walkS);
          break;
        }
      }
      if (mounted && n == _asked && identical(boards, _boards)) setState(() => _next = best);
    } catch (_) {/* offline */}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    _refresh(widget.to);
    final nowS = serviceNowS(DateTime.now().toUtc());
    final last = _last.where((x) => x.atS > nowS).take(3).toList();
    final soon = last.isNotEmpty && last.first.atS - nowS <= _lastSoonS;
    final n = _next;
    final title = n != null
        ? 'Με το ${n.b.line} από ${titleCase(n.b.stop)}'
        : _boards.isEmpty
            ? (widget.ix == null ? 'Ψάχνω…' : 'Χωρίς απευθείας λεωφορείο')
            : 'Με το ${_boards.first.line} από ${titleCase(_boards.first.stop)}';
    return SmartShell(
      onTap: () => showPlanner(from: (label: 'Η θέση μου', pts: [widget.me]), to: (label: widget.home ? 'Σπίτι' : 'Δουλειά', pts: [widget.to])),
      kicker: widget.home ? 'ΓΥΡΝΑΣ ΣΠΙΤΙ' : 'ΠΑΜΕ ΔΟΥΛΕΙΑ',
      title: title,
      lines: [
        if (n != null) 'περνά σε ${mins(n.a.etaS)}',
        if (_boards.isEmpty && widget.ix != null) 'Πάτα για διαδρομή με αλλαγή ή μετρό.',
        if (n == null && _boards.isNotEmpty) 'Δεν βλέπω λεωφορείο να έρχεται τώρα.',
      ],
      minutesLabel: n == null ? null : 'φύγε σε',
      minutes: n == null ? null : (n.leaveS < 60 ? 'τώρα' : '${(n.leaveS / 60).floor()}′'),
      foot: last.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${last.length == 1 ? 'τελευταίο' : 'τελευταία'}: ${last.map((x) => '${x.line} στις ${dayClock(x.atS)}').join(' · ')}',
                style: TextStyle(fontSize: 12.5, fontWeight: soon ? FontWeight.w700 : FontWeight.w400, color: soon ? t.late : t.muted),
              ),
            ),
    );
  }
}
