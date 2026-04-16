import SwiftUI

struct ProductCardView: View {
    @EnvironmentObject private var store: AppStore

    let product: Product
    let score: Int
    let detail: String

    var body: some View {
        PremiumCard(padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: product.category.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.orange.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.localized(product.nameKey))
                                .font(.headline)

                            Text(store.localized(product.category.titleKey))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        ScoreBadgeView(score: score)
                    }

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
