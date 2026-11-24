import SwiftUI

@MainActor
final class FavouritesModel: ObservableObject {
    @Published private(set) var data: [String: StopArrivals] = [:]
    @Published private(set) var failed: Set<String> = []
    @Published private(set) var tick = 0
    private var visible: Set<String> = []
    private var pending: Task<Void, Never>?

    func load(_ p: FavsPayload) {
        for f in p.favs where data[f.id] == nil {
            if let cached = SharedStore.shared.arrivals(city: p.city, stopId: f.id) { data[f.id] = cached }
        }
    }

    func appeared(_ id: String, _ p: FavsPayload) {
        visible.insert(id)
        // Rows that come into view without a recent answer: fetch soon (debounced).
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await refresh(p, onlyStale: true)
        }
    }

    func disappeared(_ id: String) { visible.remove(id) }

    /// At most 4 visible stops, 2 requests at a time.
    func refresh(_ p: FavsPayload, onlyStale: Bool = false) async {
        let now = Int(Date().timeIntervalSince1970)
        let ids = p.favs.map(\.id).filter { id in
            visible.contains(id) && (!onlyStale || (data[id].map { now - $0.fetchedAt > 55 } ?? true))
        }.prefix(4)
        var i = ids.startIndex
        while i < ids.endIndex {
            let pair = Array(ids[i..<min(i + 2, ids.endIndex)])
            i += 2
            await withTaskGroup(of: (String, Result<StopArrivals, FetchError>).self) { group in
                for id in pair {
                    group.addTask { (id, await StopClient.shared.fetch(city: p.city, stopId: id)) }
                }
                for await (id, result) in group {
                    switch result {
                    case .success(let a):
                        data[id] = a
                        failed.remove(id)
                        ComplicationReloader.fetched(city: p.city, stopId: id)
                    case .failure(.backingOff):
                        break
                    case .failure:
                        failed.insert(id)
                    }
                }
            }
        }
        tick += 1
    }
}

struct FavouritesView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var vm = FavouritesModel()

    var body: some View {
        Group {
            if let p = model.favs, !p.favs.isEmpty {
                List(p.favs, id: \.id) { fav in
                    NavigationLink(value: Screen.stop(StopRoute(city: p.city, id: fav.id, name: fav.name, lines: fav.lines))) {
                        row(fav, p)
                    }
                    .onAppear { vm.appeared(fav.id, p) }
                    .onDisappear { vm.disappeared(fav.id) }
                }
                .onAppear { vm.load(p) }
                .onChange(of: p) { _, new in vm.load(new) }
                .liveRefresh(every: 60) { await vm.refresh(p) }
            } else {
                ScrollView {
                    Text(L.t("favs.empty"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle(L.t("home.favourites"))
    }

    private func row(_ fav: Fav, _ p: FavsPayload) -> some View {
        let now = Int(Date().timeIntervalSince1970)
        let cached = vm.data[fav.id]
        let fresh = FreshnessRule.freshness(fetchedAt: cached?.fetchedAt, lastRequestFailed: vm.failed.contains(fav.id), now: now)
        let summary = fresh == .none ? "" : ArrivalFormat.summary(cached?.arrivals ?? [], lines: fav.lines, now: now, nowWord: L.t("time.now"))
        return VStack(alignment: .leading, spacing: 2) {
            Text(fav.name)
                .font(.headline)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
            if !summary.isEmpty {
                Text(summary)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(fresh == .offline ? .secondary : .primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else if cached != nil || vm.failed.contains(fav.id) {
                Text(fresh == .none ? L.t("stop.nodata") : L.t("stop.nobuses"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
