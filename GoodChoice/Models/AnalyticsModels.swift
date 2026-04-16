import Foundation

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case allTime

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .week: return "analytics.period.week"
        case .month: return "analytics.period.month"
        case .allTime: return "analytics.period.allTime"
        }
    }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let date: Date
    let averageScore: Double
}

struct CategoryAnalytics: Identifiable {
    let id = UUID()
    let category: ProductCategory
    let scanCount: Int
    let averageScore: Double
}

struct FrequentProduct: Identifiable {
    let id = UUID()
    let product: Product
    let count: Int
    let averageScore: Double
}

struct AnalyticsInsight: Identifiable {
    let id = UUID()
    let icon: String
    let tint: AnalyticsInsightTint
    let title: String
    let message: String
    let isPremiumOnly: Bool
}

enum AnalyticsInsightTint {
    case green
    case orange
    case red
}

struct AnalyticsReport {
    let averageScore: Int
    let healthyCount: Int
    let riskyCount: Int
    let totalScans: Int
    let topCategory: ProductCategory?
    let categoryAnalytics: [CategoryAnalytics]
    let frequentProducts: [FrequentProduct]
    let trend: [TrendPoint]
    let insights: [AnalyticsInsight]
    let scoreDelta: Int
}

struct PlanFeature: Identifiable {
    let id = UUID()
    let titleKey: String
    let detailKey: String
    let freeIncluded: Bool
    let premiumIncluded: Bool
}
