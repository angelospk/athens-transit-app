# Changelog

Signed APKs for every version: [releases](https://github.com/angelospk/athens-transit-app/releases).
Backend and API changes: [athens-transit-rt CHANGELOG](https://github.com/angelospk/athens-transit-rt/blob/main/CHANGELOG.md).
Detail per task and what was checked: [docs/PLAN-2026-10-28.md](docs/PLAN-2026-10-28.md),
[docs/QA-2026-10-28.md](docs/QA-2026-10-28.md). Manual test list: [docs/TEST-CHECKLIST.md](docs/TEST-CHECKLIST.md).

## Unreleased

### Χάρτης
- New: «Κοντά σου» on the map's sheet: the nearest bus stops and metro, tram and suburban stations,
  with metres and minutes on foot. A saved line that stops there shows its next bus on the row. It
  replaces «Η στάση σου». Without location: a «Τοποθεσία» button, and the saved stop meanwhile.
- Fixed: the map waited forever for the position when the planner asked for it at the same time.
- New: a metro, tram or suburban station in «Κοντά σου» shows the next departure of each of its
  lines and directions (metro and tram: STASY timetable; suburban: live from railway.gov.gr).
- Fixed: turning «Παρασκευή και Σάββατο βράδυ» back on did not always set the evening alarm again.

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
