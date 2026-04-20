import Foundation

struct Product: Identifiable, Hashable {
    let id: UUID
    let barcode: String
    let nameKey: String
    let imageName: String
    let category: ProductCategory
    let kind: ProductKind
    let genericScore: Int
    let descriptionKey: String
    let highlightKeys: [String]
    let sensitivityTokens: [String]
    let details: ProductDetails
    let alternativeSuggestions: [AlternativeSuggestion]

    init(
        id: UUID = UUID(),
        barcode: String,
        nameKey: String,
        imageName: String,
        category: ProductCategory,
        kind: ProductKind,
        genericScore: Int,
        descriptionKey: String,
        highlightKeys: [String],
        sensitivityTokens: [String],
        details: ProductDetails,
        alternativeSuggestions: [AlternativeSuggestion]
    ) {
        self.id = id
        self.barcode = barcode
        self.nameKey = nameKey
        self.imageName = imageName
        self.category = category
        self.kind = kind
        self.genericScore = genericScore
        self.descriptionKey = descriptionKey
        self.highlightKeys = highlightKeys
        self.sensitivityTokens = sensitivityTokens
        self.details = details
        self.alternativeSuggestions = alternativeSuggestions
    }
}

enum ProductKind: String, Hashable {
    case flakes
    case yogurt
    case cream
    case shampoo
    case washing
}

enum ProductDetails: Hashable {
    case food(NutritionFacts)
    case care(ProductCareDetails)
}

struct NutritionFacts: Hashable {
    let calories: Int
    let proteins: Double
    let fats: Double
    let carbohydrates: Double
    let sugar: Int?
}

struct ProductCareDetails: Hashable {
    let typeKey: String
    let audienceKey: String
    let purposeKey: String
}

struct AlternativeSuggestion: Identifiable, Hashable {
    let id = UUID()
    let productBarcode: String
    let reasonKey: String
}
