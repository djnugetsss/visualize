import Foundation

/// Last night, described two ways: how long they slept, and whether they went to
/// bed around their usual time. Duration drives the colour; bedtime shapes the words.
enum Sleep {

    static let label = "Sleep"

    /// A night older than this stops being "last night".
    static let freshnessWindowInDays = 3

    /// Nights vary by half an hour or so either way; band in seconds.
    private static let durationBand = (20.0 * 60)...(75.0 * 60)
    /// Bedtime band in minutes.
    private static let bedtimeBand = 20.0...60.0

    static func state(
        nights: [SleepNight],
        healthDataAvailable: Bool = true,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MetricState {
        guard let latest = nights.last else {
            return .empty(
                sentence: "Nothing here yet.",
                detail: healthDataAvailable
                    ? "Sleep comes from an Apple Watch worn overnight, or from iPhone sleep tracking. We’ll show your night as soon as one lands."
                    : "This iPhone doesn’t have Apple Health data available, so cards will stay quiet here."
            )
        }

        guard Recency.daysOld(latest.night, now: now, calendar: calendar) <= freshnessWindowInDays else {
            return .empty(
                sentence: "Nothing recent.",
                detail: "The last night we can see is \(latest.night.formatted(.dateTime.month(.wide).day()))."
            )
        }

        let priorNights = nights.filter { $0.night < latest.night }

        let duration = Baseline.standing(
            of: latest.asleep,
            against: priorNights.map(\.asleep),
            eased: .higher,
            band: durationBand
        )

        let bedtime = bedtimeStanding(latest: latest, prior: priorNights, calendar: calendar)

        return .ready(MetricReadout(
            sentence: sentence(duration: duration, bedtime: bedtime),
            detail: detail(for: latest, now: now),
            standing: duration
        ))
    }

    /// Whether they went to bed around their usual time. `.typical` means consistent;
    /// `.above` is earlier than usual, `.below` later.
    private static func bedtimeStanding(
        latest: SleepNight,
        prior: [SleepNight],
        calendar: Calendar
    ) -> BaselineStanding? {
        guard let bedtime = latest.bedtime else { return nil }
        let priorOffsets = prior.compactMap { $0.bedtime }.map { offset($0, calendar: calendar) }

        return Baseline.standing(
            of: offset(bedtime, calendar: calendar),
            against: priorOffsets,
            eased: .lower,
            band: bedtimeBand
        )
    }

    /// Minutes from midnight, with evening times negative, so 11:40 PM and 12:20 AM
    /// sit twenty minutes apart instead of twenty-three hours.
    static func offset(_ date: Date, calendar: Calendar = .current) -> Double {
        let hour = calendar.component(.hour, from: date)
        let minutes = Double(hour * 60 + calendar.component(.minute, from: date))
        return hour >= 12 ? minutes - 1440 : minutes
    }

    private static func detail(for night: SleepNight, now: Date) -> String {
        let value = Format.duration(night.asleep)
        if let when = Recency.label(for: night.night, now: now) {
            return "\(value) · \(when)"
        }
        if let bedtime = night.bedtime {
            return "\(value) · to bed \(Format.clockTime(bedtime))"
        }
        return value
    }

    private static func sentence(duration: BaselineStanding?, bedtime: BaselineStanding?) -> String {
        switch duration {
        case .below?:
            return "A lighter night than usual."
        case .above?:
            return bedtime == .typical ? "Well rested." : "A longer night than usual."
        case .typical?:
            switch bedtime {
            case .below?: return "A later night than usual."
            case .above?: return "An earlier night than usual."
            default: return "A night like your others."
            }
        case nil:
            return "Your first night’s in."
        }
    }
}
