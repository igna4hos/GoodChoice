import SwiftUI

struct ProductEvaluationSheet: View {
    @EnvironmentObject private var store: AppStore

    let evaluation: ProductEvaluation
    let onClose: () -> Void
    let onContinueScanning: () -> Void
    let onShowHistory: () -> Void

    @State private var isShowingAlternatives = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topControls

                    PremiumCard(padding: 24) {
                        VStack(spacing: 18) {
                            ScoreCircleView(score: evaluation.personalizedScore)

                            VStack(spacing: 8) {
                                Text(store.localized(evaluation.verdict.titleKey))
                                    .font(.title2.bold())
                                Text(store.localized(evaluation.product.nameKey))
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                Text(store.localized(evaluation.product.category.titleKey))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(summaryText)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ProductCardView(
                        product: evaluation.product,
                        score: evaluation.personalizedScore,
                        detail: store.localized(evaluation.product.descriptionKey)
                    )

                    PremiumCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("scan.reasoning.title")
                                .font(.headline)

                            ForEach(reasonTexts, id: \.self) { reason in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(AppTheme.orange)
                                    Text(reason)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }

                            if reasonTexts.isEmpty {
                                Text("scan.reasoning.safe")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    PremiumCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("scan.points.title")
                                .font(.headline)

                            ForEach(evaluation.positives, id: \.self) { key in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.green)
                                    Text(store.localized(key))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }

                    Button {
                        isShowingAlternatives = true
                    } label: {
                        Text("scan.alternatives.cta")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.premiumGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .sheet(isPresented: $isShowingAlternatives) {
                AlternativesView(products: evaluation.alternativeProducts)
                    .environmentObject(store)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var topControls: some View {
        HStack(spacing: 12) {
            controlButton(icon: "xmark", titleKey: "action.close", action: onClose)
            controlButton(icon: "camera.viewfinder", titleKey: "scan.action.continue", action: onContinueScanning)
            controlButton(icon: "clock", titleKey: "scan.action.history", action: onShowHistory)
        }
    }

    private func controlButton(icon: String, titleKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(LocalizedStringKey(titleKey))
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: AppTheme.subtleShadow, radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private var reasonTexts: [String] {
        evaluation.warnings.map { reason in
            switch reason {
            case .allergy(let ingredient):
                return store.localized("reason.allergy", store.localized(ingredient.titleKey))
            case .intolerance(let ingredient):
                return store.localized("reason.intolerance", store.localized(ingredient.titleKey))
            case .avoidedIngredient(let ingredient):
                return store.localized("reason.avoidIngredient", store.localized(ingredient.titleKey))
            case .avoidedCategory(let category):
                return store.localized("reason.avoidCategory", store.localized(category.titleKey))
            }
        }
    }

    private var summaryText: String {
        if evaluation.warnings.contains(where: {
            if case .allergy = $0 { return true }
            return false
        }) {
            return store.localized("scan.summary.allergy")
        }

        if evaluation.warnings.contains(where: {
            if case .intolerance = $0 { return true }
            return false
        }) {
            return store.localized("scan.summary.intolerance")
        }

        if !evaluation.warnings.isEmpty {
            return store.localized("scan.summary.warning")
        }

        return store.localized("scan.summary.safe")
    }
}
