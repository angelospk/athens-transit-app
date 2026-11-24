import SwiftUI

@main
struct StaseisWatchApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(model)
                .onAppear { model.start() }
                .onOpenURL { model.open($0) }
        }
    }
}

/// Where a stop screen points: the city is an enum and the id is validated.
struct StopRoute: Hashable {
    let city: City
    let id: String
    let name: String
    let lines: [String]
}

enum Screen: Hashable {
    case favourites
    case nearby
    case stop(StopRoute)
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var favs: FavsPayload?
    @Published var path: [Screen] = []

    /// A stop screen is on top: list refreshes underneath pause.
    var isStopOpen: Bool {
        if case .stop = path.last { return true }
        return false
    }

    private let store = SharedStore.shared
    private lazy var link = PhoneLink { [weak self] payload in
        Task { @MainActor in self?.apply(payload) }
    }
    private var started = false

    init() {
        favs = store.favs
    }

    func start() {
        guard !started else { return }
        started = true
        link.activate()
        #if DEBUG
        demo()
        #endif
    }

    #if DEBUG
    /// Debug builds only, for simulator screenshots without a paired phone:
    /// `-demoFavs '<payload json>'` (validated like the phone's) and
    /// `-demoScreen favourites|nearby|stop:<city>:<id>`.
    private func demo() {
        // Read the raw arguments: UserDefaults would parse a JSON value as an old-style plist.
        let args = ProcessInfo.processInfo.arguments
        func arg(_ name: String) -> String? {
            guard let i = args.firstIndex(of: "-\(name)"), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if let json = arg("demoFavs"), let p = FavsPayloadValidator.validate(json) {
            store.saveFavs(p)
            favs = p
        }
        switch arg("demoScreen")?.split(separator: ":").map(String.init) {
        case ["favourites"]?: path = [.favourites]
        case ["nearby"]?: path = [.nearby]
        case let parts? where parts.count == 3 && parts[0] == "stop":
            if let url = DeepLink.stop(city: City(rawValue: parts[1]) ?? .athens, id: parts[2]) { open(url) }
        default: break
        }
    }
    #endif

    private func apply(_ payload: FavsPayload) {
        favs = payload
    }

    /// `staseiswatch://stop?city=athens&id=340098` from the complication.
    func open(_ url: URL) {
        guard url.scheme == DeepLink.scheme, url.host == "stop",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let city = items.first(where: { $0.name == "city" })?.value.flatMap(City.init(rawValue:)),
              let id = items.first(where: { $0.name == "id" })?.value, Validation.isStopId(id) else { return }
        let fav = favs?.city == city ? favs?.favs.first(where: { $0.id == id }) : nil
        path = [.favourites, .stop(StopRoute(city: city, id: id, name: fav?.name ?? "", lines: fav?.lines ?? []))]
    }
}
