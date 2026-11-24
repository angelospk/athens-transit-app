// "Τι σημαίνει κάθε σύμβολο" (the web's HelpPop) and where the data comes from: from the ? of the map's
// layers sheet and from Περισσότερα. The delay legend is shared with the layers sheet.

import 'package:flutter/material.dart';

import '../core/marker.dart';
import '../l10n/l10n.dart';
import 'theme.dart';

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

List<(int?, String)> _classes(AppLocalizations l) => [
      (60, l.helpDelayUpTo2),
      (200, '2–5′'),
      (400, '5–10′'),
      (700, l.helpDelayOver10),
      (null, l.helpDelayNoTrip),
    ];

class DelayLegend extends StatelessWidget {
  const DelayLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.l10n.helpDelayTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
      const SizedBox(height: 6),
      Wrap(spacing: 14, runSpacing: 6, children: [
        for (final (d, label) in _classes(context.l10n))
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: _hex(delayHex(d)), shape: BoxShape.circle)),
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
        builder: (c, scroll) {
          final l = c.l10n;
          return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
            Text(l.mapLegend, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _Item(const _Bus(fill: Color(0xFF1A7F37)), l.helpBus),
            const Padding(padding: EdgeInsets.only(left: 44, bottom: 10), child: DelayLegend()),
            _Item(const _Bus(fill: Color(0xFF0072B2), ring: Color(0xFFA87C00)), l.helpMyBus),
            _Item(const _Glyph('▲'), l.helpDirection),
            _Item(const _Bus(fill: Color(0xFF1A7F37), faded: true), l.helpFaded),
            _Item(const _Bus(fill: Color(0xFF1A7F37), ring: Color(0xFF1A73E8)), l.helpBlueRing),
            _Item(const _Glyph('›', box: true), l.helpRoute),
            _Item(const _Bus(fill: Colors.white, ring: Color(0xFF5B5F66), small: true), l.helpStop),
            _Item(const Icon(Icons.touch_app_outlined), l.helpTapEmpty),
            const SizedBox(height: 16),
            Text(l.helpDataTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _Para(l.helpPosition, l.helpPositionText),
            _Para(l.helpEta, l.helpEtaText),
            _Para(l.helpDelay, l.helpDelayText),
            _Para(l.helpTilde, l.helpTildeText),
          ]);
        },
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
  const _Bus({required this.fill, this.ring = Colors.white, this.faded = false, this.small = false});
  final Color fill, ring;
  final bool faded, small;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: faded ? .35 : 1,
        child: Container(
          width: small ? 12 : 22,
          height: small ? 12 : 22,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: ring == Colors.white ? 1.5 : 3),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
          ),
        ),
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
