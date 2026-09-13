import SwiftUI

/// Where a value sits against the person’s **own** recent days — never against a
/// medical range, and never against anyone else.
///
/// The case names describe *standing*, not numeric direction. For resting heart rate
/// a number below the person’s usual is `.above`: eased, relative to their baseline.
/// Each metric says which direction means which standing when it asks.
enum BaselineStanding: Equatable {
    case above
    case typical
    case below

    var palette: SoftGradientPalette {
        switch self {
        case .above: .aboveBaseline
        case .typical: .typical
        case .below: .belowBaseline
        }
    }
}

enum Baseline {

    /// Which numeric direction counts as eased for a given metric. Resting heart rate
    /// eases downward; heart rate variability eases upward.
    enum Eased {
        case lower
        case higher
    }

    /// Compares one value to the person’s own recent daily values.
    ///
    /// Returns nil when there isn’t enough history to say anything honest yet — the
    /// caller shows the value without claiming a comparison.
    static func standing(
        of value: Double,
        against history: [Double],
        eased: Eased,
        band bounds: ClosedRange<Double>
    ) -> BaselineStanding? {
        guard history.count >= 3 else { return nil }

        let mean = history.reduce(0, +) / Double(history.count)
        let variance = history.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(history.count - 1)
        let deviation = variance > 0 ? variance.squareRoot() : 0

        // One standard deviation of their own recent days, floored so a very steady
        // stretch doesn’t flip states on noise, and capped so one turbulent week
        // doesn’t widen the band until everything reads as typical.
        let band = min(max(deviation, bounds.lowerBound), bounds.upperBound)
        let delta = value - mean

        guard abs(delta) >= band else { return .typical }

        switch eased {
        case .lower: return delta < 0 ? .above : .below
        case .higher: return delta < 0 ? .below : .above
        }
    }
}
