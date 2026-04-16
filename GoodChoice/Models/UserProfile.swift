import Foundation

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    let nameKey: String
    let subtitleKey: String
    var tier: SubscriptionTier
    var allergies: [IngredientToken]
    var intolerances: [IngredientToken]
    var avoidedIngredients: [IngredientToken]
    var avoidedCategories: [ProductCategory]
    let preferredLanguage: AppLanguage
    let monthlyScanLimit: Int?
    var scanHistory: [ScanRecord]

    init(
        id: UUID,
        nameKey: String,
        subtitleKey: String,
        tier: SubscriptionTier,
        allergies: [IngredientToken],
        intolerances: [IngredientToken],
        avoidedIngredients: [IngredientToken],
        avoidedCategories: [ProductCategory],
        preferredLanguage: AppLanguage,
        monthlyScanLimit: Int?,
        scanHistory: [ScanRecord]
    ) {
        self.id = id
        self.nameKey = nameKey
        self.subtitleKey = subtitleKey
        self.tier = tier
        self.allergies = allergies
        self.intolerances = intolerances
        self.avoidedIngredients = avoidedIngredients
        self.avoidedCategories = avoidedCategories
        self.preferredLanguage = preferredLanguage
        self.monthlyScanLimit = monthlyScanLimit
        self.scanHistory = scanHistory
    }
}
