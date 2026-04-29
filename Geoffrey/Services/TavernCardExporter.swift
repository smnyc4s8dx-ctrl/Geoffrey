import AppKit
import Foundation

enum TavernCardExporter {

    enum Error: Swift.Error, LocalizedError {
        case avatarRenderFailed
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .avatarRenderFailed: "Could not render a placeholder avatar."
            case .encodingFailed: "Could not embed Tavern Card metadata."
            }
        }
    }

    /// Export a `StoryCharacter` as a Tavern Card V3 PNG, with V2-compatible
    /// `chara` chunk for backward compat. Returns the PNG bytes.
    static func exportPNG(_ character: StoryCharacter) throws -> Data {
        let cardV3 = makeCard(character, version: .v3)
        let cardV2 = makeCard(character, version: .v2)

        let png = try canonicalAvatarPNG(for: character)

        let v3JSON = try JSONEncoder.tavernEncoder.encode(cardV3)
        let v2JSON = try JSONEncoder.tavernEncoder.encode(cardV2)

        let v3Base64 = v3JSON.base64EncodedString()
        let v2Base64 = v2JSON.base64EncodedString()

        let withV3 = try PNGTextChunk.writeText("ccv3", value: v3Base64, into: png)
        let withBoth = try PNGTextChunk.writeText("chara", value: v2Base64, into: withV3)
        return withBoth
    }

    /// Export as plain JSON (no avatar).
    static func exportJSON(_ character: StoryCharacter) throws -> Data {
        let card = makeCard(character, version: .v3)
        return try JSONEncoder.tavernEncoder.encode(card)
    }

    // MARK: - Card construction

    private enum SpecVersion {
        case v2, v3

        var spec: String { self == .v3 ? "chara_card_v3" : "chara_card_v2" }
        var version: String { self == .v3 ? "3.0" : "2.0" }
    }

    private static func makeCard(_ character: StoryCharacter, version: SpecVersion) -> TavernCard {
        let geoffreyExt = GeoffreyExtension(
            role: character.role,
            vitalityStatus: character.vitalityStatus,
            psychologicalState: character.psychologicalState,
            knowledgeState: character.knowledgeState,
            roleplayPosture: character.roleplayPosture,
            narrativePresence: character.narrativePresence,
            currentState: character.currentState,
            notes: character.notes,
            stateUpdatePermission: character.stateUpdatePermission.rawValue
        )

        let now = Int(Date().timeIntervalSince1970)
        let data = TavernCardData(
            name: character.name,
            description: character.persona,
            personality: "",
            scenario: "",
            firstMes: "",
            mesExample: character.voiceSample,
            creatorNotes: "",
            systemPrompt: "",
            postHistoryInstructions: "",
            alternateGreetings: [],
            tags: character.tags,
            creator: "Geoffrey",
            characterVersion: "1.0",
            characterBook: nil,
            nickname: nil,
            creationDate: version == .v3 ? now : nil,
            modificationDate: version == .v3 ? now : nil,
            source: nil,
            groupOnlyGreetings: nil,
            geoffreyExtension: geoffreyExt
        )

        return TavernCard(spec: version.spec, specVersion: version.version, data: data)
    }

    // MARK: - Avatar PNG

    private static func canonicalAvatarPNG(for character: StoryCharacter) throws -> Data {
        if let imageData = character.imageData,
           let normalized = ImageUtilities.resizeImage(imageData, maxDimension: 512),
           ensurePNG(normalized) != nil {
            // resizeImage returns PNG; trust it.
            return normalized
        }
        guard let placeholder = renderPlaceholderPNG(for: character) else {
            throw Error.avatarRenderFailed
        }
        return placeholder
    }

    private static func ensurePNG(_ data: Data) -> Data? {
        let pngSig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        guard data.count >= 8, data.prefix(8).elementsEqual(pngSig) else { return nil }
        return data
    }

    private static func renderPlaceholderPNG(for character: StoryCharacter, size: Int = 512) -> Data? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let (r, g, b) = avatarRGB(for: character.name)
        ctx.setFillColor(red: r, green: g, blue: b, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

        let initials = initials(for: character.name)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.4, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let text = NSAttributedString(string: initials, attributes: attributes)
        let line = CTLineCreateWithAttributedString(text)
        let bounds = CTLineGetImageBounds(line, ctx)
        let x = (CGFloat(size) - bounds.width) / 2 - bounds.minX
        let y = (CGFloat(size) - bounds.height) / 2 - bounds.minY
        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)

        guard let cgImage = ctx.makeImage() else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = NSSize(width: size, height: size)
        return rep.representation(using: .png, properties: [:])
    }

    private static func initials(for name: String) -> String {
        let cleaned = name.replacingOccurrences(of: "\\s*\\(.*?\\)", with: "", options: .regularExpression)
        let words = cleaned.split(separator: " ").filter { !$0.isEmpty }
        switch words.count {
        case 0: return String(name.prefix(1)).uppercased()
        case 1: return String(words[0].prefix(1)).uppercased()
        default: return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased()
        }
    }

    private static func avatarRGB(for name: String) -> (CGFloat, CGFloat, CGFloat) {
        // Simple deterministic hash → HSB → RGB.
        var hash: UInt64 = 5381
        for byte in name.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        let hue = CGFloat(hash % 360) / 360.0
        let color = NSColor(hue: hue, saturation: 0.55, brightness: 0.65, alpha: 1)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
}

private extension JSONEncoder {
    static let tavernEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
