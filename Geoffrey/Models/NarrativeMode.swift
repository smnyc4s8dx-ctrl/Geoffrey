import Foundation

enum NarrativeMode: String, CaseIterable, Identifiable {
    case director = "Director"
    case author = "Author"
    case character = "Character"
    case gameMaster = "Game Master"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .director: "megaphone"
        case .author: "pencil.line"
        case .character: "person.fill"
        case .gameMaster: "crown"
        }
    }

    var description: String {
        switch self {
        case .director: "Direct the scene — your prompts are stage directions"
        case .author: "Write prose — your input continues the narrative"
        case .character: "Play as a character — your input is in-character"
        case .gameMaster: "Narrate the world — your input is world narration"
        }
    }
}
