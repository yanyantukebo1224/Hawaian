import Foundation

struct ReplySuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let template: String
    let missingFields: [String]

    static let examples: [ReplySuggestion] = [
        .init(id: "accept", title: "Accept", template: "Yes, that works for me.", missingFields: []),
        .init(id: "ask", title: "Ask a question", template: "Could you tell me more about that?", missingFields: []),
        .init(id: "choose", title: "Choose an option", template: "I'd like {item}, please.", missingFields: ["item"]),
        .init(id: "decline", title: "Politely decline", template: "No, thank you. I appreciate it.", missingFields: [])
    ]
}
