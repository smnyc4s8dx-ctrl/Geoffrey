import SwiftData

enum CenterPanelContent {
    case dialogue
    case editingLocation(Location)
    case editingCharacter(StoryCharacter)
    case editingLore(LoreCard)
    case newLocation
    case newCharacter
    case newLore

    var editingCardID: PersistentIdentifier? {
        switch self {
        case .editingLocation(let loc): loc.persistentModelID
        case .editingCharacter(let char): char.persistentModelID
        case .editingLore(let lore): lore.persistentModelID
        default: nil
        }
    }

    var isEditing: Bool {
        switch self {
        case .dialogue: false
        default: true
        }
    }
}
