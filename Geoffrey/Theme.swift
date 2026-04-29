import SwiftUI

enum Theme {

    // MARK: - Card Type Colors

    static let locationColor = Color.orange
    static let characterColor = Color.teal
    static let loreColor = Color.purple

    // MARK: - Spacing

    static let sectionSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 8
    static let bubbleCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 8

    // MARK: - Avatars

    static let avatarSize: CGFloat = 48
    static let avatarPalette: [Color] = [
        .indigo, Color(red: 0.95, green: 0.4, blue: 0.35),
        Color(red: 0.2, green: 0.6, blue: 0.35), .purple,
        Color(red: 0.35, green: 0.55, blue: 0.75), .orange,
        Color(red: 0.85, green: 0.35, blue: 0.5), .teal,
        Color(red: 0.55, green: 0.4, blue: 0.7), Color(red: 0.7, green: 0.55, blue: 0.3)
    ]

    // MARK: - Window

    static let defaultWindowWidth: CGFloat = 1100
    static let defaultWindowHeight: CGFloat = 700
    static let minWindowWidth: CGFloat = 900
    static let minWindowHeight: CGFloat = 600
}
