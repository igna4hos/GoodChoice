import Foundation

final class MockSubscriptionService {
    func planFeatures() -> [PlanFeature] {
        [
            PlanFeature(
                titleKey: "paywall.feature.scans.title",
                detailKey: "paywall.feature.scans.detail",
                freeIncluded: true,
                premiumIncluded: true
            ),
            PlanFeature(
                titleKey: "paywall.feature.analytics.title",
                detailKey: "paywall.feature.analytics.detail",
                freeIncluded: false,
                premiumIncluded: true
            ),
            PlanFeature(
                titleKey: "paywall.feature.ai.title",
                detailKey: "paywall.feature.ai.detail",
                freeIncluded: false,
                premiumIncluded: true
            ),
            PlanFeature(
                titleKey: "paywall.feature.household.title",
                detailKey: "paywall.feature.household.detail",
                freeIncluded: true,
                premiumIncluded: true
            )
        ]
    }
}
