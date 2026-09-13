import Foundation
import HealthKit

/// One sample pulled out of HealthKit and reduced to plain values.
///
/// Nothing outside `HealthKitService` ever sees an `HK` type — the rest of the app
/// works on these, which keeps HealthKit’s threading and optionality at the edge.
struct MetricSample: Sendable, Equatable {
    let date: Date
    let value: Double
}

/// One day's average for a metric, keyed to the start of that day.
struct DailyMetricValue: Sendable, Equatable, Identifiable {
    let date: Date
    let value: Double

    var id: Date { date }
}

extension HKUnit {
    static let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())
    /// HRV (SDNN) is reported in milliseconds.
    static let millisecond = HKUnit.secondUnit(with: .milli)
}
