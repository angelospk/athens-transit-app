import SwiftUI

@MainActor
final class NearbyModel: ObservableObject {
    enum State: Equatable {
        case locating
        case loadingStops
        case results(City, [NearbyStop])
        case empty
        case denied
        case failed
        case indexFailed
    }

    @Published private(set) var state: State = .locating
    private var running = false

    func run() async {
        guard !running else { return }
        running = true
        defer { running = false }
        state = .locating
        let loc: (lat: Double, lon: Double)
        do {
            let l = try await LocationProvider.shared.currentLocation()
            loc = (l.coordinate.latitude, l.coordinate.longitude)
        } catch LocationError.denied {
            state = .denied
            return
        } catch {
            state = .failed
            return
        }
        guard let city = City.containing(lat: loc.lat, lon: loc.lon) else {
            state = .empty
            return
        }
        state = .loadingStops
        guard let stops = await StopIndexStore.shared.stops(for: city) else {
            state = .indexFailed
            return
        }
        let near = await Task.detached(priority: .userInitiated) {
            NearestStops.nearest(stops, lat: loc.lat, lon: loc.lon)
        }.value
        state = near.isEmpty ? .empty : .results(city, near)
    }
}

struct NearbyView: View {
    @StateObject private var vm = NearbyModel()

    var body: some View {
        Group {
            switch vm.state {
            case .locating:
                progress(L.t("nearby.locating"))
            case .loadingStops:
                progress(L.t("nearby.loadingStops"))
            case .results(let city, let stops):
                List(stops, id: \.stop.id) { n in
                    NavigationLink(value: Screen.stop(StopRoute(city: city, id: n.stop.id, name: n.stop.name, lines: []))) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(n.stop.name)
                                .font(.headline)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                            Text([ArrivalFormat.distanceText(n.meters), ArrivalFormat.linesText(n.stop.lines)]
                                    .filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            case .empty:
                message(L.t("nearby.none"), retry: true)
            case .denied:
                message(L.t("nearby.denied"), retry: true)
            case .failed:
                message(L.t("nearby.failed"), retry: true)
            case .indexFailed:
                message(L.t("nearby.indexFailed"), retry: true)
            }
        }
        .navigationTitle(L.t("home.nearby"))
        .task { await vm.run() }
    }

    private func progress(_ text: String) -> some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func message(_ text: String, retry: Bool) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                if retry {
                    Button(L.t("action.retry")) { Task { await vm.run() } }
                }
            }
            .padding(.top, 8)
        }
    }
}
