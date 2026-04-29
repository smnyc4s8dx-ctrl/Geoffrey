import Foundation
import SwiftData

/// Parsed Tavern Card payload, ready for preview before commit.
struct ImportedTavernCharacter {
    let id = UUID()
    let card: TavernCard
    let avatarPNG: Data?
    let sourceFormat: SourceFormat

    enum SourceFormat: String {
        case pngV2 = "Tavern Card V2 (PNG)"
        case pngV3 = "Tavern Card V3 (PNG)"
        case jsonV2 = "Tavern Card V2 (JSON)"
        case jsonV3 = "Tavern Card V3 (JSON)"
    }

    var lorebookEntryCount: Int { card.data.characterBook?.entries.count ?? 0 }
    var hasScenario: Bool { !card.data.scenario.isEmpty }
    var hasSystemPrompt: Bool { !card.data.systemPrompt.isEmpty }
    var hasAlternateGreetings: Bool { !card.data.alternateGreetings.isEmpty }
}

enum TavernCardImporter {

    enum Error: Swift.Error, LocalizedError {
        case unknownFormat
        case pngStructure(String)
        case missingTavernChunk
        case invalidBase64
        case notATavernCard
        case invalidJSON(String)

        var errorDescription: String? {
            switch self {
            case .unknownFormat: "Not a recognized Tavern Card (PNG or JSON)."
            case .pngStructure(let detail): "PNG metadata could not be read: \(detail)"
            case .missingTavernChunk: "PNG does not contain Tavern Card metadata (no `chara`/`ccv3` chunk)."
            case .invalidBase64: "Tavern Card metadata is not valid base64."
            case .notATavernCard: "This JSON is not a Tavern Card (it might be a Geoffrey world export — use Import on the project picker for those)."
            case .invalidJSON(let detail): "Tavern Card JSON is malformed: \(detail)"
            }
        }
    }

    // MARK: - Format detection

    static func looksLikeTavernCard(_ data: Data) -> Bool {
        if data.count >= 8 {
            let pngSig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            if data.prefix(8).elementsEqual(pngSig) { return true }
        }
        if let first = data.first(where: { !($0 == 0x20 || $0 == 0x09 || $0 == 0x0A || $0 == 0x0D) }),
           first == UInt8(ascii: "{") {
            return true
        }
        return false
    }

    // MARK: - Parse

    static func parse(_ data: Data) throws -> ImportedTavernCharacter {
        let pngSig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        if data.count >= 8, data.prefix(8).elementsEqual(pngSig) {
            return try parsePNG(data)
        }
        return try parseJSON(data)
    }

    static func parsePNG(_ data: Data) throws -> ImportedTavernCharacter {
        let chunks: [String: String]
        do {
            chunks = try PNGTextChunk.readAllText(from: data)
        } catch let error as PNGTextChunk.Error {
            throw Error.pngStructure(error.errorDescription ?? "unknown")
        }

        // Prefer V3 (`ccv3`) when present; fall back to V2 (`chara`).
        let isV3 = chunks["ccv3"] != nil
        guard let base64 = chunks["ccv3"] ?? chunks["chara"] else {
            throw Error.missingTavernChunk
        }
        let card = try decodeCard(base64: base64)
        return ImportedTavernCharacter(
            card: card,
            avatarPNG: data,
            sourceFormat: isV3 ? .pngV3 : .pngV2
        )
    }

    static func parseJSON(_ data: Data) throws -> ImportedTavernCharacter {
        // Disambiguate Tavern from Geoffrey-native JSON before the strict
        // decode runs — gives a useful "wrong format" message instead of a
        // missing-key Codable error.
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let spec = object["spec"] as? String {
            guard spec == "chara_card_v2" || spec == "chara_card_v3" else {
                throw Error.notATavernCard
            }
        } else {
            throw Error.notATavernCard
        }
        let card = try decodeCard(jsonData: data)
        return ImportedTavernCharacter(
            card: card,
            avatarPNG: nil,
            sourceFormat: card.isV3 ? .jsonV3 : .jsonV2
        )
    }

    private static func decodeCard(base64: String) throws -> TavernCard {
        // Strip any whitespace the chunk may have picked up.
        let cleaned = base64.filter { !$0.isWhitespace && !$0.isNewline }
        guard let jsonData = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters) else {
            throw Error.invalidBase64
        }
        return try decodeCard(jsonData: jsonData)
    }

    private static func decodeCard(jsonData: Data) throws -> TavernCard {
        do {
            return try JSONDecoder().decode(TavernCard.self, from: jsonData)
        } catch {
            throw Error.invalidJSON(error.localizedDescription)
        }
    }

    // MARK: - Commit

    /// Inserts a StoryCharacter (and any character_book lore) into `world`.
    /// Avatar bytes are downsized to ≤1024px to match the existing image
    /// pipeline; metadata-only PNGs (<128 bytes after data) are discarded.
    @discardableResult
    static func commit(
        _ imported: ImportedTavernCharacter,
        into world: World,
        context: ModelContext
    ) -> StoryCharacter {
        let data = imported.card.data
        let ext = data.geoffreyExtension

        let persona = mergePersona(description: data.description, personality: data.personality)
        let voiceSample = data.mesExample
        let role = ext?.role ?? ""
        let notes = mergeNotes(creator: data.creator, creatorNotes: data.creatorNotes, existing: ext?.notes ?? "")

        let avatarData = imported.avatarPNG.flatMap { ImageUtilities.resizeImage($0) }

        let character = StoryCharacter(
            name: uniqueCharacterName(data.name.isEmpty ? "Untitled" : data.name, in: world),
            role: role,
            persona: persona,
            voiceSample: voiceSample,
            notes: notes,
            tags: data.tags,
            vitalityStatus: ext?.vitalityStatus ?? "Alive",
            psychologicalState: ext?.psychologicalState ?? "",
            knowledgeState: ext?.knowledgeState ?? "",
            roleplayPosture: ext?.roleplayPosture ?? "Authentic",
            narrativePresence: ext?.narrativePresence ?? "Active",
            currentState: ext?.currentState ?? "",
            stateUpdatePermission: StateUpdatePermission(rawValue: ext?.stateUpdatePermission ?? "") ?? .locked,
            imageData: avatarData
        )
        character.world = world
        context.insert(character)

        if let book = data.characterBook {
            for (idx, entry) in book.entries.enumerated() where entry.enabled {
                insertLore(entry, fallbackIndex: idx + 1, characterName: data.name, into: world, context: context)
            }
        }

        try? context.save()
        return character
    }

    // MARK: - Mapping helpers

    private static func mergePersona(description: String, personality: String) -> String {
        switch (description.isEmpty, personality.isEmpty) {
        case (true, true): return ""
        case (false, true): return description
        case (true, false): return personality
        case (false, false): return "\(description)\n\n\(personality)"
        }
    }

    private static func mergeNotes(creator: String, creatorNotes: String, existing: String) -> String {
        if !existing.isEmpty { return existing }
        var parts: [String] = []
        if !creator.isEmpty { parts.append("Imported from Tavern Card by \(creator).") }
        if !creatorNotes.isEmpty { parts.append(creatorNotes) }
        return parts.joined(separator: "\n\n")
    }

    private static func uniqueCharacterName(_ name: String, in world: World) -> String {
        let existing = Set(world.characters.map(\.name))
        guard existing.contains(name) else { return name }
        var i = 2
        while existing.contains("\(name) (\(i))") { i += 1 }
        return "\(name) (\(i))"
    }

    private static func insertLore(
        _ entry: CharacterBookEntry,
        fallbackIndex: Int,
        characterName: String,
        into world: World,
        context: ModelContext
    ) {
        let title = entry.name
            ?? entry.keys.first
            ?? "\(characterName) lore #\(fallbackIndex)"

        let card = LoreCard(
            title: uniqueLoreTitle(title, in: world),
            content: entry.content,
            tags: [],
            priority: .normal,
            currency: "Current",
            revelationStatus: "Universal",
            scopeChange: "",
            stateUpdatePermission: .locked
        )
        card.world = world
        context.insert(card)

        for key in entry.keys where !key.isEmpty {
            let rule = TriggerRule(ruleType: "keyword", ruleValue: key)
            rule.loreCard = card
            context.insert(rule)
        }
        for key in entry.secondaryKeys where !key.isEmpty {
            let rule = TriggerRule(ruleType: "secondary_key", ruleValue: key)
            rule.loreCard = card
            context.insert(rule)
        }
    }

    private static func uniqueLoreTitle(_ title: String, in world: World) -> String {
        let existing = Set(world.loreCards.map(\.title))
        guard existing.contains(title) else { return title }
        var i = 2
        while existing.contains("\(title) (\(i))") { i += 1 }
        return "\(title) (\(i))"
    }
}
