import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var cameraPermission = CameraPermissionService()

    @State private var flashlightOn = false
    @State private var selectedEvaluation: ProductEvaluation?
    @State private var scanTask: Task<Void, Never>?
    @State private var scanPhase: ScanPhase = .idle

    private var targets: [Product] {
        store.products.filter { $0.kind == .flakes }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch cameraPermission.status {
            case .idle, .requesting:
                loadingState
            case .denied:
                permissionDeniedState
            case .granted:
                scannerContent
            }
        }
        .navigationTitle(Text("scan.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    flashlightOn.toggle()
                } label: {
                    Image(systemName: flashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(flashlightOn ? AppTheme.orange : .primary)
                }
                .disabled(cameraPermission.status != .granted)
            }
        }
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
            await cameraPermission.requestAccessIfNeeded()
            if cameraPermission.status == .granted {
                startScanning()
            }
        }
        .onDisappear {
            scanTask?.cancel()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            cameraPermission.refresh()
            if cameraPermission.status == .granted {
                startScanning()
            }
        }
    }

    private var scannerContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                scannerHeader
                scannerFrame
                targetsShelf
                statusPanel
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private var scannerHeader: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
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
                    statusChip(icon: "camera.metering.center.weighted", text: store.localized("scan.status.alignment"), tint: AppTheme.orange)
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
                            colors: flashlightOn
                                ? [Color(red: 0.20, green: 0.24, blue: 0.28), Color(red: 0.28, green: 0.32, blue: 0.29)]
                                : [Color(red: 0.12, green: 0.14, blue: 0.18), Color(red: 0.17, green: 0.22, blue: 0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 430)

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(flashlightOn ? 0.05 : 0.0))
                    .frame(height: 430)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(height: 430)

                alignmentArea

                if scanPhase != .idle {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, scanPhase == .found ? AppTheme.green : AppTheme.orange, Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                        .padding(.horizontal, 54)
                        .offset(y: scanPhase == .found ? 0 : -6)
                        .animation(.easeInOut(duration: 0.7), value: scanPhase)
                }

                VStack(spacing: 16) {
                    Spacer()
                    Text("scan.align.title")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(scanPhase == .found ? "scan.align.detected" : "scan.align.message")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.horizontal, 40)
            }
        }
    }

    private var alignmentArea: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(scanPhase == .found ? AppTheme.green : AppTheme.orange, style: StrokeStyle(lineWidth: 2, dash: [14, 10]))
                .frame(width: 270, height: 178)
                .overlay {
                    VStack(spacing: 10) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(scanPhase == .found ? AppTheme.green : AppTheme.orange)
                        Text("scan.align.caption")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            Spacer()
        }
    }

    private var targetsShelf: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("scan.targets.title")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(targets) { product in
                            Button {
                                triggerManualScan(product)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProductImageView(imageName: product.imageName, width: 112, height: 112, cornerRadius: 22)
                                    Text(store.localized(product.nameKey))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 112, alignment: .leading)
                                        .lineLimit(2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var statusPanel: some View {
        PremiumCard(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("scan.status.title")
                    .font(.headline)

                if let account = store.currentAccount, let profile = store.currentProfile {
                    Text(store.localized("scan.status.user", "\(account.firstName) \(account.lastName)", profile.name))
                        .font(.subheadline.weight(.semibold))
                    Text("scan.status.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("scan.signedOut")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 18) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("scan.permission.requesting")
                .font(.headline)
            Text("scan.permission.message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var permissionDeniedState: some View {
        VStack {
            PremiumCard(padding: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppTheme.orange)
                    Text("scan.permission.denied.title")
                        .font(.title3.bold())
                    Text("scan.permission.denied.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        openSettings()
                    } label: {
                        Text("scan.permission.openSettings")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.premiumGradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 20)
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

    private func startScanning() {
        guard cameraPermission.status == .granted else { return }
        scanTask?.cancel()
        scanPhase = .idle

        scanTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                scanPhase = .found
            }
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                triggerManualScan()
            }
        }
    }

    private func triggerManualScan(_ forcedProduct: Product? = nil) {
        scanTask?.cancel()
        guard store.isSignedIn else {
            store.selectedTab = .profile
            return
        }
        let product = forcedProduct ?? store.nextMockScanProduct()
        selectedEvaluation = store.scanProduct(product)
        scanPhase = .idle
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private enum ScanPhase {
    case idle
    case found
}
