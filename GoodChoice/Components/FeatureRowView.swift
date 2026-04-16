import SwiftUI

struct FeatureRowView: View {
    @EnvironmentObject private var store: AppStore

    let feature: PlanFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.localized(feature.titleKey))
                .font(.headline)

            Text(store.localized(feature.detailKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                planStatus(titleKey: "subscription.free", included: feature.freeIncluded)
                planStatus(titleKey: "subscription.premium", included: feature.premiumIncluded)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
    }

    private func planStatus(titleKey: String, included: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: included ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundStyle(included ? AppTheme.green : .secondary)
            Text(store.localized(titleKey))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.04))
        )
    }
}
