import SwiftUI

struct HealthProfileHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                PremiumCard(padding: 22) {
                    VStack(alignment: .leading, spacing: 16) {
                        helpRow(icon: "slider.horizontal.3", titleKey: "profile.help.how.title", messageKey: "profile.help.how.message")
                        helpRow(icon: "heart.text.square.fill", titleKey: "profile.help.why.title", messageKey: "profile.help.why.message")
                        helpRow(icon: "sparkles.rectangle.stack.fill", titleKey: "profile.help.effect.title", messageKey: "profile.help.effect.message")
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(Text("profile.help.title"))
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

    private func helpRow(icon: String, titleKey: String, messageKey: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.orange)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.orange.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(titleKey))
                    .font(.headline)
                Text(LocalizedStringKey(messageKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
