import Foundation

struct ContextAssembler {
    func assemble(
        systemPreamble: String,
        location: LocationContext?,
        loreCards: [LoreContext],
        characters: [CharacterContext],
        speakingCharacterNames: [String] = [],
        committedExchanges: [ExchangeContext],
        workingDialogue: [ExchangeContext],
        directorsNote: String?,
        userPrompt: String
    ) -> [ChatMessage] {
        var messages: [ChatMessage] = []

        // Build world context as a single block.
        // Many local models only support user/assistant roles and reject "system" messages.
        // Bundle all world context into one user message at the start.
        let worldContext = buildWorldContext(
            systemPreamble: systemPreamble,
            location: location,
            loreCards: loreCards,
            characters: characters,
            speakingCharacterNames: speakingCharacterNames,
            directorsNote: directorsNote
        )

        if !worldContext.isEmpty {
            messages.append(ChatMessage(role: "user", content: worldContext))
            messages.append(ChatMessage(role: "assistant", content: "Understood. I will write according to these instructions, staying in character and maintaining the established tone."))
        }

        // Committed History
        for exchange in committedExchanges {
            messages.append(ChatMessage(role: exchange.role, content: exchange.content))
        }

        // Working Dialogue
        for exchange in workingDialogue {
            messages.append(ChatMessage(role: exchange.role, content: exchange.content))
        }

        // User Prompt
        messages.append(ChatMessage(role: "user", content: userPrompt))

        return messages
    }

    // MARK: - World Context Builder

    private func buildWorldContext(
        systemPreamble: String,
        location: LocationContext?,
        loreCards: [LoreContext],
        characters: [CharacterContext],
        speakingCharacterNames: [String],
        directorsNote: String?
    ) -> String {
        var sections: [String] = []

        // 1. System Preamble
        if !systemPreamble.isEmpty {
            sections.append("[Writing Style]\n\(systemPreamble)")
        }

        // 2. Active Location
        if let location {
            sections.append(buildLocationContext(location))
        }

        // 3. Active Lore (sorted by priority)
        let sortedLore = loreCards.sorted { $0.priorityOrder < $1.priorityOrder }
        for lore in sortedLore {
            sections.append("[\(lore.title)]\n\(lore.content)")
        }

        // 4. Present Characters
        for character in characters {
            sections.append(buildCharacterContext(character))
        }

        // 5. Scene Direction (who is speaking)
        if !characters.isEmpty || !speakingCharacterNames.isEmpty {
            sections.append(buildSceneDirection(
                allPresent: characters.map(\.name),
                speaking: speakingCharacterNames
            ))
        }

        // 6. Director's Note
        if let directorsNote, !directorsNote.isEmpty {
            sections.append("[Director's Note] \(directorsNote)")
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Section Builders

    private func buildLocationContext(_ location: LocationContext) -> String {
        var parts = ["[Current Location: \(location.name)]"]
        if !location.stateLabel.isEmpty {
            parts.append("State: \(location.stateLabel)")
        }
        if !location.descriptionText.isEmpty {
            parts.append(location.descriptionText)
        }
        if !location.conditionDescription.isEmpty {
            parts.append("Current condition: \(location.conditionDescription)")
        }
        if !location.atmosphere.isEmpty {
            parts.append("Atmosphere: \(location.atmosphere)")
        }
        return parts.joined(separator: "\n")
    }

    private func buildCharacterContext(_ character: CharacterContext) -> String {
        var parts = ["[Character: \(character.name)]"]
        if !character.role.isEmpty {
            parts.append("Role: \(character.role)")
        }
        if !character.persona.isEmpty {
            parts.append("Persona: \(character.persona)")
        }
        if !character.voiceSample.isEmpty {
            parts.append("Voice sample:\n\(character.voiceSample)")
        }
        if !character.psychologicalState.isEmpty {
            parts.append("Psychological state: \(character.psychologicalState)")
        }
        if !character.knowledgeState.isEmpty {
            parts.append("Knowledge: \(character.knowledgeState)")
        }
        if !character.roleplayPosture.isEmpty {
            parts.append("Posture: \(character.roleplayPosture)")
        }
        for rel in character.relationships {
            parts.append("Relationship — \(rel.targetName): \(rel.description)")
        }
        return parts.joined(separator: "\n")
    }

    private func buildSceneDirection(allPresent: [String], speaking: [String]) -> String {
        if speaking.isEmpty {
            return "[Scene Direction] Characters present: \(allPresent.joined(separator: ", ")). No character is currently speaking — provide narration only."
        }

        let observing = allPresent.filter { !speaking.contains($0) }
        var parts = ["[Scene Direction]"]

        if speaking.count == 1 {
            parts.append("Write the next scene as \(speaking[0]), staying in character. Use their voice, mannerisms, and knowledge.")
            parts.append("You may interleave dialogue with action beats. Use [\(speaking[0])] for spoken lines, [Action] for physical actions and beats, and [Narrator] for brief scene description. Every paragraph must begin with a tag.")
        } else {
            parts.append("Write the next scene. The following characters are speaking: \(speaking.joined(separator: ", ")).")
            parts.append("RESPONSE FORMAT: Tag every paragraph. Use [Narrator] for scene description. Use [CharacterName] for dialogue. Use [Action] for physical actions, beats, and stage directions. Example:")
            parts.append("[Narrator] The laboratory hummed with quiet tension.")
            parts.append("[Liora] \"Show me what you found.\"")
            parts.append("[Action] Xelia placed the specimen on the table with trembling hands.")
            parts.append("[Xelia] \"It's worse than we thought.\"")
            parts.append("Every paragraph must begin with a tag. Do not omit tags.")
        }

        if !observing.isEmpty {
            parts.append("Also present but not speaking: \(observing.joined(separator: ", ")).")
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - Context DTOs (decoupled from SwiftData models)

struct LocationContext {
    let name: String
    let stateLabel: String
    let descriptionText: String
    let conditionDescription: String
    let atmosphere: String
}

struct CharacterContext {
    let name: String
    let role: String
    let persona: String
    let voiceSample: String
    let psychologicalState: String
    let knowledgeState: String
    let roleplayPosture: String
    let relationships: [RelationshipContext]
}

struct RelationshipContext {
    let targetName: String
    let description: String
}

struct LoreContext {
    let title: String
    let content: String
    let priorityOrder: Int
}

struct ExchangeContext {
    let role: String
    let content: String
}
