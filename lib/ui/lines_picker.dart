// "Ποιες γραμμές σε νοιάζουν εδώ;" — chips, at most maxLines lines across the app.

import 'package:flutter/material.dart';

import '../data/store.dart';
import 'widgets.dart';

Future<Set<String>?> pickLines(BuildContext context, List<String> lines, Set<String> initial) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    builder: (context) => _Picker(lines: lines, initial: initial),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({required this.lines, required this.initial});
  final List<String> lines;
  final Set<String> initial;
  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late final sel = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final store = Deps.of(context).store;
    final others = store.myLines.where((l) => !widget.lines.contains(l)).length;
    final room = maxLines - others;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ποιες γραμμές σε νοιάζουν εδώ;', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Ως $maxLines γραμμές σε όλη την εφαρμογή.', style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final l in widget.lines)
            FilterChip(
              label: Text(l, style: const TextStyle(fontWeight: FontWeight.w700)),
              selected: sel.contains(l),
              onSelected: (on) => setState(() {
                if (!on) {
                  sel.remove(l);
                } else if (sel.length < room) {
                  sel.add(l);
                }
              }),
            ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(onPressed: () => Navigator.pop(context, sel), child: const Text('Αποθήκευση')),
        ),
      ]),
    );
  }
}
