import Foundation

final class LocalizationHelper {
    static let shared = LocalizationHelper()

    private init() {}

    /// Devuelve el texto traducido según el `appLanguage` (no el idioma del sistema).
    func localized(_ key: String, comment: String = "") -> String {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: comment) // fallback
        }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: comment)
    }
}
