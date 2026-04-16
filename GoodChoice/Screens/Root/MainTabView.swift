import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack {
                ScanView()
            }
            .tabItem {
                Label(LocalizedStringKey(AppTab.scan.titleKey), systemImage: AppTab.scan.systemImage)
            }
            .tag(AppTab.scan)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(LocalizedStringKey(AppTab.history.titleKey), systemImage: AppTab.history.systemImage)
            }
            .tag(AppTab.history)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label(LocalizedStringKey(AppTab.analytics.titleKey), systemImage: AppTab.analytics.systemImage)
            }
            .tag(AppTab.analytics)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(LocalizedStringKey(AppTab.profile.titleKey), systemImage: AppTab.profile.systemImage)
            }
            .tag(AppTab.profile)
        }
    }
}
