import Foundation
import SwiftData

@Model
final class CharacterResidency {
    var character: StoryCharacter?
    var location: Location?
    var isPresent: Bool

    /// Per-scene mute flag for capability (a) multi-character orchestration.
    /// A muted character is still *present* (counted in scene context, can be
    /// addressed by name) but the speaker-initiative roller skips them so
    /// they never volunteer a turn. Lets the user keep an NPC physically in
    /// the scene without dialogue spam. Defaults to `false` so existing
    /// residencies behave unchanged after migration.
    var mutedInScene: Bool = false

    init(
        character: StoryCharacter? = nil,
        location: Location? = nil,
        isPresent: Bool = true,
        mutedInScene: Bool = false
    ) {
        self.character = character
        self.location = location
        self.isPresent = isPresent
        self.mutedInScene = mutedInScene
    }
}
