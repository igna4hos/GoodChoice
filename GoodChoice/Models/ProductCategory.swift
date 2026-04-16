import Foundation

enum ProductCategory: String, CaseIterable, Identifiable, Hashable {
    case food
    case household
    case cosmetics

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .food: return "category.food"
        case .household: return "category.household"
        case .cosmetics: return "category.cosmetics"
        }
    }

    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .household: return "sparkles.rectangle.stack"
        case .cosmetics: return "drop.circle"
        }
    }
}
