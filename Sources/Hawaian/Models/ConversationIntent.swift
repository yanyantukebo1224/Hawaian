import Foundation

enum ConversationIntent: String, CaseIterable, Identifiable {
    case everyday
    case dining
    case shopping
    case travel
    case work
    case learning
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyday: "Everyday"
        case .dining: "Dining"
        case .shopping: "Shopping"
        case .travel: "Travel"
        case .work: "Work"
        case .learning: "Learning"
        case .custom: "Custom"
        }
    }

    var subtitle: String {
        switch self {
        case .everyday: "Casual conversation"
        case .dining: "Order, ask, enjoy"
        case .shopping: "Find the right thing"
        case .travel: "Move with confidence"
        case .work: "Meetings and business"
        case .learning: "Practice and understand"
        case .custom: "Set your own context"
        }
    }

    var symbol: String {
        switch self {
        case .everyday: "bubble.left.and.bubble.right"
        case .dining: "fork.knife"
        case .shopping: "bag"
        case .travel: "airplane"
        case .work: "briefcase"
        case .learning: "book"
        case .custom: "slider.horizontal.3"
        }
    }

    var guidance: String {
        switch self {
        case .everyday: "Keep replies natural, friendly, and concise."
        case .dining: "Help with menus, ordering, dietary needs, and polite questions."
        case .shopping: "Help compare options, sizes, prices, and product details."
        case .travel: "Help with directions, transport, bookings, and local situations."
        case .work: "Prefer clear, professional, and appropriately formal replies."
        case .learning: "Explain unfamiliar phrases and offer simple, useful replies."
        case .custom: "Use the user's custom context without assuming details."
        }
    }
}
