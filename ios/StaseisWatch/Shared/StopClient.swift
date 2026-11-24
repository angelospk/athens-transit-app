import Foundation

enum FetchError: Error, Equatable {
    case backingOff
    case network
    case badData
}

enum Net {
    /// Ephemeral (no cookies or cache on disk), 10 s timeouts, HTTPS hosts only (ATS without exceptions).
    static func makeSession(resourceTimeout: TimeInterval = 10) -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 10
        c.timeoutIntervalForResource = resourceTimeout
        c.httpCookieStorage = nil
        c.httpShouldSetCookies = false
        c.urlCache = nil
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        c.waitsForConnectivity = false
        c.httpAdditionalHeaders = ["User-Agent": userAgent]
        return URLSession(configuration: c)
    }

    static let userAgent: String = {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "Staseis-Watch/\(v) (watchos)"
    }()

    /// Reads a body up to `cap` bytes; nil past the cap, on a non-200 answer or on a redirect off the host.
    static func get(_ request: URLRequest, session: URLSession, cap: Int) async throws -> (Data, HTTPURLResponse)? {
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        guard http.url?.scheme == "https", http.url?.host == request.url?.host else { return nil }
        if http.statusCode == 304 { return (Data(), http) }
        guard http.statusCode == 200 else { return nil }
        if http.expectedContentLength > Int64(cap) { return nil }
        var data = Data()
        data.reserveCapacity(Int(max(0, min(http.expectedContentLength, Int64(cap)))))
        for try await b in bytes {
            data.append(b)
            if data.count > cap { return nil }
        }
        return (data, http)
    }
}

/// Fetches `/v1/stops/{id}`: one request in flight per stop, back-off 30 → 60 → 120 s after failures.
actor StopClient {
    static let shared = StopClient()

    private let session = Net.makeSession()
    private var inFlight: [String: Task<Result<StopArrivals, FetchError>, Never>] = [:]
    private var backoff: [String: Backoff] = [:]

    func fetch(city: City, stopId: String, store: SharedStore = .shared) async -> Result<StopArrivals, FetchError> {
        let key = "\(city.rawValue)/\(stopId)"
        if let running = inFlight[key] { return await running.value }
        let now = Int(Date().timeIntervalSince1970)
        if let b = backoff[key], !b.allows(now: now) { return .failure(.backingOff) }
        guard let url = city.stopURL(id: stopId) else { return .failure(.badData) }

        let session = self.session
        let task = Task<Result<StopArrivals, FetchError>, Never> {
            var req = URLRequest(url: url)
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                guard let (data, _) = try await Net.get(req, session: session, cap: ArrivalsDecoder.maxBodyBytes) else {
                    return .failure(.network)
                }
                let t = Int(Date().timeIntervalSince1970)
                guard let decoded = ArrivalsDecoder.decode(data, city: city, stopId: stopId, now: t) else {
                    return .failure(.badData)
                }
                store.saveArrivals(decoded)
                return .success(decoded)
            } catch {
                return .failure(.network)
            }
        }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        var b = backoff[key] ?? Backoff()
        switch result {
        case .success: b.succeed()
        case .failure: b.fail(now: Int(Date().timeIntervalSince1970))
        }
        backoff[key] = b
        return result
    }
}
