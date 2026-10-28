# Rail data sources: Proastiakos (Hellenic Train) and STASY metro/tram

Research date: 2026-10-28, about 02:45-03:00 Athens time (00:45-01:00 UTC).
All probes were made with `curl` from the mini PC. Few requests per endpoint.
The Grok live-search CLI did not work this session ("Debug browser did not come
up on :9333"), so no web-search facts are in this file. Everything below was
observed directly, unless it is marked as an assumption.

Important limit: the probes ran at night. Delay fields were empty or `0`
everywhere. Whether delays fill in during the day is **not verified** (see Open
questions).

---

## 1. `ose.mpass.ltd` (station departure screens, Hellenic Train / OSE)

Base: `https://ose.mpass.ltd/api/v1`. Vue SPA at `https://ose.mpass.ltd/#/routesInfos/<screenId>`.
The SPA JS (`/js/chunk-74d90ec8.*.js`) calls only two endpoints:
`/screens/{id}/data/multilingual` and `/ose-routes/{id}`. The listing endpoints
below are not in the JS, but they answer.

### Endpoints (all GET, no auth)

| Endpoint | Result |
|---|---|
| `/screens?page=N` | Spring page. **1-based** (`page=0` gives HTTP 400 "Page index must not be less than zero!"). Page size is fixed at 10; `size=` is ignored. 27 pages, `totalElements: 265`. |
| `/screens/{internalId}` | One screen, e.g. `/screens/264` gives Αιγίνιο. |
| `/areas` | Same paging; area = station (`areaCode` = station number). |
| `/areas/{internalId}` | One area. |
| `/announcements` | Paged list; empty at probe time. |
| `/screens/{stationNo}/data/multilingual` | The board: `screen`, `announcements[]`, `routes[]` (each has `routesEl` and `routesEn`). |
| `/ose-routes/{stationNo}` | `{content:[...]}`: the same route rows, one language only. |
| `/stations` | 403. `/ose-routes` (without id): 404. |

The path id of the board is the **station number** (`identifier` = `area.areaCode`
= `STATIONAA`), not the internal `screen.id`. Example: Αιγίνιο has `id: 264` and
`identifier: 682`; use `682`.

### JSON shape (board)

```json
{"screen":{"id":15,"description":"Αεροδρόμιο","identifier":28,
  "area":{"id":258,"name":"Αεροδρόμιο","nameEl":"Αεροδρόμιο","nameEn":"AIRPORT","areaCode":28},"video":null},
 "announcements":[],
 "routes":[{"routesEl":{
   "TRENO":"1203 ","RUP":"HELLENIC TRAIN","FROMTO":"Αεροδρόμιο - Πειραιάς",
   "DR_TAFIX":null,"DR_TANA":"  5:32","DR_FORECASTED_DATE":"2026-10-28T03:32:00Z",
   "DR_PLATFORM":"4","DR_DELAY_AFIX":null,"DR_DELAY_TANA":null,"PREVIOUSDELAY":null,
   "PREVIOUSDELAY9":"0","DR_DELAYCODE":null,"DR_NEXTDAYP":null,"DROPTIONAL":null,
   "DR_STATHMOS":"ΠΑ..","DR_STATHMOSP":"Αεροδρόμιο","STATIONAA":"28",
   "PASSENGER_FREIGHTS":"PASSENGERS","DR_FREEDESC":"Message of Train 1203, "},
  "routesEn":{ "...same keys, English names..." }}]}
```

Field notes:
- `TRENO` has a trailing space. `DR_TAFIX` (arrival) / `DR_TANA` (departure) are
  local Athens time as `" H:MM"` strings with leading spaces; `null` at origin or
  terminus.
- `DR_FORECASTED_DATE` is ISO UTC (`5:32` local = `03:32Z` in winter time). In all
  samples it equalled the scheduled time, because no delay was set.
- `DR_DELAY_AFIX`, `DR_DELAY_TANA`, `PREVIOUSDELAY`, `DR_DELAYCODE` were `null`
  on every row; `PREVIOUSDELAY9` was `"0"`.
- `DR_PLATFORM` is a string (`"7"`, `"-"` when unknown).
- `RUP` is the operator. Screens 704 and 706 (Πειραιάς Κέντρο/Λιμάνι "(Metro)")
  list trains `6000`-`6006` with `RUP: "Athens Urban Transport SA"` on
  "Πειραιάς Κέντρο - Δημοτικό Θέατρο - Αεροδρόμιο". These look like the Line 3
  airport service, so this source also covers some metro trains.
- **A board has at most 5 rows** (all 8 sampled screens returned exactly 5). It is
  a "next 5 trains" view only: no full timetable.

### Headers, CORS, rate

- `access-control-allow-origin: *`, preflight OK. A Flutter web build can call it
  directly. No `Referer` is needed (it answers 200 without one).
- `cache-control: no-cache, no-store`; it sends an `ETag`.
- Slow: 1.4-1.8 s per board request. 10 requests in a row: all 200, no 429, no
  rate-limit headers.
- Unofficial: it is a vendor (mpass) backend for station screens. There are no
  terms of use and no documentation. It can change without notice.

### Athens-area screen ids (station numbers)

All 265 screens were listed. These are the Attica / suburban-network ones
(id = path id for `/screens/{id}/data/multilingual`):

| id | Station | id | Station |
|---|---|---|---|
| 1 | Αθήνα (Λαρίσης) | 2 | Πειραιάς (Suburban) |
| 27 | ΣΚΑ (Κέντρο Αχαρναί) | 488 | ΣΚΑ (Γραμμή Αθήνα - Θεσσαλονίκη) |
| 28 | Αεροδρόμιο | 15 | Κηφισίας |
| 17 | Δουκίσσης Πλακεντίας | 18 | Νερατζιώτισσα |
| 16 | Ηράκλειο | 21 | Μεταμόρφωση |
| 481 | Πεντέλης | 14 | Παλλήνη |
| 13 | Παιανία - Κάντζα | 458 | Κορωπί |
| 19 | Άνω Λιόσια | 253 | Κάτω Αχαρναί |
| 91 | Αχαρνές | 494 | Πύργος Βασιλίσσης |
| 428 | Άγιοι Ανάργυροι | 422 | Ρέντη (Άγ. Ιωάννης Ρέντης) |
| 24 | Ρουφ | 25 | Ταύρος |
| 462 | Λεύκα | 194 | Ζεφύρι |
| 437 | Ασπρόπυργος | 705 | Διυλιστήρια Ασπρόπυργου |
| 23 | Θριάσιο | 466 | Μαγούλα |
| 12 | Μέγαρα | 469 | Νέα Πέραμος |
| 456 | Κινέτα | 421 | Άγιοι Θεόδωροι |
| 451 | Ζευγολατιό Κορινθίας | 6 | Κόρινθος |
| 20 | Κιάτο | 83 | Άγιος Στέφανος |
| 149 | Δεκέλεια | 89 | Αφίδναι |
| 87 | Αυλώνα | 555 | Σφενδάλη |
| 11 | Οινόη | 412 | Οινόφυτα |
| 554 | Δήλεσι | 86 | Αυλίδα |
| 597 | Χαλκίδα | 155 | Διακλάδωση Μετρό M3 |
| 704 | Πειραιάς Κέντρο (Metro) | 706 | Πειραιάς Λιμάνι (Metro) |

Αγ. Μαρίνα (695), Αγ. Γεώργιος (605), Αγ. Θωμάς (681), Καλοχώρι-Παντείχι (228)
exist, but their line is not verified (605/681/228 are on the Χαλκίδα corridor in
railway.gov.gr). The full list is reproducible: loop `/screens?page=1..27`.

---

## 2. `railway.gov.gr` train tracker (official, Ministry / OSE)

Page: `https://railway.gov.gr/train-tracker` (Next.js app; "LIVE ΧΑΡΤΗΣ",
"Δρομολόγια" at `/schedules`). Endpoints were found in lazy webpack chunks
(`/_next/static/chunks/31267.*.js`, `82581.*.js`, `51017.*.js`, `73760.*.js`,
`47794.*.js`). All the endpoints below answered 200 **without a login or cookie**.

### Endpoints

| Endpoint | What | Size |
|---|---|---|
| `GET /api/public/corridor-stations[?category=…]` | Corridors with stations and ids | 23 KB |
| `GET /api/public/schedule-board?date=YYYY-MM-DD[&originStationId=a,b][&destinationStationId=…]` (or `origin=`/`destination=` by Greek name) | All trains of the day, with stops, status and delay | 743 KB (184 trains on 2026-10-28) |
| `GET /api/public/schedules/upcoming` | Next 100 trains | 410 KB |
| `GET /api/public/schedules/{scheduleId}` | One run | - |
| `GET /api/public/train-schedules/by-train-number/{no}` | Today's run of a train number, with `stops[]` (scheduled/actual times, `platform`, `status`, `delay`) | 10 KB |
| `GET /api/public/schedules/{scheduleId}/route-segment[?fromStationId&toStationId]` | GeoJSON `LineString` of the run (`geometrySource: "chainage"`) | - |
| `GET /api/public/stations/{stationId}` | Station details: `names{el,en}`, `osm_id`, `railway_type`, address, services, photo. **No lat/lon field.** | - |
| `GET /api/public/stations/{stationId}/departures?limit=N` and `/arrivals?limit=N` | Station board | 3.7 KB for 15 |
| `GET /api/public/schedule-telemetry/stream` (SSE) | Event `scheduleTelemetry`: per running schedule `delay`, `progress`, `speedKmh`, `nextStation(Id)`, `distanceToDestinationMeters`, `signalStatus`, `lastKnown` | - |
| `GET /api/train-stream` (SSE) | Events `trainPositionsUx` (every ~1 s, ~38 KB each, ~34 trains: `lat`, `lng`, `speed`, `course`, `scheduleId`, `trainNumber`, `delay`, `corridor`, `chainage_m`, `locomotiveNumber`), `trainHistory` (213 KB), `scheduleCards` | ~38 KB/s |
| `GET /api/public/trains/{trainId}/stream` | HLS cab-camera info | not needed |

Not public or not useful: `/api/trains`, `/api/dashboard/*`, `/api/msd/*`,
`/api/external/v1` (integration API; needs a client).

### Shapes (short)

```json
// corridor-stations
{"corridors":[{"id":"PIRAIR","name":"Πειραιάς – Αεροδρόμιο",
  "stations":[{"stationId":"6928c3c150ab5bc72b39cee6","stationIds":["6928c3c150ab5bc72b39cee6"],
               "nameGreek":"Πειραιάς","name":"Πειραιάς"}]}]}
// schedule-board -> schedules[]
{"_id":"6a947454d16c475ca144d419","scheduleNumber":"2539-20261028-0000","trainNumber":"2539",
 "serviceType":"Suburban","corridor":"CHALKIDA","status":"completed","delay":0,
 "scheduledDeparture":"2026-10-27T22:00:00.000Z","scheduledArrival":"2026-10-27T22:23:00.000Z",
 "actualDeparture":null,"actualArrival":"2026-10-27T21:41:54.000Z",
 "origin":{"nameGreek":"Χαλκίδα"},"destination":{"nameGreek":"Οινόη"},
 "routeStations":[{"stationId":"…cf14","nameGreek":"Αυλίδα","role":"stop",
   "scheduledArrival":"2026-10-27T22:11:00.000Z","scheduledDeparture":"…","index":1}],
 "routeAdjusted":false,"segment":null}
// stations/{id}/departures
{"success":true,"count":3,"departures":[{"id":"…-departure","trainNumber":"1300",
 "to":"Άγιος Ιωάννης Ρέντης (Α.Ι.Ρ)","scheduledTime":"2026-10-28T03:19:00.000Z",
 "actualTime":"2026-10-28T03:19:00.000Z","platform":null,"status":"scheduled","delay":0,
 "serviceType":"Suburban"}]}
```

Notes:
- Times are ISO UTC. `status` ∈ `scheduled|in_progress|delayed|completed|cancelled`
  (from the UI translations). `delay` is in minutes (assumption; all values were 0).
- In `departures`, `to` looked like the **next stop**, not the terminus (train 1300
  Πειραιάς→Κιάτο shows `to: "Άγιος Ιωάννης Ρέντης"` at Λεύκα). Use the schedule's
  `destination` instead.
- `departures?limit=200` at Πειραιάς returned only 35 rows (last one 22:14 local).
  It seems to cover the rest of the service day only.
- Corridors on 2026-10-28: `E85`, `ATHLIA`, `THESLAR`, `CHALKIDA` (Αθήνα–Χαλκίδα),
  `KIATO` (Πειραιάς–Κιάτο), `KIAAIGIO`, `PIRAIR` (Πειραιάς–Αεροδρόμιο, also the
  Άνω Λιόσια–Αεροδρόμιο trains), `ALEXOR`, `THESFLOR`, plus `THESSER` in the board.
  Day mix: 162 Suburban, 14 Regional, 4 InterCity, 4 Freight.
- There are no line colours and no "line names" (A1/A2/…): only corridors.
- Station names are not clean: duplicates for one id ("Πύργος Βασιλίσσης" and the
  typo "Πύργος Βαιλίσσης"; "Ρέντης" and "Άγιος Ιωάννης Ρέντης (Α.Ι.Ρ)"; two ΣΚΑ names).
  Key by `stationId`, not by name.

### Headers, CORS, rate

- **No CORS headers** (OPTIONS preflight: 204 with no `access-control-*`). A Flutter
  web build cannot call it from the browser. Android/iOS builds can (no CORS there).
- `cache-control: no-store`. **No gzip** even with `Accept-Encoding` (board = 743 KB on
  the wire). nginx; no rate-limit headers seen. Board 0.7 s, departures 0.3 s.
- Official government site, but the API is undocumented and has no terms of use. It is
  built for its own page.

### railway.gov.gr station ids (Athens suburban corridors)

| Station | stationId | Corridors |
|---|---|---|
| Πειραιάς | 6928c3c150ab5bc72b39cee6 | KIATO, PIRAIR |
| Λεύκα | 6928c3c050ab5bc72b39cd93 | KIATO, PIRAIR |
| Άγ. Ιωάννης Ρέντης / Ρέντης | 6928c3c050ab5bc72b39cd95 | KIATO, PIRAIR |
| Ταύρος | 6928c3c050ab5bc72b39cd98 | KIATO, PIRAIR |
| Ρουφ | 6928c3c150ab5bc72b39d041 | KIATO, PIRAIR |
| Αθήνα | 6928c3c150ab5bc72b39d076 | all three |
| Άγιοι Ανάργυροι | 6928c3c150ab5bc72b39cee5 | all three |
| Πύργος Βασιλίσσης | 6928c3c150ab5bc72b39cee3 | KIATO, PIRAIR |
| Κάτω Αχαρναί | 6928c3c150ab5bc72b39cee4 | KIATO, PIRAIR |
| Άνω Λιόσια | 6928c3c150ab5bc72b39cf84 | KIATO, PIRAIR |
| ΣΚΑ | 6928c3c150ab5bc72b39d077 | CHALKIDA, PIRAIR |
| Μεταμόρφωση | 6928c3c150ab5bc72b39d067 | PIRAIR |
| Ηράκλειο | 6928c3c150ab5bc72b39cfc7 | PIRAIR |
| Νερατζιώτισσα | 6928c3c150ab5bc72b39d007 | PIRAIR |
| Κηφισίας | 6928c3c050ab5bc72b39cdad | PIRAIR |
| Πεντέλης | 6928c3c150ab5bc72b39d06c | PIRAIR |
| Δουκίσσης Πλακεντίας | 6928c3c050ab5bc72b39cdca | PIRAIR |
| Παλλήνη | 6928c3c150ab5bc72b39cff3 | PIRAIR |
| Παιανία-Κάντζα | 6928c3c150ab5bc72b39cec9 | PIRAIR |
| Κορωπί | 6928c3c150ab5bc72b39d006 | PIRAIR |
| Αεροδρόμιο | 6928c3c150ab5bc72b39cec7, …ced8 | PIRAIR |
| Ζεφύρι | 6928c3c150ab5bc72b39cee2 | KIATO |
| Ασπρόπυργος | 6928c3c150ab5bc72b39cf21 | KIATO |
| Μαγούλα | 6928c3c150ab5bc72b39cfe6 | KIATO |
| Νέα Πέραμος | 6928c3c150ab5bc72b39d074 | KIATO |
| Μέγαρα | 6928c3c150ab5bc72b39cf15 | KIATO |
| Κινέτα | 6928c3c150ab5bc72b39cf2c | KIATO |
| Άγιοι Θεόδωροι | 6928c3c150ab5bc72b39cf37 | KIATO |
| Κόρινθος | 6928c3c150ab5bc72b39cf17 | KIATO |
| Ζευγολατιό | 6928c3c050ab5bc72b39cdd6 | KIATO |
| Κιάτο | 6928c3c150ab5bc72b39cf12 | KIATO |
| Αχαρναί | 6928c3c150ab5bc72b39d06b | CHALKIDA |
| Δεκέλεια | 6928c3c150ab5bc72b39cedf | CHALKIDA |
| Άγιος Στέφανος | 6928c3c050ab5bc72b39cde5 | CHALKIDA |
| Αφίδνες | 6928c3c150ab5bc72b39d073 | CHALKIDA |
| Σφενδάλη | 6928c3c050ab5bc72b39cd9b | CHALKIDA |
| Αυλώνας | 6928c3c150ab5bc72b39cf13 | CHALKIDA |
| Άγιος Θωμάς | 6928c3c150ab5bc72b39cf19 | CHALKIDA |
| Οινόη | 6928c3c050ab5bc72b39cda2 | CHALKIDA |
| Οινόφυτα | 6928c3c150ab5bc72b39cf18 | CHALKIDA |
| Δήλεσι | 6928c3c150ab5bc72b39cfe5 | CHALKIDA |
| Άγιος Γεώργιος | 6928c3c150ab5bc72b39cf4f, …cfeb | CHALKIDA |
| Καλοχώρι-Παντείχι | 6928c3c150ab5bc72b39cfe4 | CHALKIDA |
| Αυλίδα | 6928c3c150ab5bc72b39cf14 | CHALKIDA |
| Χαλκίδα | 6928c3c150ab5bc72b39cf16 | CHALKIDA |

Map to the mpass ids in section 1 by name (one-off, by hand).

---

## 3. GTFS feeds (Mobility Database / transit.land)

Checked the Mobility Database catalogue CSV (`https://files.mobilitydatabase.org/feeds_v2.csv`,
all rows with GR / Athens). transit.land was not queried directly (its API needs a key);
MDB mirrors transit.land feeds as `tld-*` ids.

| MDB id | Provider | Status | Notes |
|---|---|---|---|
| mdb-1161 | TRAINOSE | inactive | 2019 snapshot (`.../trainose/1193/20190801/gtfs.zip`). Obsolete. |
| mdb-1228 / tld-711 | OASA | deprecated / inactive | 2016-era combined feed. Obsolete. |
| mdb-3220 | OASA road (OSY) | inactive in MDB | `data.gov.gr/.../osy_gtfs.zip`. The backend already uses this. |
| mdb-3221 | OASA rail (STASY) | inactive in MDB | `data.gov.gr/.../stasy_gtfs.zip`; MDB `latest.zip` = same bytes (md5 equal). |

**There is no current GTFS or GTFS-RT for Hellenic Train or Proastiakos** in the
catalogue. railway.gov.gr (section 2) is the only full suburban timetable found.

---

## 4. STASY GTFS (metro M1-M3, tram T6/T7)

Two publication points, same dataset (organisation "ΣΥΓΚΟΙΝΩΝΙΕΣ ΑΘΗΝΩΝ"):

1. **Growthfund CKAN** (recommended, loose `.txt` files, easy to fetch):
   `https://catalog.growthfund.gr/api/3/action/package_show?id=dromologia-statheron-sygkinonion`
   - Title "Δρομολόγια Σταθερών Συγκοινωνιών (ΜΕΤΡΟ, ΗΣΑΠ, ΤΡΑΜ)", `metadata_modified`
     2026-10-06.
   - Resources (TXT, uploaded 2026-10-06): `agency.txt` (186 B), `calendar_dates.txt`
     (948 B), `stop_times.txt` (62 MB), `trips.txt` (1.8 MB), `routes.txt`, `stops.txt`
     (15.5 KB). URLs are under
     `https://catalog.growthfund.gr/dataset/a7d0a0e8-2880-46c6-b85b-b4da482bd89e/resource/<id>/download/<file>`.
   - **calendar_dates covers 2026-09-16 .. 2026-10-31. It expires in 3 days.**
2. **data.gov.gr** (CKAN API works too):
   `https://data.gov.gr/api/3/action/package_show?id=4e897a75-975a-4ce7-af65-f32ea01f93b9`
   - Resource "ΣΤΑ.ΣΥ. GTFS" is now a **RAR** (`stasy_gtfs.rar`, 2026-10-06).
   - The older `stasy_gtfs.zip` URL (the one in MDB) still answers, but it is the
     2026-07-01 .. 2026-08-31 feed: **expired**.

Content (zip from July; the October files have the same layout):
- `routes.txt`: 5 routes: `M1`, `M2`, `M3` (route_type 1), `T6`, `T7` (route_type 0).
  `route_color` empty.
- `stops.txt`: 253 stops with lat/lon; `stop_code` like `34SNF`; `parent_station` and
  `wheelchair_boarding` partly set.
- `trips.txt`: ~75k trips, with `trip_headsign`, `direction_id`. `shape_id` empty
  (no `shapes.txt`).
- `stop_times.txt`: ~1.8M rows, **real per-stop times to the second** (not
  `frequencies.txt`). So scheduled departures for every metro/tram stop are possible.
- No `calendar.txt`: one `service_id` per date in `calendar_dates.txt`.
- No `feed_info.txt`. `agency_lang` is wrongly `hi`.
- Update rhythm seen: about every 1.5-2 months, and the new file came out **after** the
  old one expired (July-Aug feed, then the Sept 16 - Oct 31 feed). Expect gaps.

No live data for metro/tram was found (no GTFS-RT, OASA telematics covers buses
only).

---

## 5. What the app and backend already have

- `https://bus.haroldpoi.dev/metro.json` (43 KB, `access-control-allow-origin: *`,
  `cache-control: max-age=600`). Keys: `source` (string), `lines[]`
  (`id`, `name`, `color`, `paths` = list of polylines), `stations[]` (`name`, `lat`,
  `lon`, `lines[]`). Line colours: M1 `#00a651`, M2 `#e30613`, M3 `#0072bc`,
  T6/T7 `#f39200`. **No timetable data and no GTFS stop ids**, so it cannot join to
  `stop_times` without a name/coordinate match. Its generator was not found in
  `athens-transit-app` or `athens-transit-rt` (the app only reads it in
  `lib/data/api.dart` and `lib/core/map_geo.dart`).
- `athens-transit-rt` (Go backend) ingests only the OSY bus GTFS
  (`internal/upstreamgtfs/upstreamgtfs.go`, `data.gov.gr/.../fb049bb1-…`) and OASA
  telematics (`internal/telematics`). There is no STASY or rail code (grep for
  `stasy`/`metro` in `*.go`: no hits). Its existing GTFS loader and calendar code
  (`internal/gtfs/load.go`, `calendar.go`) are the natural place to add STASY.

---

## RECOMMENDATION

**Proastiakos: use railway.gov.gr through the backend. Keep ose.mpass.ltd as a fallback.**

Backend (`athens-transit-rt`) should proxy and cache:
1. `corridor-stations`: fetch once a day. Build a clean station table (one name per
   `stationId`, merge the duplicates, add lat/lon from OSM via `osm_id` or from the
   route-segment geometry) and a corridor-to-colour map that we choose ourselves.
2. `schedule-board?date=today`: fetch every 5-15 min (743 KB, no gzip, so never from
   the phone). Serve a compact, gzipped per-station departures JSON.
3. `schedule-telemetry/stream` (SSE): one server-side connection. Merge `delay`,
   `status`, `nextStation` into the cached board. Optionally consume `train-stream`
   server-side for positions and serve a small snapshot (it is ~38 KB/s; never on
   the phone).
4. Fallback: if railway.gov.gr fails, call ose.mpass.ltd boards (next 5 trains,
   platforms) for the requested station, with a 30-60 s cache.

Reasons: railway.gov.gr has the full day, per-stop times, status, delay, live
telemetry and geometry. It has no CORS and no gzip, and it is unofficial, so one
cached server-side client is safer and lighter than every phone hitting it. ose.mpass
has CORS `*` and platforms, but only 5 rows per station and 1.5 s latency.

The app may call ose.mpass.ltd directly only as a quick MVP for a "next trains at
this station" card (CORS ok, small JSON). Call it on screen open, not in a tight loop.

**Metro/tram: the backend ingests the STASY GTFS. The app never downloads it.**
- Source: the Growthfund CKAN resources. Check `package_show` `metadata_modified`
  daily; reload on change.
- Serve `GET /v1/rail/stasy/stops/{stop}/departures?n=…` (next N by line and
  direction, from `stop_times` + `calendar_dates`), plus a GTFS-stop-id to
  metro.json-station mapping, or add `stop_ids` to `metro.json`.
- When the feed is expired (as on 2026-11-01 unless STASY publishes a new one), use
  the backend's existing "same weekday inside the feed" fallback. The app must label
  it "ενδεικτικά δρομολόγια", because the data is not the real timetable.

---

## Open questions

1. **Do delays fill in during the day?** Re-probe both sources at rush hour
   (e.g. 08:00 and 18:00): mpass `DR_DELAY_TANA`/`PREVIOUSDELAY` and railway.gov.gr
   `delay`, `actualTime`, `status: delayed`. Compare one train in both.
2. Unit of `delay` in railway.gov.gr (minutes assumed) and how `cancelled` appears.
3. Terms of use / rate tolerance of railway.gov.gr and ose.mpass.ltd. Is there an
   official integration (`/api/external/v1` exists, needs a client)? Worth an email
   to OSE / Hellenic Train for permission.
4. Does `schedule-board` without a date default to today in Athens time? Does it list
   all suburban trains (162/day looks plausible but is not cross-checked against the
   Hellenic Train PDF timetables)?
5. Official Proastiakos line names and colours (Hellenic Train maps). Not in any API
   probed. OSM `route=train` relations may have `colour` tags; Overpass was down
   (406/502) during this session.
6. Will STASY publish a feed for November in time? Watch the Growthfund dataset after
   2026-10-31. Is the data.gov.gr RAR the same as the Growthfund TXT files?
7. STASY stop ids vs the `metro.json` station names: build and check the join
   (Piraeus/ΗΣΑΠ names, tram stops).
8. Mpass screens 704/706 show Line 3 airport trains ("Athens Urban Transport SA").
   Are these STASY runs that are missing from the STASY GTFS?
9. Grok research could not run (CLI browser error). Repeat the web-search checks
   when it works: news on a Hellenic Train GTFS, STASY live-arrival APIs.
