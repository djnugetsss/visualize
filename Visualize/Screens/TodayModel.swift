import Foundation

/// Loads every Today metric. One place for the reads, so the view stays about
/// presentation and new metrics slot in beside the existing ones.
@MainActor
final class TodayModel: ObservableObject {

    @Published private(set) var cards: [MetricCard] = [
        MetricCard(label: Sleep.label, state: .loading),
        MetricCard(label: RestingHeartRate.label, state: .loading),
        MetricCard(label: HeartRateVariability.label, state: .loading),
        MetricCard(label: Movement.label, state: .loading),
        MetricCard(label: Workouts.label, state: .loading)
    ]

    /// Fifteen days: fourteen of baseline plus today, so the most recent reading
    /// is never compared against itself.
    private let historyWindowInDays = 15

    func load(from health: HealthKitService) async {
        let available = health.isHealthDataAvailable

        async let sleepNights = health.sleepNights(days: historyWindowInDays)
        async let restingLatest = health.latestRestingHeartRate()
        async let restingHistory = health.dailyRestingHeartRate(days: historyWindowInDays)
        async let hrvLatest = health.latestHeartRateVariability()
        async let hrvHistory = health.dailyHeartRateVariability(days: historyWindowInDays)
        async let stepsToday = health.stepsToday()
        async let stepsPrior = health.stepsByDayToThisTime(days: 14)
        async let workouts = health.workoutDates(days: Workouts.historyWindowInDays)

        cards = [
            MetricCard(
                label: Sleep.label,
                state: Sleep.state(nights: await sleepNights, healthDataAvailable: available)
            ),
            MetricCard(
                label: RestingHeartRate.label,
                state: RestingHeartRate.state(
                    latest: await restingLatest,
                    history: await restingHistory,
                    healthDataAvailable: available
                )
            ),
            MetricCard(
                label: HeartRateVariability.label,
                state: HeartRateVariability.state(
                    latest: await hrvLatest,
                    history: await hrvHistory,
                    healthDataAvailable: available
                )
            ),
            MetricCard(
                label: Movement.label,
                state: Movement.state(
                    stepsToday: await stepsToday,
                    priorDays: await stepsPrior,
                    healthDataAvailable: available
                )
            ),
            MetricCard(
                label: Workouts.label,
                state: Workouts.state(workoutDates: await workouts, healthDataAvailable: available)
            )
        ]
    }
}
