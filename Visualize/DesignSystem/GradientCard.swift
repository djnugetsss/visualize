import SwiftUI

/// The signature surface: one metric, one sentence, filled edge to edge with soft color.
///
/// Reading order is deliberately label → sentence → value. The number is the
/// smallest thing on the card; the sentence is the hero.
struct GradientCard: View {
    let label: String
    let sentence: String
    let detail: String?
    let palette: SoftGradientPalette
    /// nil leaves the gradient static.
    var drift: DriftRhythm?
    var minHeight: CGFloat = 178

    init(
        label: String,
        sentence: String,
        detail: String? = nil,
        palette: SoftGradientPalette,
        drift: DriftRhythm? = nil,
        minHeight: CGFloat = 178
    ) {
        self.label = label
        self.sentence = sentence
        self.detail = detail
        self.palette = palette
        self.drift = drift
        self.minHeight = minHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(Theme.onGradientSecondary)

            Spacer(minLength: 26)

            Text(sentence)
                .font(.system(.title2, weight: .semibold))
                .foregroundStyle(Theme.onGradient)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let detail {
                Text(detail)
                    .font(.system(.footnote, weight: .regular))
                    .foregroundStyle(Theme.onGradientSecondary)
                    .padding(.top, 6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background {
            ZStack {
                if let drift {
                    DriftingGradient(palette: palette, rhythm: drift)
                } else {
                    SoftGradient(palette: palette)
                }
                // Holds white type legible over the palest corners. Tuned to be felt,
                // not seen — anything heavier reads as a scrim and muddies the color.
                LinearGradient(
                    colors: [.black.opacity(0.10), .black.opacity(0)],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.38)
                )
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.16)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .softShadow()
        .accessibilityElement(children: .combine)
    }
}

/// The calm empty state. A metric with nothing behind it yet gets a quiet card,
/// never an error and never a zero that could read as a bad score.
struct QuietCard: View {
    let label: String
    let sentence: String
    let detail: String?

    init(label: String, sentence: String, detail: String? = nil) {
        self.label = label
        self.sentence = sentence
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(Theme.secondaryText)

            Spacer(minLength: 20)

            Text(sentence)
                .font(.system(.title3, weight: .medium))
                .foregroundStyle(Theme.primaryText.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            if let detail {
                Text(detail)
                    .font(.system(.footnote, weight: .regular))
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 6)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(Theme.quietCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .softShadow(strength: 0.45)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Cards") {
    ScrollView {
        VStack(spacing: Theme.cardSpacing) {
            GradientCard(
                label: "Resting heart rate",
                sentence: "Your heart’s taking it easy today.",
                detail: "58 bpm",
                palette: .aboveBaseline
            )
            GradientCard(
                label: "Sleep",
                sentence: "A lighter night than usual.",
                detail: "6 hr 10 min",
                palette: .belowBaseline
            )
            GradientCard(
                label: "Movement",
                sentence: "Steady as usual.",
                detail: "7,400 steps",
                palette: .typical
            )
            QuietCard(
                label: "Workouts",
                sentence: "Nothing here yet.",
                detail: "This fills in as Apple Health collects your week."
            )
        }
        .padding(Theme.screenPadding)
    }
    .background(Theme.background)
}
