import Foundation
import HealthKit

/// One night's sleep, assembled from the many category samples a watch writes.
struct SleepNight: Sendable, Equatable, Identifiable {
    /// The day the night *ended* — the morning you woke up.
    let night: Date
    let asleep: TimeInterval
    /// Start of the first asleep stretch. nil only if a night somehow has none.
    let bedtime: Date?
    /// How many raw samples went into this night. Debug logging only.
    let segmentCount: Int

    var id: Date { night }
}

enum SleepAssembly {

    /// Stages that mean actually asleep. `.inBed` and `.awake` are deliberately
    /// excluded — time in bed is not time asleep, and counting it would inflate
    /// every night.
    static let asleepValues: Set<Int> = [
        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
        HKCategoryValueSleepAnalysis.asleepREM.rawValue
    ]

    /// Which night a segment belongs to: the morning it ended. A stretch ending
    /// before 18:00 belongs to that day; anything later belongs to the next.
    static func night(endingAt end: Date, calendar: Calendar = .current) -> Date {
        let day = calendar.startOfDay(for: end)
        guard calendar.component(.hour, from: end) >= 18 else { return day }
        return calendar.date(byAdding: .day, value: 1, to: day) ?? day
    }

    /// Collapses overlapping stretches before summing.
    ///
    /// This matters: a watch writes one sample per stage, and if a phone or a
    /// third-party app also writes sleep, the same minutes arrive two or three
    /// times over. Summing raw durations would report ten-hour nights.
    static func merge(_ intervals: [(start: Date, end: Date)]) -> [(start: Date, end: Date)] {
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = []

        for interval in sorted {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1].end = max(last.end, interval.end)
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    /// Groups raw asleep segments into nights, merging overlaps within each.
    static func nights(from segments: [(start: Date, end: Date)], calendar: Calendar = .current) -> [SleepNight] {
        let grouped = Dictionary(grouping: segments) { night(endingAt: $0.end, calendar: calendar) }

        return grouped.map { night, raw in
            let merged = merge(raw)
            return SleepNight(
                night: night,
                asleep: merged.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) },
                bedtime: merged.first?.start,
                segmentCount: raw.count
            )
        }
        .sorted { $0.night < $1.night }
    }
}
