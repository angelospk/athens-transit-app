import Foundation

/// The App Group defaults shared by the watch app and the complication extension:
/// the synced favourites and the last arrivals per stop. Nothing personal beyond stop ids.
final class SharedStore: @unchecked Sendable {
    static let appGroup = "group.gr.staseis.app"
    static let shared = SharedStore()

    private let defaults: UserDefaults
    private let lock = NSLock()
    private static let favsKey = "watch.favs.v1"
    private static let arrivalsKey = "watch.arrivals.v1"
    private static let maxCachedStops = 24

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.appGroup) ?? .standard
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

    private static func key(_ city: City, _ id: String) -> String { "\(city.rawValue)/\(id)" }

    private func allArrivals() -> [String: StopArrivals] {
        guard let data = defaults.data(forKey: Self.arrivalsKey),
              let map = try? JSONDecoder().decode([String: StopArrivals].self, from: data) else { return [:] }
        return map
    }

    func arrivals(city: City, stopId: String) -> StopArrivals? {
        allArrivals()[Self.key(city, stopId)]
    }

    func saveArrivals(_ a: StopArrivals) {
        lock.lock(); defer { lock.unlock() }
        var map = allArrivals()
        map[Self.key(a.city, a.stopId)] = a
        // Keep the newest few and drop anything older than an hour.
        let cutoff = a.fetchedAt - 3600
        map = map.filter { $0.value.fetchedAt >= cutoff }
        if map.count > Self.maxCachedStops {
            let keep = map.sorted { $0.value.fetchedAt > $1.value.fetchedAt }.prefix(Self.maxCachedStops)
            map = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
        if let data = try? JSONEncoder().encode(map) { defaults.set(data, forKey: Self.arrivalsKey) }
    }
}
