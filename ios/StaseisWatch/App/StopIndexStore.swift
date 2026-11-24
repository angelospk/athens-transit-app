import Foundation

/// The stop list per city: downloaded on first need, kept as the compact `s` array in the app's
/// caches directory, refreshed at most weekly with a conditional GET (ETag / Last-Modified).
actor StopIndexStore {
    static let shared = StopIndexStore()

    private struct Meta: Codable {
        var etag: String?
        var lastModified: String?
        var checkedAt: Date
    }

    private let session = Net.makeSession(resourceTimeout: 30)
    private var memory: [City: [StopEntry]] = [:]
    private var refreshing: [City: Task<[StopEntry]?, Never>] = [:]
    private static let week: TimeInterval = 7 * 24 * 3600

    private func dir() -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let d = base.appendingPathComponent("stop-index", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private func fileURL(_ city: City) -> URL? { dir()?.appendingPathComponent("\(city.rawValue).v\(StopIndexParser.compactFormat).json") }
    private func metaURL(_ city: City) -> URL? { dir()?.appendingPathComponent("\(city.rawValue).v\(StopIndexParser.compactFormat).meta.json") }

    /// Caches from an older format (e.g. `athens.json` without lines) are deleted and rebuilt.
    private func removeOldFormats(_ city: City) {
        guard let d = dir(), let names = try? FileManager.default.contentsOfDirectory(atPath: d.path) else { return }
        let current = "\(city.rawValue).v\(StopIndexParser.compactFormat)."
        for n in names where n.hasPrefix("\(city.rawValue).") && !n.hasPrefix(current) {
            try? FileManager.default.removeItem(at: d.appendingPathComponent(n))
        }
    }

    private func readMeta(_ city: City) -> Meta? {
        guard let u = metaURL(city), let d = try? Data(contentsOf: u) else { return nil }
        return try? JSONDecoder().decode(Meta.self, from: d)
    }

    private func writeMeta(_ m: Meta, _ city: City) {
        guard let u = metaURL(city), let d = try? JSONEncoder().encode(m) else { return }
        try? d.write(to: u, options: .atomic)
    }

    /// The stops of a city; nil when there is nothing local and the download failed.
    func stops(for city: City) async -> [StopEntry]? {
        if memory[city] == nil {
            removeOldFormats(city)
            if let u = fileURL(city), let d = try? Data(contentsOf: u) { memory[city] = StopIndexParser.decodeCompact(d) }
        }
        // Without a usable local file, ask for the full file (no conditional headers).
        let meta = memory[city] == nil ? nil : readMeta(city)
        let due = meta.map { -$0.checkedAt.timeIntervalSinceNow > Self.week } ?? true
        if let local = memory[city] {
            if due { _ = startRefresh(city, meta: meta) }
            return local
        }
        return await startRefresh(city, meta: nil).value
    }

    private func startRefresh(_ city: City, meta: Meta?) -> Task<[StopEntry]?, Never> {
        if let t = refreshing[city] { return t }
        let session = self.session
        let t = Task<[StopEntry]?, Never> {
            var req = URLRequest(url: city.stopIndexURL)
            if let e = meta?.etag { req.setValue(e, forHTTPHeaderField: "If-None-Match") }
            if let m = meta?.lastModified { req.setValue(m, forHTTPHeaderField: "If-Modified-Since") }
            guard let (data, http) = try? await Net.get(req, session: session, cap: StopIndexParser.maxDownloadBytes) else {
                return nil
            }
            if http.statusCode == 304 {
                self.finish(city, stops: nil, http: http)
                return self.memory[city]
            }
            // Parse off the actor and the main thread.
            let parsed = await Task.detached(priority: .utility) { StopIndexParser.parseTrips(data) }.value
            guard let parsed else { return nil }
            self.finish(city, stops: parsed, http: http)
            return parsed
        }
        refreshing[city] = t
        Task { _ = await t.value; self.clear(city) }
        return t
    }

    private func clear(_ city: City) { refreshing[city] = nil }

    private func finish(_ city: City, stops: [StopEntry]?, http: HTTPURLResponse) {
        if let stops {
            memory[city] = stops
            if let u = fileURL(city), let d = StopIndexParser.encodeCompact(stops) {
                try? d.write(to: u, options: .atomic)
            }
        }
        writeMeta(Meta(etag: http.value(forHTTPHeaderField: "ETag"),
                       lastModified: http.value(forHTTPHeaderField: "Last-Modified"),
                       checkedAt: Date()), city)
    }
}
