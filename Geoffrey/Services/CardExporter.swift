import Foundation
import SwiftData
import ZIPFoundation

enum FileFormat {
    case json
    case zip
}

enum CardExporter {

    // MARK: - Format Detection

    static func detectFileFormat(_ data: Data) -> FileFormat {
        data.isZIPFile ? .zip : .json
    }

    static func worldHasImages(_ world: World) -> Bool {
        world.locations.contains(where: { $0.imageData != nil }) ||
        world.characters.contains(where: { $0.imageData != nil })
    }

    // MARK: - Export

    static func exportWorld(_ world: World) -> ExportedWorld {
        let locations = world.locations.map { loc in
            ExportedLocation(
                name: loc.name,
                stateLabel: loc.stateLabel,
                descriptionText: loc.descriptionText,
                notes: loc.notes,
                conditionDescription: loc.conditionDescription,
                accessibility: loc.accessibility,
                atmosphere: loc.atmosphere,
                stateUpdatePermission: loc.stateUpdatePermission.rawValue
            )
        }

        let characters = world.characters.map { char in
            ExportedCharacter(
                name: char.name,
                role: char.role,
                persona: char.persona,
                voiceSample: char.voiceSample,
                notes: char.notes,
                tags: char.tags,
                vitalityStatus: char.vitalityStatus,
                psychologicalState: char.psychologicalState,
                knowledgeState: char.knowledgeState,
                roleplayPosture: char.roleplayPosture,
                narrativePresence: char.narrativePresence,
                currentState: char.currentState,
                stateUpdatePermission: char.stateUpdatePermission.rawValue
            )
        }

        let loreCards = world.loreCards.map { lore in
            ExportedLoreCard(
                title: lore.title,
                content: lore.content,
                tags: lore.tags,
                priority: lore.priority.rawValue,
                currency: lore.currency,
                revelationStatus: lore.revelationStatus,
                scopeChange: lore.scopeChange,
                stateUpdatePermission: lore.stateUpdatePermission.rawValue
            )
        }

        return ExportedWorld(
            name: world.name,
            systemPreamble: world.systemPreamble,
            locations: locations,
            characters: characters,
            loreCards: loreCards
        )
    }

    // MARK: - ZIP Export

    static func exportWorldAsZip(_ world: World, includeTheme: ThemeConfig? = nil) throws -> Data {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tempDir) }

        var exported = exportWorld(world)

        // Write character images
        let charMediaDir = tempDir.appendingPathComponent("media/characters")
        try fm.createDirectory(at: charMediaDir, withIntermediateDirectories: true)

        for i in exported.characters.indices {
            let char = world.characters.first(where: { $0.name == exported.characters[i].name })
            if let imageData = char?.imageData {
                let filename = sanitizeFilename(exported.characters[i].name) + ".png"
                try imageData.write(to: charMediaDir.appendingPathComponent(filename))
                exported.characters[i].imageFilename = "media/characters/\(filename)"
            }
        }

        // Write location images
        let locMediaDir = tempDir.appendingPathComponent("media/locations")
        try fm.createDirectory(at: locMediaDir, withIntermediateDirectories: true)

        for i in exported.locations.indices {
            let loc = world.locations.first(where: { $0.name == exported.locations[i].name })
            if let imageData = loc?.imageData {
                let filename = sanitizeFilename(exported.locations[i].name) + ".png"
                try imageData.write(to: locMediaDir.appendingPathComponent(filename))
                exported.locations[i].imageFilename = "media/locations/\(filename)"
            }
        }

        // Write world.json
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(exported)
        try jsonData.write(to: tempDir.appendingPathComponent("world.json"))

        // Write optional theme
        if var theme = includeTheme {
            let imageEntries = ThemeExporter.extractAndClearImages(from: &theme)
            if !imageEntries.isEmpty {
                let themeImagesDir = tempDir.appendingPathComponent("theme_images")
                try fm.createDirectory(at: themeImagesDir, withIntermediateDirectories: true)
                for (filename, data) in imageEntries {
                    try data.write(to: themeImagesDir.appendingPathComponent(filename))
                }
            }
            let themeEncoder = JSONEncoder()
            themeEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let themeData = try themeEncoder.encode(theme)
            try themeData.write(to: tempDir.appendingPathComponent("theme.json"))
        }

        // Create ZIP
        let zipURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        defer { try? fm.removeItem(at: zipURL) }

        try fm.zipItem(at: tempDir, to: zipURL)
        return try Data(contentsOf: zipURL)
    }

    // MARK: - Import as New World

    static func importWorld(from data: Data, into context: ModelContext) throws -> World {
        switch detectFileFormat(data) {
        case .json:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exported = try decoder.decode(ExportedWorld.self, from: data)
            try validateVersion(exported)
            return createWorldFromExport(exported, images: [:], in: context)
        case .zip:
            return try importWorldFromZip(data: data, into: context)
        }
    }

    private static func validateVersion(_ exported: ExportedWorld) throws {
        let majorVersion = exported.geoffreyVersion.split(separator: ".").first.flatMap { Int($0) } ?? 0
        let supportedMajor = 1
        if majorVersion > supportedMajor {
            throw ImportError.unsupportedVersion(exported.geoffreyVersion)
        }
    }

    // MARK: - ZIP Import

    static func importWorldFromZip(data: Data, into context: ModelContext) throws -> World {
        let fm = FileManager.default
        let tempZip = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try data.write(to: tempZip)
        defer { try? fm.removeItem(at: tempZip) }
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try fm.unzipItem(at: tempZip, to: tempDir)

        // Find world.json (may be in a subdirectory if zipped from a folder)
        let jsonURL = findFile(named: "world.json", in: tempDir)
        guard let jsonURL else {
            throw ImportError.missingWorldJSON
        }

        let jsonData = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exported = try decoder.decode(ExportedWorld.self, from: jsonData)
        try validateVersion(exported)

        // Load images
        let baseDir = jsonURL.deletingLastPathComponent()
        var images: [String: Data] = [:]

        for char in exported.characters {
            if let filename = char.imageFilename {
                let imageURL = baseDir.appendingPathComponent(filename).standardized
                guard imageURL.path.hasPrefix(baseDir.standardized.path) else { continue }
                if let imageData = try? Data(contentsOf: imageURL) {
                    images[char.name] = imageData
                }
            }
        }

        for loc in exported.locations {
            if let filename = loc.imageFilename {
                let imageURL = baseDir.appendingPathComponent(filename).standardized
                guard imageURL.path.hasPrefix(baseDir.standardized.path) else { continue }
                if let imageData = try? Data(contentsOf: imageURL) {
                    images[loc.name] = imageData
                }
            }
        }

        return createWorldFromExport(exported, images: images, in: context)
    }

    // MARK: - Parse Exported World (for preview)

    static func parseExportedWorld(from data: Data) throws -> ExportedWorld {
        switch detectFileFormat(data) {
        case .json:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ExportedWorld.self, from: data)
        case .zip:
            return try parseExportedWorldFromZip(data: data)
        }
    }

    private static func parseExportedWorldFromZip(data: Data) throws -> ExportedWorld {
        let fm = FileManager.default
        let tempZip = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try data.write(to: tempZip)
        defer { try? fm.removeItem(at: tempZip) }
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try fm.unzipItem(at: tempZip, to: tempDir)

        guard let jsonURL = findFile(named: "world.json", in: tempDir) else {
            throw ImportError.missingWorldJSON
        }

        let jsonData = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportedWorld.self, from: jsonData)
    }

    // MARK: - Detect Duplicates

    static func detectDuplicates(in exported: ExportedWorld, against world: World) -> [DuplicateConflict] {
        var conflicts: [DuplicateConflict] = []

        let existingLocationNames = Set(world.locations.map(\.name))
        for loc in exported.locations where existingLocationNames.contains(loc.name) {
            guard let existing = world.locations.first(where: { $0.name == loc.name }) else { continue }
            conflicts.append(DuplicateConflict(
                cardType: .location,
                name: loc.name,
                existingSummary: summarize(existingLocation: existing),
                incomingSummary: summarize(importedLocation: loc)
            ))
        }

        let existingCharNames = Set(world.characters.map(\.name))
        for char in exported.characters where existingCharNames.contains(char.name) {
            guard let existing = world.characters.first(where: { $0.name == char.name }) else { continue }
            conflicts.append(DuplicateConflict(
                cardType: .character,
                name: char.name,
                existingSummary: summarize(existingCharacter: existing),
                incomingSummary: summarize(importedCharacter: char)
            ))
        }

        let existingLoreNames = Set(world.loreCards.map(\.title))
        for lore in exported.loreCards where existingLoreNames.contains(lore.title) {
            guard let existing = world.loreCards.first(where: { $0.title == lore.title }) else { continue }
            conflicts.append(DuplicateConflict(
                cardType: .lore,
                name: lore.title,
                existingSummary: summarize(existingLore: existing),
                incomingSummary: summarize(importedLore: lore)
            ))
        }

        return conflicts
    }

    // MARK: - Merge Into Existing World

    static func mergeIntoWorld(_ world: World, from exported: ExportedWorld, resolutions: [DuplicateConflict], context: ModelContext) {
        mergeIntoWorld(world, from: exported, resolutions: resolutions, images: [:], context: context)
    }

    static func mergeIntoWorld(_ world: World, from exported: ExportedWorld, resolutions: [DuplicateConflict], images: [String: Data], context: ModelContext) {
        let resolutionMap = Dictionary(uniqueKeysWithValues: resolutions.map { ($0.name, $0.resolution) })

        // Locations
        for loc in exported.locations {
            let resolution = resolutionMap[loc.name] ?? .keepBoth
            let existing = world.locations.first { $0.name == loc.name }

            if let existing {
                switch resolution {
                case .keepExisting:
                    continue
                case .replace:
                    context.delete(existing)
                    insertLocation(loc, into: world, imageData: images[loc.name], context: context)
                case .keepBoth:
                    var renamed = ExportedLocation(
                        name: "\(loc.name) (imported)",
                        stateLabel: loc.stateLabel,
                        descriptionText: loc.descriptionText,
                        notes: loc.notes,
                        conditionDescription: loc.conditionDescription,
                        accessibility: loc.accessibility,
                        atmosphere: loc.atmosphere,
                        stateUpdatePermission: loc.stateUpdatePermission
                    )
                    renamed.imageFilename = loc.imageFilename
                    insertLocation(renamed, into: world, imageData: images[loc.name], context: context)
                }
            } else {
                insertLocation(loc, into: world, imageData: images[loc.name], context: context)
            }
        }

        // Characters
        for char in exported.characters {
            let resolution = resolutionMap[char.name] ?? .keepBoth
            let existing = world.characters.first { $0.name == char.name }

            if let existing {
                switch resolution {
                case .keepExisting:
                    continue
                case .replace:
                    context.delete(existing)
                    insertCharacter(char, into: world, imageData: images[char.name], context: context)
                case .keepBoth:
                    var renamed = ExportedCharacter(
                        name: "\(char.name) (imported)",
                        role: char.role,
                        persona: char.persona,
                        voiceSample: char.voiceSample,
                        notes: char.notes,
                        tags: char.tags,
                        vitalityStatus: char.vitalityStatus,
                        psychologicalState: char.psychologicalState,
                        knowledgeState: char.knowledgeState,
                        roleplayPosture: char.roleplayPosture,
                        narrativePresence: char.narrativePresence,
                        currentState: char.currentState,
                        stateUpdatePermission: char.stateUpdatePermission
                    )
                    renamed.imageFilename = char.imageFilename
                    insertCharacter(renamed, into: world, imageData: images[char.name], context: context)
                }
            } else {
                insertCharacter(char, into: world, imageData: images[char.name], context: context)
            }
        }

        // Lore
        for lore in exported.loreCards {
            let resolution = resolutionMap[lore.title] ?? .keepBoth
            let existing = world.loreCards.first { $0.title == lore.title }

            if let existing {
                switch resolution {
                case .keepExisting:
                    continue
                case .replace:
                    context.delete(existing)
                    insertLore(lore, into: world, context: context)
                case .keepBoth:
                    let renamed = ExportedLoreCard(
                        title: "\(lore.title) (imported)",
                        content: lore.content,
                        tags: lore.tags,
                        priority: lore.priority,
                        currency: lore.currency,
                        revelationStatus: lore.revelationStatus,
                        scopeChange: lore.scopeChange,
                        stateUpdatePermission: lore.stateUpdatePermission
                    )
                    insertLore(renamed, into: world, context: context)
                }
            } else {
                insertLore(lore, into: world, context: context)
            }
        }

        try? context.save()
    }

    // MARK: - Private Helpers

    private static func createWorldFromExport(_ exported: ExportedWorld, images: [String: Data], in context: ModelContext) -> World {
        let world = World(name: exported.name, systemPreamble: exported.systemPreamble)
        context.insert(world)

        for loc in exported.locations {
            insertLocation(loc, into: world, imageData: images[loc.name], context: context)
        }
        for char in exported.characters {
            insertCharacter(char, into: world, imageData: images[char.name], context: context)
        }
        for lore in exported.loreCards {
            insertLore(lore, into: world, context: context)
        }

        try? context.save()
        return world
    }

    private static func insertLocation(_ loc: ExportedLocation, into world: World, imageData: Data? = nil, context: ModelContext) {
        let location = Location(
            name: loc.name,
            stateLabel: loc.stateLabel,
            descriptionText: loc.descriptionText,
            notes: loc.notes,
            conditionDescription: loc.conditionDescription,
            accessibility: loc.accessibility,
            atmosphere: loc.atmosphere,
            stateUpdatePermission: StateUpdatePermission(rawValue: loc.stateUpdatePermission) ?? .locked,
            imageData: imageData
        )
        location.world = world
        context.insert(location)
    }

    private static func insertCharacter(_ char: ExportedCharacter, into world: World, imageData: Data? = nil, context: ModelContext) {
        let character = StoryCharacter(
            name: char.name,
            role: char.role,
            persona: char.persona,
            voiceSample: char.voiceSample,
            notes: char.notes,
            tags: char.tags,
            vitalityStatus: char.vitalityStatus,
            psychologicalState: char.psychologicalState,
            knowledgeState: char.knowledgeState,
            roleplayPosture: char.roleplayPosture,
            narrativePresence: char.narrativePresence,
            currentState: char.currentState,
            stateUpdatePermission: StateUpdatePermission(rawValue: char.stateUpdatePermission) ?? .locked,
            imageData: imageData
        )
        character.world = world
        context.insert(character)
    }

    private static func insertLore(_ lore: ExportedLoreCard, into world: World, context: ModelContext) {
        let card = LoreCard(
            title: lore.title,
            content: lore.content,
            tags: lore.tags,
            priority: LorePriority(rawValue: lore.priority) ?? .normal,
            currency: lore.currency,
            revelationStatus: lore.revelationStatus,
            scopeChange: lore.scopeChange,
            stateUpdatePermission: StateUpdatePermission(rawValue: lore.stateUpdatePermission) ?? .locked
        )
        card.world = world
        context.insert(card)
    }

    private static func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_ "))
        let sanitized = name.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
            .trimmingCharacters(in: .whitespaces)
        return sanitized.isEmpty ? UUID().uuidString : sanitized
    }

    private static func findFile(named filename: String, in directory: URL) -> URL? {
        let direct = directory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: direct.path) {
            return direct
        }
        // Check one level deep (ZIP may contain a wrapper folder)
        if let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for item in contents {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                    let nested = item.appendingPathComponent(filename)
                    if FileManager.default.fileExists(atPath: nested.path) {
                        return nested
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Extract Images from ZIP (for merge path)

    static func extractImages(from data: Data) -> [String: Data] {
        guard detectFileFormat(data) == .zip else { return [:] }
        let fm = FileManager.default
        let tempZip = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        defer { try? fm.removeItem(at: tempZip) }
        defer { try? fm.removeItem(at: tempDir) }

        do {
            try data.write(to: tempZip)
            try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try fm.unzipItem(at: tempZip, to: tempDir)

            guard let jsonURL = findFile(named: "world.json", in: tempDir) else { return [:] }
            let jsonData = try Data(contentsOf: jsonURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exported = try decoder.decode(ExportedWorld.self, from: jsonData)
            let baseDir = jsonURL.deletingLastPathComponent()

            let baseDirStd = baseDir.standardized.path
            var images: [String: Data] = [:]
            for char in exported.characters {
                if let filename = char.imageFilename {
                    let url = baseDir.appendingPathComponent(filename).standardized
                    guard url.path.hasPrefix(baseDirStd) else { continue }
                    if let imageData = try? Data(contentsOf: url) {
                        images[char.name] = imageData
                    }
                }
            }
            for loc in exported.locations {
                if let filename = loc.imageFilename {
                    let url = baseDir.appendingPathComponent(filename).standardized
                    guard url.path.hasPrefix(baseDirStd) else { continue }
                    if let imageData = try? Data(contentsOf: url) {
                        images[loc.name] = imageData
                    }
                }
            }
            return images
        } catch {
            return [:]
        }
    }

    // MARK: - Import Error

    enum ImportError: LocalizedError {
        case missingWorldJSON
        case unsupportedVersion(String)

        var errorDescription: String? {
            switch self {
            case .missingWorldJSON:
                return "The ZIP file does not contain a world.json file."
            case .unsupportedVersion(let version):
                return "This file requires Geoffrey version \(version) or later. Please update the app."
            }
        }
    }

    // MARK: - Summaries for Conflict Display

    private static func summarize(existingLocation loc: Location) -> String {
        var parts = [loc.descriptionText]
        if !loc.stateLabel.isEmpty && loc.stateLabel != "Default" { parts.insert("State: \(loc.stateLabel)", at: 0) }
        if !loc.atmosphere.isEmpty { parts.append("Atmosphere: \(loc.atmosphere)") }
        return parts.joined(separator: "\n")
    }

    private static func summarize(importedLocation loc: ExportedLocation) -> String {
        var parts = [loc.descriptionText]
        if !loc.stateLabel.isEmpty && loc.stateLabel != "Default" { parts.insert("State: \(loc.stateLabel)", at: 0) }
        if !loc.atmosphere.isEmpty { parts.append("Atmosphere: \(loc.atmosphere)") }
        return parts.joined(separator: "\n")
    }

    private static func summarize(existingCharacter char: StoryCharacter) -> String {
        var parts: [String] = []
        if !char.role.isEmpty { parts.append("Role: \(char.role)") }
        if !char.persona.isEmpty { parts.append(String(char.persona.prefix(200))) }
        if !char.psychologicalState.isEmpty { parts.append("State: \(char.psychologicalState)") }
        return parts.joined(separator: "\n")
    }

    private static func summarize(importedCharacter char: ExportedCharacter) -> String {
        var parts: [String] = []
        if !char.role.isEmpty { parts.append("Role: \(char.role)") }
        if !char.persona.isEmpty { parts.append(String(char.persona.prefix(200))) }
        if !char.psychologicalState.isEmpty { parts.append("State: \(char.psychologicalState)") }
        return parts.joined(separator: "\n")
    }

    private static func summarize(existingLore lore: LoreCard) -> String {
        var parts: [String] = []
        if !lore.tags.isEmpty { parts.append("Tags: \(lore.tags.joined(separator: ", "))") }
        parts.append(String(lore.content.prefix(200)))
        return parts.joined(separator: "\n")
    }

    private static func summarize(importedLore lore: ExportedLoreCard) -> String {
        var parts: [String] = []
        if !lore.tags.isEmpty { parts.append("Tags: \(lore.tags.joined(separator: ", "))") }
        parts.append(String(lore.content.prefix(200)))
        return parts.joined(separator: "\n")
    }
}
