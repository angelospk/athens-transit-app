import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack(path: $model.path) {
            List {
                NavigationLink(value: Screen.favourites) {
                    Label(L.t("home.favourites"), systemImage: "star.fill")
                }
                NavigationLink(value: Screen.nearby) {
                    Label(L.t("home.nearby"), systemImage: "location.fill")
                }
            }
            // At accessibility sizes the icons would squeeze «Αγαπημένα» into a hyphenated break.
            .labelStyle(HomeLabelStyle(iconless: typeSize.isAccessibilitySize))
            .navigationTitle(L.t("app.title"))
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .favourites: FavouritesView()
                case .nearby: NearbyView()
                case .stop(let route): StopView(route: route)
                }
            }
        }
    }
}

/// True while the screen is on, not dimmed and not `paused`: refresh only then.
struct LiveRefresh: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let every: UInt64
    let paused: Bool
    let action: @MainActor () async -> Void

    func body(content: Content) -> some View {
        let live = scenePhase == .active && !isLuminanceReduced && !paused
        content.task(id: live) {
            guard live else { return }
            while !Task.isCancelled {
                await action()
                try? await Task.sleep(nanoseconds: every * 1_000_000_000)
            }
        }
    }
}

extension View {
    func liveRefresh(every seconds: UInt64, paused: Bool = false,
                     _ action: @escaping @MainActor () async -> Void) -> some View {
        modifier(LiveRefresh(every: seconds, paused: paused, action: action))
    }
}

struct HomeLabelStyle: LabelStyle {
    let iconless: Bool

    func makeBody(configuration: Configuration) -> some View {
        if iconless {
            configuration.title
        } else {
            Label(configuration)
        }
    }
}
