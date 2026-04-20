import Foundation

enum HealthPreferenceCategory: String, CaseIterable, Identifiable {
    case allergies
    case intolerances
    case avoidIngredients

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .allergies: return "profile.preferences.allergies"
        case .intolerances: return "profile.preferences.intolerances"
        case .avoidIngredients: return "profile.preferences.avoidIngredients"
        }
    }

    var suggestionTokens: [HealthToken] {
        switch self {
        case .allergies:
            return [.peanuts, .gluten, .lactose, .cocoa, .strawberries, .fragrance, .aloe]
        case .intolerances:
            return [.lactose, .addedSugar, .gluten, .fragrance, .alcohol, .sulfates, .probiotics]
        case .avoidIngredients:
            return [.addedSugar, .palmOil, .parabens, .sulfates, .silicones, .fragrance, .colorants, .alcohol]
        }
    }
}

enum HealthToken: String, CaseIterable, Hashable, Identifiable {
    case peanuts
    case gluten
    case lactose
    case addedSugar
    case cocoa
    case strawberries
    case fragrance
    case sulfates
    case parabens
    case silicones
    case alcohol
    case aloe
    case zincOxide
    case niacinamide
    case dimethicone
    case probiotics
    case colorants
    case honey
    case wheat
    case oatFlour
    case palmOil
    case essentialOils
    case panthenol

    var id: String { rawValue }

    var titleKey: String {
        "health.token.\(rawValue)"
    }
}

struct HealthPreference: Identifiable, Hashable {
    let id: UUID
    let token: String
    let titleKey: String?
    let customValue: String?

    init(id: UUID = UUID(), token: String, titleKey: String? = nil, customValue: String? = nil) {
        self.id = id
        self.token = token
        self.titleKey = titleKey
        self.customValue = customValue
    }

    static func predefined(_ token: HealthToken) -> HealthPreference {
        HealthPreference(token: token.rawValue, titleKey: token.titleKey)
    }

    static func custom(_ value: String) -> HealthPreference {
        HealthPreference(token: normalized(value), customValue: value)
    }

    func displayTitle(localize: (String, CVarArg...) -> String) -> String {
        if let titleKey {
            return localize(titleKey)
        }
        return customValue ?? token
    }

    nonisolated static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }
}
