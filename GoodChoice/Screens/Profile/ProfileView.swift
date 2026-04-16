import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showingPaywall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                accountSwitcher

                if let profile = store.currentProfile {
                    accountCard(profile: profile)
                    subscriptionCard(profile: profile)
                    preferenceEditor(profile: profile)
                } else {
                    signedOutState
                }
            }
            .padding(20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("profile.title"))
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }

    private var accountSwitcher: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("profile.accounts.title")
                        .font(.headline)
                    Spacer()
                    if store.isSignedIn {
                        Button("profile.action.logout") {
                            store.logout()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.availableProfiles) { profile in
                            accountSwitcherButton(profile: profile)
                        }
                    }
                }
            }
        }
    }

    private func accountSwitcherButton(profile: UserProfile) -> some View {
        let isSelected = store.currentProfile?.id == profile.id
        let accent = profile.tier == .premium ? AppTheme.orange : AppTheme.green

        return Button {
            store.signIn(as: profile.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(store.localized(profile.nameKey))
                        .font(.headline)
                    Spacer()
                    Image(systemName: profile.tier == .premium ? "crown.fill" : "person.fill")
                        .foregroundStyle(accent)
                }

                Text(store.localized(profile.subtitleKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                Text(store.localized(profile.tier.titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .padding(16)
            .frame(width: 200, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.heroGradient)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private func accountCard(profile: UserProfile) -> some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.localized(profile.nameKey))
                            .font(.title2.bold())
                        Text(store.localized(profile.subtitleKey))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(store.localized(profile.tier.titleKey))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(profile.tier == .premium ? AppTheme.orange : AppTheme.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill((profile.tier == .premium ? AppTheme.orange : AppTheme.green).opacity(0.12))
                        )
                }

                NavigationLink {
                    SettingsView()
                        .environmentObject(store)
                } label: {
                    HStack {
                        Label("profile.settings", systemImage: "gearshape")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.background)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func subscriptionCard(profile: UserProfile) -> some View {
        Button {
            showingPaywall = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(profile.tier == .premium ? AppTheme.premiumGradient : AppTheme.heroGradient)
                    .shadow(color: AppTheme.subtleShadow, radius: 18, x: 0, y: 10)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(profile.tier == .premium ? "profile.subscription.active" : "profile.subscription.title")
                            .font(.title3.bold())
                            .foregroundStyle(profile.tier == .premium ? .white : .primary)
                        Spacer()
                        Image(systemName: profile.tier == .premium ? "checkmark.seal.fill" : "crown.fill")
                            .foregroundStyle(profile.tier == .premium ? .white : AppTheme.orange)
                    }

                    Text(profile.tier == .premium ? "profile.subscription.premiumMessage" : "profile.subscription.freeMessage")
                        .font(.subheadline)
                        .foregroundStyle(profile.tier == .premium ? .white.opacity(0.9) : .secondary)

                    HStack(spacing: 10) {
                        tag("paywall.benefit.analytics", light: profile.tier == .premium)
                        tag("paywall.benefit.unlimited", light: profile.tier == .premium)
                        tag("paywall.benefit.ai", light: profile.tier == .premium)
                    }
                }
                .padding(22)
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
    }

    private func preferenceEditor(profile: UserProfile) -> some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("profile.preferences.title")
                        .font(.headline)
                    Spacer()
                    Button("profile.preferences.reset") {
                        store.resetProfilePreferences()
                    }
                    .font(.subheadline.weight(.semibold))
                }

                ingredientSection(
                    titleKey: "profile.preferences.allergies",
                    values: IngredientToken.allCases.filter { [.peanuts, .almonds, .soy, .gluten, .shellfish, .fragrance].contains($0) },
                    selected: Set(profile.allergies),
                    action: store.toggleAllergy
                )

                ingredientSection(
                    titleKey: "profile.preferences.intolerances",
                    values: IngredientToken.allCases.filter { [.lactose, .gluten, .caffeine, .alcohol].contains($0) },
                    selected: Set(profile.intolerances),
                    action: store.toggleIntolerance
                )

                ingredientSection(
                    titleKey: "profile.preferences.avoidIngredients",
                    values: IngredientToken.allCases.filter { [.addedSugar, .fragrance, .parabens, .sulfates, .bleach, .ammonia].contains($0) },
                    selected: Set(profile.avoidedIngredients),
                    action: store.toggleAvoidedIngredient
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("profile.preferences.avoidCategories")
                        .font(.subheadline.weight(.semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                        ForEach(ProductCategory.allCases) { category in
                            selectionChip(
                                title: store.localized(category.titleKey),
                                selected: profile.avoidedCategories.contains(category)
                            ) {
                                store.toggleAvoidedCategory(category)
                            }
                        }
                    }
                }
            }
        }
    }

    private var signedOutState: some View {
        PremiumCard(padding: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("profile.signedOut.title")
                    .font(.headline)
                Text("profile.signedOut.message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ingredientSection(
        titleKey: String,
        values: [IngredientToken],
        selected: Set<IngredientToken>,
        action: @escaping (IngredientToken) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(titleKey))
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                ForEach(values) { ingredient in
                    selectionChip(
                        title: store.localized(ingredient.titleKey),
                        selected: selected.contains(ingredient)
                    ) {
                        action(ingredient)
                    }
                }
            }
        }
    }

    private func selectionChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(selected ? AppTheme.green : AppTheme.background)
                )
        }
        .buttonStyle(.plain)
    }

    private func tag(_ key: String, light: Bool) -> some View {
        Text(LocalizedStringKey(key))
            .font(.caption.weight(.semibold))
            .foregroundStyle(light ? .white : AppTheme.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(light ? Color.white.opacity(0.18) : AppTheme.orange.opacity(0.12))
            )
    }
}
