import SwiftUI

struct AlternativeRowView: View {
    @EnvironmentObject private var store: AppStore

    let alternative: EvaluatedAlternative

    var body: some View {
        PremiumCard(padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                ProductImageView(imageName: alternative.product.imageName, width: 62, height: 62, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(store.localized(alternative.product.nameKey))
                            .font(.headline)
                        Spacer()
                        ScoreBadgeView(score: alternative.score)
                    }

                    Text(store.localized(alternative.product.category.titleKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(store.localized(alternative.reasonKey))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
