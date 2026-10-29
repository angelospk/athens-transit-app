// The middle tab · Διαδρομή: from here (or a picked place) to a stop, area, shop or address. The
// planner (core/tp.dart, the web's planner) finds the bus lines with no change or one; each result
// shows walking, riding and, when leaving now, the next bus live at the stop to board, so "leave in N′"
// is real. With "Με μετρό" a metro or tram line between the two ends comes first. A result opens the
// trip step by step (route_screen.dart), with «Φύγε εγκαίρως», «Πού κατεβαίνω;» and «Ακολούθησέ με».

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/geo.dart';
import '../core/leave.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../core/route_steps.dart';
import '../core/trip.dart' as tp;
import '../data/live.dart' show nextArrivalsAt;
import '../data/locate.dart';
import '../data/store.dart';
import 'alert_sheet.dart';
import 'map_sel.dart';
import 'ride.dart';
import 'route_screen.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

// An end of the trip: its name and the points to walk from or to.
typedef _End = ({String label, List<Pt> pts});

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  _End? _from, _to;
  bool _locating = false, _metro = true, _failed = false;
  TimeOfDay? _at; // null: now
  TripIndex? _ix;
  Set<String>? _known;
  List<tp.MetroStation> _stations = [];

  @override
  void initState() {
    super.initState();
    planRequest.addListener(_request);
  }

  @override
  void dispose() {
    planRequest.removeListener(_request);
    super.dispose();
  }

  // Another screen asks for a trip (a run that did not start: «Άλλη επιλογή»).
  void _request() {
    final r = planRequest.value;
    if (r == null) return;
    planRequest.value = null;
    setState(() {
      if (r.from != null) _from = r.from;
      _to = r.to;
      _at = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ix == null) _init();
    _request(); // asked before this tab was first built
  }

  // Each part on its own: without the line list or the metro the buses still plan.
  Future<void> _init() async {
    final api = Deps.of(context).api;
    _failed = false;
    try {
      final ix = await api.trips();
      if (mounted) setState(() => _ix = ix);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
    try {
      final lines = await api.lines();
      if (mounted) setState(() => _known = {for (final l in lines) l.id});
    } catch (_) {
      /* every line of the index counts */
    }
    try {
      final m = await api.metro();
      if (mounted) {
        setState(
          () => _stations = [
            for (final s in m['stations'] as List)
              (
                name: s['name'] as String,
                lat: (s['lat'] as num).toDouble(),
                lon: (s['lon'] as num).toDouble(),
                lines: [for (final l in s['lines'] as List) l as String],
              ),
          ],
        );
      }
    } catch (_) {
      /* no metro suggestion */
    }
    if (mounted && _from == null) _here();
  }

  // At start: the position only if location is already allowed; the map asks for it, with a reason.
  Future<void> _here() async {
    setState(() => _locating = true);
    final p = await knownPosition();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (p != null) _from = (label: 'Η θέση μου', pts: [p]);
    });
  }

  Future<void> _pick(bool from) async {
    final got = await showModalBottomSheet<_End>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlacePicker(ix: _ix, stations: _stations, from: from),
    );
    if (got == null || !mounted) return;
    setState(() => from ? _from = got : _to = got);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final from = _from, to = _to, ix = _ix;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Container(
            decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _endTile(t, Icons.trip_origin, 'Από', from?.label ?? (_locating ? 'Βρίσκω τη θέση σου…' : 'Πού είσαι;'), () => _pick(true)),
                      Divider(height: 1, indent: 52, color: t.rule),
                      _endTile(t, Icons.place, 'Προς', to?.label ?? 'Πού πας; στάση, περιοχή, κατάστημα, διεύθυνση', () => _pick(false)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Αντιστροφή',
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () => setState(() {
                    final f = _from;
                    _from = _to;
                    _to = f;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(label: const Text('Τώρα'), selected: _at == null, onSelected: (_) => setState(() => _at = null)),
              ChoiceChip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(_at == null ? 'Αργότερα' : 'Φεύγω ${_at!.format(context)}'),
                selected: _at != null,
                onSelected: (_) async {
                  final got = await showTimePicker(context: context, initialTime: _at ?? TimeOfDay.now());
                  if (got != null && mounted) setState(() => _at = got);
                },
              ),
              FilterChip(
                avatar: const Icon(Icons.subway_outlined, size: 18),
                label: const Text('Με μετρό'),
                selected: _metro,
                showCheckmark: false,
                onSelected: (v) => setState(() => _metro = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (ix == null && !_failed)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (ix == null && _failed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Δεν φόρτωσαν οι γραμμές. Χρειάζεται σύνδεση την πρώτη φορά.', style: TextStyle(color: t.muted)),
                  TextButton(onPressed: _init, child: const Text('Δοκίμασε ξανά')),
                ],
              ),
            ),
          if (ix != null && from != null && to != null) ..._results(t, ix, from, to),
          if (ix != null && (from == null || to == null))
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                from == null
                    ? 'Διάλεξε από πού φεύγεις, ή δώσε άδεια θέσης: με αυτή υπολογίζω πόσο περπατάς ως τη στάση.'
                    : 'Διάλεξε πού πας. Βρίσκω λεωφορεία χωρίς αλλαγή ή με μία, και το μετρό όταν σε βολεύει.',
                style: TextStyle(color: t.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _endTile(Tones t, IconData icon, String label, String value, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: t.muted),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: t.muted)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // The planning runs once per question, not on every rebuild (the live cards rebuild often).
  Object? _planKey;
  late _Plan _plan;

  _Plan _planFor(TripIndex ix, _End from, _End to) {
    final key = (ix, from, to, _metro, _known, _stations);
    if (key == _planKey) return _plan;
    final direct = tp.findTrips(ix, from.pts, to.pts, tp.walkM, _known).take(5).toList();
    final changes = direct.length >= 3 ? const <tp.TripTransfer>[] : tp.findTransfers(ix, from.pts, to.pts, tp.walkM, _known);
    final metro = _metro && _stations.isNotEmpty ? tp.metroDirect(_stations, from.pts, to.pts, 900) : null;
    final combo = _metro && metro == null && _stations.isNotEmpty ? tp.busMetro(ix, _stations, from.pts, to.pts, known: _known) : null;
    _planKey = key;
    return _plan = (direct: direct, changes: changes, metro: metro, combo: combo);
  }

  List<Widget> _results(Tones t, TripIndex ix, _End from, _End to) {
    final (:direct, :changes, :metro, :combo) = _planFor(ix, from, to);
    final now = _at == null;
    if (direct.isEmpty && changes.isEmpty && metro == null && combo == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Δεν βρήκα λεωφορείο ως 500 μ. από τις δύο άκρες, ούτε με μία αλλαγή. Δοκίμασε μια κοντινή στάση ή το μετρό.',
            style: TextStyle(color: t.muted),
          ),
        ),
      ];
    }
    return [
      if (metro != null) _metroCard(t, metro),
      if (combo != null) _comboCard(t, ix, combo),
      if (direct.isNotEmpty) _head(t, 'Χωρίς αλλαγή'),
      for (final r in direct)
        _DirectCard(
          key: ValueKey('${r.line}|${from.label}|${to.label}'),
          ix: ix,
          trip: r,
          from: from.pts,
          live: now,
          onOpen: () => _open(directSteps(ix, r, from: from.pts, to: to.pts)),
        ),
      if (changes.isNotEmpty) _head(t, 'Με μία αλλαγή'),
      for (final c in changes) _changeCard(t, ix, c),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          now
              ? 'Χρόνοι: περπάτημα 4,5 χλμ/ώ, λεωφορείο 15 χλμ/ώ με τις στάσεις· η αναμονή είναι live από το GPS των λεωφορείων.'
              : 'Για αργότερα δεν ξέρω ποιο λεωφορείο θα έρθει: οι χρόνοι είναι χωρίς αναμονή.',
          style: TextStyle(fontSize: 12, color: t.muted),
        ),
      ),
    ];
  }

  Widget _head(Tones t, String s) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
    child: Text(
      s,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.muted),
    ),
  );

  Widget _metroCard(Tones t, ({String line, String from, String to, double walk}) m) => Card(
    elevation: 0,
    color: t.surface,
    margin: const EdgeInsets.only(top: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: ListTile(
      leading: Icon(m.line.startsWith('T') ? Icons.tram_outlined : Icons.subway_outlined),
      title: Text('${m.line.startsWith('T') ? 'Τραμ' : 'Μετρό'} ${m.line}: ${titleCase(m.from)} → ${titleCase(m.to)}'),
      subtitle: Text('Περπάτημα ${walkMinutes(m.walk)}′ συνολικά · τρένο κάθε λίγα λεπτά (πρόγραμμα, όχι live)'),
      onTap: () => _open(metroSteps(_stations, m, from: _from!.pts, to: _to!.pts)),
    ),
  );

  void _open(List<RouteStep> steps) {
    final ix = _ix, from = _from, to = _to;
    if (steps.isEmpty || ix == null || from == null || to == null) return;
    openRoute(context, ix: ix, steps: steps, fromLabel: from.label, toLabel: to.label, live: _at == null, stations: _stations);
  }

  // A bus and the metro: the bus leg as on the other cards, then (or before it) the metro.
  Widget _comboCard(Tones t, TripIndex ix, _Combo c) {
    final v = c.bus.variants.first;
    final board = ix.s[v.from];
    final metro = '${c.metroLine.startsWith('T') ? 'Τραμ' : 'Μετρό'} ${c.metroLine}: ${titleCase(c.station)} → ${titleCase(c.metroTo)}';
    final bus = '${c.bus.line}: ${titleCase(board.$1)} → ${titleCase(ix.s[v.to].$1)}';
    return Card(
      elevation: 0,
      color: t.surface,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(comboSteps(ix, _stations, c, from: _from!.pts, to: _to!.pts)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(c.busFirst ? Icons.directions_bus_outlined : Icons.subway_outlined, size: 20, color: t.muted),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 16, color: t.muted)),
              Icon(c.busFirst ? Icons.subway_outlined : Icons.directions_bus_outlined, size: 20, color: t.muted),
              const Spacer(),
              Text('~${c.min.round()}′', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(c.busFirst ? bus : metro, style: const TextStyle(fontSize: 15)),
            Text(c.busFirst ? metro : bus, style: const TextStyle(fontSize: 15)),
            Text('Μετρό με το πρόγραμμα (όχι live), αναμονή ~5′.', style: TextStyle(fontSize: 12, color: t.muted)),
          ]),
        ),
      ),
    );
  }

  Widget _changeCard(Tones t, TripIndex ix, tp.TripTransfer c) {
    final a = c.legs.first, b = c.legs.last;
    final board = ix.s[a.from], change = ix.s[b.from];
    return Card(
      elevation: 0,
      color: t.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(transferSteps(ix, c, from: _from!.pts, to: _to!.pts)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LineBadge(a.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 16, color: t.muted),
                  ),
                  LineBadge(b.line),
                  const Spacer(),
                  Text('~${c.min.round()}′', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ανεβαίνεις: ${titleCase(board.$1)} · αλλαγή: ${titleCase(change.$1)}${c.xfer > 30 ? ' (${c.xfer.round()} μ. με τα πόδια)' : ''}',
                style: TextStyle(fontSize: 13, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// One line with no change: walk, ride and, leaving now, the next bus at the stop to board (live).
class _DirectCard extends StatefulWidget {
  const _DirectCard({super.key, required this.ix, required this.trip, required this.from, required this.live, required this.onOpen});
  final TripIndex ix;
  final tp.TripLine trip;
  final List<Pt> from;
  final bool live;
  final VoidCallback onOpen;

  @override
  State<_DirectCard> createState() => _DirectCardState();
}

class _DirectCardState extends State<_DirectCard> {
  List<Arrival> _arrivals = [];
  int _at = 0; // when _arrivals were read (s): their ETAs count down from then
  bool _asked = false;
  Timer? _timer;
  int _gen = 0; // a reply for an earlier trip or start is dropped

  (String, double, double) get _board => widget.ix.s[widget.trip.variants.first.from];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.live && _timer == null) _start();
  }

  @override
  void didUpdateWidget(_DirectCard old) {
    super.didUpdateWidget(old);
    final same = old.live == widget.live && identical(old.from, widget.from) && old.trip.variants.first.id == widget.trip.variants.first.id;
    if (same) return;
    _timer?.cancel();
    _timer = null;
    _gen++;
    _arrivals = [];
    _asked = false;
    if (widget.live) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  // The buses of the shown variant coming to the boarding stop, from the citywide tiles around it.
  Future<void> _load() async {
    final live = Deps.of(context).live;
    final gen = _gen;
    try {
      final got = await nextArrivalsAt(live, widget.trip.line, widget.trip.variants.first.id, _board);
      if (mounted && gen == _gen) {
        setState(() {
          _arrivals = got;
          _at = live.nowS;
          _asked = true;
        });
      }
    } catch (_) {
      if (mounted && gen == _gen) setState(() => _asked = true); // no live: the estimate stays
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final r = widget.trip, v = r.variants.first;
    final (name, lat, lon) = _board;
    final off = widget.ix.s[v.to];
    final walk = walkMinutes(v.walk);
    final toStop = walkMinutes(widget.from.map((p) => distM(p, (lat, lon))).reduce(min));
    // The first bus there is still time to walk to, its ETA aged since it was read.
    final age = _arrivals.isEmpty ? 0 : max(0, Deps.of(context).live.nowS - _at);
    final next = _arrivals.map((a) => (a: a, eta: a.etaS - age)).where((x) => x.eta >= toStop * 60).firstOrNull;
    final leave = next == null ? null : leaveInMinutes(next.eta, toStop, 1);
    // Leaving now: the wait at the stop is what is left of the bus's ETA after walking there.
    final total = r.min + (next == null ? 0 : max(0, next.eta / 60 - toStop));
    return Card(
      elevation: 0,
      color: t.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LineBadge(r.line, big: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${v.stops} στάσεις · περπάτημα $walk′', style: TextStyle(fontSize: 13, color: t.muted)),
                  ),
                  Text('~${total.round()}′', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Ανεβαίνεις: ${titleCase(name)}', style: const TextStyle(fontSize: 15)),
              Text('Κατεβαίνεις: ${titleCase(off.$1)}', style: TextStyle(fontSize: 13, color: t.muted)),
              if (widget.live) ...[
                const SizedBox(height: 6),
                if (next == null)
                  Text(
                    _asked ? (_arrivals.isEmpty ? 'Κανένα λεωφορείο με GPS κοντά τώρα' : 'Δεν προλαβαίνεις αυτά που έρχονται τώρα') : '',
                    style: TextStyle(fontSize: 13, color: t.muted),
                  )
                else
                  Row(
                    children: [
                      Dot(delayNote(context, next.a.delayS)?.$2 ?? t.onTime),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Το επόμενο που προλαβαίνεις σε ${mins(next.eta)} (${clockIn(next.eta)})${leave == null
                              ? ''
                              : leave <= 0
                              ? ' · φύγε τώρα'
                              : ' · φύγε σε $leave′'}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: leave != null && leave <= 0 ? t.late : null),
                        ),
                      ),
                    ],
                  ),
                // Following the trip: an alert when to leave for the stop, then on the bus one before
                // the stop to get off at.
                Wrap(
                  spacing: 4,
                  children: [
                    if (next != null)
                      TextButton.icon(
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text('Φύγε εγκαίρως'),
                        onPressed: () => showAlertSheet(
                          context,
                          stop: StopRef(name: name, lat: lat, lon: lon, lines: linesAt(widget.ix, name, lat, lon)),
                          arrival: next.a,
                          leave: true,
                        ),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Πού κατεβαίνω;'),
                      onPressed: () => rideFromHere(context, line: r.line, variant: v.id, alight: off.$1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Where to: the user's place, stops and areas of the network, metro stations, and places from OSM.
/// «Πού είναι το σπίτι σου;»: an address or an area, or a point near the user's position snapped to a
/// grid (approxPoint). Saves it in the store as the place [name] of «Μέρη» and returns it; null when
/// the user backs out.
Future<SavedPlace?> askHome(BuildContext context) => askPlace(context, homeName);

Future<SavedPlace?> askPlace(BuildContext context, String name) async {
  final d = Deps.of(context);
  TripIndex? ix;
  try {
    ix = await d.api.trips();
  } catch (_) {/* offline: the address search still has the cached places */}
  if (!context.mounted) return null;
  final got = await showModalBottomSheet<_End>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PlacePicker(ix: ix, stations: const [], from: false, home: true, name: name),
  );
  if (got == null || got.pts.isEmpty) return null;
  final approx = got.label == _nearMe;
  final lat = got.pts.map((p) => p.$1).reduce((a, b) => a + b) / got.pts.length;
  final lon = got.pts.map((p) => p.$2).reduce((a, b) => a + b) / got.pts.length;
  // A point near home is named after the nearest stop, so «Σπίτι · κοντά σε Υμηττό» still reads later.
  final near = approx && ix != null ? nearbyStops(ix, (lat, lon), radiusM: 600, max: 1).firstOrNull : null;
  final label = !approx ? got.label : near == null ? 'κοντά στη θέση σου' : 'κοντά σε ${titleCase(near.name)}';
  final h = SavedPlace(name: name, label: label, lat: lat, lon: lon, approx: approx);
  d.store.putPlace(h);
  return h;
}

const _nearMe = 'Κοντά στη θέση μου (περίπου)';

class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.ix, required this.stations, required this.from, this.home = false, this.name = homeName});
  final TripIndex? ix;
  final List<tp.MetroStation> stations;
  final bool from;
  final bool home; // a place of «Μέρη»: an area is enough; the position is snapped, not exact
  final String name; // which place

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  final _c = TextEditingController();
  List<tp.Place> _all = [], _hits = [];
  List<({String name, String detail, double lat, double lon})> _osm = [];
  Timer? _wait;
  int _asked = 0;

  @override
  void initState() {
    super.initState();
    final ix = widget.ix;
    _all = [if (ix != null) ...tp.places(ix), ...tp.metroPlaces(widget.stations)];
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _search(String q) {
    final n = ++_asked;
    _wait?.cancel();
    setState(() {
      _hits = q.trim().length < 2 ? [] : tp.searchPlaces(_all, q, 6);
      _osm = [];
    });
    if (q.trim().length >= 3) {
      _wait = Timer(const Duration(milliseconds: 400), () async {
        try {
          final got = await Deps.of(context).api.places(q.trim());
          if (mounted && n == _asked) setState(() => _osm = got.take(5).toList());
        } catch (_) {
          /* offline: the network's own places still work */
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _c,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: widget.home
                      ? '${widget.name}: διεύθυνση ή περιοχή'
                      : widget.from
                          ? 'Από: στάση, περιοχή, διεύθυνση'
                          : 'Προς: στάση, περιοχή, κατάστημα, διεύθυνση',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (widget.home)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text('Αρκεί μια περιοχή κοντά. Ανώνυμο: μένει μόνο στο κινητό.', style: TextStyle(fontSize: 13, color: t.muted)),
                    ),
                  ListTile(
                    leading: const Icon(Icons.my_location),
                    title: Text(widget.home ? _nearMe : 'Η θέση μου'),
                    onTap: () async {
                      final p = await myPosition();
                      if (!context.mounted) return;
                      if (p == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Δεν βρήκα τη θέση σου. Άνοιξε την τοποθεσία ή διάλεξε ένα μέρος.')));
                        return;
                      }
                      Navigator.pop(context, widget.home ? (label: _nearMe, pts: [approxPoint(p)]) : (label: 'Η θέση μου', pts: [p]));
                    },
                  ),
                  for (final p in _hits)
                    ListTile(
                      leading: Icon(switch (p.kind) {
                        tp.PlaceKind.metro || tp.PlaceKind.metroAny => Icons.subway_outlined,
                        tp.PlaceKind.stop => Icons.directions_bus_outlined,
                        _ => Icons.location_city_outlined,
                      }),
                      title: Text(titleCase(p.label)),
                      subtitle: p.hint == null && p.lines.isEmpty
                          ? null
                          : Text(p.hint ?? p.lines.take(8).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, (label: titleCase(p.label), pts: p.pts)),
                    ),
                  for (final p in _osm)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(p.name),
                      subtitle: p.detail.isEmpty ? null : Text(p.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, (label: p.name, pts: [(p.lat, p.lon)])),
                    ),
                  if (_c.text.trim().length >= 2 && _hits.isEmpty && _osm.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ψάχνω…', style: TextStyle(color: t.muted)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Combo = ({tp.TripLine bus, String station, String metroLine, String metroTo, bool busFirst, double min});
typedef _Plan = ({
  List<tp.TripLine> direct,
  List<tp.TripTransfer> changes,
  ({String line, String from, String to, double walk})? metro,
  _Combo? combo,
});
