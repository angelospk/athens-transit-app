// The bottom bar as a floating island: a capsule over the page in the theme's colours. The open tab
// shows its icon and name on a pill; the other tabs show only their icon. One tab can be the raised
// round button in the middle ("Διαδρομή"). While the map is busy (it moves, or its sheet is up) the
// island shrinks to a small row of icons; a tap on it, or the map at rest, brings it back.

import 'package:flutter/material.dart';

import 'theme.dart';

class IslandItem {
  const IslandItem(this.icon, this.label, {this.raised = false});
  final IconData icon;
  final String label;
  final bool raised; // the round button in the middle
}

// Set by the map: the island shrinks while it is true.
final navCompact = ValueNotifier(false);

class IslandNav extends StatelessWidget {
  const IslandNav({super.key, required this.items, required this.index, required this.onTap});
  final List<IslandItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return ValueListenableBuilder(
      valueListenable: navCompact,
      builder: (context, small, _) => ColoredBox(
        color: t.ground, // the page under the island: the map's sheet has the same colour
        child: SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: small ? const EdgeInsets.fromLTRB(72, 2, 72, 6) : const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: small ? 40 : 60,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: t.rule),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 4))],
              ),
              padding: EdgeInsets.all(small ? 3 : 6),
              // Each tab is as wide as it needs: the open one fits its whole name, the rest share the space.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    items[i].raised
                        ? _raised(context, items[i], i == index, small, () => onTap(i))
                        : _tab(context, items[i], i == index, small, () => onTap(i)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The open tab: icon and name on a pill in the theme's indicator colour. The others: the icon only.
  // Small: icons only, the open one on its pill.
  Widget _tab(BuildContext context, IslandItem it, bool on, bool small, VoidCallback tap) {
    final t = context.tones;
    return Semantics(
      selected: on,
      button: true,
      label: it.label,
      excludeSemantics: true,
      onTap: tap, // excludeSemantics drops the InkWell's own tap action
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          navCompact.value = false;
          tap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(color: on ? t.indicator : Colors.transparent, borderRadius: BorderRadius.circular(24)),
          padding: EdgeInsets.symmetric(horizontal: small ? 10 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(it.icon, color: on ? t.ink : t.muted, size: small ? 20 : 22),
              if (on && !small) ...[
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
  Widget _raised(BuildContext context, IslandItem it, bool on, bool small, VoidCallback tap) {
    final t = context.tones;
    final size = small ? 34.0 : 52.0;
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
            offset: Offset(0, small ? 0 : -10),
            child: Material(
              color: on ? t.indicator : t.ink,
              shape: CircleBorder(
                side: BorderSide(color: t.ground, width: small ? 0 : 3),
              ),
              elevation: small ? 0 : 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  navCompact.value = false;
                  tap();
                },
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(it.icon, size: small ? 20 : 26, color: on ? t.ink : t.ground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
