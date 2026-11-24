import Foundation

/// What one complication entry shows.
struct ComplicationSlot: Equatable, Sendable {
    let date: Int
    /// nil → `—`.
    let line: String?
    let minutes: String?
    let at: Int?
}

/// Builds the complication's entries from cached arrivals so the minutes roll without a fetch.
/// One entry a minute until the last known arrival has gone (or the data is 20 min old), then `—`.
enum ComplicationTimeline {
    static let maxEntries = 30

    static func slots(_ data: StopArrivals?, lines: [String], now: Int, nowWord: String) -> [ComplicationSlot] {
        guard let data else { return [ComplicationSlot(date: now, line: nil, minutes: nil, at: nil)] }
        let pool = ArrivalFormat.next(data.arrivals, lines: lines, now: now, count: 3)
        let staleAt = data.fetchedAt + FreshnessRule.maxAge
        guard let last = pool.last, now < staleAt else {
            return [ComplicationSlot(date: now, line: nil, minutes: nil, at: nil)]
        }
        let end = min(staleAt, last.at + 30)
        var out: [ComplicationSlot] = []
        var t = now
        while t < end && out.count < maxEntries {
            if let a = pool.first(where: { ArrivalFormat.isUpcoming($0, now: t) }) {
                out.append(ComplicationSlot(date: t, line: a.line,
                                            minutes: ArrivalFormat.minutesText(at: a.at, now: t, nowWord: nowWord),
                                            at: a.at))
            } else {
                break
            }
            t += 60
        }
        out.append(ComplicationSlot(date: max(end, out.last.map { $0.date + 1 } ?? now), line: nil, minutes: nil, at: nil))
        return out
    }
}
