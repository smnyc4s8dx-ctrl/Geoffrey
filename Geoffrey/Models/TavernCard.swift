import Foundation

// Tavern Character Card V2 / V3 Codable representation.
// Spec: https://github.com/malfoyslastname/character-card-spec-v2
// V3 is additive over V2; V2 readers ignore unknown fields.

struct TavernCard: Codable {
    let spec: String
    let specVersion: String
    let data: TavernCardData

    enum CodingKeys: String, CodingKey {
        case spec
        case specVersion = "spec_version"
        case data
    }

    var isV3: Bool { spec == "chara_card_v3" }
}

struct TavernCardData: Codable {
    let name: String
    let description: String
    let personality: String
    let scenario: String
    let firstMes: String
    let mesExample: String
    let creatorNotes: String
    let systemPrompt: String
    let postHistoryInstructions: String
    let alternateGreetings: [String]
    let tags: [String]
    let creator: String
    let characterVersion: String
    let characterBook: CharacterBook?

    // V3 additions (decoded as optional; V2 cards ignore)
    let nickname: String?
    let creationDate: Int?
    let modificationDate: Int?
    let source: [String]?
    let groupOnlyGreetings: [String]?

    // Geoffrey round-trip stash. We embed our own state-layer fields here on
    // export so a Geoffrey → Tavern → Geoffrey round-trip is lossless.
    let geoffreyExtension: GeoffreyExtension?

    enum CodingKeys: String, CodingKey {
        case name, description, personality, scenario
        case firstMes = "first_mes"
        case mesExample = "mes_example"
        case creatorNotes = "creator_notes"
        case systemPrompt = "system_prompt"
        case postHistoryInstructions = "post_history_instructions"
        case alternateGreetings = "alternate_greetings"
        case tags, creator
        case characterVersion = "character_version"
        case characterBook = "character_book"
        case nickname
        case creationDate = "creation_date"
        case modificationDate = "modification_date"
        case source
        case groupOnlyGreetings = "group_only_greetings"
        case extensions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        personality = (try? c.decode(String.self, forKey: .personality)) ?? ""
        scenario = (try? c.decode(String.self, forKey: .scenario)) ?? ""
        firstMes = (try? c.decode(String.self, forKey: .firstMes)) ?? ""
        mesExample = (try? c.decode(String.self, forKey: .mesExample)) ?? ""
        creatorNotes = (try? c.decode(String.self, forKey: .creatorNotes)) ?? ""
        systemPrompt = (try? c.decode(String.self, forKey: .systemPrompt)) ?? ""
        postHistoryInstructions = (try? c.decode(String.self, forKey: .postHistoryInstructions)) ?? ""
        alternateGreetings = (try? c.decode([String].self, forKey: .alternateGreetings)) ?? []
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        creator = (try? c.decode(String.self, forKey: .creator)) ?? ""
        characterVersion = (try? c.decode(String.self, forKey: .characterVersion)) ?? ""
        characterBook = try? c.decode(CharacterBook.self, forKey: .characterBook)
        nickname = try? c.decode(String.self, forKey: .nickname)
        creationDate = try? c.decode(Int.self, forKey: .creationDate)
        modificationDate = try? c.decode(Int.self, forKey: .modificationDate)
        source = try? c.decode([String].self, forKey: .source)
        groupOnlyGreetings = try? c.decode([String].self, forKey: .groupOnlyGreetings)

        if let extensions = try? c.decode(TavernExtensions.self, forKey: .extensions) {
            geoffreyExtension = extensions.geoffrey
        } else {
            geoffreyExtension = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(personality, forKey: .personality)
        try c.encode(scenario, forKey: .scenario)
        try c.encode(firstMes, forKey: .firstMes)
        try c.encode(mesExample, forKey: .mesExample)
        try c.encode(creatorNotes, forKey: .creatorNotes)
        try c.encode(systemPrompt, forKey: .systemPrompt)
        try c.encode(postHistoryInstructions, forKey: .postHistoryInstructions)
        try c.encode(alternateGreetings, forKey: .alternateGreetings)
        try c.encode(tags, forKey: .tags)
        try c.encode(creator, forKey: .creator)
        try c.encode(characterVersion, forKey: .characterVersion)
        try c.encodeIfPresent(characterBook, forKey: .characterBook)
        try c.encodeIfPresent(nickname, forKey: .nickname)
        try c.encodeIfPresent(creationDate, forKey: .creationDate)
        try c.encodeIfPresent(modificationDate, forKey: .modificationDate)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encodeIfPresent(groupOnlyGreetings, forKey: .groupOnlyGreetings)
        if let geoffreyExtension {
            try c.encode(TavernExtensions(geoffrey: geoffreyExtension), forKey: .extensions)
        }
    }

    init(
        name: String,
        description: String = "",
        personality: String = "",
        scenario: String = "",
        firstMes: String = "",
        mesExample: String = "",
        creatorNotes: String = "",
        systemPrompt: String = "",
        postHistoryInstructions: String = "",
        alternateGreetings: [String] = [],
        tags: [String] = [],
        creator: String = "",
        characterVersion: String = "",
        characterBook: CharacterBook? = nil,
        nickname: String? = nil,
        creationDate: Int? = nil,
        modificationDate: Int? = nil,
        source: [String]? = nil,
        groupOnlyGreetings: [String]? = nil,
        geoffreyExtension: GeoffreyExtension? = nil
    ) {
        self.name = name
        self.description = description
        self.personality = personality
        self.scenario = scenario
        self.firstMes = firstMes
        self.mesExample = mesExample
        self.creatorNotes = creatorNotes
        self.systemPrompt = systemPrompt
        self.postHistoryInstructions = postHistoryInstructions
        self.alternateGreetings = alternateGreetings
        self.tags = tags
        self.creator = creator
        self.characterVersion = characterVersion
        self.characterBook = characterBook
        self.nickname = nickname
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.source = source
        self.groupOnlyGreetings = groupOnlyGreetings
        self.geoffreyExtension = geoffreyExtension
    }
}

struct CharacterBook: Codable {
    let name: String?
    let description: String?
    let scanDepth: Int?
    let tokenBudget: Int?
    let recursiveScanning: Bool?
    let entries: [CharacterBookEntry]

    enum CodingKeys: String, CodingKey {
        case name, description, entries
        case scanDepth = "scan_depth"
        case tokenBudget = "token_budget"
        case recursiveScanning = "recursive_scanning"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try? c.decode(String.self, forKey: .name)
        description = try? c.decode(String.self, forKey: .description)
        scanDepth = try? c.decode(Int.self, forKey: .scanDepth)
        tokenBudget = try? c.decode(Int.self, forKey: .tokenBudget)
        recursiveScanning = try? c.decode(Bool.self, forKey: .recursiveScanning)
        entries = (try? c.decode([CharacterBookEntry].self, forKey: .entries)) ?? []
    }

    init(name: String? = nil, description: String? = nil, entries: [CharacterBookEntry] = []) {
        self.name = name
        self.description = description
        self.scanDepth = nil
        self.tokenBudget = nil
        self.recursiveScanning = nil
        self.entries = entries
    }
}

struct CharacterBookEntry: Codable {
    let keys: [String]
    let content: String
    let enabled: Bool
    let insertionOrder: Int
    let caseSensitive: Bool?
    let name: String?
    let priority: Int?
    let comment: String?
    let selective: Bool?
    let secondaryKeys: [String]
    let constant: Bool?
    let position: String?

    enum CodingKeys: String, CodingKey {
        case keys, content, enabled, name, priority, comment, selective, constant, position
        case insertionOrder = "insertion_order"
        case caseSensitive = "case_sensitive"
        case secondaryKeys = "secondary_keys"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        keys = (try? c.decode([String].self, forKey: .keys)) ?? []
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        insertionOrder = (try? c.decode(Int.self, forKey: .insertionOrder)) ?? 0
        caseSensitive = try? c.decode(Bool.self, forKey: .caseSensitive)
        name = try? c.decode(String.self, forKey: .name)
        priority = try? c.decode(Int.self, forKey: .priority)
        comment = try? c.decode(String.self, forKey: .comment)
        selective = try? c.decode(Bool.self, forKey: .selective)
        secondaryKeys = (try? c.decode([String].self, forKey: .secondaryKeys)) ?? []
        constant = try? c.decode(Bool.self, forKey: .constant)
        position = try? c.decode(String.self, forKey: .position)
    }

    init(
        keys: [String],
        content: String,
        name: String? = nil,
        secondaryKeys: [String] = [],
        insertionOrder: Int = 0,
        priority: Int? = nil,
        comment: String? = nil
    ) {
        self.keys = keys
        self.content = content
        self.enabled = true
        self.insertionOrder = insertionOrder
        self.caseSensitive = nil
        self.name = name
        self.priority = priority
        self.comment = comment
        self.selective = nil
        self.secondaryKeys = secondaryKeys
        self.constant = nil
        self.position = nil
    }
}

// MARK: - Geoffrey extension namespace

/// Namespaced into `extensions.geoffrey` on export. Lossless round-trip of the
/// state-layer fields Tavern V3 doesn't natively model.
struct GeoffreyExtension: Codable {
    let role: String
    let vitalityStatus: String
    let psychologicalState: String
    let knowledgeState: String
    let roleplayPosture: String
    let narrativePresence: String
    let currentState: String
    let notes: String
    let stateUpdatePermission: String
}

private struct TavernExtensions: Codable {
    let geoffrey: GeoffreyExtension?
}
