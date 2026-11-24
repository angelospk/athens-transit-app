import SwiftUI
import WidgetKit

/// Asks the complication to rebuild when the app has fresh arrivals for the first favourite
/// (at most every 5 min; reloads from the foreground app do not use the complication's budget).
@MainActor
enum ComplicationReloader {
    private static var last = Date.distantPast

    static func fetched(city: City, stopId: String) {
        guard let p = SharedStore.shared.favs, p.city == city, p.favs.first?.id == stopId,
              -last.timeIntervalSinceNow > 300 else { return }
        last = Date()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

@MainActor
final class StopModel: ObservableObject {
    let route: StopRoute
    @Published private(set) var data: StopArrivals?
    @Published private(set) var lastFailed = false
    @Published private(set) var loading = true
    /// Changes on every refresh, so the minutes re-render even when the data did not change.
    @Published private(set) var tick = 0

    init(route: StopRoute) {
        self.route = route
        data = SharedStore.shared.arrivals(city: route.city, stopId: route.id)
    }

    func refresh() async {
        let r = await StopClient.shared.fetch(city: route.city, stopId: route.id)
        switch r {
        case .success(let a):
            data = a
            lastFailed = false
            ComplicationReloader.fetched(city: route.city, stopId: route.id)
        case .failure(.backingOff):
            break
        case .failure(.badData):
            data = nil
            lastFailed = true
        case .failure(.network):
            lastFailed = true
        }
        loading = false
        tick += 1
    }
}

struct StopView: View {
    @StateObject private var vm: StopModel

    init(route: StopRoute) {
        _vm = StateObject(wrappedValue: StopModel(route: route))
    }

    var body: some View {
        let now = Int(Date().timeIntervalSince1970)
        let fresh = FreshnessRule.freshness(fetchedAt: vm.data?.fetchedAt, lastRequestFailed: vm.lastFailed, now: now)
        let rows = fresh == .none ? [] : ArrivalFormat.next(vm.data?.arrivals ?? [], lines: [], now: now, count: 8)
        let name = vm.route.name.isEmpty ? (vm.data?.name ?? vm.route.id) : vm.route.name

        List {
            Section {
                if fresh == .none {
                    Text(vm.loading && !vm.lastFailed ? L.t("stop.loading") : L.t("stop.nodata"))
                        .foregroundStyle(.secondary)
                } else if rows.isEmpty {
                    Text(L.t("stop.nobuses"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, a in
                        ArrivalRow(arrival: a, now: now)
                            .opacity(fresh == .offline ? 0.5 : 1)
                    }
                }
            } footer: {
                if let t = vm.data?.fetchedAt, fresh != .none {
                    Text(fresh == .offline ? L.f("stop.offline", L.time(t)) : L.f("stop.updated", L.time(t)))
                        .font(.footnote)
                }
            }
        }
        .navigationTitle(name)
        .liveRefresh(every: 30) { await vm.refresh() }
    }
}

struct ArrivalRow: View {
    let arrival: Arrival
    let now: Int
    @Environment(\.dynamicTypeSize) private var typeSize

    /// From xxLarge up the minutes would squeeze the headsign: stack the row instead.
    private var stacked: Bool { typeSize >= .xxLarge }

    var body: some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 2) {
                    // Badge, minutes and delay keep their size; the delay drops to its own line if they don't fit.
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            badge
                            Spacer(minLength: 2)
                            minutes.fixedSize()
                            DelayBadge(delay: arrival.delay).fixedSize()
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                badge
                                Spacer(minLength: 2)
                                minutes.fixedSize()
                            }
                            DelayBadge(delay: arrival.delay).fixedSize()
                        }
                    }
                    headsign
                }
            } else {
                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        badge
                        headsign
                    }
                    Spacer(minLength: 2)
                    VStack(alignment: .trailing, spacing: 1) {
                        minutes
                        DelayBadge(delay: arrival.delay)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var badge: some View {
        LineBadge(line: arrival.line).fixedSize().layoutPriority(2)
    }

    private var minutes: some View {
        Text(ArrivalFormat.minutesText(at: arrival.at, now: now, nowWord: L.t("time.now")))
            .font(.title3.weight(.semibold).monospacedDigit())
            .foregroundStyle(arrival.live ? .primary : .secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .layoutPriority(1)
    }

    @ViewBuilder
    private var headsign: some View {
        if !arrival.headsign.isEmpty {
            Text(arrival.headsign)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
