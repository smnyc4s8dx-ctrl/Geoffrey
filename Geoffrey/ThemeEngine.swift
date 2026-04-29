import SwiftUI

@Observable
final class ThemeEngine {

    // MARK: - Config Sources

    var appDefaultConfig: ThemeConfig = .geoffreyClassic
    var projectOverride: ThemeConfig?

    // MARK: - Resolved Config

    var resolved: ThemeConfig {
        projectOverride ?? appDefaultConfig
    }

    // MARK: - Convenience: Colors

    var accentColor: Color {
        resolved.accentColor.color
    }

    var secondaryAccent: Color {
        resolved.secondaryAccent?.color ?? resolved.accentColor.color.opacity(0.6)
    }

    var committedAccent: Color {
        accentColor.opacity(0.4)
    }

    var warmthOverlay: Color {
        switch resolved.backgroundTint {
        case .warm: Color.orange.opacity(0.04)
        case .cool: Color.blue.opacity(0.04)
        case .neutral: Color.clear
        }
    }

    // MARK: - Convenience: Fonts

    var manuscriptFont: Font {
        .system(.body, design: resolved.dialogueFont.fontDesign)
    }

    var manuscriptSmall: Font {
        .system(.callout, design: resolved.dialogueFont.fontDesign)
    }

    // MARK: - Background Images

    private var imageCache: [String: NSImage] = [:]

    func backgroundImage(for panel: PanelPosition) -> (NSImage, ImageConfig)? {
        guard let config = resolved.imageConfig(for: panel),
              let imageData = config.imageData else { return nil }

        let cacheKey = "\(panel.rawValue)_\(imageData.count)"
        if let cached = imageCache[cacheKey] {
            return (cached, config)
        }

        guard let nsImage = NSImage(data: imageData) else { return nil }
        imageCache[cacheKey] = nsImage
        return (nsImage, config)
    }

    func clearImageCache() {
        imageCache.removeAll()
    }

    // MARK: - Persistence (App Default)

    private static let appThemeKey = "appThemeConfig"

    func saveAppDefault() {
        guard let data = try? JSONEncoder().encode(appDefaultConfig) else { return }
        UserDefaults.standard.set(data, forKey: Self.appThemeKey)
    }

    func loadAppDefault() {
        guard let data = UserDefaults.standard.data(forKey: Self.appThemeKey),
              let config = try? JSONDecoder().decode(ThemeConfig.self, from: data) else { return }
        appDefaultConfig = config
    }

    init() {
        loadAppDefault()
    }
}
