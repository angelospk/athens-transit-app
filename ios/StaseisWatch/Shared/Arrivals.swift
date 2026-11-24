import Foundation

/// One arrival, normalised: `at` is a Unix time in seconds, so a cached answer stays right.
struct Arrival: Codable, Equatable, Sendable {
    let line: String
    let headsign: String
    let at: Int
    let delay: Int?
    let live: Bool
}

/// A stop's answer as the watch keeps it (also in the App Group cache for the complication).
struct StopArrivals: Codable, Equatable, Sendable {
    let city: City
    let stopId: String
    let name: String?
    let arrivals: [Arrival]
    /// When the answer was received (Unix seconds).
    let fetchedAt: Int
}

/// Decodes `GET /v1/stops/{id}`. Every field is optional and a wrong type counts as missing.
enum ArrivalsDecoder {
    static let maxBodyBytes = 256 * 1024
    static let maxEta = 7200
    static let maxArrivals = 40

    private struct Root: Decodable {
        let stop: StopInfo?
        let arrivals: [Lossy]?

        enum CodingKeys: String, CodingKey { case stop, arrivals }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            stop = try? c.decodeIfPresent(StopInfo.self, forKey: .stop)
            arrivals = try? c.decodeIfPresent([Lossy].self, forKey: .arrivals)
        }
    }

    private struct StopInfo: Decodable {
        let id: String?
        let name: String?

        enum CodingKeys: String, CodingKey { case id, name }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try? c.decodeIfPresent(String.self, forKey: .id)
            name = try? c.decodeIfPresent(String.self, forKey: .name)
        }
    }

    /// An element that never throws, so one bad arrival does not sink the list.
    private struct Lossy: Decodable {
        let line: String?
        let headsign: String?
        let etaS: Double?
        let at: Double?
        let delayS: Double?
        let source: String?

        enum CodingKeys: String, CodingKey {
            case line, headsign, at, source
            case etaS = "eta_s"
            case delayS = "delay_s"
        }

        init(from decoder: Decoder) throws {
            guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
                line = nil; headsign = nil; etaS = nil; at = nil; delayS = nil; source = nil
                return
            }
            line = try? c.decodeIfPresent(String.self, forKey: .line)
            headsign = try? c.decodeIfPresent(String.self, forKey: .headsign)
            etaS = try? c.decodeIfPresent(Double.self, forKey: .etaS)
            at = try? c.decodeIfPresent(Double.self, forKey: .at)
            delayS = try? c.decodeIfPresent(Double.self, forKey: .delayS)
            source = try? c.decodeIfPresent(String.self, forKey: .source)
        }
    }

    /// nil on a body over the cap or a body that is not a JSON object ("no data", never a crash).
    static func decode(_ data: Data, city: City, stopId: String, now: Int) -> StopArrivals? {
        guard data.count <= maxBodyBytes else { return nil }
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else { return nil }

        var out: [Arrival] = []
        for a in root.arrivals ?? [] {
            let line = (a.line ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, line.count <= 16 else { continue }
            let at: Int
            if let raw = a.at, raw.isFinite {
                at = min(max(Int(raw), now - 60), now + maxEta)
            } else if let eta = a.etaS, eta.isFinite {
                at = now + min(max(Int(eta), 0), maxEta)
            } else {
                continue
            }
            let delay: Int? = a.delayS.flatMap { $0.isFinite ? Int(max(min($0, 86_400), -86_400)) : nil }
            let headsign = String((a.headsign ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
            out.append(Arrival(line: line, headsign: headsign, at: at, delay: delay, live: a.source == "live"))
        }
        out.sort { $0.at < $1.at }
        if out.count > maxArrivals { out.removeLast(out.count - maxArrivals) }

        let name = root.stop?.name.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80)) }
        return StopArrivals(city: city, stopId: stopId, name: name?.isEmpty == true ? nil : name,
                            arrivals: out, fetchedAt: now)
    }
}

// MARK: - Formatting (pure; the caller passes the localized words)

enum DelayLevel: Equatable, Sendable {
    case none
    /// > +300 s: amber.
    case worse(minutes: Int)
    /// > +600 s: red.
    case muchWorse(minutes: Int)
}

enum ArrivalFormat {
    /// The agreed levels (QUALITY.md, "Live vehicle level, sparse"): −60…+300 s, earlier, or missing → nothing.
    static func delayLevel(_ delay: Int?) -> DelayLevel {
        guard let d = delay else { return .none }
        let minutes = Int((Double(d) / 60).rounded())
        if d > 600 { return .muchWorse(minutes: minutes) }
        if d > 300 { return .worse(minutes: minutes) }
        return .none
    }

    static func delayText(_ level: DelayLevel) -> String? {
        switch level {
        case .none: return nil
        case .worse(let m), .muchWorse(let m): return "+\(m)′"
        }
    }

    static func secondsUntil(_ at: Int, now: Int) -> Int { max(0, at - now) }

    /// «τώρα» under 45 s, else `N′` rounded to minutes.
    static func minutesText(at: Int, now: Int, nowWord: String) -> String {
        let s = secondsUntil(at, now: now)
        if s < 45 { return nowWord }
        return "\(Int((Double(s) / 60).rounded()))′"
    }

    /// An arrival stays on screen until 30 s after its time.
    static func isUpcoming(_ a: Arrival, now: Int) -> Bool { a.at >= now - 30 }

    static func matches(_ a: Arrival, lines: [String]) -> Bool {
        lines.isEmpty || lines.contains { $0.uppercased() == a.line.uppercased() }
    }

    /// The next `count` arrivals for the chosen lines (empty → all).
    static func next(_ arrivals: [Arrival], lines: [String], now: Int, count: Int) -> [Arrival] {
        Array(arrivals.filter { isUpcoming($0, now: now) && matches($0, lines: lines) }.prefix(count))
    }

    /// `040 3′ · 137 12′` (a no-break space keeps each line with its minutes when the text wraps)
    static func summary(_ arrivals: [Arrival], lines: [String], now: Int, nowWord: String) -> String {
        next(arrivals, lines: lines, now: now, count: 2)
            .map { "\($0.line)\u{00A0}\(minutesText(at: $0.at, now: now, nowWord: nowWord))" }
            .joined(separator: " · ")
    }

    /// `1, 2, 4, 11 +3`: the first `max` lines, then how many more (kept on the last id's line by a no-break space).
    static func linesText(_ lines: [String], max: Int = 4) -> String {
        guard !lines.isEmpty else { return "" }
        let head = lines.prefix(max).joined(separator: ", ")
        return lines.count > max ? "\(head)\u{00A0}+\(lines.count - max)" : head
    }

    /// `120 m`, to 10 m, at least 10 m.
    static func distanceText(_ meters: Double) -> String {
        "\(max(10, Int((meters / 10).rounded()) * 10)) m"
    }
}

// MARK: - Freshness

enum Freshness: Equatable, Sendable {
    /// The last request worked.
    case fresh
    /// The last request failed; the cached rows are shown dimmed.
    case offline
    /// Nothing, or data older than 20 min.
    case none
}

enum FreshnessRule {
    static let maxAge = 20 * 60

    static func freshness(fetchedAt: Int?, lastRequestFailed: Bool, now: Int) -> Freshness {
        guard let t = fetchedAt, now - t <= maxAge else { return .none }
        return lastRequestFailed ? .offline : .fresh
    }
}

// MARK: - Back-off

/// One request in flight per stop; after failures wait 30 → 60 → 120 s.
struct Backoff: Sendable, Equatable {
    static let steps = [30, 60, 120]
    private(set) var failures = 0
    private(set) var notBefore = 0

    mutating func fail(now: Int) {
        notBefore = now + Self.steps[min(failures, Self.steps.count - 1)]
        failures += 1
    }

    mutating func succeed() {
        failures = 0
        notBefore = 0
    }

    func allows(now: Int) -> Bool { now >= notBefore }
}
