import SwiftUI

extension ThemeConfig {

    // MARK: - Geoffrey Classic (current default look)

    static let geoffreyClassic = ThemeConfig(
        name: "Geoffrey Classic",
        accentColor: CodableColor(red: 0.0, green: 0.478, blue: 1.0),  // System blue accent
        secondaryAccent: nil,
        backgroundTint: .neutral,
        dialogueFont: .serif,
        backgroundMode: .single
    )

    // MARK: - Starbridge (Sci-Fi / Cyberpunk)

    static let starbridge = ThemeConfig(
        name: "Starbridge",
        accentColor: CodableColor(red: 0.0, green: 0.85, blue: 0.9),     // Electric cyan
        secondaryAccent: CodableColor(red: 0.9, green: 0.2, blue: 0.7),  // Hot magenta
        backgroundTint: .cool,
        dialogueFont: .mono,
        backgroundMode: .single
    )

    // MARK: - Hearthfire (High Fantasy / Medieval)

    static let hearthfire = ThemeConfig(
        name: "Hearthfire",
        accentColor: CodableColor(red: 0.8, green: 0.65, blue: 0.2),     // Burnished gold
        secondaryAccent: CodableColor(red: 0.2, green: 0.5, blue: 0.25), // Forest green
        backgroundTint: .warm,
        dialogueFont: .serif,
        backgroundMode: .single
    )

    // MARK: - Crimson Ink (Gothic Horror)

    static let crimsonInk = ThemeConfig(
        name: "Crimson Ink",
        accentColor: CodableColor(red: 0.7, green: 0.1, blue: 0.1),      // Deep crimson
        secondaryAccent: CodableColor(red: 0.9, green: 0.88, blue: 0.82), // Bone white
        backgroundTint: .cool,
        dialogueFont: .serif,
        backgroundMode: .single
    )

    // MARK: - Fogline (Noir / Detective)

    static let fogline = ThemeConfig(
        name: "Fogline",
        accentColor: CodableColor(red: 0.85, green: 0.65, blue: 0.2),    // Amber
        secondaryAccent: CodableColor(red: 0.35, green: 0.35, blue: 0.35), // Charcoal
        backgroundTint: .neutral,
        dialogueFont: .mono,
        backgroundMode: .single
    )

    // MARK: - Meadowlight (Fairy Tale / Whimsical)

    static let meadowlight = ThemeConfig(
        name: "Meadowlight",
        accentColor: CodableColor(red: 0.6, green: 0.5, blue: 0.85),     // Lavender
        secondaryAccent: CodableColor(red: 0.4, green: 0.8, blue: 0.65), // Mint
        backgroundTint: .warm,
        dialogueFont: .rounded,
        backgroundMode: .single
    )

    // MARK: - Obsidian (Modern / Thriller)

    static let obsidian = ThemeConfig(
        name: "Obsidian",
        accentColor: CodableColor(red: 0.7, green: 0.72, blue: 0.78),    // Silver
        secondaryAccent: CodableColor(red: 0.3, green: 0.3, blue: 0.6),  // Indigo
        backgroundTint: .cool,
        dialogueFont: .system,
        backgroundMode: .single
    )

    // MARK: - All Palettes

    static let allPalettes: [ThemeConfig] = [
        .geoffreyClassic,
        .starbridge,
        .hearthfire,
        .crimsonInk,
        .fogline,
        .meadowlight,
        .obsidian
    ]
}
