import Foundation

/// Resting heart rate, described against the person’s own recent days.
enum RestingHeartRate {

    static let label = "Resting heart rate"

    /// Resting heart rate usually arrives from an Apple Watch, so gaps are normal.
    /// Past this we stop leading with a reading rather than presenting a stale one.
    static let freshnessWindowInDays = 14

    /// Resting heart rate moves by a few beats day to day, so the typical band
    /// sits between 1.5 and 5 bpm wide depending on how steady their days are.
    private static let band = 1.5...5.0

    static func state(
        latest: MetricSample?,
        history: [DailyMetricValue],
        healthDataAvailable: Bool = true,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MetricState {
        guard let latest else {
            return .empty(
                sentence: "Nothing here yet.",
                detail: healthDataAvailable
                    ? "Resting heart rate usually comes from an Apple Watch. We’ll show it as soon as one lands."
                    : "This iPhone doesn’t have Apple Health data available, so cards will stay quiet here."
            )
        }

        guard Recency.daysOld(latest.date, now: now, calendar: calendar) <= freshnessWindowInDays else {
            return .empty(
                sentence: "Nothing recent.",
                detail: "The last reading we can see is from \(latest.date.formatted(.dateTime.month(.wide).day()))."
            )
        }

        // Compare against the days *before* this reading, so it is never part of
        // the baseline it is being measured against.
        let latestDay = calendar.startOfDay(for: latest.date)
        let standing = Baseline.standing(
            of: latest.value,
            against: history.filter { $0.date < latestDay }.map(\.value),
            eased: .lower,
            band: band
        )

        return .ready(MetricReadout(
            sentence: sentence(for: standing),
            detail: Recency.detail("\(Int(latest.value.rounded())) bpm", from: latest.date, now: now),
            standing: standing
        ))
    }

    private static func sentence(for standing: BaselineStanding?) -> String {
        switch standing {
        case .above?: "Your heart’s taking it easy."
        case .typical?: "Steady as usual."
        case .below?: "A little higher than your usual."
        case nil: "Your first reading’s in."
        }
    }
}
