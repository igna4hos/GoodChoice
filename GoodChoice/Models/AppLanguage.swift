import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var titleKey: String {
        switch self {
        case .english: return "settings.language.english"
        case .russian: return "settings.language.russian"
        }
    }
}
