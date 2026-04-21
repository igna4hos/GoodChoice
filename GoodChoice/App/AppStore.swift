import Combine
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var hasSeenOnboarding: Bool
    @Published var language: AppLanguage
    @Published var selectedTab: AppTab = .scan
    @Published private(set) var accounts: [UserAccount]
    @Published private(set) var currentAccountID: UUID?

    private let defaults: UserDefaults
    private let productService: MockProductService
    private let profileService: MockProfileService
    private let analyticsService: MockAnalyticsService
    private let subscriptionService: MockSubscriptionService
    private var localeChangeCancellable: AnyCancellable?

    init(
        defaults: UserDefaults = .standard,
        productService: MockProductService? = nil,
        profileService: MockProfileService? = nil,
        analyticsService: MockAnalyticsService? = nil,
        subscriptionService: MockSubscriptionService? = nil
    ) {
        self.defaults = defaults

        let resolvedProductService = productService ?? MockProductService()
        let resolvedProfileService = profileService ?? MockProfileService()
        let resolvedAnalyticsService = analyticsService ?? MockAnalyticsService()
        let resolvedSubscriptionService = subscriptionService ?? MockSubscriptionService()

        self.productService = resolvedProductService
        self.profileService = resolvedProfileService
        self.analyticsService = resolvedAnalyticsService
        self.subscriptionService = resolvedSubscriptionService

        let initialAccounts = resolvedProfileService.makeAccounts()
        let savedLanguage = AppLanguage(rawValue: defaults.string(forKey: StorageKey.language) ?? "")
        let defaultAccountID = initialAccounts.first?.id
        let savedAccountID = defaults.string(forKey: StorageKey.currentAccountID).flatMap(UUID.init(uuidString:))
        let resolvedAccountID = initialAccounts.contains(where: { $0.id == savedAccountID }) ? savedAccountID : defaultAccountID
        let initialHasSeenOnboarding = defaults.object(forKey: StorageKey.hasSeenOnboarding) as? Bool ?? false
        let hasSavedLanguage = defaults.object(forKey: StorageKey.language) != nil
        let hasManualLanguageOverride = defaults.bool(forKey: StorageKey.manualLanguageOverride)
        let hasManualLanguageOverrideRecord = defaults.object(forKey: StorageKey.manualLanguageOverride) != nil
        let initialLanguage: AppLanguage

        if hasManualLanguageOverride || (!hasManualLanguageOverrideRecord && hasSavedLanguage) {
            initialLanguage = savedLanguage ?? .english
            defaults.set(true, forKey: StorageKey.manualLanguageOverride)
        } else {
            initialLanguage = AppLanguage.preferredSystemLanguage()
            defaults.set(initialLanguage.rawValue, forKey: StorageKey.language)
            defaults.set(false, forKey: StorageKey.manualLanguageOverride)
        }

        self.accounts = initialAccounts
        self.currentAccountID = resolvedAccountID
        self.hasSeenOnboarding = initialHasSeenOnboarding
        self.language = initialLanguage
        observeLocaleChanges()
    }

    var currentAccount: UserAccount? {
        guard let currentAccountID else { return nil }
        return accounts.first(where: { $0.id == currentAccountID })
    }

    var currentProfile: UserProfile? {
        guard let account = currentAccount else { return nil }
        return account.profiles.first(where: { $0.id == account.activeProfileID }) ?? account.profiles.first
    }

    var availableAccounts: [UserAccount] {
        accounts
    }

    var availableProfiles: [UserProfile] {
        currentAccount?.profiles ?? []
    }

    var isSignedIn: Bool {
        currentAccount != nil
    }

    var currentTier: SubscriptionTier {
        currentAccount?.tier ?? .free
    }

    var currentScanHistory: [ScanRecord] {
        (currentProfile?.scanHistory ?? []).sorted { $0.scannedAt > $1.scannedAt }
    }

    var products: [Product] {
        productService.allProducts
    }

    var freeScansRemaining: Int? {
        guard let currentAccount, currentAccount.tier == .free, let currentProfile else { return nil }
        let monthlyCount = currentProfile.scanHistory.filter {
            Calendar.current.isDate($0.scannedAt, equalTo: .now, toGranularity: .month)
        }.count
        return max(0, (currentAccount.monthlyScanLimit ?? 20) - monthlyCount)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: StorageKey.hasSeenOnboarding)
    }

    func resetOnboarding() {
        hasSeenOnboarding = false
        defaults.set(false, forKey: StorageKey.hasSeenOnboarding)
    }

    func switchLanguage(_ language: AppLanguage) {
        setLanguage(language, isManualOverride: true)
    }

    func localized(_ key: String, _ arguments: CVarArg...) -> String {
        LocalizationService.string(key, language: language, arguments: arguments)
    }

    func signIn(as accountID: UUID) {
        guard accounts.contains(where: { $0.id == accountID }) else { return }
        currentAccountID = accountID
        defaults.set(accountID.uuidString, forKey: StorageKey.currentAccountID)
    }

    func logout() {
        currentAccountID = nil
        defaults.removeObject(forKey: StorageKey.currentAccountID)
    }

    func switchActiveProfile(_ profileID: UUID) {
        updateCurrentAccount { account in
            guard account.profiles.contains(where: { $0.id == profileID }) else { return }
            account.activeProfileID = profileID
        }
    }

    func addSecondaryProfile() {
        updateCurrentAccount { account in
            guard account.profiles.count < 2 else { return }
            let newProfile = profileService.makeAdditionalProfile(for: account)
            account.profiles.append(newProfile)
            account.activeProfileID = newProfile.id
        }
    }

    func product(for barcode: String) -> Product? {
        productService.product(for: barcode)
    }

    func evaluation(for product: Product, profile: UserProfile? = nil) -> ProductEvaluation {
        productService.evaluate(product: product, profile: profile ?? currentProfile)
    }

    func scanProduct(_ product: Product) -> ProductEvaluation {
        updateCurrentProfile { profile in
            profile.scanHistory.insert(ScanRecord(productBarcode: product.barcode, scannedAt: .now), at: 0)
        }
        return evaluation(for: product)
    }

    func nextMockScanProduct() -> Product {
        let historyCount = currentProfile?.scanHistory.count ?? 0
        return productService.mockScanProduct(index: historyCount)
    }

    func deleteHistoryRecord(_ recordID: UUID) {
        updateCurrentProfile { profile in
            profile.scanHistory.removeAll { $0.id == recordID }
        }
    }

    func analyticsReport(period: AnalyticsPeriod, category: ProductCategory?) -> AnalyticsReport {
        analyticsService.report(
            for: currentProfile,
            period: period,
            category: category,
            productService: productService,
            localization: localized(_:_:)
        )
    }

    func planFeatures() -> [PlanFeature] {
        subscriptionService.planFeatures()
    }

    func setTier(_ tier: SubscriptionTier) {
        updateCurrentAccount { account in
            account.tier = tier
        }
    }

    func togglePreference(_ preference: HealthPreference, in category: HealthPreferenceCategory) {
        updateCurrentProfile { profile in
            switch category {
            case .allergies:
                toggle(preference, in: &profile.allergies)
            case .intolerances:
                toggle(preference, in: &profile.intolerances)
            case .avoidIngredients:
                toggle(preference, in: &profile.avoidIngredients)
            }
        }
    }

    func addCustomPreference(_ value: String, to category: HealthPreferenceCategory) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        togglePreference(.custom(trimmed), in: category)
    }

    func deletePreference(_ preferenceID: UUID, from category: HealthPreferenceCategory) {
        updateCurrentProfile { profile in
            switch category {
            case .allergies:
                profile.allergies.removeAll { $0.id == preferenceID }
            case .intolerances:
                profile.intolerances.removeAll { $0.id == preferenceID }
            case .avoidIngredients:
                profile.avoidIngredients.removeAll { $0.id == preferenceID }
            }
        }
    }

    func suggestions(for category: HealthPreferenceCategory, query: String) -> [HealthPreference] {
        let normalized = HealthPreference.normalized(query)
        let base = category.suggestionTokens.map(HealthPreference.predefined)
        guard !normalized.isEmpty else { return base }

        return base.filter { preference in
            let localizedTitle = localized(preference.titleKey ?? "")
            return localizedTitle.localizedCaseInsensitiveContains(query) || preference.token.localizedCaseInsensitiveContains(normalized)
        }
    }

    func toggleGlutenSensitivity() {
        updateCurrentProfile { profile in
            profile.glutenSensitivity.toggle()
        }
    }

    func toggleSugarTracking() {
        updateCurrentProfile { profile in
            profile.sugarTracking.toggle()
        }
    }

    func resetProfilePreferences() {
        guard let currentAccountID, let currentProfileID = currentProfile?.id else { return }
        let freshAccount = profileService.makeAccounts().first(where: { $0.id == currentAccountID })

        if let freshProfile = freshAccount?.profiles.first(where: { $0.id == currentProfileID }) {
            updateCurrentProfile { profile in
                profile.allergies = freshProfile.allergies
                profile.intolerances = freshProfile.intolerances
                profile.avoidIngredients = freshProfile.avoidIngredients
                profile.glutenSensitivity = freshProfile.glutenSensitivity
                profile.sugarTracking = freshProfile.sugarTracking
            }
        } else {
            updateCurrentProfile { profile in
                profile.allergies = []
                profile.intolerances = []
                profile.avoidIngredients = []
                profile.glutenSensitivity = false
                profile.sugarTracking = false
            }
        }
    }

    private func updateCurrentAccount(_ update: (inout UserAccount) -> Void) {
        guard let currentAccountID, let index = accounts.firstIndex(where: { $0.id == currentAccountID }) else { return }
        update(&accounts[index])
    }

    private func updateCurrentProfile(_ update: (inout UserProfile) -> Void) {
        guard
            let currentAccountID,
            let accountIndex = accounts.firstIndex(where: { $0.id == currentAccountID }),
            let profileIndex = accounts[accountIndex].profiles.firstIndex(where: { $0.id == accounts[accountIndex].activeProfileID })
        else { return }
        update(&accounts[accountIndex].profiles[profileIndex])
    }

    private func toggle(_ preference: HealthPreference, in array: inout [HealthPreference]) {
        if let index = array.firstIndex(where: { $0.token == preference.token }) {
            array.remove(at: index)
        } else {
            array.append(preference)
        }
    }

    private func observeLocaleChanges() {
        localeChangeCancellable = NotificationCenter.default
            .publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.applySystemLanguageIfNeeded()
                }
            }
    }

    private func applySystemLanguageIfNeeded() {
        guard !defaults.bool(forKey: StorageKey.manualLanguageOverride) else { return }
        setLanguage(AppLanguage.preferredSystemLanguage(), isManualOverride: false)
    }

    private func setLanguage(_ language: AppLanguage, isManualOverride: Bool) {
        self.language = language
        defaults.set(language.rawValue, forKey: StorageKey.language)
        defaults.set(isManualOverride, forKey: StorageKey.manualLanguageOverride)
    }

    private enum StorageKey {
        static let hasSeenOnboarding = "goodchoice.hasSeenOnboarding"
        static let language = "goodchoice.language"
        static let manualLanguageOverride = "goodchoice.manualLanguageOverride"
        static let currentAccountID = "goodchoice.currentAccountID"
    }
}

extension AppStore {
    static var preview: AppStore {
        AppStore(defaults: UserDefaults(suiteName: "GoodChoicePreview") ?? .standard)
    }
}
