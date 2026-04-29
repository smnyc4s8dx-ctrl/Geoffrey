import Foundation

enum CardType: String, CaseIterable {
    case location
    case character
    case lore

    var displayName: String {
        switch self {
        case .location: "Location"
        case .character: "Character"
        case .lore: "Lore"
        }
    }

    var icon: String {
        switch self {
        case .location: "map"
        case .character: "person.fill"
        case .lore: "book.fill"
        }
    }
}

struct DuplicateConflict: Identifiable {
    let id = UUID()
    let cardType: CardType
    let name: String
    let existingSummary: String
    let incomingSummary: String
    var resolution: DuplicateResolution = .keepExisting
}

enum DuplicateResolution: String, CaseIterable {
    case keepExisting
    case replace
    case keepBoth

    var displayName: String {
        switch self {
        case .keepExisting: "Keep Existing"
        case .replace: "Replace with Imported"
        case .keepBoth: "Keep Both"
        }
    }
}
