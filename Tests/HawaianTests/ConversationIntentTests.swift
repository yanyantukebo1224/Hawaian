import XCTest
@testable import Hawaian

final class ConversationIntentTests: XCTestCase {
    func testEveryIntentHasDisplayMetadata() {
        for intent in ConversationIntent.allCases {
            XCTAssertFalse(intent.title.isEmpty)
            XCTAssertFalse(intent.subtitle.isEmpty)
            XCTAssertFalse(intent.symbol.isEmpty)
            XCTAssertFalse(intent.guidance.isEmpty)
        }
    }

    func testReplyTemplatesDeclareOnlyRequiredVariables() {
        let choose = ReplySuggestion.examples.first { $0.id == "choose" }
        XCTAssertEqual(choose?.missingFields, ["item"])

        let accept = ReplySuggestion.examples.first { $0.id == "accept" }
        XCTAssertEqual(accept?.missingFields, [])
    }
}


final class SpeechLanguagePolicyTests: XCTestCase {
    func testDeviceLanguageUsesFirstPreferredLanguage() {
        XCTAssertEqual(
            SpeechLanguagePolicy.deviceLanguageCode(preferredLanguages: ["ja-JP", "en-US"]),
            "ja"
        )
    }

    func testFilteringExcludesOnlyTheDeviceLanguage() {
        let locales = [
            Locale(identifier: "ja-JP"),
            Locale(identifier: "en-US"),
            Locale(identifier: "ko-KR")
        ]
        let filtered = SpeechLanguagePolicy.filter(locales, excludingLanguageCode: "ja")
        XCTAssertEqual(filtered.map { $0.identifier }, ["en-US", "ko-KR"])
    }

    func testFilteringCanBeDisabled() {
        let locales = [Locale(identifier: "ja-JP"), Locale(identifier: "en-US")]
        XCTAssertEqual(SpeechLanguagePolicy.filter(locales, excludingLanguageCode: nil).count, 2)
    }
}
