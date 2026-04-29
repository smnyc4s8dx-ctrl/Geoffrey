import Foundation
import SwiftData

@Model
final class StoryCharacter {
    var name: String
    var role: String
    var persona: String
    var voiceSample: String
    var notes: String
    var tags: [String] = []

    // State Layer
    var vitalityStatus: String
    var psychologicalState: String
    var knowledgeState: String
    var roleplayPosture: String
    var narrativePresence: String
    var currentState: String

    var stateUpdatePermission: StateUpdatePermission

    /// Personality-driven likelihood to volunteer a turn in multi-character
    /// scenes. `0.0` = wallflower (only speaks when addressed); `0.5` =
    /// average; `1.0` = always wants the floor. Consumed by capability (a)
    /// `SpeakerInitiativeRoller` as the per-character base score before
    /// recency/mention/situational modifiers. Default `0.5` keeps existing
    /// characters neutral after migration.
    var extroversion: Double = 0.5

    @Attribute(.externalStorage) var imageData: Data?

    var world: World?

    @Relationship(deleteRule: .cascade, inverse: \CharacterRelationship.ownerCharacter)
    var relationships: [CharacterRelationship] = []

    @Relationship(deleteRule: .cascade, inverse: \CharacterResidency.character)
    var residencies: [CharacterResidency] = []

    init(
        name: String,
        role: String = "",
        persona: String = "",
        voiceSample: String = "",
        notes: String = "",
        tags: [String] = [],
        vitalityStatus: String = "Alive",
        psychologicalState: String = "",
        knowledgeState: String = "",
        roleplayPosture: String = "Authentic",
        narrativePresence: String = "Active",
        currentState: String = "",
        stateUpdatePermission: StateUpdatePermission = .locked,
        extroversion: Double = 0.5,
        imageData: Data? = nil
    ) {
        self.name = name
        self.role = role
        self.persona = persona
        self.voiceSample = voiceSample
        self.notes = notes
        self.tags = tags
        self.vitalityStatus = vitalityStatus
        self.psychologicalState = psychologicalState
        self.knowledgeState = knowledgeState
        self.roleplayPosture = roleplayPosture
        self.narrativePresence = narrativePresence
        self.currentState = currentState
        self.stateUpdatePermission = stateUpdatePermission
        self.extroversion = extroversion
        self.imageData = imageData
    }
}
