import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            AppTheme.heroGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Spacer(minLength: 30)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppTheme.green)

                            Text("app.title")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                        }

                        Text("onboarding.headline")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("onboarding.subheadline")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        onboardingCard(
                            icon: "barcode.viewfinder",
                            titleKey: "onboarding.card.scan.title",
                            messageKey: "onboarding.card.scan.message",
                            tint: AppTheme.orange
                        )
                        onboardingCard(
                            icon: "person.crop.circle.badge.checkmark",
                            titleKey: "onboarding.card.personal.title",
                            messageKey: "onboarding.card.personal.message",
                            tint: AppTheme.green
                        )
                        onboardingCard(
                            icon: "bolt.badge.clock",
                            titleKey: "onboarding.card.fast.title",
                            messageKey: "onboarding.card.fast.message",
                            tint: AppTheme.orange
                        )
                    }

                    PremiumCard(padding: 22) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("onboarding.promo.title")
                                .font(.headline)
                            Text("onboarding.promo.message")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(spacing: 12) {
                        Button(action: store.completeOnboarding) {
                            Text("onboarding.cta.primary")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppTheme.premiumGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .foregroundStyle(.white)
                        }

                        Button(action: store.completeOnboarding) {
                            Text("onboarding.cta.secondary")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 22)
            }
        }
    }

    private func onboardingCard(icon: String, titleKey: String, messageKey: String, tint: Color) -> some View {
        PremiumCard(padding: 20) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(tint.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 8) {
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
}
