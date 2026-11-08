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
        case .everyday: NSLocalizedString("Everyday", comment: "")
        case .dining: NSLocalizedString("Dining", comment: "")
        case .shopping: NSLocalizedString("Shopping", comment: "")
        case .travel: NSLocalizedString("Travel", comment: "")
        case .work: NSLocalizedString("Work", comment: "")
        case .learning: NSLocalizedString("Learning", comment: "")
        case .custom: NSLocalizedString("Custom", comment: "")
        }
    }

    var subtitle: String {
        switch self {
        case .everyday: NSLocalizedString("Casual conversation", comment: "")
        case .dining: NSLocalizedString("Order, ask, enjoy", comment: "")
        case .shopping: NSLocalizedString("Find the right thing", comment: "")
        case .travel: NSLocalizedString("Move with confidence", comment: "")
        case .work: NSLocalizedString("Meetings and business", comment: "")
        case .learning: NSLocalizedString("Practice and understand", comment: "")
        case .custom: NSLocalizedString("Set your own context", comment: "")
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
        case .everyday: NSLocalizedString("Keep replies natural, friendly, and concise.", comment: "")
        case .dining: NSLocalizedString("Help with menus, ordering, dietary needs, and polite questions.", comment: "")
        case .shopping: NSLocalizedString("Help compare options, sizes, prices, and product details.", comment: "")
        case .travel: NSLocalizedString("Help with directions, transport, bookings, and local situations.", comment: "")
        case .work: NSLocalizedString("Prefer clear, professional, and appropriately formal replies.", comment: "")
        case .learning: NSLocalizedString("Explain unfamiliar phrases and offer simple, useful replies.", comment: "")
        case .custom: NSLocalizedString("Use the user's custom context without assuming details.", comment: "")
        }
    }
}
