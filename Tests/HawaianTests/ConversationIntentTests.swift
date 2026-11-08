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
