import SwiftUI

struct PermissionView: View {
    @ObservedObject var health: HealthKitService
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            SoftGradient(palette: .pageWash).ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("visualize")
                            .font(.system(.subheadline, weight: .medium))
                            .tracking(0.6)
                            .foregroundStyle(Theme.secondaryText)

                        Spacer(minLength: 44)

                        Text("Your health,\nin plain language.")
                            .font(.system(.largeTitle, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Apple Health already knows how you slept, how your heart is doing, and how much you moved. Visualize reads it and gives you back a color and a sentence. Nothing to log, nothing to score.")
                            .font(.system(.body, weight: .regular))
                            .foregroundStyle(Theme.secondaryText)
                            .lineSpacing(5)
                            .padding(.top, 18)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 36)

                        whatWeRead

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height - 190, alignment: .top)
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                }
                .safeAreaInset(edge: .bottom) { connectFooter }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 14)
        .onAppear {
            withAnimation(.smooth(duration: 0.9)) { hasAppeared = true }
        }
    }

    // MARK: Pieces

    private var whatWeRead: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What we read")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
                .padding(.bottom, 18)

            ForEach(Array(HealthMetrics.humanNames.enumerated()), id: \.offset) { index, name in
                if index > 0 {
                    Divider()
                        .background(Theme.secondaryText.opacity(0.10))
                        .padding(.vertical, 14)
                }
                Text(name)
                    .font(.system(.body, weight: .regular))
                    .foregroundStyle(Theme.primaryText.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.quietCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .softShadow(strength: 0.4)
    }

    private var connectFooter: some View {
        VStack(spacing: 14) {
            Button {
                Task { await health.connect() }
            } label: {
                ZStack {
                    SoftGradient(palette: .ambient)
                    if health.phase == .requesting {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Connecting…")
                        }
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(Theme.onGradient)
                    } else {
                        Text("Connect Health")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(Theme.onGradient)
                    }
                }
                .frame(height: 58)
                .frame(maxWidth: .infinity)
                .clipShape(Capsule())
                .softShadow(strength: 0.6)
            }
            .buttonStyle(.plain)
            .disabled(health.phase == .requesting)

            Text(health.lastErrorMessage ?? "Read-only. Your data stays on your iPhone — nothing is uploaded, and there’s no account.")
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview("Permission") {
    PermissionView(health: HealthKitService())
}
