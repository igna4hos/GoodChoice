import SwiftUI

struct AlternativesView: View {
    @EnvironmentObject private var store: AppStore

    let products: [Product]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(products) { product in
                        let evaluation = store.evaluation(for: product)
                        ProductCardView(
                            product: product,
                            score: evaluation.personalizedScore,
                            detail: store.localized(product.descriptionKey)
                        )
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(Text("scan.alternatives.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
