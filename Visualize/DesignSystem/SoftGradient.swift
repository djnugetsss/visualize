import SwiftUI

/// A soft, blurred, multi-stop gradient — diffused light, never hard bands.
///
/// Built as a base wash plus a few radial "blobs", then blurred as a whole and
/// scaled up slightly so the blur never softens the card's edges.
struct SoftGradient: View {
    let palette: SoftGradientPalette

    var body: some View {
        GeometryReader { geo in
            // Blob size follows the long edge so color spans the shape; blur follows
            // the short edge so a wide, short surface (a button) doesn’t wash out.
            let span = max(geo.size.width, geo.size.height)
            let thickness = min(geo.size.width, geo.size.height)
            let blur = thickness * palette.softness * 1.2

            ZStack {
                LinearGradient(colors: palette.base, startPoint: .topLeading, endPoint: .bottomTrailing)

                ForEach(Array(palette.blobs.enumerated()), id: \.offset) { _, blob in
                    let r = span * blob.radius
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: blob.color.opacity(blob.opacity), location: 0),
                            .init(color: blob.color.opacity(blob.opacity * 0.45), location: 0.45),
                            .init(color: blob.color.opacity(0), location: 1)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: r
                    )
                    .frame(width: r * 2, height: r * 2)
                    .position(x: geo.size.width * blob.center.x, y: geo.size.height * blob.center.y)
                }
            }
            .blur(radius: blur)
            // Scale past the blur's soft edge so the shape's own edges stay crisp.
            .scaleEffect(1 + palette.softness * 2.6)
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

// MARK: - Palettes

struct SoftGradientPalette {
    struct Blob {
        let color: Color
        let center: UnitPoint
        let radius: CGFloat
        let opacity: Double
    }

    let base: [Color]
    let blobs: [Blob]
    /// Blur radius as a fraction of the view's longest edge.
    var softness: CGFloat = 0.10
}

extension SoftGradientPalette {

    /// Gradient-as-status. A metric's hue comes from where it sits against the
    /// person’s *own* recent baseline — never against a medical range.
    /// The worst state here is a warm orange. There is no red anywhere in this app.

    /// Running better than their own baseline — greens and teals, but the card
    /// still opens on a warm corner. The journey is what makes it feel alive:
    /// cream-amber → chartreuse → green → teal, corner to corner.
    static let aboveBaseline = SoftGradientPalette(
        base: [
            .adaptive(light: 0xFBDCB6, dark: 0x63471F),
            .adaptive(light: 0xF3CB95, dark: 0x594B26),
            .adaptive(light: 0xC2DA8A, dark: 0x3A5730),
            .adaptive(light: 0x63BC82, dark: 0x1C5C40),
            .adaptive(light: 0x2E9A7C, dark: 0x0E4438)
        ],
        blobs: [
            .init(color: .adaptive(light: 0xF9BE92, dark: 0xA67231), center: .init(x: 0.10, y: 0.05), radius: 0.62, opacity: 1.0),
            .init(color: .adaptive(light: 0xA9D77A, dark: 0x4E7C38), center: .init(x: 0.40, y: 0.44), radius: 0.50, opacity: 0.80),
            .init(color: .adaptive(light: 0x2FA88C, dark: 0x1B8A72), center: .init(x: 0.94, y: 0.94), radius: 0.58, opacity: 0.88)
        ]
    )

    /// Typical for them — soft neutral warmth, sand and pale amber.
    static let typical = SoftGradientPalette(
        base: [
            .adaptive(light: 0xFBEED4, dark: 0x453626),
            .adaptive(light: 0xF0D3A4, dark: 0x3A2C1D),
            .adaptive(light: 0xDDA87A, dark: 0x281D14)
        ],
        blobs: [
            .init(color: .adaptive(light: 0xFAE3C4, dark: 0x7F5B39), center: .init(x: 0.06, y: 0.04), radius: 0.50, opacity: 0.92),
            .init(color: .adaptive(light: 0xEFC48C, dark: 0x8A6034), center: .init(x: 0.42, y: 0.48), radius: 0.50, opacity: 0.78),
            .init(color: .adaptive(light: 0xD79A66, dark: 0x6B4526), center: .init(x: 0.92, y: 0.92), radius: 0.56, opacity: 0.80)
        ]
    )

    /// Below their own baseline — warm, gentle orange. Worth noticing, not alarming.
    static let belowBaseline = SoftGradientPalette(
        base: [
            .adaptive(light: 0xCBCDE9, dark: 0x2B2C46),
            .adaptive(light: 0xF0C89C, dark: 0x543322),
            .adaptive(light: 0xF0904A, dark: 0x7A3F1E)
        ],
        blobs: [
            .init(color: .adaptive(light: 0xF39A52, dark: 0x8A4A22), center: .init(x: 0.74, y: 0.74), radius: 0.62, opacity: 0.88),
            .init(color: .adaptive(light: 0xBEC4EA, dark: 0x353758), center: .init(x: 0.20, y: 0.18), radius: 0.56, opacity: 0.85),
            .init(color: .white, center: .init(x: 0.50, y: 0.04), radius: 0.36, opacity: 0.22)
        ]
    )

    /// No reading yet — calm and ambient, deliberately carries no status meaning.
    /// Same warm→cool travel as the status palettes: peach-cream → green → periwinkle.
    static let ambient = SoftGradientPalette(
        base: [
            .adaptive(light: 0xFBDABA, dark: 0x63431F),
            .adaptive(light: 0xF5C89E, dark: 0x584524),
            .adaptive(light: 0x8ECBA4, dark: 0x2C5442),
            .adaptive(light: 0x55B5AA, dark: 0x1A4C56),
            .adaptive(light: 0x7C92D8, dark: 0x2B3568)
        ],
        blobs: [
            .init(color: .adaptive(light: 0xF9B98E, dark: 0xA87031), center: .init(x: 0.10, y: 0.05), radius: 0.64, opacity: 1.0),
            .init(color: .adaptive(light: 0x4FB583, dark: 0x2E7C56), center: .init(x: 0.38, y: 0.58), radius: 0.50, opacity: 0.84),
            .init(color: .adaptive(light: 0x7B8FDA, dark: 0x414C9A), center: .init(x: 0.94, y: 0.94), radius: 0.58, opacity: 0.90)
        ],
        softness: 0.09
    )

    /// Full-screen wash behind the permission screen. Barely there.
    static let pageWash = SoftGradientPalette(
        base: [
            .adaptive(light: 0xEFEEEC, dark: 0x0C0C0F),
            .adaptive(light: 0xECEBE8, dark: 0x0E0E12)
        ],
        blobs: [
            .init(color: .adaptive(light: 0xF5D9BC, dark: 0x33261A), center: .init(x: 0.06, y: 0.04), radius: 0.78, opacity: 0.75),
            .init(color: .adaptive(light: 0xC7E4D6, dark: 0x143029), center: .init(x: 0.18, y: 0.62), radius: 0.78, opacity: 0.55),
            .init(color: .adaptive(light: 0xCFD6F2, dark: 0x191933), center: .init(x: 0.94, y: 0.96), radius: 0.70, opacity: 0.58)
        ],
        softness: 0.20
    )
}
