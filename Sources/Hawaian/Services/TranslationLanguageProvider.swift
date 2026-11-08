import Foundation
import Translation

enum TranslationLanguageProvider {
    static func supportedLanguages() async -> [Locale.Language] {
        let availability = LanguageAvailability()
        return await availability.supportedLanguages
    }
}
