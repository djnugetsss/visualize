import Foundation
import HealthKit

/// The read-only set this app asks for. Nothing here is written, ever —
/// `requestAuthorization` is always called with an empty share set.
enum HealthMetrics {

    /// Chosen because they're commonly available and need no medical interpretation.
    static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKCategoryType(.sleepAnalysis),
        HKObjectType.workoutType()
    ]

    /// Plain-language names, for the permission screen and for labels later.
    static let humanNames = [
        "Sleep",
        "Resting heart rate and heart rate variability",
        "Steps, active energy, and workouts"
    ]
}
