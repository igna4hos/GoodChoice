import SwiftUI

@main
struct GoodChoiceApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, store.language.locale)
        }
    }
}
