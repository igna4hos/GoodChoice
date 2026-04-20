import SwiftUI

struct AddPreferenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let category: HealthPreferenceCategory
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section("profile.add.suggestions") {
                    ForEach(store.suggestions(for: category, query: query)) { preference in
                        Button {
                            store.togglePreference(preference, in: category)
                            dismiss()
                        } label: {
                            Text(preference.displayTitle(localize: store.localized(_:_:)))
                        }
                    }
                }

                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("profile.add.custom") {
                        Button {
                            store.addCustomPreference(query, to: category)
                            dismiss()
                        } label: {
                            Text(store.localized("profile.add.customValue", query))
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: Text("profile.add.search"))
            .navigationTitle(Text(LocalizedStringKey(category.titleKey)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
