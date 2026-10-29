// The bottom bar as a floating island: a capsule over the page in the theme's colours. The open tab
// shows its icon and name on a pill; the other tabs show only their icon. One tab can be the raised
// round button in the middle ("Διαδρομή"). It keeps its size: shrinking it while the map moved resized
// the map under it every frame.

import 'package:flutter/material.dart';

import 'theme.dart';

class IslandItem {
  const IslandItem(this.icon, this.label, {this.raised = false});
  final IconData icon;
  final String label;
  final bool raised; // the round button in the middle
}

class IslandNav extends StatelessWidget {
  const IslandNav({super.key, required this.items, required this.index, required this.onTap});
  final List<IslandItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return ColoredBox(
      color: t.ground, // the page under the island: the map's sheet has the same colour
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: t.rule),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(6),
            // Each tab is as wide as it needs: the open one fits its whole name, the rest share the space.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  items[i].raised
                      ? _raised(context, items[i], i == index, () => onTap(i))
                      : _tab(context, items[i], i == index, () => onTap(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The open tab: icon and name on a pill in the theme's indicator colour. The others: the icon only.
  Widget _tab(BuildContext context, IslandItem it, bool on, VoidCallback tap) {
    final t = context.tones;
    return Semantics(
      selected: on,
      button: true,
      label: it.label,
      excludeSemantics: true,
      onTap: tap, // excludeSemantics drops the InkWell's own tap action
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(color: on ? t.indicator : Colors.transparent, borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(it.icon, color: on ? t.ink : t.muted, size: 22),
              if (on) ...[
                const SizedBox(width: 6),
                Text(
                  it.label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(color: t.ink, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // The round button in the middle, a little above the island (the planner).
  Widget _raised(BuildContext context, IslandItem it, bool on, VoidCallback tap) {
    final t = context.tones;
    const size = 52.0;
    return Semantics(
      selected: on,
      button: true,
      label: it.label,
      excludeSemantics: true,
      onTap: tap,
      child: SizedBox(
        width: size + 8,
        child: OverflowBox(
          maxWidth: size + 8,
          maxHeight: size + 20,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, -10),
            child: Material(
              color: on ? t.indicator : t.ink,
              shape: CircleBorder(
                side: BorderSide(color: t.ground, width: 3),
              ),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: tap,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(it.icon, size: 26, color: on ? t.ink : t.ground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
