import Foundation

struct ExportedWorld: Codable {
    let name: String
    let systemPreamble: String
    var locations: [ExportedLocation]
    var characters: [ExportedCharacter]
    let loreCards: [ExportedLoreCard]
    let exportedAt: Date
    let geoffreyVersion: String

    init(name: String, systemPreamble: String, locations: [ExportedLocation], characters: [ExportedCharacter], loreCards: [ExportedLoreCard]) {
        self.name = name
        self.systemPreamble = systemPreamble
        self.locations = locations
        self.characters = characters
        self.loreCards = loreCards
        self.exportedAt = .now
        self.geoffreyVersion = "1.1"
    }
}

struct ExportedLocation: Codable {
    let name: String
    let stateLabel: String
    let descriptionText: String
    let notes: String
    let conditionDescription: String
    let accessibility: String
    let atmosphere: String
    let stateUpdatePermission: String
    var imageFilename: String?
}

struct ExportedCharacter: Codable {
    let name: String
    let role: String
    let persona: String
    let voiceSample: String
    let notes: String
    var tags: [String] = []
    let vitalityStatus: String
    let psychologicalState: String
    let knowledgeState: String
    let roleplayPosture: String
    let narrativePresence: String
    let currentState: String
    let stateUpdatePermission: String
    var imageFilename: String?
}

struct ExportedLoreCard: Codable {
    let title: String
    let content: String
    let tags: [String]
    let priority: String
    let currency: String
    let revelationStatus: String
    let scopeChange: String
    let stateUpdatePermission: String
}
