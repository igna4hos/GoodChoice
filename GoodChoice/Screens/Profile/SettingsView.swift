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

            if let account = store.currentAccount {
                Section("settings.profileSwitch.title") {
                    ForEach(account.profiles) { profile in
                        Button(profile.name) {
                            store.switchActiveProfile(profile.id)
                        }
                    }
                }
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
