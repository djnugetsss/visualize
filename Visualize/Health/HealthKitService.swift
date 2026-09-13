import Foundation
import HealthKit
import SwiftUI

/// Owns the one `HKHealthStore` and the app's authorization phase.
///
/// Every HealthKit entry point here is guarded: on a device or simulator where
/// health data isn’t available, nothing throws and nothing crashes — the app
/// simply carries on and the screens fall back to their calm empty states.
@MainActor
final class HealthKitService: ObservableObject {

    enum Phase: Equatable {
        case needsPermission
        case requesting
        case connected
    }

    @Published private(set) var phase: Phase
    @Published private(set) var lastErrorMessage: String?

    /// False in most Simulator configurations and on unsupported hardware.
    let isHealthDataAvailable: Bool

    private let store: HKHealthStore?
    private let defaults: UserDefaults
    private static let connectedKey = "health.hasCompletedAuthorizationRequest"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        self.store = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
        self.phase = defaults.bool(forKey: Self.connectedKey) ? .connected : .needsPermission
    }

    /// Asks once for read access to the v1 metric set.
    ///
    /// HealthKit deliberately never tells an app that read access was *denied* —
    /// that itself would leak information. So there’s nothing to interpret here:
    /// we move on either way, and a metric the person declined simply arrives
    /// empty and shows its quiet card.
    func connect() async {
        guard phase != .requesting else { return }

        guard let store, isHealthDataAvailable else {
            // No health data on this device. Let the person through to the app
            // rather than dead-ending them on a permission screen.
            markConnected()
            return
        }

        phase = .requesting
        lastErrorMessage = nil

        do {
            try await store.requestAuthorization(toShare: [], read: HealthMetrics.readTypes)
            markConnected()
        } catch {
            lastErrorMessage = "Apple Health didn’t respond just now. You can try again."
            phase = .needsPermission
        }
    }

    private func markConnected() {
        defaults.set(true, forKey: Self.connectedKey)
        phase = .connected
    }

    // MARK: - Reads

    /// The most recent resting heart rate sample, or nil when there are none.
    ///
    /// A nil here is not an error: it’s what a person who declined this type, or who
    /// has no Apple Watch, legitimately looks like. Callers show an empty state.
    func latestRestingHeartRate() async -> MetricSample? {
        await latestSample(of: HKQuantityType(.restingHeartRate), unit: .beatsPerMinute)
    }

    /// Daily average resting heart rate over the trailing `days` days, most recent last.
    /// Days with no samples are simply absent from the result rather than zero-filled —
    /// a zero would read as a value, and it isn’t one.
    func dailyRestingHeartRate(days: Int) async -> [DailyMetricValue] {
        await dailyAverages(of: HKQuantityType(.restingHeartRate), unit: .beatsPerMinute, days: days)
    }

    // MARK: - Heart rate variability

    func latestHeartRateVariability() async -> MetricSample? {
        await latestSample(of: HKQuantityType(.heartRateVariabilitySDNN), unit: .millisecond)
    }

    func dailyHeartRateVariability(days: Int) async -> [DailyMetricValue] {
        await dailyAverages(of: HKQuantityType(.heartRateVariabilitySDNN), unit: .millisecond, days: days)
    }

    // MARK: - Movement

    /// Steps so far today.
    func stepsToday() async -> Double? {
        let calendar = Calendar.current
        let now = Date()
        return await stepSum(from: calendar.startOfDay(for: now), to: now)
    }

    /// Steps on each of the previous `days` days, counted only up to the same
    /// time of day it is now.
    ///
    /// Comparing a half-finished day against other days' finished totals would
    /// call every morning quiet. This compares like with like.
    func stepsByDayToThisTime(days: Int) async -> [DailyMetricValue] {
        guard store != nil, days > 0 else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let elapsed = now.timeIntervalSince(startOfToday)

        return await withTaskGroup(of: DailyMetricValue?.self) { group in
            for offset in 1...days {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { continue }
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    guard let sum = await self.stepSum(from: day, to: day.addingTimeInterval(elapsed)) else { return nil }
                    return DailyMetricValue(date: day, value: sum)
                }
            }

            var values: [DailyMetricValue] = []
            for await value in group {
                if let value { values.append(value) }
            }
            return values.sorted { $0.date < $1.date }
        }
    }

    private func stepSum(from start: Date, to end: Date) async -> Double? {
        guard let store else { return nil }

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
                options: .cumulativeSum
            ) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: .count()))
            }
            store.execute(query)
        }
    }

    // MARK: - Workouts

    /// Start dates of every workout in the trailing `days` days, oldest first.
    func workoutDates(days: Int) async -> [Date] {
        guard let store, days > 0 else { return [] }

        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) else { return [] }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: HKQuery.predicateForSamples(withStart: start, end: now),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                continuation.resume(returning: (samples ?? []).map(\.startDate))
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep

    /// Nights of actual sleep over the trailing `days` days.
    ///
    /// Sleep is a *category* type, not a quantity: a watch writes a run of stage
    /// samples per night rather than one number, so there is nothing to average.
    /// We pull the raw samples, keep the asleep stages, group them by the morning
    /// they ended, and merge overlaps before summing.
    func sleepNights(days: Int) async -> [SleepNight] {
        await sleepSegments(days: days).nights
    }

    /// Raw segments plus a tally of what came back, for debug logging.
    func sleepSegments(days: Int) async -> (nights: [SleepNight], totalSamples: Int, valueTally: [Int: Int]) {
        guard let store, days > 0 else { return ([], 0, [:]) }

        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) else {
            return ([], 0, [:])
        }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKCategoryType(.sleepAnalysis),
                predicate: HKQuery.predicateForSamples(withStart: start, end: now),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                let categorySamples = (samples ?? []).compactMap { $0 as? HKCategorySample }

                var tally: [Int: Int] = [:]
                var asleep: [(start: Date, end: Date)] = []
                for sample in categorySamples {
                    tally[sample.value, default: 0] += 1
                    if SleepAssembly.asleepValues.contains(sample.value) {
                        asleep.append((sample.startDate, sample.endDate))
                    }
                }

                continuation.resume(returning: (
                    SleepAssembly.nights(from: asleep, calendar: calendar),
                    categorySamples.count,
                    tally
                ))
            }
            store.execute(query)
        }
    }

    // MARK: - Shared query shapes

    private func latestSample(of type: HKQuantityType, unit: HKUnit) async -> MetricSample? {
        guard let store else { return nil }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: MetricSample(
                    date: sample.endDate,
                    value: sample.quantity.doubleValue(for: unit)
                ))
            }
            store.execute(query)
        }
    }

    private func dailyAverages(of type: HKQuantityType, unit: HKUnit, days: Int) async -> [DailyMetricValue] {
        guard let store, days > 0 else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else { return [] }

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: now),
                options: .discreteAverage,
                anchorDate: startOfToday,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, _ in
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }
                var values: [DailyMetricValue] = []
                collection.enumerateStatistics(from: start, to: now) { statistics, _ in
                    if let average = statistics.averageQuantity() {
                        values.append(DailyMetricValue(date: statistics.startDate, value: average.doubleValue(for: unit)))
                    }
                }
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }

    #if DEBUG
    /// Prints what HealthKit actually returned, so real reads can be confirmed
    /// before any of it reaches the screen.
    ///
    /// DEBUG-only on purpose: health values should never be written to the device
    /// log in a shipping build, even though the log never leaves the phone.
    func logAllMetrics() async {
        guard isHealthDataAvailable else {
            print("\(Self.tag) Health data isn\u{2019}t available on this device \u{2014} no reads attempted.")
            return
        }
        await logRestingHeartRate()
        await logHeartRateVariability()
        await logSleep()
        await logMovement()
        await logWorkouts()
    }

    private static let tag = "[Visualize]"
    private static let day = Date.FormatStyle(date: .abbreviated, time: .omitted)
    private static let dayAndTime = Date.FormatStyle(date: .abbreviated, time: .shortened)

    func logRestingHeartRate() async {
        let tag = Self.tag
        if let latest = await latestRestingHeartRate() {
            print("\(tag) Resting HR \u{2014} most recent sample: \(String(format: "%.0f", latest.value)) bpm at \(latest.date.formatted(Self.dayAndTime))")
        } else {
            print("\(tag) Resting HR \u{2014} no resting HR samples found.")
        }

        let week = await dailyRestingHeartRate(days: 7)
        if week.isEmpty {
            print("\(tag) Resting HR \u{2014} no resting HR samples found in the last 7 days.")
        } else {
            print("\(tag) Resting HR \u{2014} last 7 days (\(week.count) day(s) with data):")
            for entry in week {
                print("\(tag)   \(entry.date.formatted(Self.day))  \(String(format: "%.1f", entry.value)) bpm")
            }
        }
    }

    func logHeartRateVariability() async {
        let tag = Self.tag
        if let latest = await latestHeartRateVariability() {
            print("\(tag) HRV (SDNN) \u{2014} most recent sample: \(String(format: "%.0f", latest.value)) ms at \(latest.date.formatted(Self.dayAndTime))")
        } else {
            print("\(tag) HRV (SDNN) \u{2014} no HRV samples found.")
        }

        let week = await dailyHeartRateVariability(days: 7)
        if week.isEmpty {
            print("\(tag) HRV (SDNN) \u{2014} no HRV samples found in the last 7 days.")
        } else {
            print("\(tag) HRV (SDNN) \u{2014} last 7 days (\(week.count) day(s) with data):")
            for entry in week {
                print("\(tag)   \(entry.date.formatted(Self.day))  \(String(format: "%.1f", entry.value)) ms")
            }
        }
    }

    /// Sleep gets the most detail of any of these, because sleep is the one that
    /// can look empty for reasons other than "no data" \u{2014} wrong stages, overlapping
    /// sources, or samples that land outside the night window.
    func logSleep() async {
        let tag = Self.tag
        let result = await sleepSegments(days: 14)

        print("\(tag) Sleep \u{2014} \(result.totalSamples) raw category sample(s) in the last 14 days.")

        if result.totalSamples == 0 {
            print("\(tag) Sleep \u{2014} no sleep samples found. Check Health \u{203A} Browse \u{203A} Sleep for data, and that Sleep was allowed when connecting.")
            return
        }

        for (value, count) in result.valueTally.sorted(by: { $0.key < $1.key }) {
            let asleep = SleepAssembly.asleepValues.contains(value) ? "counted as asleep" : "not counted"
            print("\(tag)   stage \(Self.stageName(value)): \(count) sample(s) \u{2014} \(asleep)")
        }

        if result.nights.isEmpty {
            print("\(tag) Sleep \u{2014} samples exist but none are asleep stages (likely inBed/awake only).")
            return
        }

        print("\(tag) Sleep \u{2014} last \(result.nights.count) night(s):")
        for night in result.nights.suffix(7) {
            let hours = Int(night.asleep) / 3600
            let minutes = (Int(night.asleep) % 3600) / 60
            let bedtime = night.bedtime.map { " , to bed \($0.formatted(date: .omitted, time: .shortened))" } ?? ""
            print("\(tag)   \(night.night.formatted(Self.day))  \(hours)h \(minutes)m asleep\(bedtime)  (\(night.segmentCount) segments)")
        }
    }

    private static func stageName(_ value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue: "inBed"
        case HKCategoryValueSleepAnalysis.awake.rawValue: "awake"
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: "asleepUnspecified"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: "asleepCore"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: "asleepDeep"
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: "asleepREM"
        default: "unknown(\(value))"
        }
    }

    func logMovement() async {
        let tag = Self.tag
        if let today = await stepsToday() {
            print("\(tag) Movement \u{2014} steps so far today: \(Int(today))")
        } else {
            print("\(tag) Movement \u{2014} no step samples found for today.")
        }

        let prior = await stepsByDayToThisTime(days: 7)
        if prior.isEmpty {
            print("\(tag) Movement \u{2014} no step samples found on the previous 7 days.")
        } else {
            print("\(tag) Movement \u{2014} previous days, counted to this same time of day:")
            for entry in prior {
                print("\(tag)   \(entry.date.formatted(Self.day))  \(Int(entry.value)) steps")
            }
        }
    }

    func logWorkouts() async {
        let tag = Self.tag
        let dates = await workoutDates(days: 28)
        if dates.isEmpty {
            print("\(tag) Workouts \u{2014} no workouts found in the last 28 days.")
            return
        }
        print("\(tag) Workouts \u{2014} \(dates.count) in the last 28 days:")
        for date in dates.suffix(10) {
            print("\(tag)   \(date.formatted(Self.dayAndTime))")
        }
    }

    /// Lets the permission screen be re-viewed in the Simulator without deleting the app.
    func resetForDevelopment() {
        defaults.set(false, forKey: Self.connectedKey)
        lastErrorMessage = nil
        phase = .needsPermission
    }
    #endif
}
