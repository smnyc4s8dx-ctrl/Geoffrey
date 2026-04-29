import Foundation
import SwiftData

@Model
final class CharacterRelationship {
    var ownerCharacter: StoryCharacter?
    var targetCharacterName: String
    var relationshipDescription: String

    init(
        ownerCharacter: StoryCharacter? = nil,
        targetCharacterName: String,
        relationshipDescription: String = ""
    ) {
        self.ownerCharacter = ownerCharacter
        self.targetCharacterName = targetCharacterName
        self.relationshipDescription = relationshipDescription
    }
}
