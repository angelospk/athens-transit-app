// "Τι σημαίνει κάθε σύμβολο" (the web's HelpPop) and where the data comes from: from the ? of the map's
// layers sheet and from Περισσότερα. The level legend is shared with the layers sheet.

import 'package:flutter/material.dart';

import '../core/live_quality.dart';
import 'levels.dart';
import 'theme.dart';

/// The level colours of the ring round a vehicle and of a slow part of the route (web v0.2.38): always against the
/// usual service of the same hour and day type.
class LevelLegend extends StatelessWidget {
  const LevelLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Σε σύγκριση με το συνηθισμένο', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
      const SizedBox(height: 6),
      Wrap(spacing: 14, runSpacing: 6, children: [
        for (final (l, label) in const [
          (QualityLevel.normal, 'κανονικά'),
          (QualityLevel.worse, 'λίγο χειρότερα'),
          (QualityLevel.muchWorse, 'πολύ χειρότερα'),
          (QualityLevel.unknown, 'άγνωστο'),
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: levelFill(l), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ]),
      ]),
    ]);
  }
}

Future<void> showMapHelp(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .95,
        builder: (c, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: const [
          Text('Τι σημαίνει κάθε σύμβολο', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          _Item(_Bus(fill: Color(0xFF0072B2)), 'Λεωφορείο. Πάτημα: ολόκληρη η γραμμή του, με το περίγραμμα σε κάθε όχημα.'),
          _Item(_Bus(fill: Color(0xFF0072B2), level: Color(0xFFA87C00)),
              'Όχημα της γραμμής που άνοιξες ή μιας από τις γραμμές σου: έχει το χρώμα της γραμμής. Το περίγραμμα το συγκρίνει με το συνηθισμένο αυτής της ώρας: '
              'πράσινο κανονικά, κίτρινο λίγο χειρότερα, κόκκινο πολύ χειρότερα, γκρι άγνωστο. Συχνή γραμμή: η απόσταση από το προηγούμενο όχημα· αραιή: η καθυστέρηση.'),
          Padding(padding: EdgeInsets.only(left: 44, bottom: 10), child: LevelLegend()),
          _Item(_Glyph('▲'), 'Η κατεύθυνση που πηγαίνει. Λείπει όταν δεν είναι γνωστή.'),
          _Item(_Bus(fill: Color(0xFF0072B2), faded: true), 'Αχνό: η θέση του είναι παλιά, πάνω από 1½ λεπτό. Δίπλα γράφει πόσο παλιά (π.χ. 2′).'),
          _Item(_Bus(fill: Color(0xFF0072B2), ring: Color(0xFF1A73E8)), 'Μπλε δαχτυλίδι: το λεωφορείο ή η γραμμή που άνοιξες.'),
          _Item(_Glyph('›', box: true), 'Η διαδρομή, με βέλη προς τα πού πηγαίνει. Κάθε κατεύθυνση έχει τη δική της λωρίδα.'),
          _Item(_Slow(), 'Κίτρινο περίγραμμα στη διαδρομή: κίνηση πιο αργή από συνήθως· κόκκινο: πολύ πιο αργή. Πάτημα: η ταχύτητα.'),
          _Item(_Bus(fill: Colors.white, ring: Color(0xFF5B5F66), small: true), 'Στάση. Πάτα τη για να δεις τι έρχεται.'),
          _Item(Icon(Icons.touch_app_outlined), 'Πάτα σε κενό σημείο του χάρτη για να κλείσεις ό,τι είναι ανοιχτό.'),
          SizedBox(height: 16),
          Text('Από πού έρχονται τα δεδομένα', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          _Para('Θέση', 'Κάθε λεωφορείο στέλνει το GPS του στον ΟΑΣΑ. Ο server μας το διαβάζει κάθε 30″ περίπου. '
              'Ανάμεσα σε δύο θέσεις η εφαρμογή κινεί το λεωφορείο πάνω στη διαδρομή του, με την ταχύτητά του.'),
          _Para('Χρόνος άφιξης', 'Τον υπολογίζει η εφαρμογή: από το πού είναι το λεωφορείο και την τυπική ταχύτητα κάθε κομματιού του δρόμου '
              '(από τις θέσεις των τελευταίων 14 ημερών). Δεν είναι η πρόβλεψη του ΟΑΣΑ.'),
          _Para('Καθυστέρηση', 'Σύγκριση με το πρόγραμμα του ΟΑΣΑ για το δρομολόγιο που κάνει το λεωφορείο.'),
          _Para('«~» πριν από έναν χρόνο', 'Χωρίς σύνδεση: εκτίμηση από τα τελευταία δεδομένα. Διορθώνεται μόλις βρεθεί σήμα.'),
        ]),
      ),
    );

class _Item extends StatelessWidget {
  const _Item(this.icon, this.text);
  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 32, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35))),
        ]),
      );
}

class _Para extends StatelessWidget {
  const _Para(this.title, this.text);
  final String title, text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$title. ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: text),
        ]), style: const TextStyle(fontSize: 15, height: 1.4)),
      );
}

class _Bus extends StatelessWidget {
  const _Bus({required this.fill, this.ring = Colors.white, this.level, this.faded = false, this.small = false});
  final Color fill, ring;
  final Color? level; // the live level: a ring outside the edge
  final bool faded, small;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: small ? 12 : 22,
      height: small ? 12 : 22,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: ring == Colors.white ? 1.5 : 3),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
      ),
    );
    return Opacity(
      opacity: faded ? .35 : 1,
      child: level == null ? dot : Container(padding: const EdgeInsets.all(2.5), decoration: BoxDecoration(color: level, shape: BoxShape.circle), child: dot),
    );
  }
}

// A slow part of a route: the route's colour with a yellow halo round it.
class _Slow extends StatelessWidget {
  const _Slow();

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 13,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: levelFill(QualityLevel.worse).withValues(alpha: .85), borderRadius: BorderRadius.circular(7)),
        child: Container(height: 5, decoration: BoxDecoration(color: const Color(0xFF0072B2), borderRadius: BorderRadius.circular(3))),
      );
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.g, {this.box = false});
  final String g;
  final bool box;

  @override
  Widget build(BuildContext context) => Container(
        padding: box ? const EdgeInsets.symmetric(horizontal: 6) : null,
        decoration: box ? BoxDecoration(color: const Color(0xFF0072B2), borderRadius: BorderRadius.circular(4)) : null,
        child: Text(g, style: TextStyle(fontSize: box ? 18 : 16, fontWeight: FontWeight.w700, color: box ? Colors.white : context.tones.ink)),
      );
}
