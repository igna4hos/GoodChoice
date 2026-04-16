import Foundation

enum IngredientToken: String, CaseIterable, Identifiable, Hashable {
    case peanuts
    case almonds
    case lactose
    case soy
    case gluten
    case shellfish
    case fragrance
    case parabens
    case alcohol
    case sulfates
    case bleach
    case ammonia
    case addedSugar
    case caffeine
    case palmOil
    case zincOxide
    case hyaluronicAcid
    case aloe
    case enzymes
    case probiotics

    var id: String { rawValue }

    var titleKey: String {
        "ingredient.\(rawValue)"
    }
}
