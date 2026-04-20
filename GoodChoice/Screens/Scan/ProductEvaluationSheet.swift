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

                            ProductImageView(imageName: evaluation.product.imageName, width: 120, height: 120, cornerRadius: 28)

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

                    detailsCard
                    reasoningCard
                    positivesCard

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
                AlternativesView(alternatives: evaluation.alternatives)
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

    private var detailsCard: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("scan.details.title")
                    .font(.headline)

                switch evaluation.product.details {
                case .food(let nutrition):
                    nutritionRow(titleKey: "scan.detail.calories", value: "\(nutrition.calories)")
                    nutritionRow(titleKey: "scan.detail.proteins", value: formattedGram(nutrition.proteins))
                    nutritionRow(titleKey: "scan.detail.fats", value: formattedGram(nutrition.fats))
                    nutritionRow(titleKey: "scan.detail.carbs", value: formattedGram(nutrition.carbohydrates))
                    if let sugar = nutrition.sugar {
                        nutritionRow(titleKey: "scan.detail.sugar", value: "\(sugar) g")
                    }
                case .care(let details):
                    nutritionRow(titleKey: "scan.detail.type", value: store.localized(details.typeKey))
                    nutritionRow(titleKey: "scan.detail.audience", value: store.localized(details.audienceKey))
                    nutritionRow(titleKey: "scan.detail.purpose", value: store.localized(details.purposeKey))
                }
            }
        }
    }

    private var reasoningCard: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("scan.reasoning.title")
                    .font(.headline)

                if reasonTexts.isEmpty {
                    Text("scan.reasoning.safe")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
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
                }
            }
        }
    }

    private var positivesCard: some View {
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

    private func nutritionRow(titleKey: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(titleKey))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func formattedGram(_ value: Double) -> String {
        String(format: "%.1f g", value)
    }

    private var reasonTexts: [String] {
        evaluation.warnings.map { reason in
            switch reason.kind {
            case .allergy:
                return store.localized("reason.allergy", displayTitle(for: reason))
            case .intolerance:
                return store.localized("reason.intolerance", displayTitle(for: reason))
            case .avoidIngredient:
                return store.localized("reason.avoidIngredient", displayTitle(for: reason))
            case .glutenSensitivity:
                return store.localized("reason.glutenSensitivity")
            case .sugarTracking:
                return store.localized("reason.sugarTracking", reason.numericValue ?? 0)
            }
        }
    }

    private func displayTitle(for reason: EvaluationReason) -> String {
        if let titleKey = reason.titleKey {
            return store.localized(titleKey)
        }
        return reason.customValue ?? store.localized("profile.custom.unknown")
    }

    private var summaryText: String {
        if evaluation.warnings.contains(where: { $0.kind == .allergy }) {
            return store.localized("scan.summary.allergy")
        }
        if evaluation.warnings.contains(where: { $0.kind == .glutenSensitivity }) {
            return store.localized("scan.summary.gluten")
        }
        if evaluation.warnings.contains(where: { $0.kind == .sugarTracking }) {
            return store.localized("scan.summary.sugar")
        }
        if !evaluation.warnings.isEmpty {
            return store.localized("scan.summary.warning")
        }
        return store.localized("scan.summary.safe")
    }
}
