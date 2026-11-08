import Foundation
import Speech
import Translation

@MainActor
final class LanguageCatalog: ObservableObject {
    @Published private(set) var speechInputLocales: [Locale] = []
    @Published private(set) var translationLanguages: [Locale.Language] = []
    @Published private(set) var isLoaded = false

    func load(excludingDeviceLanguage: Bool, targetLanguageCode: String? = nil) async {
        let speechLocales = Array(SFSpeechRecognizer.supportedLocales())
        let translation = await LanguageAvailability().supportedLanguages
        let translationCodes = Set(translation.map { $0.languageCode?.identifier.lowercased() ?? $0.minimalIdentifier.lowercased() })
        let excludedCode = excludingDeviceLanguage ? SpeechLanguagePolicy.deviceLanguageCode() : nil

        speechInputLocales = SpeechLanguagePolicy.filter(speechLocales, excludingLanguageCode: excludedCode)
            .filter { locale in
                let code = locale.language.languageCode?.identifier.lowercased() ?? ""
                return translationCodes.contains(code)
            }
            .sorted {
                $0.localizedString(forIdentifier: $0.identifier) ?? $0.identifier
                    < $1.localizedString(forIdentifier: $1.identifier) ?? $1.identifier
            }

        translationLanguages = translation.sorted {
            $0.localizedDescription.localizedStandardCompare($1.localizedDescription) == .orderedAscending
        }
        isLoaded = true
    }

    func displayName(for languageCode: String) -> String {
        Locale.current.localizedString(forIdentifier: languageCode)
            ?? Locale.current.localizedString(forLanguageCode: languageCode)
            ?? languageCode.uppercased()
    }
}
