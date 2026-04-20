import AVFoundation
import Combine
import Foundation

@MainActor
final class CameraPermissionService: ObservableObject {
    enum Status {
        case idle
        case requesting
        case granted
        case denied
    }

    @Published private(set) var status: Status = .idle

    func requestAccessIfNeeded() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch currentStatus {
        case .authorized:
            status = .granted
        case .denied, .restricted:
            status = .denied
        case .notDetermined:
            status = .requesting
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            status = granted ? .granted : .denied
        @unknown default:
            status = .denied
        }
    }

    func refresh() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch currentStatus {
        case .authorized:
            status = .granted
        case .denied, .restricted:
            status = .denied
        case .notDetermined:
            status = .idle
        @unknown default:
            status = .denied
        }
    }
}
