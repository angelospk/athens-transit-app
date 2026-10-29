# UX audit and simplification proposal (2026-10-29)

Scope: the whole Android app, from the first launch to every screen, judged as a person who has
never seen it. Goal: make it simple enough for anyone, **without removing a feature**. Design and
proposal only; no product code changed.

Method:

- A first-time-user walkthrough on an Android emulator (AVD `qa36`, debug APK of `f9b8629`, live
  backend, position Σύνταγμα and Αμπελόκηποι, light and dark, online and offline). 63 screenshots;
  the ones cited below are named `NN-name.png` (kept in the thread scratchpad, not in the repo).
- A read of `lib/ui/` and `lib/background/` to confirm each finding in code.
- Desk research on Transit, Citymapper, Moovit, Google Maps, Busmate, OASA Telematics, Öffi, and the
  Android widget and location rules (sources at the end). Grok live search was down; web search only.
- The web spec `athens-transit-map/docs/UI-SPEC-web-v2.md` (Part B and Part E).

Mockups: [`docs/ux-audit-2026-10/home.html`](ux-audit-2026-10/home.html) (first screen, stop card,
one-tap alert) and [`docs/ux-audit-2026-10/widgets.html`](ux-audit-2026-10/widgets.html) (widget set).

---

## 1. Verdict in one paragraph

The core is strong. After setup, «when is my bus» needs **zero taps**: the «Κοντά σου» sheet shows
the nearest stops with live minutes and walking time. The problem is everything around that core.
The app has **5 tabs, 4 map controls, 2 map option sheets with 10 settings, a stop card with a mode
switch, a vehicle card with 3 actions and a toggle, and an alert sheet with 9 controls**. It uses
**six different words** for things a user sees as one or two ideas («Ειδοποίησέ με», «Πότε να φύγω»,
«Είμαι μέσα», «Ανέβηκα», «Ακολούθησέ με», «Κλείδωσε στο λεωφορείο»). Each feature is reasonable
alone; together they look like a power-user tool. The fix is not to cut features. The fix is
**one default action per screen, with the rest one tap deeper**, and one word per concept.

---

## 2. Ranked findings

P0 = blocks or misleads a newcomer. P1 = slows or confuses. P2 = polish.

| # | Sev | Finding | Evidence |
|---|---|---|---|
| 1 | P0 | **Onboarding cannot be finished without a hidden step.** After a stop is picked, «Έτοιμο» stays disabled. The reason («Ποιες γραμμές σε νοιάζουν εδώ;», pick ≥ 1 line) is below the fold. Nothing says «scroll». Onboarding also asks for a stop and lines before the user has seen anything of value. | `05-onboard-picked.png`, `07-onboard-scrolled.png`; `onboard_screen.dart:129-145` (button enabled only with `picked != null && sel.isNotEmpty`) |
| 2 | P0 | **Location is asked with no in-app reason first**, then Google's second «Location Accuracy» dialog follows. After the grant, the placeholder still says «Χωρίς τοποθεσία: γράψε το όνομα…». | `02-onboard.png`, `03-onboard-after-loc.png`, `04-onboard.png` |
| 3 | P0 | **The biggest number on the vehicle card is the delay, not the arrival.** «+20′ από πρόγραμμα» in 40 pt; the header «→ Ελ. Βενιζελου - …» wraps to 4 lines with raw timetable text («δρομολόγιο 17:30 ΕΛ. ΒΕΝΙΖΕΛΟΥ → ΠΕΤΡΑΛΩΝΑ»). Under it: «6 χλμ/ώ συνήθως 12 › · GPS πριν 3′ · #06058». A newcomer cannot tell what the bus means for them. | `17-linecard.png`; `vehicle_screen.dart` |
| 4 | P1 | **Six verbs for the alert/boarding family.** «Ειδοποίησέ με», «Πότε να φύγω» (a mode inside the alert sheet), «Είμαι μέσα» (vehicle), «Ανέβηκα» (planner steps), «Ακολούθησέ με», «Κλείδωσε στο λεωφορείο» (a map-follow toggle). «Είμαι μέσα» and «Ανέβηκα» do the same thing and use a seated-person icon (`Icons.airline_seat_recline_normal`) that reads as an accessibility seat. The bell never shows that an alert is set. | `12-alert-sheet.png`, `17-linecard.png`, `40-trip-steps.png`; `vehicle_screen.dart:186`, `route_screen.dart:198,305`, `planner_screen.dart:563` |
| 5 | P1 | **The alert sheet has 9 controls for one common wish** («tell me 5′ before»): 3 modes, −/+, 4 switches, a weekly-rule row, the button. The preview «Τώρα αυτό σημαίνει» is excellent; the rest is advanced. | `12-alert-sheet.png`; `alert_sheet.dart:234-366` |
| 6 | P1 | **Stop rows carry 4-5 facts each.** «040 → Πειραιας - Συνταγμ… 11′ · ●●○ 2 στάσεις πριν · +21′ … επόμενο 11′, 11′». «+21′» looks like a time, not a delay. The «Οι γραμμές μου · 2 / Όλες · 22» switch hides 20 lines by default and makes the user decide what «μου» means. | `11-stopcard.png`, `15-stop-all.png`; `stop_screen.dart:200-306` |
| 7 | P1 | **Names without accents and with raw GTFS suffixes.** «Συνταγμα», «Πειραιας», «Ακροπολη», «…(προσωρινη Λογω Εργων)». It reads as broken data and truncates the useful part (the destination). | `09-after-done.png`, `11`, `39-routes.png` |
| 8 | P1 | **5 tabs, 2 of them thin.** «Ειδοποιήσεις» is mostly empty for a newcomer; «Περισσότερα» mixes settings, help, statistics, the widget and links. The map has 2 option entries (the «Όλα ▾» chip and the layers button) that both change what the map shows. The legend is 2 taps deep, in a sheet on top of a sheet. | `09`, `21-filter.png`, `22-layers.png`, `23-help.png`, `48-settings.png`; `main.dart:116-125`, `map_screen.dart:785-952` |
| 9 | P1 | **«Σπίτι» is set silently.** The onboarding stop becomes «Σπίτι» with no question. «Απόγευμα: πρώτα η στάση της δουλειάς» shows with no work stop, and with no stops at all. «+ Στάση» reuses the onboarding copy («Θα τη βλέπεις πρώτη κάθε φορά…»), wrong for a second stop. | `11-stopcard.png`, `33-favs.png`, `35-add-stop.png`, `61-empty-favs.png` |
| 10 | P1 | **Saving a weekly rule throws the user into Android «Alarms & reminders»** with no in-app reason. A rule has no visible delete. | `46-rule-saved.png`, `47-after-alarm-perm.png` |
| 11 | P1 | **Map search: Latin «syntagma» finds nothing and shows nothing.** The planner's search finds it. The search-result star means «my line», the stop-card star means «saved stop». | `29-search-latin.png`, `30-search-040.png` |
| 12 | P1 | **Trust signals of a prototype:** default Flutter launcher icon, Flutter logo as the widget preview, the stats screen says «Το πρόγραμμα του ΟΑΣΑ (GTFS) έχει λήξει: 2026-07-08». | `51-home-widget.png`, `49-widget-add.png`, `52-stats.png`; `AndroidManifest.xml:15`, `stop_widget_info.xml` (no `previewLayout`) |
| 13 | P2 | **The widget reads «040 μετά 3′ … ~2′»**: two numbers, unclear which is the next bus. Always white on a dark home screen. Large empty area at 4×2. Only one widget, one size. | `51-home-widget.png`; `res/layout/stop_widget.xml` |
| 14 | P2 | «Κοντά σου»: the second place (metro) is half under the nav island when the sheet is low; no hint that the sheet expands. Bus dots have no line number; their colour (delay) is explained only in the legend. | `09-after-done.png`, `10-sheet-expanded.png` |
| 15 | P2 | Planner: the «Με μετρό» chip looks selected without a check; destination suggestions offer «Η θέση μου» as a destination and no saved places; the metro option says «Περπάτημα 10′ συνολικά» with no ride time. | `36-planner.png`, `37-planner-to.png`, `39-routes.png` |
| 16 | P2 | Jargon on screen: «στίγμα GPS», «με GPS», «Ηλικία θέσης», «Αχνά / Κρυφά», «από πρόγραμμα», «GTFS», «#06058». | `13`, `22-layers.png`, `52-stats.png` |

Keep (users get these right on the first try): zero-tap «Κοντά σου» with walk minutes; the alert
preview «Τώρα αυτό σημαίνει: όταν είναι στο Μακρυγιάννη, 1 στάση πριν»; notification permission asked
only when a bell is pressed; «Πού κατεβαίνεις;»; the sentence rule editor («Κάθε Δε–Πα από 08:00 ως
08:40 πες μου…»); planner results grouped «Χωρίς αλλαγή / Με μία αλλαγή» with «φύγε τώρα»; step-by-step
Back (line → stop → sheet → exit); the offline banner with the time of the last data; dark mode.

Tap counts today: next arrival at the nearest stop 0 (after setup; ~5 + a scroll on first launch);
alert for a bus 3; trip to a place 3 + typing; widget 3 (no confirmation in the app).

---

## 3. What similar apps do (short)

| App | First screen | Pattern worth copying |
|---|---|---|
| Transit | Map + list of nearby lines, pinned lines on top | Nearby **lines** (not stops) are the home; tap a line for detail. Step guidance («GO») and its options exist only during a trip. Two Android widgets: «Nearby» and «Instant ETA» (time to a favourite place). |
| Moovit | Nearby stops with next departures, 3 tabs | Favourites become one-tap shortcuts on the main screen. Get-off notification during live directions. |
| Citymapper | Search + «Get me home / to work» | One tap from the first screen to «home», with no form at use time. |
| Google Maps | Map + search; Home/Work shortcuts | Long-press the launcher icon → Home / Work. Directions widget: one tap to a saved place. |
| Öffi | Nearby stations, departures | A departures widget for nearby stations. |
| Busmate (Athens) | Nearby stops with walk distance | Favourite lines **and** stops; small, buses only, 4.7★. Competitor for the simple case. |
| OASA Telematics | Nearby stops | Official; reviews complain about crashes and unreliable live data. |

The common rule: **the first screen answers «what leaves near me now»; a second one-tap answers
«get me home»; everything else waits until the user picks a stop, a line or a trip.**

---

## 4. Proposed information architecture

### 4.1 Three tabs instead of five

| Tab | What it is | What moves in |
|---|---|---|
| **Κοντά** (home) | Map + the «Κοντά σου» sheet, as today, plus one «Σπίτι» card on top of the sheet (§4.3). | Map, search, stop / line / vehicle cards. |
| **Διαδρομή** | The planner, opening on **saved places** («Σπίτι», «Δουλειά», recent destinations) instead of an empty form. | Planner, step screen, «Γυρνάς σπίτι» full view, last-bus info. |
| **Δικά μου** | Saved stops and lines **and** active alerts and weekly rules, on one page. Gear icon top right opens Ρυθμίσεις. | «Αγαπημένα», «Ειδοποιήσεις», «Περισσότερα» (as Ρυθμίσεις). |

Trade-off: 3 tabs make the bar calmer and give each tab a clear job; alerts lose their own tab, so a
person with many weekly rules needs one scroll more. Recommended, because a newcomer has no rules and
an active alert also shows as an ongoing notification and as a filled bell in the cards.

### 4.2 One default per screen, the rest behind «Περισσότερα»

- **Map controls**: merge the «Όλα ▾» chip and the layers button into one «Χάρτης» button (one
  sheet). Top of the sheet: Λεωφορεία / Μετρό / Τραμ / Προαστιακός (icons) and «Μόνο οι γραμμές μου».
  Below a fold «Για προχωρημένους»: Κανονικά / Αχνά / Κρυφά, «Μόνο με πρόσφατη θέση», «Μόνο στην ώρα
  τους», «Ηλικία θέσης». The legend: a 3-dot strip in the sheet itself («στην ώρα / αργεί / πολύ
  αργά»), full help one tap away.
- **Stop card**: no «Οι γραμμές μου / Όλες» switch. One list sorted by next arrival; starred lines
  pinned on top with a star; after 6 rows «Όλες οι γραμμές (22) ›». One row = line badge, short
  destination, big minutes; the second line holds **one** fact: «2 στάσεις μακριά», or «αργεί 21′»
  in the delay colour. «Επόμενο 11′, 11′» moves into the expanded row. «Δεν ξεκίνησαν» stays as its
  own folded section at the end.
- **Vehicle card**: title «040 → Πειραιάς» (one line). Big number = minutes to the user's stop (or
  to the next stop), with the delay as a word under it. Actions: «Ειδοποίησέ με» and «Πού
  κατεβαίνω;». The map follows the bus while the card is open, by default, so the «Κλείδωσε» toggle
  goes (a tap on the map stops following, as in every map app). Speed, GPS age, vehicle number go into
  a folded «Λεπτομέρειες».
- **Alert sheet**: opens with **one** big button «Ειδοποίησέ με 5′ πριν» plus the existing preview
  line, and −/+ on the number. «Περισσότερες επιλογές» unfolds: Στάσεις πριν / Φύγε εγκαίρως, live
  card, «Πες μου και αν αργεί», «Κάθε καθημερινή», «Το τελευταίο της ημέρας». Defaults remember the
  last choice.
- **Onboarding**: none. First launch opens the map with a card «Δες τι περνάει κοντά σου» →
  [Τοποθεσία] (in-app reason first, then the system dialog) or «Ψάξε στάση». «Σπίτι» is asked the
  first time the user taps the «Σπίτι» card or a home widget («Πού είναι το σπίτι σου;» → stop,
  address or map pin). Lines are starred from cards, not picked up front.

### 4.3 One word per concept (glossary for the UI)

| Concept | One label | Replaces |
|---|---|---|
| Notify before a bus reaches my stop | **Ειδοποίησέ με** (bell; filled bell = set) | «Ειδοποιήσεις», bell without state |
| Notify when to leave home/office | **Φύγε εγκαίρως** (mode in «Περισσότερες επιλογές») | «Πότε να φύγω» |
| I am on this bus, tell me where to get off | **Πού κατεβαίνω;** (flag icon) | «Είμαι μέσα», «Ανέβηκα» |
| Notice by itself when I board | **Ακολούθησέ με** (kept; good copy) | — |
| Map follows a bus | default while the card is open | «Κλείδωσε στο λεωφορείο» |
| Time from the timetable, not live | small «≈» before the minutes + «πρόγραμμα» in help | «~», «από πρόγραμμα» |

### 4.4 Every feature keeps a home

| Feature today | Where it lives after |
|---|---|
| Live map, delay colours, motion between fixes | Κοντά (unchanged) |
| «Κοντά σου» nearest stops/stations | Κοντά, sheet (unchanged) + «Σπίτι» card on top |
| Map filter «Όλα / Μόνο οι γραμμές μου» | Κοντά › «Χάρτης» sheet, top |
| Layers Μετρό / Τραμ / Προαστιακός | Κοντά › «Χάρτης» sheet, top |
| Αχνά / Κρυφά, πρόσφατη θέση, στην ώρα, ηλικία θέσης | Κοντά › «Χάρτης» › «Για προχωρημένους» |
| Map legend «Πώς διαβάζεται ο χάρτης» | strip in «Χάρτης» sheet; full text in Ρυθμίσεις › Βοήθεια |
| Search (lines, stops, places, mode chips) | Κοντά, top (Latin transliteration added) |
| Stop card, «Περνούν επίσης», «Δεν ξεκίνησαν», «Άλλη επιλογή» | stop card, one list; «Δεν ξεκίνησαν» folded at end |
| Line card: timetable, gaps, slow stretches | line card; slow stretches/speed under «Λεπτομέρειες» |
| Vehicle card, «Είμαι μέσα», «Κλείδωσε» | vehicle card: «Πού κατεβαίνω;»; follow = default |
| Alerts: minutes / stops / when to leave, live card, «αν αργεί», weekly, last of day | alert sheet: 1 default + «Περισσότερες επιλογές» |
| Weekly rules (list, editor) | Δικά μου › «Ειδοποιήσεις» section; editor unchanged |
| Active alerts | Δικά μου, top; also the filled bell in cards |
| Saved stops, home/work, time-of-day order | Δικά μου › «Στάσεις»; Σπίτι/Δουλειά are **places** (stop or address) |
| Saved lines (max 5 live) | Δικά μου › «Γραμμές» |
| Planner, step screen, «Ακολούθησέ με» | Διαδρομή (opens on saved places) |
| Last bus of the day, Fri/Sat 21:00 nudge | «Γυρνάς σπίτι» (card, widget); nudge switch in Ρυθμίσεις › Ειδοποιήσεις |
| Theme, walk minutes, live-card default | Ρυθμίσεις (gear in Δικά μου) |
| Network statistics | Ρυθμίσεις › «Για προχωρημένους» |
| Widget install | Ρυθμίσεις › Widgets (gallery with previews) + Android widget picker |
| Links (idea, wrong stop, API, web map) | Ρυθμίσεις › Σχετικά |
| Offline banner, cached estimates | unchanged |

Nothing is removed. Two controls disappear as **controls** and become behaviour: «Κλείδωσε στο
λεωφορείο» (follow by default) and the «Οι γραμμές μου / Όλες» switch (pinned starred lines).

---

## 5. «Γυρνάς σπίτι» and widgets

### 5.1 The «Γυρνάς σπίτι» idea

One feature, three questions, all about the same destination (the «Σπίτι» place):

| Variant | Question it answers | Example text | Data |
|---|---|---|---|
| **Επόμενος για το σπίτι** | How do I get home now? | «Φύγε σε 6′ · 040 από Σύνταγμα · σπίτι 18:52» | origin, home, on-device trip search (`core/trip.dart` `findTrips`), live arrivals of the chosen line |
| **Τελευταίο για το σπίτι** | Until when can I stay out? | «Τελευταίο 23:40 · 209 από Σύνταγμα · σε 1ώ 12′» | origin, home, today's timetable per candidate line (`/v1/lines/{id}/schedule`), `core/last_bus.dart` `lastRun` |
| **Το πρώτο από τα τελευταία** | When do my options start to vanish? | «Από τις 23:10 χάνεις λεωφορεία: 23:10 040 · 23:40 209 · 00:15 Μ2» | the same as above, for **every** route home; sort the last departures, show the earliest first |

How it reads: from 18:00 the «Σπίτι» card on the Κοντά tab shows the next way home. From about
2 hours before the first last departure it switches to «Το πρώτο από τα τελευταία», and inside the
last 30′ to «Τελευταίο …» in the warning colour. A tap opens Διαδρομή with the full list. The existing
Friday/Saturday 21:00 nudge becomes one notification of this card.

Gap to close first: today «Σπίτι» is a **stop** (`Place.home` on a saved stop). Go-home needs a
**place** (an address or a pin) so it can pick among several stops and the metro. Recommendation: let
«Σπίτι» be a place; keep the saved stop as its default stop.

Location: the in-app card uses the live position (foreground). Widgets cannot read the position in
the background without `ACCESS_BACKGROUND_LOCATION` (Android 10+, separate request, Play policy
limits it to core features). So the widgets use **the position saved the last time the app was open**
and print its age («από Σύνταγμα · 25′ πριν»); a tap opens the app, which refreshes the position and
the widget. A «Από» choice in the widget configuration («τελευταία θέση» / «Δουλειά» / a stop) makes
it exact for commuters with no location at all.

### 5.2 Widget set

All widgets: follow the system theme (dark/light), Android 12 sizing (`targetCellWidth/Height`,
resizable), a real `previewLayout`, a configuration screen on add, and a tap target that opens the
matching screen. Refresh: the current approach (exact per-minute redraws for 30′ after each data push,
`updatePeriodMillis` 30 min as a floor) stays; live data comes in when the app or the alert service
runs. The widget shows clock times, so a stale widget still counts down correctly, and it shows the
age of its data.

| # | Widget | Sizes | Shows | Config | Feasibility |
|---|---|---|---|---|---|
| W1 | **Η στάση μου** (today's, improved) | 2×1, 4×1, 4×2, 4×3 | 2×1: one line, big minutes. 4×1: 2 lines. 4×2: 3-4 lines, next two times each («5′ · 17′»). 4×3: + «Δεν ξεκίνησαν» | stop: fixed / «Σπίτι πρωί, Δουλειά απόγευμα» (today's logic) / nearest saved; lines | High: exists; layout + config screen |
| W2 | **Κοντά μου** | 4×2, 4×3 | the 2-3 nearest stops/stations to the last position, one line each | modes (bus/metro/tram) | High: same data as «Κοντά σου»; position = last saved |
| W3a | **Γυρνάς σπίτι · επόμενος** | 2×2, 4×1 | «Φύγε σε 6′ · 040 · σπίτι 18:52» | Από: last position / Δουλειά / stop | Medium: trip search on device; live minutes only as fresh as the last push |
| W3b | **Γυρνάς σπίτι · τελευταίο** | 2×1, 2×2 | «Τελευταίο 23:40 · 209 · σε 1ώ 12′» | Από | High: timetable only; compute once per evening |
| W3c | **Γυρνάς σπίτι · το πρώτο από τα τελευταία** | 4×2 | 3-4 rows: last departure per route, earliest first; struck through when gone | Από | High: timetable only, same as W3b |
| W4 | **Αντίστροφη μέτρηση** | 1×1, 2×1 | one line at one stop: the badge and big minutes | stop + line | High: subset of W1 |
| W5 | **Συντομεύσεις** | 4×1 + launcher shortcuts | «Σπίτι», «Κοντά», «Διαδρομή», «Πού κατεβαίνω;» | which 3-4 | High: no data; launcher shortcuts are a static XML |

Recommended order: W1 (fix and sizes) → W3b/W3c (timetable only, cheap, the new idea) → W2 → W3a →
W4, W5. Optionally later: an Android 16 Live Update (`Notification.ProgressStyle`) for a followed trip,
in place of today's custom live card. Whether Google accepts a bus trip as a promoted Live Update is
not verified.

---

## 6. Alignment with the web spec (UI-SPEC-web-v2, Part E)

| Part E item | Proposal here |
|---|---|
| 1. No emoji, SVG icons | Same; the seated-person icon is replaced by a flag for «Πού κατεβαίνω;». |
| 2. One vehicle marker for all modes | Same; add the line number on bus dots at high zoom (finding 14). |
| 3. Position age, short form | «Ηλικία θέσης» goes under «Για προχωρημένους»; the short form «12″ / 5′07″» in cards. |
| 5. Stop card «Περνούν επίσης · N», «Όλες οι γραμμές (N) ›», no «Οι γραμμές μου» split | Same, and for bus stops too: pinned starred lines replace the split everywhere. |
| 6. Vehicle card without direction switch, «Γραμμή ›» | Same; plus the ETA as the big number (finding 3). |
| 7. Favourite stops and lines of every mode | Same; Δικά μου holds them. |
| 8. Search filters by kind and mode | Same; add Latin transliteration (finding 11). |
| 9. Deep links | Same; widgets and launcher shortcuts use them. |

---

## 7. Decisions for Harold

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | Tabs | 5 (today) / 4 (merge Αγαπημένα + Ειδοποιήσεις) / **3** (Κοντά, Διαδρομή, Δικά μου; settings behind a gear) | **3**. Each tab has one job; nothing is lost. |
| D2 | Onboarding | keep (fix the hidden step) / **remove** (map first, ask location with a reason, ask home only when needed) | **Remove**. The fastest path to value; fixes P0 #1 and #2 together. |
| D3 | «Σπίτι» | a stop (today) / **a place** (address or pin, with a default stop) | **A place**. Needed for «Γυρνάς σπίτι» via metro or another stop. |
| D4 | Alert sheet default | all options visible (today) / **one button + «Περισσότερες επιλογές»** | **One button**. Keep the preview line. |
| D5 | Stop names | as in GTFS / **restore accents** (a dictionary built once from OSM/Wikipedia names, reviewed) and cut «(προσωρινη Λογω Εργων)» to a badge | ~~Restore, backend-side~~ **Rejected by Harold (2026-10-29): too risky.** Stop names stay as in GTFS, in the backend and everywhere else. |
| D6 | Widget priority | W1 sizes first / **W3b + W3c first** (the go-home idea, timetable only) | **W1 fix, then W3b/W3c.** W1 is in users' hands already. |
| D7 | Widget origin for «Γυρνάς σπίτι» | **last saved position** / background location / fixed stop only | **Last saved position + a «Από» choice**; no background location (Play policy, a second permission). |
| D8 | Statistics screen | keep in Ρυθμίσεις › Για προχωρημένους / move to web only | **Keep, hidden**. Fix the expired-GTFS message wording either way. |

---

## Sources

- Transit GO: https://help.transitapp.com/article/549-how-to-use-go · widget: https://help.transitapp.com/article/320-add-the-transit-widget
- Transit 5.0 / 6.0: https://www.iphoneincanada.ca/2018/08/31/transit-app-gets-major-redesign/ · https://alternativeto.net/news/2025/8/transit-6-0-launches-with-new-typeface-refreshed-design-neon-dark-mode-and-new-eta-cards
- Moovit: https://moovit.com/blog/navigating-with-moovit/ · https://www.ami.ca/node/8846
- Citymapper Get Me Home (secondary): https://econsultancy.com/six-features-to-appreciate-about-citymappers-ux/
- Google Maps Home/Work shortcuts and Directions widget: https://support.google.com/maps/answer/6291823
- Busmate: https://play.google.com/store/apps/details?id=com.costascf.BusMate · https://apps.apple.com/app/id6477835676
- OASA Telematics: https://apps.apple.com/app/id1104863353
- Öffi: https://f-droid.org/en/packages/de.schildbach.oeffi
- Android widgets (update period, WorkManager): https://developer.android.com/develop/ui/views/appwidgets/advanced · sizing: https://developer.android.com/develop/ui/views/appwidgets/layouts
- Android background location: https://developer.android.com/training/location/permissions
- Android 16 progress-centric notifications: https://developer.android.com/about/versions/16/features/progress-centric-notifications

Not verified: tab layouts of Transit, Citymapper and Moovit today; Citymapper and Moovit widgets.
