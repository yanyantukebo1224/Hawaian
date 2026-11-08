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
        XCTAssertEqual(filtered.compactMap { $0.language.languageCode?.identifier }, ["en", "ko"])
    }

    func testFilteringCanBeDisabled() {
        let locales = [Locale(identifier: "ja-JP"), Locale(identifier: "en-US")]
        XCTAssertEqual(SpeechLanguagePolicy.filter(locales, excludingLanguageCode: nil).count, 2)
    }
}


final class SmartReplyEngineTests: XCTestCase {
    func testIntentChangesReplyTemplate() {
        let dining = SmartReplyEngine.candidates(for: .dining, incomingText: "What would you like?")
        let choice = dining.first { $0.id == "choose" }
        XCTAssertEqual(choice?.body, "I'd like {choice}, please.")
        XCTAssertTrue(choice?.requiresFill == true)
    }

    func testContextChangesClarificationSuggestion() {
        let withoutContext = SmartReplyEngine.candidates(for: .everyday, incomingText: "Hello")
        let withContext = SmartReplyEngine.candidates(for: .everyday, incomingText: "Hello", recentContext: ["Nice to meet you"])
        XCTAssertEqual(withoutContext.first { $0.id == "clarify" }?.title, "Ask for clarification")
        XCTAssertEqual(withContext.first { $0.id == "clarify" }?.title, "Check the context")
    }

    func testVariableFillReplacesChoice() {
        let candidate = SmartReplyEngine.candidates(for: .shopping, incomingText: "").first { $0.id == "choose" }!
        XCTAssertEqual(SmartReplyEngine.fill(candidate, with: "the blue one"), "I'd prefer the blue one.")
    }
}


final class RecognitionCandidatePolicyTests: XCTestCase {
    func testAutoRecognitionCandidateLimit() {
        let locales = (0..<12).map { Locale(identifier: "lang" + String($0)) }
        let selected = SpeechLanguagePolicy.recognitionCandidates(locales, maximumAutomaticLanguages: 8)
        XCTAssertEqual(selected.count, 8)
    }

    func testManualRecognitionCandidateSelection() {
        let locales = [Locale(identifier: "en-US"), Locale(identifier: "ja-JP"), Locale(identifier: "ko-KR")]
        let selected = SpeechLanguagePolicy.recognitionCandidates(locales, preferredLanguageCode: "ko")
        XCTAssertEqual(selected.count, 1)
        XCTAssertEqual(selected.first?.language.languageCode?.identifier, "ko")
    }
}
