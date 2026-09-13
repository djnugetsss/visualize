import SwiftUI

struct TodayView: View {
    @ObservedObject var health: HealthKitService
    @StateObject private var model = TodayModel()
    @State private var hasAppeared = false

    private var todayLine: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Theme.cardSpacing) {
                    header
                        .padding(.bottom, 6)

                    ForEach(model.cards) { card in
                        view(for: card)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
        .onAppear {
            withAnimation(.smooth(duration: 0.8)) { hasAppeared = true }
        }
        .task {
            #if DEBUG
            await health.logAllMetrics()
            #endif
            await model.load(from: health)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
            Text(todayLine)
                .font(.system(.subheadline, weight: .regular))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        #if DEBUG
        .onLongPressGesture(minimumDuration: 1.2) { health.resetForDevelopment() }
        #endif
    }

    @ViewBuilder
    private func view(for card: MetricCard) -> some View {
        switch card.state {
        case .loading:
            // Colour first, words a moment later — never a spinner on this screen.
            GradientCard(
                label: card.label,
                sentence: "",
                palette: .ambient
            )

        case .ready(let readout):
            GradientCard(
                label: card.label,
                sentence: readout.sentence,
                detail: readout.detail,
                palette: readout.palette,
                // Trial: motion on the resting heart rate card only.
                drift: card.label == RestingHeartRate.label
                    ? DriftRhythm(standing: readout.standing)
                    : nil
            )

        case .empty(let sentence, let detail):
            QuietCard(label: card.label, sentence: sentence, detail: detail)
        }
    }
}

#Preview("Today") {
    TodayView(health: HealthKitService())
}
