import Foundation

final class MockAnalyticsService {
    typealias Localize = (String, CVarArg) -> String

    func report(
        for profile: UserProfile?,
        period: AnalyticsPeriod,
        category: ProductCategory?,
        productService: MockProductService,
        localization: @escaping (String, CVarArg...) -> String
    ) -> AnalyticsReport {
        guard let profile else {
            return AnalyticsReport(
                averageScore: 0,
                healthyCount: 0,
                riskyCount: 0,
                totalScans: 0,
                topCategory: nil,
                categoryAnalytics: [],
                frequentProducts: [],
                trend: [],
                insights: [],
                scoreDelta: 0
            )
        }

        let filteredHistory = filter(history: profile.scanHistory, period: period, category: category, productService: productService)
        let evaluatedHistory = filteredHistory.compactMap { record -> (ScanRecord, ProductEvaluation)? in
            guard let product = productService.product(for: record.productBarcode) else { return nil }
            return (record, productService.evaluate(product: product, profile: profile))
        }

        let scores = evaluatedHistory.map(\.1.personalizedScore)
        let averageScore = scores.isEmpty ? 0 : Int(scores.reduce(0, +) / scores.count)
        let healthyCount = scores.filter { $0 >= 75 }.count
        let riskyCount = scores.filter { $0 < 45 }.count
        let totalScans = scores.count

        let categoryAnalytics = ProductCategory.allCases.compactMap { currentCategory -> CategoryAnalytics? in
            let rows = evaluatedHistory.filter { $0.1.product.category == currentCategory }
            guard !rows.isEmpty else { return nil }
            let average = Double(rows.map(\.1.personalizedScore).reduce(0, +)) / Double(rows.count)
            return CategoryAnalytics(category: currentCategory, scanCount: rows.count, averageScore: average)
        }
        .sorted { $0.scanCount > $1.scanCount }

        let topCategory = categoryAnalytics.first?.category
        let frequentProducts = topProducts(from: evaluatedHistory).prefix(3).map { $0 }
        let trend = makeTrend(from: evaluatedHistory, period: period)
        let scoreDelta = calculateDelta(from: trend)
        let insights = makeInsights(
            evaluatedHistory: evaluatedHistory,
            averageScore: averageScore,
            healthyCount: healthyCount,
            riskyCount: riskyCount,
            topCategory: topCategory,
            scoreDelta: scoreDelta,
            localization: localization
        )

        return AnalyticsReport(
            averageScore: averageScore,
            healthyCount: healthyCount,
            riskyCount: riskyCount,
            totalScans: totalScans,
            topCategory: topCategory,
            categoryAnalytics: categoryAnalytics,
            frequentProducts: frequentProducts,
            trend: trend,
            insights: insights,
            scoreDelta: scoreDelta
        )
    }

    private func filter(
        history: [ScanRecord],
        period: AnalyticsPeriod,
        category: ProductCategory?,
        productService: MockProductService
    ) -> [ScanRecord] {
        let calendar = Calendar.current
        let periodFiltered = history.filter { record in
            switch period {
            case .week:
                return record.scannedAt >= calendar.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
            case .month:
                return record.scannedAt >= calendar.date(byAdding: .month, value: -1, to: .now) ?? .distantPast
            case .allTime:
                return true
            }
        }

        guard let category else { return periodFiltered }
        return periodFiltered.filter { record in
            productService.product(for: record.productBarcode)?.category == category
        }
    }

    private func topProducts(from entries: [(ScanRecord, ProductEvaluation)]) -> [FrequentProduct] {
        let grouped = Dictionary(grouping: entries, by: { $0.1.product.barcode })
        return grouped.values.compactMap { rows in
            guard let first = rows.first else { return nil }
            let count = rows.count
            let average = Double(rows.map(\.1.personalizedScore).reduce(0, +)) / Double(count)
            return FrequentProduct(product: first.1.product, count: count, averageScore: average)
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.averageScore > rhs.averageScore
            }
            return lhs.count > rhs.count
        }
    }

    private func makeTrend(from entries: [(ScanRecord, ProductEvaluation)], period: AnalyticsPeriod) -> [TrendPoint] {
        let calendar = Calendar.current
        let grouped: [Date: [(ScanRecord, ProductEvaluation)]]

        switch period {
        case .week:
            grouped = Dictionary(grouping: entries) {
                calendar.startOfDay(for: $0.0.scannedAt)
            }
        case .month:
            grouped = Dictionary(grouping: entries) {
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: $0.0.scannedAt)
                return calendar.date(from: components) ?? calendar.startOfDay(for: $0.0.scannedAt)
            }
        case .allTime:
            grouped = Dictionary(grouping: entries) {
                let components = calendar.dateComponents([.year, .month], from: $0.0.scannedAt)
                return calendar.date(from: components) ?? calendar.startOfDay(for: $0.0.scannedAt)
            }
        }

        return grouped
            .map { date, rows in
                let average = Double(rows.map(\.1.personalizedScore).reduce(0, +)) / Double(rows.count)
                return TrendPoint(
                    label: date.formatted(.dateTime.month(.abbreviated).day()),
                    date: date,
                    averageScore: average
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func calculateDelta(from trend: [TrendPoint]) -> Int {
        guard trend.count >= 2, let first = trend.first, let last = trend.last else { return 0 }
        return Int(last.averageScore - first.averageScore)
    }

    private func makeInsights(
        evaluatedHistory: [(ScanRecord, ProductEvaluation)],
        averageScore: Int,
        healthyCount: Int,
        riskyCount: Int,
        topCategory: ProductCategory?,
        scoreDelta: Int,
        localization: @escaping (String, CVarArg...) -> String
    ) -> [AnalyticsInsight] {
        var items: [AnalyticsInsight] = []

        items.append(
            AnalyticsInsight(
                icon: "arrow.up.right.circle.fill",
                tint: .green,
                title: localization("analytics.insight.score.title"),
                message: localization(
                    scoreDelta >= 0 ? "analytics.insight.score.up" : "analytics.insight.score.down",
                    abs(scoreDelta)
                ),
                isPremiumOnly: false
            )
        )

        if let topCategory {
            items.append(
                AnalyticsInsight(
                    icon: "square.grid.2x2.fill",
                    tint: .orange,
                    title: localization("analytics.insight.category.title"),
                    message: localization("analytics.insight.category.message", localization(topCategory.titleKey)),
                    isPremiumOnly: false
                )
            )
        }

        items.append(
            AnalyticsInsight(
                icon: riskyCount <= max(1, healthyCount / 2) ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tint: riskyCount <= max(1, healthyCount / 2) ? .green : .red,
                title: localization("analytics.insight.risk.title"),
                message: localization(
                    riskyCount == 0 ? "analytics.insight.risk.none" : "analytics.insight.risk.some",
                    riskyCount
                ),
                isPremiumOnly: false
            )
        )

        items.append(
            AnalyticsInsight(
                icon: "sparkles",
                tint: .orange,
                title: localization("analytics.insight.premium.title"),
                message: localization("analytics.insight.premium.message", averageScore),
                isPremiumOnly: true
            )
        )

        return items
    }
}
