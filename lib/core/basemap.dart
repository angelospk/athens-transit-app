// OpenFreeMap's dark style is near black (roads #181818 on rgb(12,12,12)): streets and names do not
// show. These paints lighten it, keyed by its layer ids, as on the web (src/lib/map/basemap.ts). A
// layer it renames keeps its own dark colour; the map does not break.

const _name = {'text-color': '#a8adb5', 'text-halo-color': 'rgba(0,0,0,0.8)'}; // every place_* layer
const _green = '#24302a'; // parks and woods: they must not read as holes in the city

const darkPaint = <String, Map<String, String>>{
  'background': {'background-color': '#1b1d21'},
  'water': {'fill-color': '#1f2a36'},
  'waterway': {'line-color': '#1f2a36'},
  'landuse_residential': {'fill-color': '#1e2024'},
  'landcover_wood': {'fill-color': _green},
  'landuse_park': {'fill-color': _green},
  'building': {'fill-color': '#25272c', 'fill-outline-color': '#2e3137'},
  'aeroway-area': {'fill-color': '#24262b'},
  'highway_path': {'line-color': '#34373e'},
  'highway_minor': {'line-color': '#3a3d44'},
  'highway_major_casing': {'line-color': '#2a2c31'},
  'highway_major_inner': {'line-color': '#4a4e57'},
  'highway_major_subtle': {'line-color': '#4a4e57'},
  'highway_motorway_casing': {'line-color': '#2a2c31'},
  'highway_motorway_inner': {'line-color': '#5a5f69'},
  'highway_motorway_subtle': {'line-color': '#4a4e57'},
  'railway_transit': {'line-color': '#4a4e57'},
  'railway_minor': {'line-color': '#4a4e57'},
  'railway': {'line-color': '#4a4e57'},
  'highway_name_other': {'text-color': '#8d929b', 'text-halo-color': '#1b1d21'},
  'highway_name_motorway': {'text-color': '#9a9fa8'},
  'water_name': {'text-color': '#6f8aa6', 'text-halo-color': '#1b1d21'},
};

/// The dark style JSON with the lighter paints written into its layers (in place, and returned).
Map<String, dynamic> lightenDark(Map<String, dynamic> style) {
  for (final l in style['layers'] as List? ?? const []) {
    final layer = l as Map<String, dynamic>;
    final id = layer['id'] as String? ?? '';
    final paint = darkPaint[id] ?? (id.startsWith('place_') ? _name : null);
    if (paint == null) continue;
    final p = (layer['paint'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    p.addAll(paint);
    layer['paint'] = p;
  }
  return style;
}
