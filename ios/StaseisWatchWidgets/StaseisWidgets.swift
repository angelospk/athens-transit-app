import SwiftUI
import WidgetKit

// The next bus at the FIRST favourite stop, for the watch face (complications / Smart Stack).

struct NextBusEntry: TimelineEntry {
    let date: Date
    let stopName: String?
    let line: String?
    let minutes: String?
    let hasFavs: Bool
    let url: URL?
}

struct NextBusProvider: TimelineProvider {
    private static let refresh: TimeInterval = 15 * 60
    /// The complication fetches only when the cached answer is older than this.
    private static let fetchAfter = 5 * 60

    func placeholder(in context: Context) -> NextBusEntry {
        NextBusEntry(date: Date(), stopName: "ΣΥΝΤΑΓΜΑ", line: "040", minutes: "3′", hasFavs: true, url: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextBusEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        completion(Self.entries(now: Int(Date().timeIntervalSince1970)).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextBusEntry>) -> Void) {
        Task {
            let store = SharedStore.shared
            let now = Int(Date().timeIntervalSince1970)
            if let p = store.favs, let first = p.favs.first {
                let cached = store.arrivals(city: p.city, stopId: first.id)
                if cached.map({ now - $0.fetchedAt > Self.fetchAfter }) ?? true {
                    _ = await StopClient.shared.fetch(city: p.city, stopId: first.id, store: store)
                }
            }
            let entries = Self.entries(now: Int(Date().timeIntervalSince1970))
            completion(Timeline(entries: entries, policy: .after(Date().addingTimeInterval(Self.refresh))))
        }
    }

    static func entries(now: Int) -> [NextBusEntry] {
        let store = SharedStore.shared
        guard let p = store.favs, let fav = p.favs.first else {
            return [NextBusEntry(date: Date(timeIntervalSince1970: TimeInterval(now)), stopName: nil, line: nil, minutes: nil, hasFavs: false, url: nil)]
        }
        let data = store.arrivals(city: p.city, stopId: fav.id)
        let url = DeepLink.stop(city: p.city, id: fav.id)
        let nowWord = NSLocalizedString("time.now", comment: "")
        return ComplicationTimeline.slots(data, lines: fav.lines, now: now, nowWord: nowWord).map {
            NextBusEntry(date: Date(timeIntervalSince1970: TimeInterval($0.date)), stopName: fav.name,
                         line: $0.line, minutes: $0.minutes, hasFavs: true, url: url)
        }
    }
}

struct NextBusView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextBusEntry

    private var short: String {
        guard let line = entry.line, let m = entry.minutes else { return "—" }
        return "\(line) · \(m)"
    }

    var body: some View {
        content
            .widgetURL(entry.url)
            .containerBackground(for: .widget) { Color.clear }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            ViewThatFits {
                Text(short)
                Text(entry.minutes ?? "—")
            }
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(entry.line ?? "—")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let m = entry.minutes {
                        Text(m)
                            .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(2)
            }
        case .accessoryCorner:
            Text(entry.minutes ?? "—")
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .widgetLabel(entry.line ?? NSLocalizedString("widget.short", comment: ""))
        default:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.hasFavs ? (entry.stopName ?? "") : NSLocalizedString("widget.title", comment: ""))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .widgetAccentable()
                if entry.hasFavs {
                    Text(short)
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text(NSLocalizedString("widget.nofavs", comment: ""))
                        .font(.footnote)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct NextBusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "gr.staseis.watch.nextbus", provider: NextBusProvider()) { entry in
            NextBusView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("widget.name", comment: ""))
        .description(NSLocalizedString("widget.description", comment: ""))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct StaseisWidgets: WidgetBundle {
    var body: some Widget {
        NextBusWidget()
    }
}
