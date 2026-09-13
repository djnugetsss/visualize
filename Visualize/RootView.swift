import SwiftUI

struct RootView: View {
    @StateObject private var health = HealthKitService()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch health.phase {
            case .needsPermission, .requesting:
                PermissionView(health: health)
                    .transition(.opacity)
            case .connected:
                TodayView(health: health)
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.55), value: health.phase)
    }
}

#Preview {
    RootView()
}
