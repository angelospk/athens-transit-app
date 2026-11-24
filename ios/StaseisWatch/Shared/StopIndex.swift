import Foundation

struct StopEntry: Equatable, Sendable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
    /// The line ids that serve the stop, sorted (from `l`); empty when unknown.
    var lines: [String] = []
}

struct NearbyStop: Equatable, Sendable {
    let stop: StopEntry
    let meters: Double
}

/// `trips.json` is `{"v":..., "s":[[name,lat,lon,id],...], "l":{line:{variant:[index into s,...]}}, "d":...}`.
/// The watch keeps `s` plus, per stop, the sorted ids of the lines from `l`.
enum StopIndexParser {
    static let maxDownloadBytes = 4 * 1024 * 1024
    static let maxStops = 30_000
    /// The compact cache format; a file in another format is ignored and rebuilt.
    static let compactFormat = 2

    /// Reads `s` and `l` from the full `trips.json`. A malformed `l` only means no lines.
    static func parseTrips(_ data: Data) -> [StopEntry]? {
        guard data.count <= maxDownloadBytes,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let s = obj["s"] as? [Any] else { return nil }
        let lines = linesByStop(obj["l"], stopCount: min(s.count, maxStops))
        return entries(from: s, lines: lines)
    }

    /// stop index → sorted line ids.
    static func linesByStop(_ l: Any?, stopCount: Int) -> [Int: [String]] {
        guard let byLine = l as? [String: Any] else { return [:] }
        var sets: [Int: Set<String>] = [:]
        for (line, variants) in byLine {
            guard Validation.isLine(line), let v = variants as? [String: Any] else { continue }
            for (_, stops) in v {
                guard let idx = stops as? [Any] else { continue }
                for i in idx {
                    guard let n = i as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { continue }
                    let k = n.intValue
                    if k >= 0 && k < stopCount && Double(k) == n.doubleValue { sets[k, default: []].insert(line) }
                }
            }
        }
        return sets.mapValues(sortLines)
    }

    /// Natural order: 1, 2, 11, 040, Α7, Β2…
    static func sortLines(_ lines: Set<String>) -> [String] {
        lines.sorted { $0.compare($1, options: [.numeric, .caseInsensitive]) == .orderedAscending }
    }

    /// The compact local file: `{"f":2,"s":[[name,lat,lon,id,[lines]],...]}`.
    static func encodeCompact(_ stops: [StopEntry]) -> Data? {
        let rows: [[Any]] = stops.map { [$0.name, $0.lat, $0.lon, $0.id, $0.lines] }
        return try? JSONSerialization.data(withJSONObject: ["f": compactFormat, "s": rows] as [String: Any])
    }

    /// nil for a file in an older format (it is then downloaded again).
    static func decodeCompact(_ data: Data) -> [StopEntry]? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (obj["f"] as? Int) == compactFormat,
              let s = obj["s"] as? [Any] else { return nil }
        var lines: [Int: [String]] = [:]
        for (i, row) in s.prefix(maxStops).enumerated() {
            if let r = row as? [Any], r.count >= 5, let ls = r[4] as? [String] {
                let ok = ls.filter(Validation.isLine)
                if !ok.isEmpty { lines[i] = ok }
            }
        }
        return entries(from: s, lines: lines)
    }

    private static func entries(from s: [Any], lines: [Int: [String]]) -> [StopEntry]? {
        var out: [StopEntry] = []
        out.reserveCapacity(min(s.count, maxStops))
        for (i, row) in s.prefix(maxStops).enumerated() {
            guard let r = row as? [Any], r.count >= 4,
                  let name = r[0] as? String,
                  let lat = (r[1] as? NSNumber)?.doubleValue,
                  let lon = (r[2] as? NSNumber)?.doubleValue,
                  lat.isFinite, lon.isFinite, abs(lat) <= 90, abs(lon) <= 180 else { continue }
            // The id goes into a URL path: only valid ids are kept.
            let id: String
            if let sid = r[3] as? String { id = sid } else if let nid = r[3] as? NSNumber { id = nid.stringValue } else { continue }
            guard Validation.isStopId(id) else { continue }
            out.append(StopEntry(id: id, name: String(name.prefix(80)), lat: lat, lon: lon, lines: lines[i] ?? []))
        }
        return out.isEmpty ? nil : out
    }
}

enum NearestStops {
    static let earthRadius = 6_371_000.0

    static func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = Double.pi / 180
        let dLat = (lat2 - lat1) * r
        let dLon = (lon2 - lon1) * r
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * r) * cos(lat2 * r) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(a)))
    }

    /// The `limit` nearest stops within `maxMeters`, nearest first.
    static func nearest(_ stops: [StopEntry], lat: Double, lon: Double, limit: Int = 5, maxMeters: Double = 1000) -> [NearbyStop] {
        var found: [NearbyStop] = []
        for s in stops {
            let d = haversine(lat1: lat, lon1: lon, lat2: s.lat, lon2: s.lon)
            if d <= maxMeters { found.append(NearbyStop(stop: s, meters: d)) }
        }
        found.sort { $0.meters < $1.meters }
        return Array(found.prefix(limit))
    }
}
