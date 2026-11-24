import Foundation

// Foundation only: compiled into the watch app, the widget extension and the macOS test harness.

/// A lat/lon box (degrees).
struct GeoBox: Sendable, Equatable {
    let south: Double
    let west: Double
    let north: Double
    let east: Double

    func contains(lat: Double, lon: Double) -> Bool {
        lat >= south && lat <= north && lon >= west && lon <= east
    }
}

/// The cities the watch knows. An enum, never a URL: the hosts are hardcoded here (HTTPS only).
enum City: String, CaseIterable, Codable, Sendable {
    case athens
    case thessaloniki

    var apiBase: URL {
        switch self {
        case .athens: return URL(string: "https://transit.haroldpoi.dev")!
        case .thessaloniki: return URL(string: "https://transit-thess.haroldpoi.dev")!
        }
    }

    var stopIndexURL: URL {
        switch self {
        case .athens: return URL(string: "https://staseis.gr/trips.json")!
        case .thessaloniki: return URL(string: "https://staseis.gr/trips-thessaloniki.json")!
        }
    }

    var box: GeoBox {
        switch self {
        case .athens: return GeoBox(south: 37.5, west: 22.9, north: 38.5, east: 24.5)
        case .thessaloniki: return GeoBox(south: 40.3, west: 22.6, north: 41.0, east: 23.4)
        }
    }

    /// `GET {api}/v1/stops/{id}`; nil for an id that is not a valid stop id.
    func stopURL(id: String) -> URL? {
        guard Validation.isStopId(id) else { return nil }
        return apiBase.appendingPathComponent("v1").appendingPathComponent("stops").appendingPathComponent(id)
    }

    /// The city whose box holds the point; nil outside both ("No stops nearby").
    static func containing(lat: Double, lon: Double) -> City? {
        allCases.first { $0.box.contains(lat: lat, lon: lon) }
    }
}

enum Validation {
    /// `^[A-Za-z0-9_-]{1,16}$`
    static func isStopId(_ s: String) -> Bool {
        let scalars = s.unicodeScalars
        guard (1...16).contains(scalars.count) else { return false }
        return scalars.allSatisfy { c in
            switch c.value {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x5F, 0x2D: return true
            default: return false
            }
        }
    }

    /// `^[A-Za-z0-9Α-Ωα-ωΆ-Ώά-ώ_-]{1,8}$`
    static func isLine(_ s: String) -> Bool {
        let scalars = s.unicodeScalars
        guard (1...8).contains(scalars.count) else { return false }
        return scalars.allSatisfy { c in
            switch c.value {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x5F, 0x2D: return true
            case 0x0391...0x03A9, 0x03B1...0x03C9, 0x0386...0x038F, 0x03AC...0x03CE: return true
            default: return false
            }
        }
    }
}
