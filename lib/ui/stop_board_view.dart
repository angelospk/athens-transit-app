// The stop card's body from the stop's arrival board, laid out as the web's StopCard: the user's lines first
// («Οι γραμμές μου | Όλες»), each line and headsign with its next bus in big minutes, where it is and whether it runs
// late, the next ones; the other lines short below («Περνούν επίσης»), the usual service of the lines with no bus
// near, and the quiet lines as chips. No invented rows: only what the board says.

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/stop_board.dart';
import 'theme.dart';
import 'widgets.dart';

class StopBoardView extends StatelessWidget {
  const StopBoardView({
    super.key,
    required this.board,
    required this.nowMs,
    required this.lines,
    required this.mine,
    required this.all,
    required this.onAll,
    required this.onBus,
    required this.onLine,
    required this.bell,
    this.ix,
    this.stopIx,
    this.oasa = false,
    this.updatedMs,
    this.failed = false,
  });

  final StopBoard board;
  final int nowMs;
  final List<String> lines; // every line that calls at the stop
  final Set<String> mine; // the user's lines
  final bool all;
  final ValueChanged<bool> onAll;
  final void Function(String line, String vehicleId) onBus;
  final ValueChanged<String> onLine;
  final Widget? Function(ArrivalGroup g) bell;
  final TripIndex? ix; // the stop index, for where a row runs to; null until it loads
  final int? stopIx; // this stop in [ix]
  final bool oasa;
  final int? updatedMs; // when the shown board loaded
  final bool failed; // the last refresh failed: the shown board is an older one

  // Where a row's bus runs to: its variant's end from the map data; on a loop, after the turn, back to the start. A
  // row with no variant: the end of the line's variants here, else the headsign.
  ({String to, bool back}) _dest(String line, String headsign, String variant) {
    final x = ix, k = stopIx;
    if (x != null && k != null && variant.isNotEmpty) {
      final d = headTo(x, line, variant, k, headsign);
      return (to: titleCase(d.to), back: d.back);
    }
    return (to: titleCase((x != null && k != null ? lineTowardAt(x, line, k) : null) ?? toward(headsign)), back: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final groups = arrivalGroups(board.arrivals, nowMs);
    final showAll = all || mine.isEmpty || mine.length == lines.length;
    final mineGroups = groups.where((g) => mine.contains(g.line)).toList();
    final shown = showAll ? groups : mineGroups;
    final also = showAll ? <ArrivalGroup>[] : groups.where((g) => !mine.contains(g.line)).take(4).toList();
    final usual = usualRows(board.usual, groups, nowMs).where((u) => showAll || mine.contains(u.line)).toList();
    final quiet = [
      for (final l in lines)
        if ((showAll || mine.contains(l)) && !groups.any((g) => g.line == l) && !usual.any((u) => u.line == l)) l,
    ];
    String big(ArrivalTime x) => x.here ? 'τώρα' : timeText(x);
    Color tone(NoteTone n) => switch (n) { NoteTone.ok => t.onTime, NoteTone.late => t.late, NoteTone.muted => t.muted };

    Widget head(String x) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(x, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
        );

    Widget row(ArrivalGroup g) {
      final first = g.times.first;
      final note = arrivalNote(first);
      final d = _dest(g.line, g.headsign, g.variant);
      final next = g.times.skip(1).map(timeText).join(', ');
      return DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.rule))),
        child: InkWell(
          onTap: () => onBus(g.line, first.vehicle),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              LineBadge(g.line, oasa: oasa),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('→ ${d.to}${d.back ? ' (επιστροφή)' : ''}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(note.text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: tone(note.tone))),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(big(first), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
                if (next.isNotEmpty) Text('μετά $next', style: TextStyle(fontSize: 12, color: t.muted)),
              ]),
              if (bell(g) case final b?) ...[const SizedBox(width: 10), b],
            ]),
          ),
        ),
      );
    }

    Widget compact(ArrivalGroup g) {
      final first = g.times.first;
      final d = _dest(g.line, g.headsign, g.variant);
      return InkWell(
        onTap: () => onBus(g.line, first.vehicle),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            LineBadge(g.line, oasa: oasa),
            const SizedBox(width: 12),
            Expanded(
              child: Text('→ ${d.to}${d.back ? ' (επιστροφή)' : ''}${first.away != null ? ' · ${first.away} στάσεις' : ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: t.muted)),
            ),
            const SizedBox(width: 8),
            Text(big(first), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    }

    final hidden = lines.length - mine.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (mine.isNotEmpty && mine.length < lines.length)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: true,
              segments: [
                ButtonSegment(value: false, label: Text('Οι γραμμές μου · ${mine.length}')),
                ButtonSegment(value: true, label: Text('Όλες · ${lines.length}')),
              ],
              selected: {all},
              onSelectionChanged: (v) => onAll(v.first),
            ),
          ),
        ),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(showAll ? 'Κανένα λεωφορείο καθ’ οδόν τώρα.' : 'Κανένα λεωφορείο των γραμμών σου καθ’ οδόν τώρα.', style: TextStyle(color: t.muted)),
        )
      else
        for (final g in shown) row(g),
      if (!showAll) ...[
        head('Περνούν επίσης · $hidden ${hidden == 1 ? 'γραμμή' : 'γραμμές'}'),
        for (final g in also) compact(g),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => onAll(true), child: Text('Όλες οι γραμμές της στάσης (${lines.length}) ›')),
        ),
      ],
      for (final u in usual)
        InkWell(
          onTap: () => onLine(u.line),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              LineBadge(u.line, oasa: oasa),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('→ ${_dest(u.line, u.headsign, '').to}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: t.muted)),
                  Text(u.text, style: TextStyle(fontSize: 12.5, color: t.muted)),
                ]),
              ),
            ]),
          ),
        ),
      if (quiet.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Χωρίς λεωφορείο κοντά τώρα:', style: TextStyle(fontSize: 13, color: t.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, runSpacing: 6, children: [
          for (final l in quiet)
            InkWell(
              onTap: () => onLine(l),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                LineBadge(l, oasa: oasa),
                if ((ix != null && stopIx != null ? lineTowardAt(ix!, l, stopIx!) : null) case final to?) ...[
                  const SizedBox(width: 6),
                  Text('→ ${titleCase(to)}', style: TextStyle(fontSize: 13, color: t.muted)),
                ],
              ]),
            ),
        ]),
      ],
      const SizedBox(height: 12),
      if (failed || updatedMs != null)
        Text(
          failed
              ? 'Η τελευταία ενημέρωση απέτυχε${updatedMs != null ? ' · ${clockAt(updatedMs! ~/ 1000)}' : ''}'
              : 'τελ. ενημέρωση: ${clockAt(updatedMs! ~/ 1000)}',
          style: TextStyle(fontSize: 12, color: failed ? t.late : t.muted),
        ),
    ]);
  }
}
