import SwiftUI

struct ProductCardView: View {
    @EnvironmentObject private var store: AppStore

    let product: Product
    let score: Int
    let detail: String

    var body: some View {
        PremiumCard(padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                ProductImageView(imageName: product.imageName)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.localized(product.nameKey))
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(store.localized(product.category.titleKey))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)
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
