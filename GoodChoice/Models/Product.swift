import Foundation

struct Product: Identifiable, Hashable {
    let id: UUID
    let barcode: String
    let nameKey: String
    let category: ProductCategory
    let ingredients: [IngredientToken]
    let genericScore: Int
    let descriptionKey: String
    let highlightKeys: [String]
    let alternativeBarcodes: [String]

    init(
        id: UUID = UUID(),
        barcode: String,
        nameKey: String,
        category: ProductCategory,
        ingredients: [IngredientToken],
        genericScore: Int,
        descriptionKey: String,
        highlightKeys: [String],
        alternativeBarcodes: [String]
    ) {
        self.id = id
        self.barcode = barcode
        self.nameKey = nameKey
        self.category = category
        self.ingredients = ingredients
        self.genericScore = genericScore
        self.descriptionKey = descriptionKey
        self.highlightKeys = highlightKeys
        self.alternativeBarcodes = alternativeBarcodes
    }
}
