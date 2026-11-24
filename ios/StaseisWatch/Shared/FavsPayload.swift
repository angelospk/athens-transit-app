import Foundation

/// One favourite stop synced from the phone.
struct Fav: Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    /// The lines the user picked at this stop; empty → all lines.
    let lines: [String]
}

/// The phone → watch payload (WatchConnectivity application context, key `json`).
struct FavsPayload: Codable, Equatable, Sendable {
    let v: Int
    let city: City
    let favs: [Fav]
}

/// The payload is untrusted: anything that fails here is dropped and the previous favourites stay.
enum FavsPayloadValidator {
    static let version = 1
    static let maxFavs = 20
    static let maxNameLength = 80
    static let maxLines = 12
    static let maxBytes = 32 * 1024

    // Strict types (JSONDecoder rejects `true` or `1.5` for an Int); unknown keys are ignored.
    private struct Raw: Decodable {
        let v: Int
        let city: String
        let favs: [RawFav]
    }

    private struct RawFav: Decodable {
        let id: String
        let name: String?
        let lines: [String]?
    }

    static func validate(_ json: String) -> FavsPayload? {
        guard json.utf8.count <= maxBytes, let data = json.data(using: .utf8) else { return nil }
        guard let raw = try? JSONDecoder().decode(Raw.self, from: data) else { return nil }
        guard raw.v == version, let city = City(rawValue: raw.city) else { return nil }
        guard raw.favs.count <= maxFavs else { return nil }

        var seen = Set<String>()
        var favs: [Fav] = []
        for f in raw.favs {
            guard Validation.isStopId(f.id) else { return nil }
            let name = (f.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.count <= maxNameLength else { return nil }
            guard !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
            let lines = f.lines ?? []
            guard lines.count <= maxLines, lines.allSatisfy(Validation.isLine) else { return nil }
            if seen.insert(f.id).inserted {
                favs.append(Fav(id: f.id, name: name.isEmpty ? f.id : name, lines: lines))
            }
        }
        return FavsPayload(v: raw.v, city: city, favs: favs)
    }
}
