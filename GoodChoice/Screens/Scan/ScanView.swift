import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var store: AppStore

    @State private var isAnimating = false
    @State private var selectedEvaluation: ProductEvaluation?
    @State private var autoScanTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    scannerHeader
                    scannerFrame
                    statusPanel
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(Text("scan.title"))
        .sheet(item: $selectedEvaluation) { evaluation in
            ProductEvaluationSheet(
                evaluation: evaluation,
                onClose: { selectedEvaluation = nil },
                onContinueScanning: {
                    selectedEvaluation = nil
                    startScanning()
                },
                onShowHistory: {
                    selectedEvaluation = nil
                    store.selectedTab = .history
                }
            )
            .environmentObject(store)
        }
        .task {
            startScanning()
        }
        .onDisappear {
            autoScanTask?.cancel()
        }
    }

    private var scannerHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            PremiumCard(padding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("scan.hero.title")
                                .font(.title2.bold())
                            Text("scan.hero.subtitle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let remaining = store.freeScansRemaining {
                            Text(store.localized("scan.free.remaining", remaining))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(AppTheme.orange.opacity(0.12))
                                )
                        }
                    }

                    HStack(spacing: 10) {
                        statusChip(icon: "person.badge.shield.checkmark", text: store.localized(store.currentTier.titleKey), tint: AppTheme.green)
                        statusChip(icon: "globe", text: store.localized(store.language.titleKey), tint: AppTheme.orange)
                    }
                }
            }
        }
    }

    private var scannerFrame: some View {
        PremiumCard(padding: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.14, blue: 0.18),
                                Color(red: 0.17, green: 0.22, blue: 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 420)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(height: 420)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.orange.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [14, 10]))
                    .padding(42)

                VStack {
                    if isAnimating {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, AppTheme.green.opacity(0.85), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 4)
                            .offset(y: 20)
                            .padding(.horizontal, 54)
                            .offset(y: isAnimating ? 104 : -104)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    Spacer()
                }
                .frame(height: 300)

                VStack(spacing: 18) {
                    Spacer()
                    barcodeHint(labelKey: "scan.mock.oat")
                    barcodeHint(labelKey: "scan.mock.cleaner")
                    barcodeHint(labelKey: "scan.mock.sunscreen")
                    Spacer()
                }
                .padding(.horizontal, 26)
            }
            .overlay(alignment: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        triggerManualScan()
                    } label: {
                        Label("scan.action.detect", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.orange)
                }
                .padding(18)
            }
        }
    }

    private var statusPanel: some View {
        PremiumCard(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                Text("scan.status.title")
                    .font(.headline)

                if store.isSignedIn {
                    Text("scan.status.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(store.localized("scan.status.user", store.localized(store.currentProfile?.nameKey ?? "")))
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("scan.signedOut")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statusChip(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private func barcodeHint(labelKey: String) -> some View {
        Button(action: triggerManualScan) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(labelKey))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("scan.mock.tap")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Image(systemName: "barcode.viewfinder")
                    .foregroundStyle(AppTheme.orange)
                    .font(.system(size: 24, weight: .semibold))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private func startScanning() {
        isAnimating = true
        autoScanTask?.cancel()
        autoScanTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                triggerManualScan()
            }
        }
    }

    private func triggerManualScan() {
        autoScanTask?.cancel()
        guard store.isSignedIn else {
            store.selectedTab = .profile
            return
        }
        let product = store.nextMockScanProduct()
        selectedEvaluation = store.scanProduct(product)
    }
}
