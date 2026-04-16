import Foundation

struct ProductEvaluation: Identifiable {
    let id = UUID()
    let product: Product
    let personalizedScore: Int
    let verdict: EvaluationVerdict
    let warnings: [EvaluationReason]
    let positives: [String]
    let alternativeProducts: [Product]
}

enum EvaluationVerdict {
    case good
    case caution
    case avoid

    var titleKey: String {
        switch self {
        case .good: return "verdict.good"
        case .caution: return "verdict.caution"
        case .avoid: return "verdict.avoid"
        }
    }
}

enum EvaluationReason: Hashable, Identifiable {
    case allergy(IngredientToken)
    case intolerance(IngredientToken)
    case avoidedIngredient(IngredientToken)
    case avoidedCategory(ProductCategory)

    var id: String {
        switch self {
        case .allergy(let ingredient):
            return "allergy-\(ingredient.rawValue)"
        case .intolerance(let ingredient):
            return "intolerance-\(ingredient.rawValue)"
        case .avoidedIngredient(let ingredient):
            return "avoid-\(ingredient.rawValue)"
        case .avoidedCategory(let category):
            return "avoid-category-\(category.rawValue)"
        }
    }
}
