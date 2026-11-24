import Foundation

enum DeepLink {
    static let scheme = "staseiswatch"

    static func stop(city: City, id: String) -> URL? {
        guard Validation.isStopId(id) else { return nil }
        var c = URLComponents()
        c.scheme = scheme
        c.host = "stop"
        c.queryItems = [URLQueryItem(name: "city", value: city.rawValue), URLQueryItem(name: "id", value: id)]
        return c.url
    }
}
