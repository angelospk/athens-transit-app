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

/// The payload is untrusted. A bad version, city or shape rejects it (the previous favourites stay);
/// an invalid favourite is skipped and the valid ones are kept.
enum FavsPayloadValidator {
    static let version = 1
    static let maxFavs = 20
    static let maxNameLength = 80
    static let maxLines = 12
    static let maxBytes = 32 * 1024
    /// More raw entries than this is not a favourites list: reject.
    static let maxRawFavs = 100

    // Strict types for the envelope (JSONDecoder rejects `true` or `1.5` for an Int); unknown keys are ignored.
    private struct Raw: Decodable {
        let v: Int
        let city: String
        let favs: [RawFav]
    }

    /// Never throws, so one bad entry does not sink the list.
    private struct RawFav: Decodable {
        let id: String?
        let name: String?
        let nameBad: Bool
        let lines: [String]?
        let linesBad: Bool

        enum CodingKeys: String, CodingKey { case id, name, lines }

        init(from decoder: Decoder) throws {
            guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
                id = nil; name = nil; nameBad = true; lines = nil; linesBad = true
                return
            }
            id = try? c.decodeIfPresent(String.self, forKey: .id)
            // Missing is fine; present with the wrong type makes the favourite invalid.
            switch Result(catching: { try c.decodeIfPresent(String.self, forKey: .name) }) {
            case .success(let v): name = v; nameBad = false
            case .failure: name = nil; nameBad = true
            }
            switch Result(catching: { try c.decodeIfPresent([String].self, forKey: .lines) }) {
            case .success(let v): lines = v; linesBad = false
            case .failure: lines = nil; linesBad = true
            }
        }
    }

    static func validate(_ json: String) -> FavsPayload? {
        guard json.utf8.count <= maxBytes, let data = json.data(using: .utf8) else { return nil }
        guard let raw = try? JSONDecoder().decode(Raw.self, from: data) else { return nil }
        guard raw.v == version, let city = City(rawValue: raw.city) else { return nil }
        guard raw.favs.count <= maxRawFavs else { return nil }

        var seen = Set<String>()
        var favs: [Fav] = []
        for f in raw.favs {
            guard favs.count < maxFavs else { break }
            guard let fav = valid(f), seen.insert(fav.id).inserted else { continue }
            favs.append(fav)
        }
        return FavsPayload(v: raw.v, city: city, favs: favs)
    }

    /// nil for a favourite that breaks a rule (wrong types, bad id, long name, bad or too many lines).
    private static func valid(_ f: RawFav) -> Fav? {
        guard let id = f.id, Validation.isStopId(id), !f.nameBad, !f.linesBad else { return nil }
        let name = (f.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count <= maxNameLength,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        let lines = f.lines ?? []
        guard lines.count <= maxLines, lines.allSatisfy(Validation.isLine) else { return nil }
        return Fav(id: id, name: name.isEmpty ? id : name, lines: lines)
    }
}
