import Foundation

enum SpeechLanguagePolicy {
    static func deviceLanguageCode(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        guard let preferred = preferredLanguages.first else {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return Locale(identifier: preferred).language.languageCode?.identifier
            ?? String(preferred.prefix(2)).lowercased()
    }

    static func filter(_ locales: [Locale], excludingLanguageCode: String?) -> [Locale] {
        guard let excluded = excludingLanguageCode?.lowercased(), !excluded.isEmpty else {
            return locales
        }
        return locales.filter { locale in
            locale.language.languageCode?.identifier.lowercased() != excluded
        }
    }
    
    static func recognitionCandidates(
        _ locales: [Locale],
        preferredLanguageCode: String = "auto",
        maximumAutomaticLanguages: Int = 2
    ) -> [Locale] {
        if preferredLanguageCode.lowercased() != "auto" {
            return locales.filter {
                $0.language.languageCode?.identifier.lowercased() == preferredLanguageCode.lowercased()
            }
        }
        return Array(locales.sorted { $0.identifier < $1.identifier }.prefix(maximumAutomaticLanguages))
    }
}
