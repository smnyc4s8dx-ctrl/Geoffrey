import SwiftUI

// MARK: - Data Extension (ZIP Detection)

extension Data {
    var isZIPFile: Bool {
        count >= 4 &&
        self[startIndex] == 0x50 &&
        self[startIndex + 1] == 0x4B &&
        self[startIndex + 2] == 0x03 &&
        self[startIndex + 3] == 0x04
    }
}

// MARK: - Theme Enums

enum WarmthShift: String, Codable, CaseIterable, Identifiable {
    case warm, cool, neutral
    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum FontMood: String, Codable, CaseIterable, Identifiable {
    case serif, mono, rounded, system
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .serif: "Serif"
        case .mono: "Monospaced"
        case .rounded: "Rounded"
        case .system: "System"
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .serif: .serif
        case .mono: .monospaced
        case .rounded: .rounded
        case .system: .default
        }
    }
}

enum BackgroundMode: String, Codable, CaseIterable, Identifiable {
    case single, perPanel
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: "Single Image"
        case .perPanel: "Per Panel"
        }
    }
}

enum PanelPosition: String, CaseIterable, Identifiable {
    case left, center, right, full
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .left: "Left Panel"
        case .center: "Center Panel"
        case .right: "Right Panel"
        case .full: "Full Window"
        }
    }
}

// MARK: - CodableColor

struct CodableColor: Codable, Equatable, Hashable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.opacity = Double(nsColor.alphaComponent)
    }
}

// MARK: - ImageConfig

struct ImageConfig: Codable, Equatable, Sendable {
    var imageData: Data?
    var anchorX: Double
    var anchorY: Double
    var opacity: Double

    init(imageData: Data? = nil, anchorX: Double = 0.5, anchorY: Double = 0.5, opacity: Double = 0.3) {
        self.imageData = imageData
        self.anchorX = anchorX
        self.anchorY = anchorY
        self.opacity = opacity
    }

    var alignment: Alignment {
        let h: HorizontalAlignment = anchorX < 0.33 ? .leading : anchorX > 0.66 ? .trailing : .center
        let v: VerticalAlignment = anchorY < 0.33 ? .top : anchorY > 0.66 ? .bottom : .center
        return Alignment(horizontal: h, vertical: v)
    }

    static func loading(from url: URL) -> ImageConfig? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return ImageConfig(imageData: data)
    }
}

// MARK: - ThemeConfig

struct ThemeConfig: Equatable, Sendable {
    var name: String
    var accentColor: CodableColor
    var secondaryAccent: CodableColor?
    var backgroundTint: WarmthShift
    var dialogueFont: FontMood
    var backgroundMode: BackgroundMode
    var singleBackground: ImageConfig?
    var leftPanelBackground: ImageConfig?
    var centerPanelBackground: ImageConfig?
    var rightPanelBackground: ImageConfig?

    func imageConfig(for panel: PanelPosition) -> ImageConfig? {
        switch backgroundMode {
        case .single:
            return singleBackground
        case .perPanel:
            switch panel {
            case .left: return leftPanelBackground
            case .center: return centerPanelBackground
            case .right: return rightPanelBackground
            case .full: return nil
            }
        }
    }
}

extension ThemeConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, accentColor, secondaryAccent, backgroundTint, dialogueFont
        case backgroundMode, singleBackground, leftPanelBackground
        case centerPanelBackground, rightPanelBackground
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        accentColor = try c.decode(CodableColor.self, forKey: .accentColor)
        secondaryAccent = try c.decodeIfPresent(CodableColor.self, forKey: .secondaryAccent)
        backgroundTint = try c.decode(WarmthShift.self, forKey: .backgroundTint)
        dialogueFont = try c.decode(FontMood.self, forKey: .dialogueFont)
        backgroundMode = try c.decode(BackgroundMode.self, forKey: .backgroundMode)
        singleBackground = try c.decodeIfPresent(ImageConfig.self, forKey: .singleBackground)
        leftPanelBackground = try c.decodeIfPresent(ImageConfig.self, forKey: .leftPanelBackground)
        centerPanelBackground = try c.decodeIfPresent(ImageConfig.self, forKey: .centerPanelBackground)
        rightPanelBackground = try c.decodeIfPresent(ImageConfig.self, forKey: .rightPanelBackground)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(accentColor, forKey: .accentColor)
        try c.encodeIfPresent(secondaryAccent, forKey: .secondaryAccent)
        try c.encode(backgroundTint, forKey: .backgroundTint)
        try c.encode(dialogueFont, forKey: .dialogueFont)
        try c.encode(backgroundMode, forKey: .backgroundMode)
        try c.encodeIfPresent(singleBackground, forKey: .singleBackground)
        try c.encodeIfPresent(leftPanelBackground, forKey: .leftPanelBackground)
        try c.encodeIfPresent(centerPanelBackground, forKey: .centerPanelBackground)
        try c.encodeIfPresent(rightPanelBackground, forKey: .rightPanelBackground)
    }
}
