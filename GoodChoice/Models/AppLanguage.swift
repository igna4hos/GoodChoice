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

    static func preferredSystemLanguage(
        preferredLanguages: [String] = Locale.preferredLanguages,
        currentLocale: Locale = .current
    ) -> AppLanguage {
        let languageIdentifiers = preferredLanguages + [currentLocale.identifier]

        for identifier in languageIdentifiers {
            let languageCode = Locale(identifier: identifier).language.languageCode?.identifier.lowercased()
            if languageCode == AppLanguage.russian.rawValue {
                return .russian
            }
        }

        return .english
    }
}
