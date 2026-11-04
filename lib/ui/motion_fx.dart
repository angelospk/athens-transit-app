// Small UI motion on the home sheet (flutter_animate). Rules from docs/DESIGN-home.md «Motion»:
// short ease-out tweens, transform and opacity only, no exit motion, and nothing at all when the
// system "remove animations" / Reduce Motion setting is on (flutter_animate does not check it itself).

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _enter = Duration(milliseconds: 180);
const _tick = Duration(milliseconds: 150);
const _step = Duration(milliseconds: 40); // stagger between rows...
const _maxSteps = 4; // ...for the first few only: later rows must not wait

// Android "Remove animations" sets disableAnimations; iOS Reduce Motion sets only reduceMotion.
bool motionOff(BuildContext context) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
    (View.maybeOf(context)?.platformDispatcher.accessibilityFeatures.reduceMotion ?? false);

/// A row or card that appears: it fades in and rises a few pixels. Row [i] of a list starts a little
/// after the row before it. A new [key] plays it again (a new tab, another smart card).
class Enter extends StatelessWidget {
  const Enter({required super.key, this.i = 0, required this.child});
  final int i;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (motionOff(context)) return child;
    final delay = _step * min(i, _maxSteps);
    return child
        .animate()
        .fadeIn(delay: delay, duration: _enter, curve: Curves.easeOut)
        .slideY(begin: .08, end: 0, delay: delay, duration: _enter, curve: Curves.easeOut);
  }
}

/// A value that changes in place (the minutes to the next bus): the new value drops in from just
/// above. Only a change of [value] plays it; a rebuild with the same value does not.
class Tick extends StatelessWidget {
  const Tick({super.key, required this.value, required this.child});
  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (motionOff(context)) return child;
    return child
        .animate(key: ValueKey(value))
        .fadeIn(duration: _tick, curve: Curves.easeOut)
        .slideY(begin: -.25, end: 0, duration: _tick, curve: Curves.easeOut);
  }
}
