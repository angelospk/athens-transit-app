# Watch apps (Wear OS, Apple Watch)

Two native watch apps live next to the phone app: `android/wear` (Kotlin, Compose for Wear OS) and
`ios/StaseisWatch` + `ios/StaseisWatchWidgets` (SwiftUI, WidgetKit). They share no code with Flutter.

## Decision: standalone for data, the phone only syncs favourites

- **The watch fetches the arrivals itself** from `GET {api}/v1/stops/{id}` (server-computed live
  arrivals, both cities; Cloudflare caches it for 15 s, so watch traffic does not reach OASA). It works
  on the watch's own Wi‑Fi/LTE, with the phone away or off.
- **The phone sends only the favourite stops** (`lib/background/watch_sync.dart`): Android through the
  Wearable Data Layer (`MainActivity.kt`, DataItem `/staseis/favs`), iOS through WatchConnectivity
  (`AppDelegate.swift`, `updateApplicationContext`). The phone app works as before without a watch.
- **Nearest stops** are computed on the watch from the stop index (`staseis.gr/trips.json`, only the
  `s` array is kept, refreshed weekly with ETag). The position never leaves the watch; only the stop id
  being looked at goes to the server, as with the phone.
- **Alerts** ("the bus is coming") reach the watch through the system: Android bridges phone
  notifications that are not local-only to Wear OS; iOS mirrors iPhone notifications to the Watch when
  the iPhone is locked. The ongoing live card stays on the phone (Android does not bridge ongoing
  notifications).

Why not companion-only (the phone fetches and relays)? It breaks when the phone is away, doubles the
battery cost (two radios), and needs much more sync code on both platforms. Why not the phone's own ETA
engine (`lib/core/eta.dart`)? It needs per-line shapes and live vehicles; the backend already computes
the same arrivals per stop.

## Payload (phone → watch), version 1

```json
{"v":1,"city":"athens","favs":[{"id":"340098","name":"ΠΑΠΑΣΠΥΡΟΥ","lines":["040","137"]}]}
```

`id` is the GTFS stop id from the stop index (`stopIdOf`: same name within 200 m). At most 20 stops,
12 lines each. No home/work places, no coordinates. The watches treat it as untrusted (version, city
enum, id/name/line patterns and lengths) and keep the previous list on any error.

## Refresh and battery

- Stop screen: on appear, then every 30 s while visible; stops in ambient/background. Back-off 30 → 60 →
  120 s after failures.
- Favourites list: every 60 s, at most 4 visible stops, 2 requests at a time.
- Tile / complication: ~15 min, from cache, with entries from the next arrivals' times so the minutes roll
  without a fetch; `—` after the last known arrival or when the data is older than 20 min.

## Security and privacy

HTTPS only (Wear: cleartext off + network security config; watchOS: no ATS exceptions, ephemeral
URLSession). Hosts are hardcoded; the synced city is an enum, never a URL. Wear permissions: INTERNET and
location (asked only on the Nearby screen); no background location, no boot, no notifications
permission. watchOS: location "when in use"; each watch target has its own `PrivacyInfo.xcprivacy`. No
accounts, analytics, crash SDKs or device ids. Delay badges follow the levels in the backend's
`docs/QUALITY.md` (sparse vehicle level: > 300 s worse, > 600 s much worse).

## Ids

| | id |
|---|---|
| iPhone app (unchanged, iPhone-only) | `gr.staseis.app` |
| Watch app | `gr.staseis.app.watchkitapp` |
| Watch widgets | `gr.staseis.app.watchkitapp.widgets` |
| App Group (watch app ↔ widgets) | `group.gr.staseis.app` |
| Wear OS | `gr.staseis.app` (same as the phone: the Data Layer needs the same package and signing key; `.dev` with `-P staging=true`) |
