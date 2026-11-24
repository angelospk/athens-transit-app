import SwiftUI

enum L {
    static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }
    static func f(_ key: String, _ arg: String) -> String { String(format: t(key), arg) }

    static func time(_ unix: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return f.string(from: Date(timeIntervalSince1970: TimeInterval(unix)))
    }
}

enum Palette {
    /// "Worse" delay (> 5′): the phone app's dark-theme late colour.
    static let late = Color(red: 1.0, green: 0.698, blue: 0.361)
    /// "Much worse" delay (> 10′).
    static let veryLate = Color(red: 1.0, green: 0.42, blue: 0.36)
}

struct LineBadge: View {
    let line: String

    var body: some View {
        Text(line)
            .font(.system(.footnote, design: .rounded).weight(.heavy).monospacedDigit())
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.white.opacity(0.18)))
    }
}

struct DelayBadge: View {
    let delay: Int?

    var body: some View {
        switch ArrivalFormat.delayLevel(delay) {
        case .none:
            EmptyView()
        case .worse(let m):
            badge(m, Palette.late)
        case .muchWorse(let m):
            badge(m, Palette.veryLate)
        }
    }

    private func badge(_ minutes: Int, _ color: Color) -> some View {
        Text("+\(minutes)′")
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(color)
            .accessibilityLabel(L.f("a11y.late", String(minutes)))
    }
}
