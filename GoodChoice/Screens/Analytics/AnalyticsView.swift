import Charts
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedPeriod: AnalyticsPeriod = .week
    @State private var selectedCategory: ProductCategory?
    @State private var showingPaywall = false

    var report: AnalyticsReport {
        store.analyticsReport(period: selectedPeriod, category: selectedCategory)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if store.isSignedIn {
                    header
                    summaryCards
                    trendCard
                    categoryCard
                    insightGrid
                    topProductsCard
                } else {
                    signedOutState
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("analytics.title"))
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Picker("analytics.period.title", selection: $selectedPeriod) {
                ForEach(AnalyticsPeriod.allCases) { period in
                    Text(LocalizedStringKey(period.titleKey)).tag(period)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    categoryChip(title: store.localized("analytics.filter.all"), selected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(ProductCategory.allCases) { category in
                        categoryChip(title: store.localized(category.titleKey), selected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 14) {
            summaryCard(
                title: store.localized("analytics.card.average"),
                value: "\(report.averageScore)",
                detail: store.localized("analytics.card.average.detail"),
                tint: AppTheme.green
            )

            summaryCard(
                title: store.localized("analytics.card.risky"),
                value: "\(report.riskyCount)",
                detail: store.localized("analytics.card.risky.detail"),
                tint: AppTheme.orange
            )
        }
    }

    private var trendCard: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                Text("analytics.chart.title")
                    .font(.headline)

                if report.trend.isEmpty {
                    Text("analytics.empty")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(report.trend) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.averageScore)
                        )
                        .foregroundStyle(AppTheme.green)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.averageScore)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.green.opacity(0.18), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...100)

                    Text(store.localized("analytics.delta", report.scoreDelta))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(report.scoreDelta >= 0 ? AppTheme.green : AppTheme.red)
                }
            }
        }
    }

    private var categoryCard: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                Text("analytics.category.title")
                    .font(.headline)

                ForEach(report.categoryAnalytics) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(store.localized(item.category.titleKey))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(Int(item.averageScore))")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.green)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule(style: .continuous)
                                    .fill(Color.black.opacity(0.06))
                                Capsule(style: .continuous)
                                    .fill(AppTheme.premiumGradient)
                                    .frame(width: geometry.size.width * CGFloat(item.averageScore / 100.0))
                            }
                        }
                        .frame(height: 10)

                        Text(store.localized("analytics.category.count", item.scanCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var insightGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("analytics.insights.title")
                .font(.headline)
                .padding(.horizontal, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(report.insights) { insight in
                    let locked = insight.isPremiumOnly && store.currentTier == .free
                    Button {
                        if locked {
                            showingPaywall = true
                        }
                    } label: {
                        InsightCardView(insight: insight, locked: locked)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var topProductsCard: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("analytics.products.title")
                    .font(.headline)

                ForEach(report.frequentProducts) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.localized(item.product.nameKey))
                                .font(.subheadline.weight(.semibold))
                            Text(store.localized(item.product.category.titleKey))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(store.localized("analytics.products.count", item.count))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
    }

    private var signedOutState: some View {
        PremiumCard(padding: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("analytics.signedOut.title")
                    .font(.headline)
                Text("analytics.signedOut.message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func categoryChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? AppTheme.orange : Color.white)
                        .shadow(color: AppTheme.subtleShadow.opacity(selected ? 0 : 1), radius: 8, x: 0, y: 5)
                )
        }
        .buttonStyle(.plain)
    }

    private func summaryCard(title: String, value: String, detail: String, tint: Color) -> some View {
        PremiumCard(padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
