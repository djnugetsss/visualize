import SwiftUI

/// The quiet ground everything sits on. Cards carry the color; the app does not.
enum Theme {

    // MARK: Surfaces

    /// Off-white in light mode, soft near-black in dark. Never pure white or pure black.
    static let background = Color.adaptive(light: 0xEDECEA, dark: 0x0C0C0F)

    /// Frosted, colorless card — used for quiet states that shouldn’t imply a reading.
    static let quietCard = Color.adaptive(light: 0xFAF9F7, dark: 0x1C1C20)

    // MARK: Ink

    static let primaryText = Color.adaptive(light: 0x1B1B1D, dark: 0xF3F2EF)
    static let secondaryText = Color.adaptive(light: 0x7C7B80, dark: 0x908F95)

    /// Ink that sits on top of a gradient card.
    static let onGradient = Color.white
    static let onGradientSecondary = Color.white.opacity(0.76)

    // MARK: Geometry

    static let cardCornerRadius: CGFloat = 30
    static let cardPadding: CGFloat = 22
    static let screenPadding: CGFloat = 22
    /// Cards still breathe, but the Today feed is a glance: five of these should
    /// be a short scroll, not five screens.
    static let cardSpacing: CGFloat = 14
}

// MARK: - Soft depth

extension View {
    /// Diffused light, not a drop shadow. Two passes: a wide ambient one and a close contact one.
    func softShadow(strength: Double = 1) -> some View {
        self
            .shadow(color: .black.opacity(0.10 * strength), radius: 26 * strength, x: 0, y: 14 * strength)
            .shadow(color: .black.opacity(0.04 * strength), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Hex helpers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A single color that resolves differently in light and dark mode.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
