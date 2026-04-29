import Foundation
import SwiftData
import Observation

/// Owns the transient scene state (which location is active, which
/// characters are present and speaking, which lore is layered into
/// pre-context). `SessionViewModel.buildContextMessages` reads from this
/// VM at send time — there is no synced copy elsewhere.
///
/// **Long-arc target.** Capability (a) item 8 adds
/// `CharacterResidency.mutedInScene`, at which point `presentCharacters`
/// and `speakingCharacters` should derive from `location.residencies`
/// directly (filtered by `isPresent` and `mutedInScene`). The runtime
/// arrays here are an interim — useful while there's no persistent
/// "speaking this turn" axis on the model.
@MainActor
@Observable
final class SceneInspectorViewModel {
    var activeLocation: Location?
    var presentCharacters: [StoryCharacter] = []
    var speakingCharacters: [StoryCharacter] = []
    var activeLoreCards: [LoreCard] = []

    /// Weak back-reference. Inspector mutations bump the session's
    /// token-count cache so `DialogueCanvasView`'s counter stays current
    /// when the user adjusts scene state. Symmetric with
    /// `SessionViewModel.inspectorVM`; both refs are set in
    /// `MainView.initializeViewModels()`.
    weak var sessionVM: SessionViewModel?

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func setLocation(_ location: Location?) {
        activeLocation = location

        // Update present characters from residencies
        if let location {
            presentCharacters = location.residencies
                .filter(\.isPresent)
                .compactMap(\.character)
        } else {
            presentCharacters = []
        }

        // Clear speaking characters on location change
        speakingCharacters = []

        // Update active lore from location links
        if let location {
            activeLoreCards = location.loreLinks.compactMap(\.loreCard)
        } else {
            activeLoreCards = []
        }

        sessionVM?.invalidateTokenCount()
    }

    func toggleCharacterPresence(_ character: StoryCharacter) {
        if presentCharacters.contains(where: { $0.persistentModelID == character.persistentModelID }) {
            presentCharacters.removeAll { $0.persistentModelID == character.persistentModelID }
            // Auto-remove from speaking when leaving the scene
            speakingCharacters.removeAll { $0.persistentModelID == character.persistentModelID }
        } else {
            presentCharacters.append(character)
        }
        sessionVM?.invalidateTokenCount()
    }

    func toggleCharacterSpeaking(_ character: StoryCharacter) {
        if speakingCharacters.contains(where: { $0.persistentModelID == character.persistentModelID }) {
            speakingCharacters.removeAll { $0.persistentModelID == character.persistentModelID }
        } else {
            // Auto-enable presence when enabling speaking
            if !presentCharacters.contains(where: { $0.persistentModelID == character.persistentModelID }) {
                presentCharacters.append(character)
            }
            speakingCharacters.append(character)
        }
        sessionVM?.invalidateTokenCount()
    }

    func addLoreCard(_ lore: LoreCard) {
        guard !activeLoreCards.contains(where: { $0.persistentModelID == lore.persistentModelID }) else { return }
        activeLoreCards.append(lore)
        sessionVM?.invalidateTokenCount()
    }

    func removeLoreCard(_ lore: LoreCard) {
        activeLoreCards.removeAll { $0.persistentModelID == lore.persistentModelID }
        sessionVM?.invalidateTokenCount()
    }

    /// Clears all transient scene state. Called when switching projects so
    /// the new project's first send doesn't inherit the previous scene
    /// configuration.
    func reset() {
        activeLocation = nil
        presentCharacters = []
        speakingCharacters = []
        activeLoreCards = []
    }
}
