import Foundation

/// What one Today card says, once its metric has something to show.
struct MetricReadout: Equatable {
    let sentence: String
    let detail: String
    /// nil when there isn't enough of the person's own history to compare against.
    let standing: BaselineStanding?

    var palette: SoftGradientPalette { standing?.palette ?? .typical }
}

/// Every metric resolves to one of these. A metric with nothing behind it is
/// `.empty` — never an error, never a zero dressed up as a reading.
enum MetricState: Equatable {
    case loading
    case empty(sentence: String, detail: String)
    case ready(MetricReadout)
}

struct MetricCard: Identifiable, Equatable {
    let label: String
    let state: MetricState

    var id: String { label }
}

// MARK: - Shared phrasing

enum Recency {
    /// nil when the date is today — so today's reading carries no date at all,
    /// and an older one always says when it's from.
    static func label(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String? {
        switch daysOld(date, now: now, calendar: calendar) {
        case ..<1: nil
        case 1: "yesterday"
        case 2...6: date.formatted(.dateTime.weekday(.wide))
        default: date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    static func daysOld(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)
        ).day ?? 0
    }

    /// Appends "· yesterday" and friends to a value, leaving today's value bare.
    static func detail(_ value: String, from date: Date, now: Date = .now) -> String {
        guard let when = label(for: date, now: now) else { return value }
        return "\(value) · \(when)"
    }
}

enum Format {
    static func duration(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours == 0 { return "\(minutes) min" }
        if minutes == 0 { return "\(hours) hr" }
        return "\(hours) hr \(minutes) min"
    }

    static func clockTime(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}
