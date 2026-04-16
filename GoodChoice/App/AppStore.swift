import Combine
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var hasSeenOnboarding: Bool
    @Published var language: AppLanguage
    @Published var selectedTab: AppTab = .scan
    @Published private(set) var profiles: [UserProfile]
    @Published private(set) var currentProfileID: UUID?

    private let defaults: UserDefaults
    private let productService: MockProductService
    private let analyticsService: MockAnalyticsService
    private let subscriptionService: MockSubscriptionService

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
        self.analyticsService = resolvedAnalyticsService
        self.subscriptionService = resolvedSubscriptionService
        let initialProfiles = resolvedProfileService.makeProfiles()

        let savedLanguage = AppLanguage(rawValue: defaults.string(forKey: StorageKey.language) ?? "") ?? .english
        let defaultProfile = initialProfiles.first
        let defaultProfileID = defaultProfile?.id
        let savedProfileID = defaults.string(forKey: StorageKey.currentProfileID).flatMap(UUID.init(uuidString:))
        let resolvedProfileID = initialProfiles.contains(where: { $0.id == savedProfileID }) ? savedProfileID : defaultProfileID
        let initialHasSeenOnboarding = defaults.object(forKey: StorageKey.hasSeenOnboarding) as? Bool ?? false
        let initialLanguage: AppLanguage

        if defaults.object(forKey: StorageKey.language) == nil,
           let currentProfile = initialProfiles.first(where: { $0.id == resolvedProfileID }) {
            initialLanguage = currentProfile.preferredLanguage
        } else {
            initialLanguage = savedLanguage
        }

        self.profiles = initialProfiles
        self.currentProfileID = resolvedProfileID
        self.hasSeenOnboarding = initialHasSeenOnboarding
        self.language = initialLanguage
    }

    var currentProfile: UserProfile? {
        guard let currentProfileID else { return nil }
        return profiles.first(where: { $0.id == currentProfileID })
    }

    var availableProfiles: [UserProfile] {
        profiles
    }

    var isSignedIn: Bool {
        currentProfile != nil
    }

    var currentTier: SubscriptionTier {
        currentProfile?.tier ?? .free
    }

    var currentScanHistory: [ScanRecord] {
        (currentProfile?.scanHistory ?? []).sorted { $0.scannedAt > $1.scannedAt }
    }

    var products: [Product] {
        productService.allProducts
    }

    var freeScansRemaining: Int? {
        guard let currentProfile, currentProfile.tier == .free else { return nil }
        let monthlyCount = currentProfile.scanHistory.filter {
            Calendar.current.isDate($0.scannedAt, equalTo: .now, toGranularity: .month)
        }.count
        return max(0, (currentProfile.monthlyScanLimit ?? 20) - monthlyCount)
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
        self.language = language
        defaults.set(language.rawValue, forKey: StorageKey.language)
    }

    func localized(_ key: String, _ arguments: CVarArg...) -> String {
        LocalizationService.string(key, language: language, arguments: arguments)
    }

    func signIn(as profileID: UUID) {
        guard profiles.contains(where: { $0.id == profileID }) else { return }
        currentProfileID = profileID
        defaults.set(profileID.uuidString, forKey: StorageKey.currentProfileID)
        if let profile = currentProfile {
            switchLanguage(profile.preferredLanguage)
        }
    }

    func logout() {
        currentProfileID = nil
        defaults.removeObject(forKey: StorageKey.currentProfileID)
    }

    func product(for barcode: String) -> Product? {
        productService.product(for: barcode)
    }

    func evaluation(for product: Product, profile: UserProfile? = nil) -> ProductEvaluation {
        productService.evaluate(product: product, profile: profile ?? currentProfile)
    }

    func scanProduct(_ product: Product) -> ProductEvaluation {
        if let currentProfileID, let index = profiles.firstIndex(where: { $0.id == currentProfileID }) {
            let record = ScanRecord(productBarcode: product.barcode, scannedAt: .now)
            profiles[index].scanHistory.insert(record, at: 0)
        }
        return evaluation(for: product)
    }

    func nextMockScanProduct() -> Product {
        let historyCount = currentProfile?.scanHistory.count ?? 0
        return productService.mockScanProduct(index: historyCount)
    }

    func deleteHistoryRecord(_ recordID: UUID) {
        guard let currentProfileID, let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        profiles[index].scanHistory.removeAll { $0.id == recordID }
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
        guard let currentProfileID, let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        profiles[index].tier = tier
    }

    func toggleAllergy(_ ingredient: IngredientToken) {
        updateIngredient(ingredient, keyPath: \.allergies)
    }

    func toggleIntolerance(_ ingredient: IngredientToken) {
        updateIngredient(ingredient, keyPath: \.intolerances)
    }

    func toggleAvoidedIngredient(_ ingredient: IngredientToken) {
        updateIngredient(ingredient, keyPath: \.avoidedIngredients)
    }

    func toggleAvoidedCategory(_ category: ProductCategory) {
        guard let currentProfileID, let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        if profiles[index].avoidedCategories.contains(category) {
            profiles[index].avoidedCategories.removeAll { $0 == category }
        } else {
            profiles[index].avoidedCategories.append(category)
        }
    }

    func resetProfilePreferences() {
        guard let currentProfileID, let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        let freshProfile = MockProfileService().makeProfiles().first(where: { $0.id == currentProfileID })
        guard let freshProfile else { return }
        profiles[index].allergies = freshProfile.allergies
        profiles[index].intolerances = freshProfile.intolerances
        profiles[index].avoidedIngredients = freshProfile.avoidedIngredients
        profiles[index].avoidedCategories = freshProfile.avoidedCategories
    }

    private func updateIngredient(
        _ ingredient: IngredientToken,
        keyPath: WritableKeyPath<UserProfile, [IngredientToken]>
    ) {
        guard let currentProfileID, let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        if profiles[index][keyPath: keyPath].contains(ingredient) {
            profiles[index][keyPath: keyPath].removeAll { $0 == ingredient }
        } else {
            profiles[index][keyPath: keyPath].append(ingredient)
        }
    }

    private enum StorageKey {
        static let hasSeenOnboarding = "goodchoice.hasSeenOnboarding"
        static let language = "goodchoice.language"
        static let currentProfileID = "goodchoice.currentProfileID"
    }
}

extension AppStore {
    static var preview: AppStore {
        AppStore(defaults: UserDefaults(suiteName: "GoodChoicePreview") ?? .standard)
    }
}
