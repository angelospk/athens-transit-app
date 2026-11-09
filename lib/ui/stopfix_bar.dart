// «Λάθος θέση στάσης;» on the map: while [stopFix] is set, the stop's sheet gives way to this bar and a tap
// on the map moves a blue pin (map_screen). The report goes to the web's feedback endpoint (core/stopfix.dart).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/geo.dart';
import '../core/stopfix.dart';
import 'theme.dart';

class StopFix {
  const StopFix({required this.id, required this.name, required this.from, required this.at});
  final String id, name; // GTFS stop id, stop name
  final Pt from, at; // the stop on the map; the user's pin

  StopFix moved(Pt to) => StopFix(id: id, name: name, from: from, at: to);
}

/// The fix in progress, or null. A map tap moves its pin.
final stopFix = ValueNotifier<StopFix?>(null);

enum _Status { edit, sending, done, failed }

class StopFixBar extends StatefulWidget {
  const StopFixBar({
    super.key,
    required this.name,
    required this.from,
    required this.at,
    required this.send,
    required this.onClose,
  });
  final String name;
  final Pt from, at;
  final Future<bool> Function() send; // true: the endpoint took it
  final VoidCallback onClose;

  @override
  State<StopFixBar> createState() => _StopFixBarState();
}

class _StopFixBarState extends State<StopFixBar> {
  var _status = _Status.edit;

  @override
  void didUpdateWidget(StopFixBar old) {
    super.didUpdateWidget(old);
    if (old.at != widget.at && _status == _Status.failed) _status = _Status.edit;
  }

  Future<void> _send() async {
    setState(() => _status = _Status.sending);
    final ok = await widget.send();
    if (mounted) setState(() => _status = ok ? _Status.done : _Status.failed);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final moved = distM(widget.from, widget.at).round();
    final tooFar = moved > maxMoveM;
    final ok = fixSendable(moved) && _status != _Status.sending;
    const title = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final hint = TextStyle(fontSize: 13.5, height: 1.35, color: t.muted);
    if (_status == _Status.done) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ευχαριστούμε, το πήραμε!', style: title),
          const SizedBox(height: 4),
          Text('Η στάση δεν αλλάζει αμέσως: κάθε πρόταση ελέγχεται με τα GPS των λεωφορείων.', style: hint),
          const SizedBox(height: 12),
          FilledButton(onPressed: widget.onClose, child: const Text('Κλείσιμο')),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Πάτα στον χάρτη εκεί που είναι το κολωνάκι', style: title),
        const SizedBox(height: 4),
        Text(
          tooFar
              ? 'Πάνω από $maxMoveM μ από τη στάση. Φέρ’ την πιο κοντά.'
              : _status == _Status.failed
              ? 'Δεν στάλθηκε. Έλεγξε τη σύνδεση και ξαναδοκίμασε.'
              : moved < minMoveM
              ? 'Η μικρή τελεία είναι η θέση που ξέρουμε.'
              : 'Μετακίνηση $moved μ.',
          style: hint.copyWith(color: tooFar || _status == _Status.failed ? t.late : null),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _status == _Status.sending ? null : widget.onClose,
                child: const Text('Άκυρο'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: ok ? _send : null,
                child: Text(_status == _Status.sending ? 'Αποστολή…' : 'Αποστολή'),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => launchUrl(Uri.parse(streetViewUrl(widget.at)), mode: LaunchMode.externalApplication),
          child: const Text('Δες το σημείο στο Street View ›'),
        ),
        Text(
          'Στέλνεται η θέση της πινέζας, η στάση και ένας τυχαίος κωδικός συσκευής.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: t.muted),
        ),
      ],
    );
  }
}
