import Foundation

enum SubscriptionTier: String, Identifiable, CaseIterable {
    case free
    case premium

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .free: return "subscription.free"
        case .premium: return "subscription.premium"
        }
    }
}
