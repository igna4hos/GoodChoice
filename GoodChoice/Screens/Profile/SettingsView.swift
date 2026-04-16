import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("settings.language.title") {
                Picker("settings.language.title", selection: Binding(
                    get: { store.language },
                    set: { store.switchLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(store.localized(language.titleKey)).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("settings.demo.title") {
                Button("settings.demo.resetOnboarding") {
                    store.resetOnboarding()
                }
            }
        }
        .navigationTitle(Text("settings.title"))
    }
}
