import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(AppTheme.premiumGradient)
                            .frame(height: 240)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("paywall.title")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("paywall.subtitle")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))

                            HStack(spacing: 10) {
                                chip("paywall.benefit.analytics")
                                chip("paywall.benefit.unlimited")
                                chip("paywall.benefit.ai")
                            }
                        }
                        .padding(24)
                    }

                    VStack(spacing: 14) {
                        ForEach(store.planFeatures()) { feature in
                            FeatureRowView(feature: feature)
                                .environmentObject(store)
                        }
                    }

                    Button {
                        store.setTier(.premium)
                        dismiss()
                    } label: {
                        Text(store.currentTier == .premium ? "paywall.currentPlan" : "paywall.cta")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.premiumGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .disabled(store.currentTier == .premium)

                    Button("action.close") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }

    private func chip(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.18))
            )
    }
}
