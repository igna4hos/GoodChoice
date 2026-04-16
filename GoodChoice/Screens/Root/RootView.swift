import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .tint(AppTheme.orange)
    }
}
