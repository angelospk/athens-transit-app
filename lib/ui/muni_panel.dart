// «Δημοτικά» on the map's sheet: a municipal line, or a stop of one. The times are the municipality's
// timetable, timed at a terminus (`at`), never at each stop: a row says where a time leaves from, and the
// sheet says the times are scheduled, not live.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/muni.dart';
import '../data/api.dart';
import 'map_sel.dart';
import 'theme.dart';
import 'widgets.dart';

const muniHex = '#8C7FA6'; // as the web's municipal pill and routes
const _muniColor = Color(0xFF8C7FA6);

class MuniBadge extends StatelessWidget {
  const MuniBadge(this.ref, {super.key});
  final String? ref;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(color: _muniColor, borderRadius: BorderRadius.circular(8)),
        child: Text(ref ?? 'Δ',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      );
}

/// «08:50 · 10:50 από Πολύδροσο», «≈ 08:40 · 09:00» for a frequency.
String muniTimesText(({String? at, bool approx, List<String> times}) d) =>
    '${d.approx ? '≈ ' : ''}${d.times.join(' · ')}${d.at == null ? '' : ' από ${d.at}'}';

/// The next departures of a card's timetable lines, now in Athens; with two refs each row names its own.
List<String> muniNextRows(MuniCard c, MuniClock clock, {int n = 3}) => [
      for (final l in c.lines)
        for (final d in nextByStop(l, clock, n: n))
          '${c.lines.length > 1 && l.ref != null ? '${l.ref}: ' : ''}${muniTimesText(d)}',
    ];

String _date(String ymd) => ymd.split('-').reversed.map(int.parse).join('/');

// The shared state of both panels: the municipal data, and a clock that moves the next times on.
mixin _MuniLoad<T extends StatefulWidget> on State<T> {
  MuniData? muni;
  bool loaded = false;
  Timer? _tick;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tick != null) return;
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
    Deps.of(context).api.muni().then((m) => muni = m, onError: (_) => null).whenComplete(() {
      if (mounted) setState(() => loaded = true);
    }).ignore();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  MuniClock get clock => muniClock(DateTime.now().toUtc());
}

// Back and close on one row, the title under them at full width: a municipal name is long.
Widget _head(BuildContext context, String kind, Widget title) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const BackSel(),
        const Spacer(),
        const CloseSel(),
      ]),
      Text(kind, style: TextStyle(fontSize: 13, color: context.tones.muted, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      title,
    ]);

Widget _scheduled(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(children: [
        Icon(Icons.schedule, size: 16, color: context.tones.muted),
        const SizedBox(width: 6),
        Text('Προγραμματισμένα · όχι live', style: TextStyle(fontSize: 13, color: context.tones.muted)),
      ]),
    );

Widget _note(BuildContext context, String text) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(text, style: TextStyle(fontSize: 13, color: context.tones.muted)));

Widget _link(String label, String url) => Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Text('$label ›'),
      ),
    );

class MuniPanel extends StatefulWidget {
  const MuniPanel({super.key, required this.card, required this.scroll});
  final MuniCard card;
  final ScrollController scroll;

  @override
  State<MuniPanel> createState() => _MuniPanelState();
}

class _MuniPanelState extends State<MuniPanel> with _MuniLoad {
  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final table = c.table;
    final rows = muniNextRows(c, clock);
    final page = c.routes.map((r) => r.timetableUrl).nonNulls.firstOrNull;
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SheetHandle(),
        _head(
          context,
          'Δημοτική γραμμή · ${c.municipality}',
          Row(children: [
            MuniBadge(c.ref),
            const SizedBox(width: 10),
            Expanded(child: Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
          ]),
        ),
        _scheduled(context),
        if (table == null) ...[
          _note(context, 'Δεν έχουμε ελεγμένο ωράριο για αυτή τη γραμμή.'),
          if (page != null) _link('Ωράριο του δήμου', page),
        ] else ...[
          const SizedBox(height: 8),
          const Text('Επόμενες αναχωρήσεις', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (rows.isEmpty) _note(context, 'Κανένα άλλο δρομολόγιο σήμερα, κατά το ωράριο.'),
          for (final r in rows)
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(r, style: const TextStyle(fontSize: 16))),
          if (rows.any((r) => r.contains('≈'))) _note(context, '≈: ο δήμος δίνει συχνότητα, όχι ακριβείς ώρες.'),
          for (final l in c.lines)
            if (l.note != null) _note(context, l.note!),
          const SizedBox(height: 8),
          _note(context, 'Ωράριο: ${table.municipality}, ελέγχθηκε ${_date(table.checked)}.'),
          _link('Σελίδα του δήμου', table.source),
        ],
        const SizedBox(height: 8),
        Text('Διαδρομή και στάσεις: ${muni?.data.attribution ?? '© OpenStreetMap contributors (ODbL)'}',
            style: TextStyle(fontSize: 11, color: context.tones.muted)),
      ],
    );
  }
}

class MuniStopPanel extends StatefulWidget {
  const MuniStopPanel({super.key, required this.id, required this.stop, required this.scroll});
  final String id;
  final MuniStop stop;
  final ScrollController scroll;

  @override
  State<MuniStopPanel> createState() => _MuniStopPanelState();
}

class _MuniStopPanelState extends State<MuniStopPanel> with _MuniLoad {
  @override
  Widget build(BuildContext context) {
    final cards = muni == null ? const <MuniCard>[] : cardsAtStop(muni!.cards, widget.id);
    final now = clock;
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SheetHandle(),
        _head(
          context,
          'Στάση δημοτικής γραμμής',
          Text(widget.stop.name ?? 'Στάση', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        _scheduled(context),
        if (!loaded)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
        else if (cards.isEmpty)
          _note(context, 'Δεν φόρτωσαν οι δημοτικές γραμμές. Δοκίμασε ξανά σε λίγο.')
        else ...[
          for (final c in cards)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: MuniBadge(c.ref),
              title: Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                c.table == null
                    ? 'Χωρίς ελεγμένο ωράριο'
                    : switch (muniNextRows(c, now, n: 2)) { [] => 'Κανένα άλλο δρομολόγιο σήμερα', final rows => rows.join('\n') },
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => mapSel.value = MuniSel(c),
            ),
          _note(context, 'Οι ώρες είναι από την αφετηρία που γράφει ο δήμος, όχι από αυτή τη στάση.'),
        ],
      ],
    );
  }
}
