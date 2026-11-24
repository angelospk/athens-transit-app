import Foundation
import os

/// The App Group defaults shared by the watch app and the complication extension:
/// the synced favourites and the last arrivals per stop. Nothing personal beyond stop ids.
///
/// The app and the extension are two processes, so there is no read-modify-write of a shared blob:
/// each stop's arrivals live under their own key (`watch.arrivals.v1.<city>/<id>`), a write touches
/// only its own key, and pruning only removes entries that are stale (> 1 h) or beyond the newest 24.
final class SharedStore: @unchecked Sendable {
    static let appGroup = "group.gr.staseis.app"
    static let shared = SharedStore()

    private static let log = Logger(subsystem: "gr.staseis.app.watch", category: "store")
    private static let favsKey = "watch.favs.v1"
    static let arrivalsPrefix = "watch.arrivals.v1."
    /// The single-blob cache of the first build; removed on the next write.
    private static let legacyArrivalsKey = "watch.arrivals.v1"
    static let maxCachedStops = 24
    static let maxAge = 3600

    private let defaults: UserDefaults
    private let lock = NSLock()

    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup) != nil,
                  let group = UserDefaults(suiteName: Self.appGroup) {
            self.defaults = group
        } else {
            // The App Group is not registered or not in the signature: the app still works on its own,
            // but the complication cannot see the favourites. Logged once per process.
            Self.log.error("App Group \(Self.appGroup, privacy: .public) unavailable; using standard defaults (complication will not share data)")
            self.defaults = .standard
        }
    }

    var favs: FavsPayload? {
        guard let data = defaults.data(forKey: Self.favsKey) else { return nil }
        return try? JSONDecoder().decode(FavsPayload.self, from: data)
    }

    /// Returns true when the favourites changed.
    @discardableResult
    func saveFavs(_ payload: FavsPayload) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if favs == payload { return false }
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        defaults.set(data, forKey: Self.favsKey)
        return true
    }

    static func key(_ city: City, _ id: String) -> String { "\(arrivalsPrefix)\(city.rawValue)/\(id)" }

    func arrivals(city: City, stopId: String) -> StopArrivals? {
        guard let data = defaults.data(forKey: Self.key(city, stopId)) else { return nil }
        return try? JSONDecoder().decode(StopArrivals.self, from: data)
    }

    func saveArrivals(_ a: StopArrivals) {
        lock.lock(); defer { lock.unlock() }
        guard let data = try? JSONEncoder().encode(a) else { return }
        defaults.set(data, forKey: Self.key(a.city, a.stopId))
        defaults.removeObject(forKey: Self.legacyArrivalsKey)
        prune(now: a.fetchedAt)
    }

    /// Drops entries older than an hour and keeps the newest 24. Safe to run in both processes at once:
    /// it only removes keys, re-reading them just before deciding.
    private func prune(now: Int) {
        var entries: [(key: String, fetchedAt: Int)] = []
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Self.arrivalsPrefix) {
            guard let d = defaults.data(forKey: key),
                  let a = try? JSONDecoder().decode(StopArrivals.self, from: d) else {
                defaults.removeObject(forKey: key)
                continue
            }
            entries.append((key, a.fetchedAt))
        }
        entries.sort { $0.fetchedAt > $1.fetchedAt }
        for (i, e) in entries.enumerated() where i >= Self.maxCachedStops || e.fetchedAt < now - Self.maxAge {
            defaults.removeObject(forKey: e.key)
        }
    }
}
