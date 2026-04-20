import Foundation

struct ProductEvaluation: Identifiable {
    let id = UUID()
    let product: Product
    let personalizedScore: Int
    let verdict: EvaluationVerdict
    let warnings: [EvaluationReason]
    let positives: [String]
    let alternatives: [EvaluatedAlternative]
}

struct EvaluatedAlternative: Identifiable, Hashable {
    let id = UUID()
    let product: Product
    let reasonKey: String
    let score: Int
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

struct EvaluationReason: Hashable, Identifiable {
    let id = UUID()
    let kind: EvaluationReasonKind
    let titleKey: String?
    let customValue: String?
    let numericValue: Int?

    init(
        kind: EvaluationReasonKind,
        titleKey: String? = nil,
        customValue: String? = nil,
        numericValue: Int? = nil
    ) {
        self.kind = kind
        self.titleKey = titleKey
        self.customValue = customValue
        self.numericValue = numericValue
    }
}

enum EvaluationReasonKind: Hashable {
    case allergy
    case intolerance
    case avoidIngredient
    case glutenSensitivity
    case sugarTracking
}
