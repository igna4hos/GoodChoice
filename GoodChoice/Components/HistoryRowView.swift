import SwiftUI

struct HistoryRowView: View {
    @EnvironmentObject private var store: AppStore

    let record: ScanRecord
    let product: Product
    let evaluation: ProductEvaluation

    var body: some View {
        HStack(spacing: 14) {
            ProductImageView(imageName: product.imageName, width: 54, height: 54, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.localized(product.nameKey))
                    .font(.headline)
                Text(store.localized(product.category.titleKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(record.scannedAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            ScoreBadgeView(score: evaluation.personalizedScore)
        }
        .padding(.vertical, 6)
    }
}
