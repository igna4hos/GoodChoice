import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case scan
    case history
    case analytics
    case profile

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .scan: return "tab.scan"
        case .history: return "tab.history"
        case .analytics: return "tab.analytics"
        case .profile: return "tab.profile"
        }
    }

    var systemImage: String {
        switch self {
        case .scan: return "viewfinder.circle"
        case .history: return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .profile: return "person.crop.circle"
        }
    }
}
