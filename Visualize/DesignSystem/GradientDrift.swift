import SwiftUI

/// How a card breathes. Derived from the metric's standing, so there is one rule
/// for all five cards and no per-card special-casing.
///
/// The mapping soothes rather than mirrors: a state running below the person's own
/// baseline drifts the *slowest and gentlest* of the three, never the liveliest.
/// A card shouldn't get restless exactly when the person reading it might be.
///
/// The spread is deliberately small — 8 seconds and two tenths of a degree across
/// the whole range — so no state reads as agitated and none reads as inert. Every
/// card is light settling; the elevated one just settles a little more slowly.
struct DriftRhythm: Equatable {
    /// Seconds for a full there-and-back cycle.
    let cycle: Double
    let rotation: Double
    let offset: CGFloat

    init(standing: BaselineStanding?) {
        switch standing {
        case .below?:
            cycle = 48; rotation = 0.6; offset = 3
        case .above?:
            cycle = 40; rotation = 0.8; offset = 4
        // Typical, and "not enough history yet", sit between the two.
        default:
            cycle = 44; rotation = 0.7; offset = 3.5
        }
    }
}

/// A gradient with a very slow ambient drift.
///
/// The whole blurred gradient is transformed rather than each blob being moved and
/// re-rendered: a rigid transform of an already-rasterized layer is a GPU operation
/// Core Animation runs on the render server, whereas redrawing three radial
/// gradients under a 20pt blur every frame is CPU work, times five cards. At this
/// amplitude the two are indistinguishable — it reads as light shifting either way.
///
/// Motion stops completely when the app isn't active, when the card scrolls out of
/// view, and whenever Reduce Motion is on.
struct DriftingGradient: View {
    let palette: SoftGradientPalette
    let rhythm: DriftRhythm

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var isDrifting = false
    @State private var isOnScreen = false

    private var shouldDrift: Bool {
        isOnScreen && scenePhase == .active && !reduceMotion
    }

    var body: some View {
        SoftGradient(palette: palette)
            // Headroom so the drift never pulls a transparent edge into the card.
            .scaleEffect(1.18)
            .rotationEffect(.degrees(isDrifting ? rhythm.rotation : -rhythm.rotation))
            .offset(
                x: isDrifting ? rhythm.offset : -rhythm.offset,
                y: isDrifting ? -rhythm.offset * 0.6 : rhythm.offset * 0.6
            )
            // autoreverses, so the animation's duration is half a full cycle.
            .animation(
                shouldDrift
                    ? .easeInOut(duration: rhythm.cycle / 2).repeatForever(autoreverses: true)
                    : nil,
                value: isDrifting
            )
            .onAppear { isOnScreen = true }
            .onDisappear { isOnScreen = false }
            .onChange(of: shouldDrift, initial: true) { _, drift in
                isDrifting = drift
            }
    }
}
