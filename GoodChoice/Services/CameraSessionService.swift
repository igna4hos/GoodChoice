import AVFoundation
import Combine
import Foundation

final class CameraSessionService: ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isPreviewAvailable = false

    private let queue = DispatchQueue(label: "goodchoice.camera.session", qos: .userInitiated)
    private var isConfigured = false
    private weak var cameraDevice: AVCaptureDevice?

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func setTorch(enabled: Bool) {
        queue.async { [weak self] in
            guard let self, let device = self.cameraDevice, device.hasTorch else { return }

            do {
                try device.lockForConfiguration()
                if enabled {
                    try device.setTorchModeOn(level: min(AVCaptureDevice.maxAvailableTorchLevel, 0.9))
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                return
            }
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(for: .video)
        else {
            DispatchQueue.main.async { [weak self] in
                self?.isPreviewAvailable = false
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                DispatchQueue.main.async { [weak self] in
                    self?.isPreviewAvailable = false
                }
                return
            }

            session.addInput(input)
            cameraDevice = device
            isConfigured = true

            DispatchQueue.main.async { [weak self] in
                self?.isPreviewAvailable = true
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isPreviewAvailable = false
            }
        }
    }
}
