import Foundation

/// Workouts in the last seven days, against how the three weeks before that went.
enum Workouts {

    static let label = "Workouts"

    /// Four weeks: this one plus three to compare it against.
    static let historyWindowInDays = 28
    private static let weeks = 4

    /// Counts are small integers, so the band is small too — a difference of one
    /// workout is real, a fraction of one is not.
    private static let band = 0.5...2.0

    static func state(
        workoutDates: [Date],
        healthDataAvailable: Bool = true,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MetricState {
        guard !workoutDates.isEmpty else {
            return .empty(
                sentence: "Nothing here yet.",
                detail: healthDataAvailable
                    ? "Workouts you record will show up here."
                    : "This iPhone doesn’t have Apple Health data available, so cards will stay quiet here."
            )
        }

        // Bucket into trailing 7-day windows: index 0 is this week, then earlier ones.
        var counts = Array(repeating: 0, count: weeks)
        for date in workoutDates {
            let daysAgo = Recency.daysOld(date, now: now, calendar: calendar)
            let week = daysAgo / 7
            if week < weeks { counts[week] += 1 }
        }

        let thisWeek = counts[0]
        let priorWeeks = Array(counts.dropFirst()).map(Double.init)

        let standing = Baseline.standing(
            of: Double(thisWeek),
            against: priorWeeks,
            eased: .higher,
            band: band
        )

        return .ready(MetricReadout(
            sentence: sentence(for: standing, thisWeek: thisWeek),
            detail: detail(thisWeek),
            standing: standing
        ))
    }

    private static func detail(_ count: Int) -> String {
        switch count {
        case 0: "None in the last 7 days"
        case 1: "1 in the last 7 days"
        default: "\(count) in the last 7 days"
        }
    }

    private static func sentence(for standing: BaselineStanding?, thisWeek: Int) -> String {
        if thisWeek == 0 {
            return "A rest week so far."
        }
        switch standing {
        case .above?: return "Nice work this week."
        case .typical?: return "Your usual rhythm."
        case .below?: return "A lighter week than usual."
        case nil: return "You’ve been moving this week."
        }
    }
}
