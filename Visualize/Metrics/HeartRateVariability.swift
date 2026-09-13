import Foundation

/// Heart rate variability (SDNN). Eases *upward* — the opposite direction to
/// resting heart rate — which is why each metric states its own direction.
enum HeartRateVariability {

    static let label = "Heart rate variability"

    static let freshnessWindowInDays = 14

    /// SDNN swings far more than resting heart rate does, so the band is wider.
    private static let band = 3.0...15.0

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
                    ? "Heart rate variability usually comes from an Apple Watch. We’ll show it as soon as one lands."
                    : "This iPhone doesn’t have Apple Health data available, so cards will stay quiet here."
            )
        }

        guard Recency.daysOld(latest.date, now: now, calendar: calendar) <= freshnessWindowInDays else {
            return .empty(
                sentence: "Nothing recent.",
                detail: "The last reading we can see is from \(latest.date.formatted(.dateTime.month(.wide).day()))."
            )
        }

        let latestDay = calendar.startOfDay(for: latest.date)
        let standing = Baseline.standing(
            of: latest.value,
            against: history.filter { $0.date < latestDay }.map(\.value),
            eased: .higher,
            band: band
        )

        return .ready(MetricReadout(
            sentence: sentence(for: standing),
            detail: Recency.detail("\(Int(latest.value.rounded())) ms", from: latest.date, now: now),
            standing: standing
        ))
    }

    private static func sentence(for standing: BaselineStanding?) -> String {
        switch standing {
        case .above?: "You’re recovering well."
        case .typical?: "About your usual."
        case .below?: "Your body might still be catching up."
        case nil: "Your first reading’s in."
        }
    }
}
