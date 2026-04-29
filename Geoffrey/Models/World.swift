import Foundation
import SwiftData

@Model
final class World {
    var name: String
    var systemPreamble: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Location.world)
    var locations: [Location] = []

    @Relationship(deleteRule: .cascade, inverse: \StoryCharacter.world)
    var characters: [StoryCharacter] = []

    @Relationship(deleteRule: .cascade, inverse: \LoreCard.world)
    var loreCards: [LoreCard] = []

    @Relationship(deleteRule: .cascade, inverse: \Session.world)
    var sessions: [Session] = []

    var project: Project?

    init(name: String, systemPreamble: String = "") {
        self.name = name
        self.systemPreamble = systemPreamble
        self.createdAt = .now
    }
}
