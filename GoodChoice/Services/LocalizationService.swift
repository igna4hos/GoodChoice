import Foundation

enum LocalizationService {
    static func string(_ key: String, language: AppLanguage, arguments: [CVarArg] = []) -> String {
        let bundle = bundle(for: language)
        let format = NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: language.locale, arguments: arguments)
    }

    private static func bundle(for language: AppLanguage) -> Bundle {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }
}
