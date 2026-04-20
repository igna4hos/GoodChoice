import Foundation

final class MockProductService {
    let allProducts: [Product]

    init(products: [Product] = MockProductService.makeProducts()) {
        self.allProducts = products
    }

    var scannableProducts: [Product] {
        allProducts.filter { $0.kind == .flakes }
    }

    func product(for barcode: String) -> Product? {
        allProducts.first(where: { $0.barcode == barcode })
    }

    func mockScanProduct(index: Int) -> Product {
        let products = scannableProducts
        let safeIndex = max(0, index) % max(products.count, 1)
        return products[safeIndex]
    }

    func evaluate(product: Product, profile: UserProfile?, includeAlternatives: Bool = true) -> ProductEvaluation {
        var score = product.genericScore
        var warnings: [EvaluationReason] = []

        if let profile {
            let tokens = Set(product.sensitivityTokens.map(HealthPreference.normalized))

            for preference in profile.allergies where tokens.contains(preference.token) {
                score -= 34
                warnings.append(EvaluationReason(kind: .allergy, titleKey: preference.titleKey, customValue: preference.customValue))
            }

            for preference in profile.intolerances where tokens.contains(preference.token) {
                score -= 22
                warnings.append(EvaluationReason(kind: .intolerance, titleKey: preference.titleKey, customValue: preference.customValue))
            }

            for preference in profile.avoidIngredients where tokens.contains(preference.token) {
                score -= 14
                warnings.append(EvaluationReason(kind: .avoidIngredient, titleKey: preference.titleKey, customValue: preference.customValue))
            }

            if profile.glutenSensitivity, tokens.contains(HealthToken.gluten.rawValue) || tokens.contains(HealthToken.wheat.rawValue) {
                score -= 18
                warnings.append(EvaluationReason(kind: .glutenSensitivity))
            }

            if profile.sugarTracking,
               case let .food(nutrition) = product.details,
               let sugar = nutrition.sugar,
               sugar >= 10 {
                score -= min(22, sugar)
                warnings.append(EvaluationReason(kind: .sugarTracking, numericValue: sugar))
            }
        }

        score = min(100, max(0, score))

        let verdict: EvaluationVerdict
        switch score {
        case 75...100:
            verdict = .good
        case 45..<75:
            verdict = .caution
        default:
            verdict = .avoid
        }

        let alternatives: [EvaluatedAlternative]
        if includeAlternatives {
            alternatives = product.alternativeSuggestions.compactMap { suggestion in
                guard let alternative = self.product(for: suggestion.productBarcode) else { return nil }
                let alternativeScore = evaluate(product: alternative, profile: profile, includeAlternatives: false).personalizedScore
                return EvaluatedAlternative(product: alternative, reasonKey: suggestion.reasonKey, score: alternativeScore)
            }
            .sorted { $0.score > $1.score }
        } else {
            alternatives = []
        }

        return ProductEvaluation(
            product: product,
            personalizedScore: score,
            verdict: verdict,
            warnings: warnings,
            positives: product.highlightKeys,
            alternatives: alternatives
        )
    }

    private static func makeProducts() -> [Product] {
        [
            Product(
                barcode: "460200000001",
                nameKey: "product.flakes.kosmostars.name",
                imageName: "products.flakes.kosmostars",
                category: .food,
                kind: .flakes,
                genericScore: 46,
                descriptionKey: "product.flakes.kosmostars.description",
                highlightKeys: ["highlight.kidsFavorite"],
                sensitivityTokens: [HealthToken.gluten.rawValue, HealthToken.addedSugar.rawValue, HealthToken.honey.rawValue, HealthToken.colorants.rawValue],
                details: .food(NutritionFacts(calories: 392, proteins: 6.1, fats: 4.8, carbohydrates: 79.0, sugar: 26)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000004", reasonKey: "alternative.betterSugar"),
                    AlternativeSuggestion(productBarcode: "460200000002", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000002",
                nameKey: "product.flakes.khrutka.name",
                imageName: "products.flakes.khrutka",
                category: .food,
                kind: .flakes,
                genericScore: 58,
                descriptionKey: "product.flakes.khrutka.description",
                highlightKeys: ["highlight.wholeGrains"],
                sensitivityTokens: [HealthToken.gluten.rawValue, HealthToken.cocoa.rawValue, HealthToken.addedSugar.rawValue],
                details: .food(NutritionFacts(calories: 365, proteins: 7.0, fats: 5.4, carbohydrates: 70.0, sugar: 18)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000004", reasonKey: "alternative.lowerCalories"),
                    AlternativeSuggestion(productBarcode: "460200000003", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000003",
                nameKey: "product.flakes.oreo.name",
                imageName: "products.flakes.oreo",
                category: .food,
                kind: .flakes,
                genericScore: 38,
                descriptionKey: "product.flakes.oreo.description",
                highlightKeys: ["highlight.crispyTexture"],
                sensitivityTokens: [HealthToken.gluten.rawValue, HealthToken.cocoa.rawValue, HealthToken.addedSugar.rawValue, HealthToken.palmOil.rawValue],
                details: .food(NutritionFacts(calories: 405, proteins: 5.2, fats: 7.8, carbohydrates: 78.0, sugar: 28)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000004", reasonKey: "alternative.betterComposition"),
                    AlternativeSuggestion(productBarcode: "460200000002", reasonKey: "alternative.betterSugar")
                ]
            ),
            Product(
                barcode: "460200000004",
                nameKey: "product.flakes.redprice.name",
                imageName: "products.flakes.redprice",
                category: .food,
                kind: .flakes,
                genericScore: 72,
                descriptionKey: "product.flakes.redprice.description",
                highlightKeys: ["highlight.lowerSugar", "highlight.simpleComposition"],
                sensitivityTokens: [HealthToken.gluten.rawValue, HealthToken.oatFlour.rawValue],
                details: .food(NutritionFacts(calories: 344, proteins: 8.0, fats: 2.1, carbohydrates: 72.0, sugar: 7)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000008", reasonKey: "alternative.betterProtein"),
                    AlternativeSuggestion(productBarcode: "460200000006", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000005",
                nameKey: "product.yogurt.frugurt.name",
                imageName: "products.yogurt.frugurt",
                category: .food,
                kind: .yogurt,
                genericScore: 61,
                descriptionKey: "product.yogurt.frugurt.description",
                highlightKeys: ["highlight.liveCultures"],
                sensitivityTokens: [HealthToken.lactose.rawValue, HealthToken.addedSugar.rawValue, HealthToken.strawberries.rawValue, HealthToken.probiotics.rawValue],
                details: .food(NutritionFacts(calories: 124, proteins: 3.4, fats: 2.8, carbohydrates: 20.0, sugar: 15)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000006", reasonKey: "alternative.betterProtein"),
                    AlternativeSuggestion(productBarcode: "460200000008", reasonKey: "alternative.betterSugar")
                ]
            ),
            Product(
                barcode: "460200000006",
                nameKey: "product.yogurt.teos.name",
                imageName: "products.yogurt.teos",
                category: .food,
                kind: .yogurt,
                genericScore: 88,
                descriptionKey: "product.yogurt.teos.description",
                highlightKeys: ["highlight.highProtein", "highlight.cleanerComposition"],
                sensitivityTokens: [HealthToken.lactose.rawValue, HealthToken.probiotics.rawValue],
                details: .food(NutritionFacts(calories: 78, proteins: 10.0, fats: 2.0, carbohydrates: 4.2, sugar: 3)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000008", reasonKey: "alternative.betterProtein"),
                    AlternativeSuggestion(productBarcode: "460200000007", reasonKey: "alternative.lowerCalories")
                ]
            ),
            Product(
                barcode: "460200000007",
                nameKey: "product.yogurt.savushkin.name",
                imageName: "products.yogurt.savushkin",
                category: .food,
                kind: .yogurt,
                genericScore: 69,
                descriptionKey: "product.yogurt.savushkin.description",
                highlightKeys: ["highlight.lightTexture"],
                sensitivityTokens: [HealthToken.lactose.rawValue, HealthToken.addedSugar.rawValue, HealthToken.strawberries.rawValue],
                details: .food(NutritionFacts(calories: 109, proteins: 4.1, fats: 2.5, carbohydrates: 16.0, sugar: 12)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000008", reasonKey: "alternative.betterSugar"),
                    AlternativeSuggestion(productBarcode: "460200000006", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000008",
                nameKey: "product.yogurt.activia.name",
                imageName: "products.yogurt.activia",
                category: .food,
                kind: .yogurt,
                genericScore: 82,
                descriptionKey: "product.yogurt.activia.description",
                highlightKeys: ["highlight.probioticSupport", "highlight.lowerSugar"],
                sensitivityTokens: [HealthToken.lactose.rawValue, HealthToken.probiotics.rawValue],
                details: .food(NutritionFacts(calories: 92, proteins: 5.0, fats: 2.4, carbohydrates: 10.0, sugar: 6)),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000006", reasonKey: "alternative.betterProtein"),
                    AlternativeSuggestion(productBarcode: "460200000007", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000009",
                nameKey: "product.cream.spf30.name",
                imageName: "products.cream.spf30",
                category: .cosmetics,
                kind: .cream,
                genericScore: 58,
                descriptionKey: "product.cream.spf30.description",
                highlightKeys: ["highlight.cityComfort"],
                sensitivityTokens: [HealthToken.fragrance.rawValue, HealthToken.alcohol.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.spf30.type",
                    audienceKey: "detail.city.audience",
                    purposeKey: "detail.spf30.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000010", reasonKey: "alternative.cleanerIngredients"),
                    AlternativeSuggestion(productBarcode: "460200000012", reasonKey: "alternative.betterComposition")
                ]
            ),
            Product(
                barcode: "460200000010",
                nameKey: "product.cream.spf40.name",
                imageName: "products.cream.spf40",
                category: .cosmetics,
                kind: .cream,
                genericScore: 86,
                descriptionKey: "product.cream.spf40.description",
                highlightKeys: ["highlight.mineralFilter", "highlight.sensitiveSkin"],
                sensitivityTokens: [HealthToken.zincOxide.rawValue, HealthToken.niacinamide.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.spf40.type",
                    audienceKey: "detail.sensitive.audience",
                    purposeKey: "detail.spf40.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000012", reasonKey: "alternative.betterComposition"),
                    AlternativeSuggestion(productBarcode: "460200000011", reasonKey: "alternative.lowerIrritation")
                ]
            ),
            Product(
                barcode: "460200000011",
                nameKey: "product.cream.spf50.name",
                imageName: "products.cream.spf50",
                category: .cosmetics,
                kind: .cream,
                genericScore: 74,
                descriptionKey: "product.cream.spf50.description",
                highlightKeys: ["highlight.sportReady"],
                sensitivityTokens: [HealthToken.fragrance.rawValue, HealthToken.dimethicone.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.spf50.type",
                    audienceKey: "detail.outdoor.audience",
                    purposeKey: "detail.spf50.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000012", reasonKey: "alternative.cleanerIngredients"),
                    AlternativeSuggestion(productBarcode: "460200000010", reasonKey: "alternative.lowerIrritation")
                ]
            ),
            Product(
                barcode: "460200000012",
                nameKey: "product.cream.spf50v2.name",
                imageName: "products.cream.spf50v2",
                category: .cosmetics,
                kind: .cream,
                genericScore: 91,
                descriptionKey: "product.cream.spf50v2.description",
                highlightKeys: ["highlight.familyFriendly", "highlight.cleanerComposition"],
                sensitivityTokens: [HealthToken.zincOxide.rawValue, HealthToken.panthenol.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.spf50kids.type",
                    audienceKey: "detail.kids.audience",
                    purposeKey: "detail.spf50kids.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000010", reasonKey: "alternative.lowerIrritation"),
                    AlternativeSuggestion(productBarcode: "460200000011", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000013",
                nameKey: "product.shampoo.bubchen.name",
                imageName: "products.shampoo.bubchen",
                category: .cosmetics,
                kind: .shampoo,
                genericScore: 83,
                descriptionKey: "product.shampoo.bubchen.description",
                highlightKeys: ["highlight.kidsFriendly", "highlight.gentleCleanse"],
                sensitivityTokens: [HealthToken.aloe.rawValue, HealthToken.panthenol.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.shampoo.kids.type",
                    audienceKey: "detail.kids.audience",
                    purposeKey: "detail.shampoo.kids.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000016", reasonKey: "alternative.lowerIrritation"),
                    AlternativeSuggestion(productBarcode: "460200000014", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000014",
                nameKey: "product.shampoo.head.name",
                imageName: "products.shampoo.head",
                category: .cosmetics,
                kind: .shampoo,
                genericScore: 54,
                descriptionKey: "product.shampoo.head.description",
                highlightKeys: ["highlight.antiDandruff"],
                sensitivityTokens: [HealthToken.fragrance.rawValue, HealthToken.sulfates.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.shampoo.scalp.type",
                    audienceKey: "detail.scalp.audience",
                    purposeKey: "detail.shampoo.scalp.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000016", reasonKey: "alternative.lowerIrritation"),
                    AlternativeSuggestion(productBarcode: "460200000015", reasonKey: "alternative.cleanerIngredients")
                ]
            ),
            Product(
                barcode: "460200000015",
                nameKey: "product.shampoo.jojo.name",
                imageName: "products.shampoo.jojo",
                category: .cosmetics,
                kind: .shampoo,
                genericScore: 67,
                descriptionKey: "product.shampoo.jojo.description",
                highlightKeys: ["highlight.repairCare"],
                sensitivityTokens: [HealthToken.silicones.rawValue, HealthToken.fragrance.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.shampoo.repair.type",
                    audienceKey: "detail.dryhair.audience",
                    purposeKey: "detail.shampoo.repair.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000016", reasonKey: "alternative.cleanerIngredients"),
                    AlternativeSuggestion(productBarcode: "460200000013", reasonKey: "alternative.lowerIrritation")
                ]
            ),
            Product(
                barcode: "460200000016",
                nameKey: "product.shampoo.vois.name",
                imageName: "products.shampoo.vois",
                category: .cosmetics,
                kind: .shampoo,
                genericScore: 88,
                descriptionKey: "product.shampoo.vois.description",
                highlightKeys: ["highlight.sulfateFree", "highlight.cleanerComposition"],
                sensitivityTokens: [HealthToken.aloe.rawValue, HealthToken.panthenol.rawValue],
                details: .care(ProductCareDetails(
                    typeKey: "detail.shampoo.daily.type",
                    audienceKey: "detail.everyday.audience",
                    purposeKey: "detail.shampoo.daily.purpose"
                )),
                alternativeSuggestions: [
                    AlternativeSuggestion(productBarcode: "460200000013", reasonKey: "alternative.gentlerUse"),
                    AlternativeSuggestion(productBarcode: "460200000015", reasonKey: "alternative.lowerIrritation")
                ]
            )
        ]
    }
}
