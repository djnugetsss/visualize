import Foundation

/// Steps so far today, against the same stretch of the person’s own recent days.
enum Movement {

    static let label = "Movement"

    /// Step counts are big and noisy, so the band is generous: between 800 steps
    /// and 5,000 depending on how varied their days are.
    private static let band = 800.0...5000.0

    /// Before this hour there is too little of the day to say anything useful,
    /// so we show the count and skip the comparison.
    private static let earliestComparableHour = 9

    static func state(
        stepsToday: Double?,
        priorDays: [DailyMetricValue],
        healthDataAvailable: Bool = true,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MetricState {
        guard let stepsToday else {
            return .empty(
                sentence: "Nothing here yet.",
                detail: healthDataAvailable
                    ? "We’ll show your movement as Apple Health records it."
                    : "This iPhone doesn’t have Apple Health data available, so cards will stay quiet here."
            )
        }

        let steps = Int(stepsToday.rounded())
        let detail = "\(steps.formatted(.number)) steps so far"

        // Early morning: a handful of steps against a whole prior morning tells
        // you nothing, and calling it a quiet day would be wrong more often than right.
        guard calendar.component(.hour, from: now) >= earliestComparableHour else {
            return .ready(MetricReadout(
                sentence: "The day’s just getting going.",
                detail: detail,
                standing: nil
            ))
        }

        let standing = Baseline.standing(
            of: stepsToday,
            against: priorDays.map(\.value),
            eased: .higher,
            band: band
        )

        return .ready(MetricReadout(
            sentence: sentence(for: standing),
            detail: detail,
            standing: standing
        ))
    }

    private static func sentence(for standing: BaselineStanding?) -> String {
        switch standing {
        case .above?: "You’ve been on the move."
        case .typical?: "About as active as usual."
        case .below?: "A quieter day so far."
        case nil: "Your first day’s counting."
        }
    }
}
