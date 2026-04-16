import Foundation

final class MockProductService {
    let allProducts: [Product]

    init(products: [Product] = MockProductService.makeProducts()) {
        self.allProducts = products
    }

    func product(for barcode: String) -> Product? {
        allProducts.first(where: { $0.barcode == barcode })
    }

    func mockScanProduct(index: Int) -> Product {
        let safeIndex = max(0, index) % allProducts.count
        return allProducts[safeIndex]
    }

    func evaluate(product: Product, profile: UserProfile?) -> ProductEvaluation {
        var score = product.genericScore
        var warnings: [EvaluationReason] = []

        if let profile {
            for ingredient in product.ingredients {
                if profile.allergies.contains(ingredient) {
                    score -= 42
                    warnings.append(.allergy(ingredient))
                } else if profile.intolerances.contains(ingredient) {
                    score -= 24
                    warnings.append(.intolerance(ingredient))
                } else if profile.avoidedIngredients.contains(ingredient) {
                    score -= 16
                    warnings.append(.avoidedIngredient(ingredient))
                }
            }

            if profile.avoidedCategories.contains(product.category) {
                score -= 12
                warnings.append(.avoidedCategory(product.category))
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

        let alternatives = product.alternativeBarcodes.compactMap(product(for:))
        return ProductEvaluation(
            product: product,
            personalizedScore: score,
            verdict: verdict,
            warnings: warnings,
            positives: product.highlightKeys,
            alternativeProducts: alternatives
        )
    }

    private static func makeProducts() -> [Product] {
        [
            Product(
                barcode: "460100000001",
                nameKey: "product.oatBar.name",
                category: .food,
                ingredients: [.almonds, .soy, .addedSugar],
                genericScore: 82,
                descriptionKey: "product.oatBar.description",
                highlightKeys: ["highlight.wholeGrains", "highlight.fiber"],
                alternativeBarcodes: ["460100000005", "460100000013"]
            ),
            Product(
                barcode: "460100000002",
                nameKey: "product.strawberryYogurt.name",
                category: .food,
                ingredients: [.lactose, .addedSugar, .probiotics],
                genericScore: 68,
                descriptionKey: "product.strawberryYogurt.description",
                highlightKeys: ["highlight.probiotics", "highlight.protein"],
                alternativeBarcodes: ["460100000014", "460100000013"]
            ),
            Product(
                barcode: "460100000003",
                nameKey: "product.peanutShake.name",
                category: .food,
                ingredients: [.peanuts, .lactose, .addedSugar],
                genericScore: 54,
                descriptionKey: "product.peanutShake.description",
                highlightKeys: ["highlight.protein", "highlight.postWorkout"],
                alternativeBarcodes: ["460100000015", "460100000013"]
            ),
            Product(
                barcode: "460100000004",
                nameKey: "product.kombucha.name",
                category: .food,
                ingredients: [.caffeine, .addedSugar, .probiotics],
                genericScore: 71,
                descriptionKey: "product.kombucha.description",
                highlightKeys: ["highlight.liveCulture", "highlight.lightEnergy"],
                alternativeBarcodes: ["460100000013", "460100000014"]
            ),
            Product(
                barcode: "460100000005",
                nameKey: "product.seedCrackers.name",
                category: .food,
                ingredients: [.soy],
                genericScore: 86,
                descriptionKey: "product.seedCrackers.description",
                highlightKeys: ["highlight.lowSugar", "highlight.fiber"],
                alternativeBarcodes: ["460100000013", "460100000014"]
            ),
            Product(
                barcode: "460100000006",
                nameKey: "product.ecoLaundry.name",
                category: .household,
                ingredients: [.fragrance, .sulfates, .enzymes],
                genericScore: 72,
                descriptionKey: "product.ecoLaundry.description",
                highlightKeys: ["highlight.plantBase", "highlight.lowResidue"],
                alternativeBarcodes: ["460100000016", "460100000017"]
            ),
            Product(
                barcode: "460100000007",
                nameKey: "product.kitchenDegreaser.name",
                category: .household,
                ingredients: [.ammonia, .bleach, .fragrance],
                genericScore: 36,
                descriptionKey: "product.kitchenDegreaser.description",
                highlightKeys: ["highlight.heavyDuty"],
                alternativeBarcodes: ["460100000016", "460100000018"]
            ),
            Product(
                barcode: "460100000008",
                nameKey: "product.dishSoap.name",
                category: .household,
                ingredients: [.sulfates, .fragrance],
                genericScore: 61,
                descriptionKey: "product.dishSoap.description",
                highlightKeys: ["highlight.quickRinse"],
                alternativeBarcodes: ["460100000017", "460100000016"]
            ),
            Product(
                barcode: "460100000009",
                nameKey: "product.faceCream.name",
                category: .cosmetics,
                ingredients: [.fragrance, .parabens, .alcohol],
                genericScore: 43,
                descriptionKey: "product.faceCream.description",
                highlightKeys: ["highlight.richTexture"],
                alternativeBarcodes: ["460100000010", "460100000019"]
            ),
            Product(
                barcode: "460100000010",
                nameKey: "product.mineralSunscreen.name",
                category: .cosmetics,
                ingredients: [.zincOxide, .hyaluronicAcid],
                genericScore: 92,
                descriptionKey: "product.mineralSunscreen.description",
                highlightKeys: ["highlight.fragranceFree", "highlight.dailyUse"],
                alternativeBarcodes: ["460100000019", "460100000020"]
            ),
            Product(
                barcode: "460100000011",
                nameKey: "product.repairShampoo.name",
                category: .cosmetics,
                ingredients: [.sulfates, .fragrance, .parabens],
                genericScore: 57,
                descriptionKey: "product.repairShampoo.description",
                highlightKeys: ["highlight.salonFinish"],
                alternativeBarcodes: ["460100000020", "460100000019"]
            ),
            Product(
                barcode: "460100000012",
                nameKey: "product.aloeGel.name",
                category: .cosmetics,
                ingredients: [.aloe, .alcohol, .fragrance],
                genericScore: 64,
                descriptionKey: "product.aloeGel.description",
                highlightKeys: ["highlight.cooling"],
                alternativeBarcodes: ["460100000019", "460100000010"]
            ),
            Product(
                barcode: "460100000013",
                nameKey: "product.greekYogurt.name",
                category: .food,
                ingredients: [.probiotics],
                genericScore: 90,
                descriptionKey: "product.greekYogurt.description",
                highlightKeys: ["highlight.highProtein", "highlight.lowSugar"],
                alternativeBarcodes: ["460100000014", "460100000005"]
            ),
            Product(
                barcode: "460100000014",
                nameKey: "product.coconutSkyr.name",
                category: .food,
                ingredients: [.probiotics],
                genericScore: 88,
                descriptionKey: "product.coconutSkyr.description",
                highlightKeys: ["highlight.lactoseFree", "highlight.lowSugar"],
                alternativeBarcodes: ["460100000013", "460100000005"]
            ),
            Product(
                barcode: "460100000015",
                nameKey: "product.seedShake.name",
                category: .food,
                ingredients: [.soy],
                genericScore: 84,
                descriptionKey: "product.seedShake.description",
                highlightKeys: ["highlight.noPeanuts", "highlight.highProtein"],
                alternativeBarcodes: ["460100000013", "460100000014"]
            ),
            Product(
                barcode: "460100000016",
                nameKey: "product.enzymeCleaner.name",
                category: .household,
                ingredients: [.enzymes],
                genericScore: 89,
                descriptionKey: "product.enzymeCleaner.description",
                highlightKeys: ["highlight.fragranceFree", "highlight.lowResidue"],
                alternativeBarcodes: ["460100000017", "460100000018"]
            ),
            Product(
                barcode: "460100000017",
                nameKey: "product.fragranceFreeDishSoap.name",
                category: .household,
                ingredients: [.enzymes],
                genericScore: 86,
                descriptionKey: "product.fragranceFreeDishSoap.description",
                highlightKeys: ["highlight.fragranceFree", "highlight.quickRinse"],
                alternativeBarcodes: ["460100000016", "460100000018"]
            ),
            Product(
                barcode: "460100000018",
                nameKey: "product.surfaceSpray.name",
                category: .household,
                ingredients: [.enzymes],
                genericScore: 82,
                descriptionKey: "product.surfaceSpray.description",
                highlightKeys: ["highlight.kitchenSafe", "highlight.lowResidue"],
                alternativeBarcodes: ["460100000016", "460100000017"]
            ),
            Product(
                barcode: "460100000019",
                nameKey: "product.calmCream.name",
                category: .cosmetics,
                ingredients: [.hyaluronicAcid, .aloe],
                genericScore: 91,
                descriptionKey: "product.calmCream.description",
                highlightKeys: ["highlight.fragranceFree", "highlight.barrierSupport"],
                alternativeBarcodes: ["460100000010", "460100000020"]
            ),
            Product(
                barcode: "460100000020",
                nameKey: "product.calmShampoo.name",
                category: .cosmetics,
                ingredients: [.aloe],
                genericScore: 87,
                descriptionKey: "product.calmShampoo.description",
                highlightKeys: ["highlight.sulfateFree", "highlight.fragranceFree"],
                alternativeBarcodes: ["460100000019", "460100000010"]
            )
        ]
    }
}
