import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cameraPermission = CameraPermissionService()
    @StateObject private var cameraSession = CameraSessionService()

    @State private var flashlightOn = false
    @State private var selectedEvaluation: ProductEvaluation?
    @State private var scanTask: Task<Void, Never>?
    @State private var scanPhase: ScanPhase = .idle
    @State private var scanLineProgress: CGFloat = 0

    private var targets: [Product] {
        store.products.filter { $0.kind == .flakes }
    }

    private var previewProduct: Product? {
        targets.first
    }

    var body: some View {
        ZStack {
            cameraBackground

            switch cameraPermission.status {
            case .idle, .requesting:
                loadingState
            case .denied:
                permissionDeniedState
            case .granted:
                scannerChrome
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

    private var cameraBackground: some View {
        ZStack {
            if cameraPermission.status == .granted, cameraSession.isPreviewAvailable {
                CameraPreviewView(session: cameraSession.session)
                    .ignoresSafeArea()
            } else {
                fallbackPreview
            }

            LinearGradient(
                colors: [Color.black.opacity(0.52), Color.clear, Color.black.opacity(0.74)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(flashlightOn ? 0.16 : 0.03), .clear],
                center: .center,
                startRadius: 12,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }

    private var fallbackPreview: some View {
        GeometryReader { geometry in
            ZStack {
                if let previewProduct {
                    Image(previewProduct.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .saturation(0.45)
                        .blur(radius: 24)
                        .overlay(Color.black.opacity(0.4))
                } else {
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.12, green: 0.14, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()
        }
    }

    private var scannerChrome: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topOverlay
                Spacer(minLength: 24)
                scanFrame(width: min(geometry.size.width - 64, 306))
                Spacer()
                bottomStatus
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 86)
        }
    }

    private var topOverlay: some View {
        HStack {
            Spacer()
            Button {
                toggleFlashlight()
            } label: {
                Image(systemName: flashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(flashlightOn ? AppTheme.orange : .white)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(cameraPermission.status != .granted)
        }
        .padding(.top, 4)
    }

    private func scanFrame(width: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .frame(width: width, height: 212)

            ScannerCornerMarks(color: scanAccentColor)
                .frame(width: width, height: 212)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(scanAccentColor.opacity(0.96), style: StrokeStyle(lineWidth: 2, dash: [12, 8]))
                .frame(width: width - 44, height: 154)

            GeometryReader { geometry in
                let lineOffset = -geometry.size.height / 2 + 40 + (geometry.size.height - 80) * scanLineProgress

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, scanAccentColor, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)
                    .shadow(color: scanAccentColor.opacity(0.38), radius: 16, x: 0, y: 6)
                    .opacity(scanPhase == .idle ? 0 : 1)
                    .offset(y: lineOffset)
                    .animation(.easeInOut(duration: 0.15), value: scanPhase)
            }
            .frame(width: width - 44, height: 154)
            .clipped()

            VStack(spacing: 10) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text("scan.align.caption")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }
        }
    }

    private var bottomStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: scanPhase == .idle ? "camera.aperture" : "waveform.path.ecg.rectangle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(scanPhase == .found ? AppTheme.green : AppTheme.orange)

            Text(scanStatusText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)

            Spacer(minLength: 10)

            if let remaining = store.freeScansRemaining {
                Text(store.localized("scan.free.remaining", remaining))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var scanAccentColor: Color {
        switch scanPhase {
        case .idle:
            return AppTheme.orange
        case .scanning:
            return AppTheme.orange
        case .found:
            return AppTheme.green
        }
    }

    private var scanStatusText: String {
        switch scanPhase {
        case .idle:
            return store.localized("scan.camera.ready")
        case .scanning:
            return store.localized("scan.camera.scanning")
        case .found:
            return store.localized("scan.align.detected")
        }
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

        cameraSession.start()

        guard selectedEvaluation == nil else { return }
        startScanning()
    }

    private func startScanning() {
        guard isAutoScanActive else { return }
        scanTask?.cancel()
        scanPhase = .idle
        scanLineProgress = 0

        scanTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            let isStillActive = await MainActor.run { isAutoScanActive }
            guard isStillActive else { return }

            await MainActor.run {
                scanPhase = .scanning
                scanLineProgress = 0
                withAnimation(.easeInOut(duration: 0.95)) {
                    scanLineProgress = 1
                }
            }

            try? await Task.sleep(for: .milliseconds(1050))
            guard !Task.isCancelled else { return }
            let isReadyForResult = await MainActor.run { isAutoScanActive }
            guard isReadyForResult else { return }

            await MainActor.run {
                scanPhase = .found
                scanLineProgress = 0.5
            }

            try? await Task.sleep(for: .milliseconds(260))
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
        scanLineProgress = 0
    }

    private func stopScanning(resetResult: Bool) {
        scanTask?.cancel()
        scanTask = nil
        scanPhase = .idle
        scanLineProgress = 0
        if flashlightOn {
            flashlightOn = false
            cameraSession.setTorch(enabled: false)
        }
        cameraSession.stop()
        if resetResult {
            selectedEvaluation = nil
        }
    }

    private var isAutoScanActive: Bool {
        cameraPermission.status == .granted && store.selectedTab == .scan && scenePhase == .active && selectedEvaluation == nil
    }

    private func toggleFlashlight() {
        flashlightOn.toggle()
        cameraSession.setTorch(enabled: flashlightOn)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private enum ScanPhase {
    case idle
    case scanning
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
            .shadow(color: color.opacity(0.24), radius: 16, x: 0, y: 0)
        }
    }
}
