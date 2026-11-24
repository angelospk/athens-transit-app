import Foundation

// Plain assertions over the Foundation-only watch logic (StaseisWatch/Shared). Run: ./run_tests.sh

var failures = 0
var checks = 0

func check(_ cond: @autoclosure () -> Bool, _ msg: String, file: String = #file, line: Int = #line) {
    checks += 1
    if !cond() {
        failures += 1
        print("FAIL \(URL(fileURLWithPath: file).lastPathComponent):\(line): \(msg)")
    }
}

func eq<T: Equatable>(_ a: T, _ b: T, _ msg: String, file: String = #file, line: Int = #line) {
    check(a == b, "\(msg): got \(a), want \(b)", file: file, line: line)
}

// MARK: Payload validation

let good = #"{"v":1,"city":"athens","favs":[{"id":"340098","name":"ΠΑΠΑΣΠΥΡΟΥ","lines":["040","137"]}]}"#
let p = FavsPayloadValidator.validate(good)
check(p != nil, "good payload accepted")
eq(p?.city, .athens, "city")
eq(p?.favs.first?.lines ?? [], ["040", "137"], "lines")
eq(p?.favs.first?.name, "ΠΑΠΑΣΠΥΡΟΥ", "name")

check(FavsPayloadValidator.validate(#"{"v":1,"city":"thessaloniki","favs":[]}"#) != nil, "empty favs accepted")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"a-1_B"}]}"#)?.favs.first?.name == "a-1_B",
      "missing name falls back to id, missing lines → all")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","lines":["Α7","Χ95","ε1","ά","Ώ","ς"]}]}"#) != nil,
      "Greek line names accepted")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","lines":["Ξ"]}],"home":{"lat":1},"x":[1,2]}"#) != nil,
      "extra keys ignored")

check(FavsPayloadValidator.validate(#"{"v":2,"city":"athens","favs":[]}"#) == nil, "bad version rejected")
check(FavsPayloadValidator.validate(#"{"v":true,"city":"athens","favs":[]}"#) == nil, "bool version rejected")
check(FavsPayloadValidator.validate(#"{"v":"1","city":"athens","favs":[]}"#) == nil, "string version rejected")
check(FavsPayloadValidator.validate(#"{"city":"athens","favs":[]}"#) == nil, "missing version rejected")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"patras","favs":[]}"#) == nil, "unknown city rejected")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"https://evil.example","favs":[]}"#) == nil, "URL as city rejected")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"Athens","favs":[]}"#) == nil, "city is case-sensitive")
for badId in ["../x", "a/b", "", "12345678901234567", "a b", "σ1", "a?b", "a%2F"] {
    let json = #"{"v":1,"city":"athens","favs":[{"id":"\#(badId)","name":"x"}]}"#
    check(FavsPayloadValidator.validate(json) == nil, "bad id rejected: \(badId)")
}
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":340098}]}"#) == nil, "numeric id rejected")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1234567890123456"}]}"#) != nil, "16-char id accepted")

let tooMany = (0..<21).map { #"{"id":"s\#($0)"}"# }.joined(separator: ",")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[\#(tooMany)]}"#) == nil, "21 favs rejected")
let twenty = (0..<20).map { #"{"id":"s\#($0)"}"# }.joined(separator: ",")
eq(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[\#(twenty)]}"#)?.favs.count, 20, "20 favs accepted")

let longName = String(repeating: "Α", count: 81)
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","name":"\#(longName)"}]}"#) == nil, "81-char name rejected")
let okName = String(repeating: "Α", count: 80)
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","name":"\#(okName)"}]}"#) != nil, "80-char name accepted")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","name":"a\u0007b"}]}"#) == nil, "control char in name rejected")
let thirteen = (0..<13).map { #""L\#($0)""# }.joined(separator: ",")
check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","lines":[\#(thirteen)]}]}"#) == nil, "13 lines rejected")
for badLine in ["123456789", "", "a b", "<b>", "Ä", "040/1"] {
    check(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1","lines":["\#(badLine)"]}]}"#) == nil,
          "bad line rejected: \(badLine)")
}
check(FavsPayloadValidator.validate("not json") == nil, "malformed rejected")
check(FavsPayloadValidator.validate("[]") == nil, "array rejected")
check(FavsPayloadValidator.validate(String(repeating: " ", count: 40_000) + good) == nil, "oversized rejected")
eq(FavsPayloadValidator.validate(#"{"v":1,"city":"athens","favs":[{"id":"1"},{"id":"1"},{"id":"2"}]}"#)?.favs.map(\.id) ?? [],
   ["1", "2"], "duplicate ids dropped")

// MARK: Arrivals decoding

let now = 1_795_540_000
let body = """
{"stop":{"id":"340098","name":" ΠΑΠΑΣΠΥΡΟΥ ","lat":37.95,"lon":23.71},
 "lines":["040","137"],
 "arrivals":[
  {"line":"137","headsign":"ΑΓ. ΙΩΑΝΝΗΣ","eta_s":720,"source":"schedule"},
  {"line":"040","headsign":"ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ","eta_s":180,"at":\(now + 180),"delay_s":1571,"source":"live","stops_away":3},
  {"headsign":"no line","eta_s":60},
  {"line":"B1"},
  {"line":"X","eta_s":99999},
  {"line":"Y","eta_s":-50},
  {"line":"Z","at":"soon","eta_s":"x"},
  {"line":"W","eta_s":"5","at":\(now + 300),"delay_s":"late"},
  17, null, "x"
 ]}
"""
let dec = ArrivalsDecoder.decode(Data(body.utf8), city: .athens, stopId: "340098", now: now)
check(dec != nil, "body decoded")
eq(dec?.name, "ΠΑΠΑΣΠΥΡΟΥ", "stop name trimmed")
eq(dec?.arrivals.map(\.line) ?? [], ["Y", "040", "W", "137", "X"], "skips without line/time, sorted by time")
eq(dec?.arrivals.first(where: { $0.line == "X" })?.at, now + 7200, "eta clamped to 7200")
eq(dec?.arrivals.first(where: { $0.line == "Y" })?.at, now, "negative eta clamped to 0")
eq(dec?.arrivals.first(where: { $0.line == "040" })?.live, true, "live source")
eq(dec?.arrivals.first(where: { $0.line == "040" })?.delay, 1571, "delay kept")
eq(dec?.arrivals.first(where: { $0.line == "W" })?.delay, nil, "bad-type delay → missing")
eq(dec?.arrivals.first(where: { $0.line == "137" })?.at, now + 720, "eta → at")

let farAt = ArrivalsDecoder.decode(Data(#"{"arrivals":[{"line":"1","at":\#(now + 50_000)}]}"#.utf8), city: .athens, stopId: "1", now: now)
eq(farAt?.arrivals.first?.at, now + 7200, "far at clamped")
let empty = ArrivalsDecoder.decode(Data("{}".utf8), city: .athens, stopId: "1", now: now)
check(empty != nil && empty!.arrivals.isEmpty && empty!.name == nil, "empty object → no arrivals")
check(ArrivalsDecoder.decode(Data(#"{"arrivals":"nope","stop":5}"#.utf8), city: .athens, stopId: "1", now: now)?.arrivals.isEmpty == true,
      "wrong-type fields tolerated")
check(ArrivalsDecoder.decode(Data("{\"arrivals\":[".utf8), city: .athens, stopId: "1", now: now) == nil, "malformed JSON → nil")
check(ArrivalsDecoder.decode(Data("[1,2]".utf8), city: .athens, stopId: "1", now: now) == nil, "array root → nil")
check(ArrivalsDecoder.decode(Data(), city: .athens, stopId: "1", now: now) == nil, "empty body → nil")
check(ArrivalsDecoder.decode(Data(repeating: 0x20, count: 256 * 1024 + 1), city: .athens, stopId: "1", now: now) == nil, "over cap → nil")

// MARK: Minutes formatting

eq(ArrivalFormat.minutesText(at: now + 44, now: now, nowWord: "τώρα"), "τώρα", "44 s → now")
eq(ArrivalFormat.minutesText(at: now + 45, now: now, nowWord: "τώρα"), "1′", "45 s → 1′")
eq(ArrivalFormat.minutesText(at: now + 89, now: now, nowWord: "now"), "1′", "89 s → 1′")
eq(ArrivalFormat.minutesText(at: now + 90, now: now, nowWord: "now"), "2′", "90 s → 2′")
eq(ArrivalFormat.minutesText(at: now + 720, now: now, nowWord: "now"), "12′", "720 s → 12′")
eq(ArrivalFormat.minutesText(at: now - 100, now: now, nowWord: "now"), "now", "past → now")
eq(ArrivalFormat.secondsUntil(now - 5, now: now), 0, "max(0, at-now)")

eq(ArrivalFormat.delayLevel(nil), .none, "missing delay")
eq(ArrivalFormat.delayLevel(-600), .none, "early → nothing")
eq(ArrivalFormat.delayLevel(-60), .none, "−60 → nothing")
eq(ArrivalFormat.delayLevel(90), .none, "90 → nothing")
eq(ArrivalFormat.delayLevel(300), .none, "300 → nothing")
eq(ArrivalFormat.delayLevel(301), .worse(minutes: 5), "301 → amber +5′")
eq(ArrivalFormat.delayLevel(600), .worse(minutes: 10), "600 → amber +10′")
eq(ArrivalFormat.delayLevel(601), .muchWorse(minutes: 10), "601 → red")
eq(ArrivalFormat.delayLevel(1571), .muchWorse(minutes: 26), "1571 → red +26′")
eq(ArrivalFormat.delayText(.worse(minutes: 7)), "+7′", "delay text")
eq(ArrivalFormat.delayText(.none), nil, "no delay text")

let arr = [
    Arrival(line: "040", headsign: "", at: now + 180, delay: nil, live: true),
    Arrival(line: "B1", headsign: "", at: now + 200, delay: nil, live: false),
    Arrival(line: "137", headsign: "", at: now + 720, delay: nil, live: false),
    Arrival(line: "040", headsign: "", at: now + 900, delay: nil, live: false),
]
eq(ArrivalFormat.summary(arr, lines: ["040", "137"], now: now, nowWord: "τώρα"), "040\u{00A0}3′ · 137\u{00A0}12′", "summary, chosen lines")
eq(ArrivalFormat.summary(arr, lines: [], now: now, nowWord: "τώρα"), "040\u{00A0}3′ · B1\u{00A0}3′", "summary, all lines")
eq(ArrivalFormat.summary(arr, lines: ["999"], now: now, nowWord: "τώρα"), "", "summary, none")
eq(ArrivalFormat.summary(arr, lines: ["b1"], now: now, nowWord: "τώρα"), "B1\u{00A0}3′", "line match ignores case")

eq(ArrivalFormat.distanceText(118), "120 m", "distance rounding")
eq(ArrivalFormat.distanceText(2), "10 m", "distance minimum")

// MARK: Freshness and back-off

eq(FreshnessRule.freshness(fetchedAt: now - 60, lastRequestFailed: false, now: now), .fresh, "fresh")
eq(FreshnessRule.freshness(fetchedAt: now - 60, lastRequestFailed: true, now: now), .offline, "offline")
eq(FreshnessRule.freshness(fetchedAt: now - 1201, lastRequestFailed: true, now: now), .none, "older than 20 min")
eq(FreshnessRule.freshness(fetchedAt: nil, lastRequestFailed: false, now: now), .none, "nothing")

var b = Backoff()
check(b.allows(now: now), "back-off starts open")
b.fail(now: now); check(!b.allows(now: now + 29) && b.allows(now: now + 30), "30 s")
b.fail(now: now); check(!b.allows(now: now + 59) && b.allows(now: now + 60), "60 s")
b.fail(now: now); check(!b.allows(now: now + 119) && b.allows(now: now + 120), "120 s")
b.fail(now: now); check(b.allows(now: now + 120), "capped at 120 s")
b.succeed(); check(b.allows(now: now), "reset on success")

// MARK: Nearest stops and city boxes

let syntagma = (lat: 37.9755, lon: 23.7348)
let stops = [
    StopEntry(id: "far", name: "Far", lat: 37.9900, lon: 23.7348),     // ~1.6 km
    StopEntry(id: "c", name: "C", lat: 37.9780, lon: 23.7348),         // ~278 m
    StopEntry(id: "a", name: "A", lat: 37.9756, lon: 23.7348),         // ~11 m
    StopEntry(id: "edge", name: "Edge", lat: 37.9845, lon: 23.7348),   // ~1001 m
    StopEntry(id: "b", name: "B", lat: 37.9755, lon: 23.7368),         // ~176 m
    StopEntry(id: "d", name: "D", lat: 37.9700, lon: 23.7348),         // ~612 m
    StopEntry(id: "e", name: "E", lat: 37.9755, lon: 23.7448),         // ~879 m
    StopEntry(id: "f", name: "F", lat: 37.9800, lon: 23.7348),         // ~500 m
]
let near = NearestStops.nearest(stops, lat: syntagma.lat, lon: syntagma.lon)
eq(near.map(\.stop.id), ["a", "b", "c", "f", "d"], "5 nearest, ordered")
check(near.allSatisfy { $0.meters <= 1000 }, "within 1 km")
eq(NearestStops.nearest(stops, lat: syntagma.lat, lon: syntagma.lon, limit: 10).map(\.stop.id),
   ["a", "b", "c", "f", "d", "e"], "1 km cut drops far and edge")
check(NearestStops.nearest(stops, lat: 40.64, lon: 22.94).isEmpty, "nothing near Thessaloniki")
let d1 = NearestStops.haversine(lat1: 37.9755, lon1: 23.7348, lat2: 40.6401, lon2: 22.9444)
check(abs(d1 - 302_000) < 5_000, "Athens–Thessaloniki ≈ 302 km (\(Int(d1)))")

eq(City.containing(lat: 37.9755, lon: 23.7348), .athens, "Syntagma in Athens")
eq(City.containing(lat: 40.6401, lon: 22.9444), .thessaloniki, "Aristotelous in Thessaloniki")
eq(City.containing(lat: 38.2466, lon: 21.7346), nil, "Patras outside both")
eq(City.containing(lat: 39.0, lon: 23.0), nil, "between boxes")
eq(City.containing(lat: 37.5, lon: 22.9), .athens, "box edge inclusive")
eq(City.athens.stopURL(id: "340098")?.absoluteString, "https://transit.haroldpoi.dev/v1/stops/340098", "stop URL")
eq(City.thessaloniki.stopURL(id: "../x"), nil, "bad id → no URL")

// MARK: Stop index

let trips = #"{"v":"2026-11-20","s":[["ΣΥΝΤΑΓΜΑ",37.9755,23.7348,"400010"],["NUM",37.1,23.1,12345],["BAD",91,0,"x"],["EVIL",37,23,"../a"],["SHORT",1],"junk"],"l":[[1,2]],"d":{"a":1}}"#
let idx = StopIndexParser.parseTrips(Data(trips.utf8))
eq(idx?.map(\.id) ?? [], ["400010", "12345"], "index keeps valid rows only")
let compact = idx.flatMap(StopIndexParser.encodeCompact)
eq(compact.flatMap(StopIndexParser.decodeCompact), idx, "compact round trip")
check(StopIndexParser.parseTrips(Data("{\"s\":5}".utf8)) == nil, "bad index → nil")
eq(idx?.map(\.lines) ?? [], [[], []], "no l → no lines")

// Lines from `l` (line → variant → indices into `s`).
let tripsL = #"""
{"v":"x","s":[["ΣΥΝΤΑΓΜΑ",37.9755,23.7348,"A1"],["ΣΥΝΤΑΓΜΑ",37.9757,23.7349,"A2"],["ΣΥΝΤΑΓΜΑ",37.9760,23.7350,"A3"],["FAR",38.2,23.9,"Z"]],
 "l":{"11":{"v1":[0,1],"v2":[1]},"2":{"a":[0]},"1":{"a":[0,2]},"4":{"a":[0]},"Α7":{"a":[0]},"040":{"a":[0,1]},"Χ95":{"a":[0]},
      "bad line!":{"a":[2]},"9":{"a":[99,-1,1.5,true,"0"]},"8":"junk","7":{"a":"junk"}}}
"""#
let withLines = StopIndexParser.parseTrips(Data(tripsL.utf8))
eq(withLines?.first?.lines ?? [], ["1", "2", "4", "11", "040", "Α7", "Χ95"], "lines sorted naturally")
eq(withLines?[1].lines ?? [], ["11", "040"], "lines deduplicated across variants")
eq(withLines?[2].lines ?? [], ["1"], "invalid line ids and bad indices skipped")
eq(withLines?[3].lines ?? [], [], "stop without lines")
let nearL = NearestStops.nearest(withLines ?? [], lat: 37.9755, lon: 23.7348)
eq(nearL.map(\.stop.id), ["A1", "A2", "A3"], "nearest with lines, ordered")
eq(nearL.first?.stop.lines.count, 7, "nearest stops carry their lines")
eq(ArrivalFormat.linesText(nearL[0].stop.lines), "1, 2, 4, 11\u{00A0}+3", "lines text with +N (no-break space)")
eq(ArrivalFormat.linesText(["1", "2"]), "1, 2", "short lines text")
eq(ArrivalFormat.linesText([]), "", "no lines text")
eq("\(ArrivalFormat.distanceText(nearL[0].meters)) · \(ArrivalFormat.linesText(nearL[0].stop.lines))", "10 m · 1, 2, 4, 11\u{00A0}+3", "row text")
for badL in [#""l":5"#, #""l":[[1,2]]"#, #""l":{"1":[0]}"#, #""l":null"#, #""l":{"1":{"a":{"b":0}}}"#] {
    let j = #"{"s":[["A",37.9,23.7,"A1"]],\#(badL)}"#
    let r = StopIndexParser.parseTrips(Data(j.utf8))
    check(r?.count == 1 && r?.first?.lines == [], "malformed l → no lines: \(badL)")
}
let compactL = withLines.flatMap(StopIndexParser.encodeCompact)
eq(compactL.flatMap(StopIndexParser.decodeCompact), withLines, "compact round trip keeps lines")
let oldFormat = try! JSONSerialization.data(withJSONObject: [["ΣΥΝΤΑΓΜΑ", 37.9755, 23.7348, "A1"]])
check(StopIndexParser.decodeCompact(oldFormat) == nil, "old cache format → rebuilt")
check(StopIndexParser.decodeCompact(Data(#"{"f":1,"s":[["A",37.9,23.7,"A1"]]}"#.utf8)) == nil, "other format number → rebuilt")

// MARK: Complication timeline

let cached = StopArrivals(city: .athens, stopId: "340098", name: "ΠΑΠΑΣΠΥΡΟΥ", arrivals: arr, fetchedAt: now)
let slots = ComplicationTimeline.slots(cached, lines: ["040", "137"], now: now, nowWord: "τώρα")
eq(slots.first?.line, "040", "first slot → next bus")
eq(slots.first?.minutes, "3′", "first slot minutes")
eq(slots.first(where: { $0.date == now + 240 })?.line, "137", "after the first bus leaves, the next one")
eq(slots.last?.line, nil, "ends with —")
check(slots.last!.date <= now + 20 * 60, "— by 20 min")
check(zip(slots, slots.dropFirst()).allSatisfy { $0.date < $1.date }, "dates increase")
let old = StopArrivals(city: .athens, stopId: "1", name: nil, arrivals: arr, fetchedAt: now - 1300)
eq(ComplicationTimeline.slots(old, lines: [], now: now, nowWord: "now").map(\.line), [nil], "old data → —")
eq(ComplicationTimeline.slots(nil, lines: [], now: now, nowWord: "now").map(\.line), [nil], "no data → —")

// MARK: Shared store

let suite = "staseis.watch.tests.\(getpid())"
let ud = UserDefaults(suiteName: suite)!
let store = SharedStore(defaults: ud)
check(store.favs == nil, "store starts empty")
check(store.saveFavs(p!), "first save changes")
check(!store.saveFavs(p!), "same save does not change")
eq(store.favs, p, "favs round trip")
store.saveArrivals(cached)
eq(store.arrivals(city: .athens, stopId: "340098"), cached, "arrivals round trip")
eq(store.arrivals(city: .thessaloniki, stopId: "340098"), nil, "arrivals keyed by city")
ud.removePersistentDomain(forName: suite)

print("\(checks - failures)/\(checks) checks passed")
exit(failures == 0 ? 0 : 1)
