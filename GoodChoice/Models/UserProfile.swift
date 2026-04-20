import Foundation

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    var name: String
    var relation: ProfileRelation
    var allergies: [HealthPreference]
    var intolerances: [HealthPreference]
    var avoidIngredients: [HealthPreference]
    var glutenSensitivity: Bool
    var sugarTracking: Bool
    var scanHistory: [ScanRecord]
}

enum ProfileRelation: String, CaseIterable, Identifiable {
    case primary
    case child
    case partner

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .primary: return "profile.relation.primary"
        case .child: return "profile.relation.child"
        case .partner: return "profile.relation.partner"
        }
    }
}
