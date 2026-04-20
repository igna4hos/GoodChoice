import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cameraPermission = CameraPermissionService()

    @State private var flashlightOn = false
    @State private var selectedEvaluation: ProductEvaluation?
    @State private var scanTask: Task<Void, Never>?
    @State private var scanPhase: ScanPhase = .idle

    private var targets: [Product] {
        store.products.filter { $0.kind == .flakes }
    }

    private var previewProduct: Product? {
        targets.first
    }

    var body: some View {
        ZStack {
            cameraBackdrop

            switch cameraPermission.status {
            case .idle, .requesting:
                loadingState
            case .denied:
                permissionDeniedState
            case .granted:
                scannerContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
        .onAppear {
            Task {
                await updateScannerState()
            }
        }
        .onDisappear {
            stopScanning(resetResult: true)
        }
        .onChange(of: store.selectedTab) { _, _ in
            Task {
                await updateScannerState()
            }
        }
        .onChange(of: scenePhase) { _, _ in
            Task {
                await updateScannerState()
            }
        }
    }

    private var cameraBackdrop: some View {
        GeometryReader { geometry in
            ZStack {
                if let previewProduct {
                    Image(previewProduct.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .saturation(flashlightOn ? 0.95 : 0.68)
                        .blur(radius: scanPhase == .found ? 12 : 18)
                        .overlay(Color.black.opacity(flashlightOn ? 0.26 : 0.44))
                } else {
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.12, green: 0.14, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                RoundedRectangle(cornerRadius: 280, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(flashlightOn ? 0.18 : 0.04), .clear],
                            center: .center,
                            startRadius: 24,
                            endRadius: 420
                        )
                    )
                    .scaleEffect(1.35)

                LinearGradient(
                    colors: [Color.black.opacity(0.72), Color.clear, Color.black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                cameraFeedDecor
            }
            .ignoresSafeArea()
        }
    }

    private var cameraFeedDecor: some View {
        VStack {
            HStack(spacing: 18) {
                feedPill(width: 124)
                Spacer()
                feedPill(width: 74)
            }
            .padding(.horizontal, 28)
            .padding(.top, 104)

            Spacer()

            HStack(spacing: 14) {
                feedThumbnail(imageName: "products.flakes.kosmostars", angle: -7)
                feedThumbnail(imageName: "products.flakes.khrutka", angle: 3)
                feedThumbnail(imageName: "products.flakes.oreo", angle: 8)
                feedThumbnail(imageName: "products.flakes.redprice", angle: -5)
            }
            .padding(.bottom, 164)
        }
    }

    private func feedPill(width: CGFloat) -> some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(0.08))
            .frame(width: width, height: 16)
            .blur(radius: 0.5)
    }

    private func feedThumbnail(imageName: String, angle: Double) -> some View {
        ProductImageView(imageName: imageName, width: 62, height: 90, cornerRadius: 20)
            .rotationEffect(.degrees(angle))
            .opacity(0.58)
            .blur(radius: 0.4)
    }

    private var scannerContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 24)
                scannerFrame(width: min(geometry.size.width - 48, 320))
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 96)
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("scan.camera.badge")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12), in: Capsule(style: .continuous))

                Text("scan.title")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                flashlightOn.toggle()
            } label: {
                Image(systemName: flashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(flashlightOn ? AppTheme.orange : .white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.14))
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .disabled(cameraPermission.status != .granted)
        }
    }

    private func scannerFrame(width: CGFloat) -> some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.black.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .frame(width: width, height: 208)

                ScannerCornerMarks(color: scanPhase == .found ? AppTheme.green : AppTheme.orange)
                    .frame(width: width, height: 208)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(scanPhase == .found ? AppTheme.green.opacity(0.92) : AppTheme.orange.opacity(0.92), style: StrokeStyle(lineWidth: 2, dash: [12, 8]))
                    .frame(width: width - 42, height: 154)

                if scanPhase != .idle {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, scanPhase == .found ? AppTheme.green : AppTheme.orange, Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width - 54, height: 4)
                        .shadow(color: (scanPhase == .found ? AppTheme.green : AppTheme.orange).opacity(0.45), radius: 16, x: 0, y: 4)
                        .transition(.opacity)
                }

                VStack(spacing: 10) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    Text("scan.align.caption")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }

            Text(scanPhase == .found ? "scan.align.detected" : "scan.align.center")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("scan.camera.demo")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("scan.camera.demo.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                if let remaining = store.freeScansRemaining {
                    Text(store.localized("scan.free.remaining", remaining))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.orange.opacity(0.14), in: Capsule(style: .continuous))
                }
            }

            if let account = store.currentAccount, let profile = store.currentProfile {
                Text(store.localized("scan.status.user", "\(account.firstName) \(account.lastName)", profile.name))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(targets) { product in
                        Button {
                            triggerManualScan(product)
                        } label: {
                            ProductImageView(imageName: product.imageName, width: 66, height: 94, cornerRadius: 18)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var loadingState: some View {
        VStack(spacing: 18) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
            Text("scan.permission.requesting")
                .font(.headline)
                .foregroundStyle(.white)
            Text("scan.permission.message")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
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

    private func updateScannerState() async {
        guard store.selectedTab == .scan else {
            stopScanning(resetResult: true)
            return
        }

        guard scenePhase == .active else {
            stopScanning(resetResult: false)
            return
        }

        await cameraPermission.requestAccessIfNeeded()
        guard cameraPermission.status == .granted else {
            stopScanning(resetResult: true)
            return
        }

        guard selectedEvaluation == nil else { return }
        startScanning()
    }

    private func startScanning() {
        guard isAutoScanActive else { return }
        scanTask?.cancel()
        scanPhase = .idle

        scanTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            let isStillActive = await MainActor.run { isAutoScanActive }
            guard isStillActive else { return }
            await MainActor.run {
                scanPhase = .found
            }
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            let isReadyForResult = await MainActor.run { isAutoScanActive }
            guard isReadyForResult else { return }
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

    private func stopScanning(resetResult: Bool) {
        scanTask?.cancel()
        scanTask = nil
        scanPhase = .idle
        flashlightOn = false
        if resetResult {
            selectedEvaluation = nil
        }
    }

    private var isAutoScanActive: Bool {
        cameraPermission.status == .granted && store.selectedTab == .scan && scenePhase == .active && selectedEvaluation == nil
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

private struct ScannerCornerMarks: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let cornerLength: CGFloat = 34
            let lineWidth: CGFloat = 4

            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                path.move(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))

                path.move(to: CGPoint(x: width - cornerLength, y: 0))
                path.addLine(to: CGPoint(x: width, y: 0))
                path.addLine(to: CGPoint(x: width, y: cornerLength))

                path.move(to: CGPoint(x: 0, y: height - cornerLength))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: cornerLength, y: height))

                path.move(to: CGPoint(x: width - cornerLength, y: height))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: width, y: height - cornerLength))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .shadow(color: color.opacity(0.28), radius: 16, x: 0, y: 0)
        }
    }
}
