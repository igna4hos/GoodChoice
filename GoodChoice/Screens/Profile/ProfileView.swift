import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showingPaywall = false
    @State private var showingHelp = false
    @State private var addPreferenceCategory: HealthPreferenceCategory?
    @State private var pendingDeletion: PendingDeletion?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let account = store.currentAccount, let profile = store.currentProfile {
                    summaryCard(account: account, profile: profile)
                    accountSwitcher
                    healthProfileCard(profile: profile)
                    togglesSection(profile: profile)
                    subscriptionCard(account: account)
                    settingsCard(account: account)
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
        .sheet(isPresented: $showingHelp) {
            HealthProfileHelpView()
        }
        .sheet(item: $addPreferenceCategory) { category in
            AddPreferenceSheet(category: category)
                .environmentObject(store)
        }
        .confirmationDialog(
            store.localized("profile.delete.title"),
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingDeletion {
                Button(store.localized("profile.delete.confirm", pendingDeletion.preference.displayTitle(localize: store.localized(_:_:))), role: .destructive) {
                    store.deletePreference(pendingDeletion.preference.id, from: pendingDeletion.category)
                    self.pendingDeletion = nil
                }
            }
            Button("action.close", role: .cancel) {
                pendingDeletion = nil
            }
        }
    }

    private func summaryCard(account: UserAccount, profile: UserProfile) -> some View {
        PremiumCard(padding: 22) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.heroGradient)
                            .frame(width: 72, height: 72)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(AppTheme.orange)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(account.firstName) \(account.lastName)")
                            .font(.title2.bold())
                        Text(profile.name)
                            .font(.headline)
                        Text(store.localized(profile.relation.titleKey))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack {
                    Text(store.localized("profile.plan.label", store.localized(account.tier.titleKey)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(account.tier == .premium ? AppTheme.orange : AppTheme.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill((account.tier == .premium ? AppTheme.orange : AppTheme.green).opacity(0.12))
                        )

                    Spacer()

                    Button {
                        store.addSecondaryProfile()
                    } label: {
                        Label("profile.addProfile", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .disabled(account.profiles.count >= 2)
                }
            }
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
                        ForEach(store.availableAccounts) { account in
                            accountButton(account)
                        }
                    }
                }
            }
        }
    }

    private func accountButton(_ account: UserAccount) -> some View {
        let isSelected = store.currentAccount?.id == account.id
        let accent = account.tier == .premium ? AppTheme.orange : AppTheme.green

        return Button {
            store.signIn(as: account.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(account.firstName) \(account.lastName)")
                        .font(.headline)
                    Spacer()
                    Image(systemName: account.tier == .premium ? "crown.fill" : "person.fill")
                        .foregroundStyle(accent)
                }

                Text(store.localized(account.accountSummaryKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                Text(store.localized(account.tier.titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .padding(16)
            .frame(width: 220, alignment: .leading)
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

    private func healthProfileCard(profile: UserProfile) -> some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("profile.preferences.title")
                        .font(.headline)
                    Spacer()
                    Button("profile.preferences.help") {
                        showingHelp = true
                    }
                    .font(.subheadline.weight(.semibold))
                    Button("profile.preferences.reset") {
                        store.resetProfilePreferences()
                    }
                    .font(.subheadline.weight(.semibold))
                }

                preferenceSection(category: .allergies, selected: profile.allergies)
                preferenceSection(category: .intolerances, selected: profile.intolerances)
                preferenceSection(category: .avoidIngredients, selected: profile.avoidIngredients)
            }
        }
    }

    private func preferenceSection(category: HealthPreferenceCategory, selected: [HealthPreference]) -> some View {
        let selectedTokens = Set(selected.map(\.token))
        let visibleItems = deduplicatePreferences(selected + category.suggestionTokens.map(HealthPreference.predefined))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey(category.titleKey))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    addPreferenceCategory = category
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.orange)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                ForEach(visibleItems) { preference in
                    PreferenceChipView(
                        title: preference.displayTitle(localize: store.localized(_:_:)),
                        selected: selectedTokens.contains(preference.token)
                    ) {
                        store.togglePreference(preference, in: category)
                    }
                    .onLongPressGesture {
                        if selectedTokens.contains(preference.token) {
                            pendingDeletion = PendingDeletion(category: category, preference: preference)
                        }
                    }
                }
            }
        }
    }

    private func togglesSection(profile: UserProfile) -> some View {
        VStack(spacing: 14) {
            HealthToggleCardView(
                titleKey: "profile.toggle.gluten.title",
                descriptionKey: "profile.toggle.gluten.description",
                isOn: Binding(
                    get: { profile.glutenSensitivity },
                    set: { _ in store.toggleGlutenSensitivity() }
                )
            )

            HealthToggleCardView(
                titleKey: "profile.toggle.sugar.title",
                descriptionKey: "profile.toggle.sugar.description",
                isOn: Binding(
                    get: { profile.sugarTracking },
                    set: { _ in store.toggleSugarTracking() }
                )
            )
        }
    }

    private func subscriptionCard(account: UserAccount) -> some View {
        Button {
            showingPaywall = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(account.tier == .premium ? AppTheme.premiumGradient : AppTheme.heroGradient)
                    .shadow(color: AppTheme.subtleShadow, radius: 18, x: 0, y: 10)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(account.tier == .premium ? "profile.subscription.active" : "profile.subscription.title")
                            .font(.title3.bold())
                            .foregroundStyle(account.tier == .premium ? .white : .primary)
                        Spacer()
                        Image(systemName: account.tier == .premium ? "checkmark.seal.fill" : "crown.fill")
                            .foregroundStyle(account.tier == .premium ? .white : AppTheme.orange)
                    }

                    Text(account.tier == .premium ? "profile.subscription.premiumMessage" : "profile.subscription.freeMessage")
                        .font(.subheadline)
                        .foregroundStyle(account.tier == .premium ? .white.opacity(0.92) : .secondary)

                    HStack(spacing: 10) {
                        tag("paywall.benefit.analytics", light: account.tier == .premium)
                        tag("paywall.benefit.unlimited", light: account.tier == .premium)
                        tag("paywall.benefit.ai", light: account.tier == .premium)
                    }
                }
                .padding(22)
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
    }

    private func settingsCard(account: UserAccount) -> some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                Text("settings.title")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text("settings.language.title")
                        .font(.subheadline.weight(.semibold))
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

                VStack(alignment: .leading, spacing: 10) {
                    Text("settings.profileSwitch.title")
                        .font(.subheadline.weight(.semibold))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(account.profiles) { profile in
                            PreferenceChipView(
                                title: profile.name,
                                selected: store.currentProfile?.id == profile.id
                            ) {
                                store.switchActiveProfile(profile.id)
                            }
                        }
                    }
                }

                Button("settings.demo.resetOnboarding") {
                    store.resetOnboarding()
                }
                .font(.subheadline.weight(.semibold))
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

    private func deduplicatePreferences(_ items: [HealthPreference]) -> [HealthPreference] {
        var seen: Set<String> = []
        return items.filter { seen.insert($0.token).inserted }
    }
}

private struct PendingDeletion {
    let category: HealthPreferenceCategory
    let preference: HealthPreference
}
