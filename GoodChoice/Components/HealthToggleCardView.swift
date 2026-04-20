import SwiftUI

struct HealthToggleCardView: View {
    let titleKey: String
    let descriptionKey: String
    @Binding var isOn: Bool

    var body: some View {
        PremiumCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $isOn) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.headline)
                }
                .tint(AppTheme.orange)

                Text(LocalizedStringKey(descriptionKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
