import Foundation

struct SmartReplyEngine {
    struct Candidate: Identifiable, Equatable {
        let id: String
        let title: String
        let body: String
        let requiresFill: Bool
        let fillPrompt: String?
    }

    static func candidates(for intent: ConversationIntent, incomingText: String) -> [Candidate] {
        let text = incomingText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasQuestion = text.contains("?") || text.contains("？")
        let detail = text.isEmpty ? nil : String(text.prefix(100))

        let clarify = Candidate(
            id: "clarify",
            title: "Ask for clarification",
            body: hasQuestion ? "Could you explain that a little more?" : "Could you tell me a little more about that?",
            requiresFill: false,
            fillPrompt: nil
        )
        let acknowledge = Candidate(
            id: "acknowledge",
            title: "Acknowledge",
            body: "I understand. Thank you for explaining.",
            requiresFill: false,
            fillPrompt: nil
        )
        let choose: Candidate
        switch intent {
        case .dining:
            choose = Candidate(id: "choose", title: "Place an order", body: "I'd like {choice}, please.", requiresFill: true, fillPrompt: "What would you like?")
        case .shopping:
            choose = Candidate(id: "choose", title: "Choose an item", body: "I'd prefer {choice}.", requiresFill: true, fillPrompt: "Which item?")
        case .travel:
            choose = Candidate(id: "choose", title: "Choose an option", body: "I'll go with {choice}.", requiresFill: true, fillPrompt: "Which option?")
        case .work:
            choose = Candidate(id: "choose", title: "Confirm a plan", body: "That works for me. I'll {choice}.", requiresFill: true, fillPrompt: "What will you do?")
        case .learning:
            choose = Candidate(id: "choose", title: "Give an example", body: "Could you show me an example of {choice}?", requiresFill: true, fillPrompt: "Which topic?")
        case .everyday, .custom:
            choose = Candidate(id: "choose", title: "Add your response", body: "I think {choice}.", requiresFill: true, fillPrompt: "What do you want to say?")
        }

        var results = [acknowledge, clarify, choose]
        if let detail, detail.count > 18 {
            results[0] = Candidate(
                id: "acknowledge",
                title: "Acknowledge what they said",
                body: "I understand what you mean. Thank you for sharing that.",
                requiresFill: false,
                fillPrompt: nil
            )
        }
        return results
    }

    static func fill(_ candidate: Candidate, with value: String) -> String {
        candidate.body.replacingOccurrences(of: "{choice}", with: value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
