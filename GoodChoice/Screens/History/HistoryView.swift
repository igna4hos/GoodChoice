import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    @State private var sortOption: HistorySortOption = .date
    @State private var selectedEvaluation: ProductEvaluation?
    @State private var searchText = ""

    var body: some View {
        Group {
            if store.isSignedIn {
                List {
                    ForEach(sections) { section in
                        Section(section.title) {
                            ForEach(section.records) { record in
                                if let product = store.product(for: record.productBarcode) {
                                    let evaluation = store.evaluation(for: product)
                                    Button {
                                        selectedEvaluation = evaluation
                                    } label: {
                                        HistoryRowView(record: record, product: product, evaluation: evaluation)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            store.deleteHistoryRecord(record.id)
                                        } label: {
                                            Label("history.delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("history.search.placeholder"))
            } else {
                signedOutState
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(Text("history.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("history.sort.title", selection: $sortOption) {
                        ForEach(HistorySortOption.allCases) { option in
                            Text(LocalizedStringKey(option.titleKey)).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(item: $selectedEvaluation) { evaluation in
            ProductEvaluationSheet(
                evaluation: evaluation,
                onClose: { selectedEvaluation = nil },
                onContinueScanning: {
                    selectedEvaluation = nil
                    store.selectedTab = .scan
                },
                onShowHistory: { selectedEvaluation = nil }
            )
            .environmentObject(store)
        }
    }

    private var signedOutState: some View {
        VStack(spacing: 18) {
            PremiumCard(padding: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("history.signedOut.title")
                        .font(.headline)
                    Text("history.signedOut.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding(.top, 20)
    }

    private var filteredRecords: [ScanRecord] {
        let records = store.currentScanHistory
        guard !searchText.isEmpty else { return records }
        return records.filter { record in
            guard let product = store.product(for: record.productBarcode) else { return false }
            return store.localized(product.nameKey).localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sections: [HistorySection] {
        switch sortOption {
        case .date:
            let grouped = Dictionary(grouping: filteredRecords) { Calendar.current.startOfDay(for: $0.scannedAt) }
            return grouped.keys.sorted(by: >).map { date in
                HistorySection(
                    title: date.formatted(.dateTime.weekday(.wide).day().month()),
                    records: grouped[date]?.sorted { $0.scannedAt > $1.scannedAt } ?? []
                )
            }
        case .category:
            let grouped = Dictionary(grouping: filteredRecords) { record in
                store.product(for: record.productBarcode)?.category ?? .food
            }
            return ProductCategory.allCases.compactMap { category in
                let rows = grouped[category] ?? []
                guard !rows.isEmpty else { return nil }
                return HistorySection(title: store.localized(category.titleKey), records: rows.sorted { $0.scannedAt > $1.scannedAt })
            }
        case .name:
            let sorted = filteredRecords.sorted {
                let left = store.localized(store.product(for: $0.productBarcode)?.nameKey ?? "")
                let right = store.localized(store.product(for: $1.productBarcode)?.nameKey ?? "")
                return left < right
            }
            let grouped = Dictionary(grouping: sorted) { record in
                String(store.localized(store.product(for: record.productBarcode)?.nameKey ?? "").prefix(1)).uppercased()
            }
            return grouped.keys.sorted().map { key in
                HistorySection(title: key, records: grouped[key] ?? [])
            }
        }
    }
}

private struct HistorySection: Identifiable {
    let id = UUID()
    let title: String
    let records: [ScanRecord]
}

enum HistorySortOption: String, CaseIterable, Identifiable {
    case date
    case category
    case name

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .date: return "history.sort.date"
        case .category: return "history.sort.category"
        case .name: return "history.sort.name"
        }
    }
}
