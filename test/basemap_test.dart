import 'dart:convert';

import 'package:athens_transit/core/basemap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the dark style gets the lighter paints; other layers and keys stay', () {
    final style = {
      'version': 8,
      'layers': [
        {'id': 'background', 'type': 'background', 'paint': {'background-color': 'rgb(12,12,12)'}},
        {'id': 'highway_minor', 'type': 'line', 'paint': {'line-color': '#181818', 'line-width': 2}},
        {'id': 'place_city', 'type': 'symbol'},
        {'id': 'unknown', 'type': 'line', 'paint': {'line-color': '#000'}},
      ],
    };
    final out = lightenDark(jsonDecode(jsonEncode(style)) as Map<String, dynamic>); // as decoded from the network
    final ls = out['layers'] as List;
    expect(ls[0]['paint']['background-color'], '#1b1d21');
    expect(ls[1]['paint'], {'line-color': '#3a3d44', 'line-width': 2});
    expect(ls[2]['paint']['text-color'], '#a8adb5');
    expect(ls[3]['paint']['line-color'], '#000');
  });
}
