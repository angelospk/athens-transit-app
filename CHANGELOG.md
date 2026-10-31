# Changelog

Signed APKs for every version: [releases](https://github.com/angelospk/athens-transit-app/releases).
Backend and API changes: [athens-transit-rt CHANGELOG](https://github.com/angelospk/athens-transit-rt/blob/main/CHANGELOG.md).
Detail per task and what was checked: [docs/PLAN-2026-10-28.md](docs/PLAN-2026-10-28.md),
[docs/QA-2026-10-28.md](docs/QA-2026-10-28.md). Manual test list: [docs/TEST-CHECKLIST.md](docs/TEST-CHECKLIST.md).

## Unreleased

## v0.3.0 (2026-10-31)

### Αρχική (new home screen)
- New: no bottom bar. A full-screen map with one sheet half open, and a search bar with the menu
  button on its left. The menu (from the left): Διαδρομή, Γραμμές, Ενημερώσεις, Ειδοποιήσεις, Μέρη,
  Widgets, Στατιστικά, Ρυθμίσεις, Σχετικά.
- New: the sheet has two tabs, «Κοντά σου» and «Αγαπημένα». «Κοντά σου» lists the nearest bus stops
  and metro, tram and suburban stations, grouped by stop, with metres and minutes on foot, line pills
  (line + minutes) and a walk button that opens Google Maps walking directions.
- A metro, tram or suburban station shows the next departure of each of its lines and directions
  (metro and tram: STASY timetable; suburban: live from railway.gov.gr).
- New: a smart card on top: «Γυρνάς σπίτι» (the direct lines home, the next bus you can still walk
  to, today's last run home, in the warning colour within 30′), «Πάμε δουλειά» on weekday mornings,
  else the next bus of a favourite stop.
- New: «Μέρη»: named places (an address, an area, or «Κοντά στη θέση μου (περίπου)» on a ~250 m grid),
  kept only on the phone. The old «Σπίτι» stop moves there.
- No first-run screen: the map opens first and asks for location only after it says why.
- «‹ Πίσω» names the level before. The back button closes the menu first, then one sheet level.

### Map, stops and buses
- One «Χάρτης» sheet replaces the «Όλα ▾» menu and the layers button: all buses or my lines, the
  Μετρό / Τραμ / Προαστιακός chips, the colours; the rarer settings under «Για προχωρημένους».
- Search: Latin letters find Greek names («syntagma», «kifisia», «marousi»). The results list fits
  above the keyboard.
- Bus card: the minutes to your stop first, the delay in words («αργεί 20′»), the details folded.
  The map follows an open bus and stops on a drag. «Είμαι μέσα» / «Ανέβηκα» become «Πού κατεβαίνω;»,
  «Πότε να φύγω» becomes «Φύγε εγκαίρως».
- Stop card: one list, starred lines on top («Οι γραμμές σου»), then «Περνούν επίσης». Each row has
  one fact («αργεί 7′», «2 στάσεις μακριά» or «εκτίμηση»). A bell on every line; filled when an
  alert is set.
- Alert sheet: one button («Ειδοποίησέ με 5′ πριν»); the rest under «Περισσότερες επιλογές».
- Weekly rule: a dialog says why before the Android «Alarms & reminders» page; × deletes a rule from
  the list.
- Statistics: plainer words about the OASA timetable date, no «GTFS».

### Widgets and icon
- «Η στάση μου»: one layout per size (2×1 to 4×3), light or dark with the system, a real preview in
  the picker, rows that read «→ Πειραιάς  2′ · 14′».
- New widget «Γυρνάς σπίτι»: today's last runs home; the small size shows the next one, the large one
  lists them and warns within 30′.
- New app icon (white bus on green, with a monochrome layer for themed icons).

### Fixed
- The map waited forever for the position when the planner asked for it at the same time.
- Turning «Παρασκευή και Σάββατο βράδυ» back on did not always set the evening alarm again.
- The map stuttered while it moved: the bottom bar resized the map on every frame.
- After midnight, a «24:40» last run counted as future until 04:00, also on nights the clocks change.

## v0.2.0 (2026-10-28)

### Διαδρομή (journey planner, new tab)
- From your position, a stop, an area, an address or a place; now or later; «Με μετρό».
- Results: one bus, two buses with one change, bus + metro or tram (either order), metro alone.
- New: a step-by-step screen for every result: walk, bus (stop, where to get off, how many stops),
  change, metro, walk; total time and «φτάνεις ~HH:MM». The first bus is live with «φύγε σε N′».
  A step opens its stop or station on the map.
- «Πότε να φύγω», «Ανέβηκα» (finds your bus and alerts one stop before you get off).
- New: «Ακολούθησέ με»: with the app closed and the screen off, the app notices when you board the
  first bus and alerts one stop before you get off. It needs location only «while using the app».
- Fixed: «Η θέση μου» failed when the phone's last known position was old or elsewhere.

### Map, stops and lines
- Lighter dark map as on the web; buses glide along their route between GPS fixes.
- Metro, tram and suburban rail: corridors, stations, next trains (metro/tram from the STASY
  timetable, suburban rail live with delays). Search chips per mode that also switch the map layers.
- Back arrow with history in every sheet, and the phone's back button walks back through it.
- Bus sheet: compact info row, line badge opens the line, line speeds, «Κλείδωσε στο λεωφορείο»,
  next stops with clock times.
- Line sheet: «Δρομολόγια» with today's real OASA timetable and each run seen or missed (new on the
  backend: from buses seen leaving their start), the gaps between buses, slow stretches ahead.
- Stop: runs not started yet from the timetable; new «Δεν ξεκίνησαν»: runs that did not leave and
  would be here about now, with «Άλλη επιλογή» that opens the planner.

### Alerts
- «Πες μου πότε να φύγω» from your walk time; «Πες μου και αν αργεί» (one notification when the
  bus is 5′+ late); «Είμαι μέσα» for one bus; on-a-bus detection with the map open.
- New: «Για το τελευταίο της ημέρας» in the alert sheet (15′ before the last run passes).
- New: Friday and Saturday evening: a banner in Αγαπημένα and a 21:00 notification with the last bus
  to the home stop; «Ειδοποίησέ με 30′ πριν». Can be turned off in Περισσότερα.

### Other
- Αγαπημένα with saved stops (home first in the morning, work in the afternoon) and saved lines.
- Statistics: «Τάσεις», the worst lines over 7/14/28 days.

### Permissions
- New `FOREGROUND_SERVICE_LOCATION`: the alert service reads the location only while you follow a
  trip.

## v0.1.7 (2026-10-27)

- Map as on the web: buses coloured by delay, a direction triangle, faded old positions with their age.
- «Τι δείχνει ο χάρτης»: other buses normal/dim/hidden while one is open, only recent, only on time,
  ages, legend, help.
- Line directions with their buses and stops; the live card's «Σταμάτα»; network statistics.
