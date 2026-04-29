import Foundation
import ZIPFoundation

enum ThemeExporter {

    // MARK: - Export

    static func exportTheme(_ config: ThemeConfig) throws -> Data {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tempDir) }

        // Strip image data from JSON (stored as separate files)
        var exportConfig = config
        let imageEntries = extractAndClearImages(from: &exportConfig)

        // Write theme.json
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(exportConfig)
        try jsonData.write(to: tempDir.appendingPathComponent("theme.json"))

        // Write images
        if !imageEntries.isEmpty {
            let imagesDir = tempDir.appendingPathComponent("images")
            try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            for (filename, data) in imageEntries {
                try data.write(to: imagesDir.appendingPathComponent(filename))
            }
        }

        // Create ZIP
        let zipURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".geoffreytheme")
        defer { try? fm.removeItem(at: zipURL) }
        try fm.zipItem(at: tempDir, to: zipURL)
        return try Data(contentsOf: zipURL)
    }

    // MARK: - Import

    static func importTheme(from data: Data) throws -> ThemeConfig {
        let fm = FileManager.default

        // Try plain JSON if not ZIP
        guard data.isZIPFile else {
            return try JSONDecoder().decode(ThemeConfig.self, from: data)
        }

        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tempDir) }

        // Write ZIP to temp file and unzip
        let zipURL = tempDir.appendingPathComponent("theme.zip")
        try data.write(to: zipURL)

        let extractDir = tempDir.appendingPathComponent("extracted")
        try fm.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try fm.unzipItem(at: zipURL, to: extractDir)

        // Find theme.json (may be at root or one level deep)
        let themeJsonURL = findFile(named: "theme.json", in: extractDir)
        guard let themeJsonURL else {
            throw ThemeImportError.missingThemeJson
        }

        let jsonData = try Data(contentsOf: themeJsonURL)
        var config = try JSONDecoder().decode(ThemeConfig.self, from: jsonData)

        // Load images
        let imagesDir = themeJsonURL.deletingLastPathComponent().appendingPathComponent("images")
        loadImageIfExists(at: imagesDir, filename: "single.png", into: &config.singleBackground)
        loadImageIfExists(at: imagesDir, filename: "left.png", into: &config.leftPanelBackground)
        loadImageIfExists(at: imagesDir, filename: "center.png", into: &config.centerPanelBackground)
        loadImageIfExists(at: imagesDir, filename: "right.png", into: &config.rightPanelBackground)

        return config
    }

    // MARK: - Helpers

    static func extractAndClearImages(from config: inout ThemeConfig) -> [(String, Data)] {
        var entries: [(String, Data)] = []

        if let data = config.singleBackground?.imageData {
            entries.append(("single.png", data))
            config.singleBackground?.imageData = nil
        }
        if let data = config.leftPanelBackground?.imageData {
            entries.append(("left.png", data))
            config.leftPanelBackground?.imageData = nil
        }
        if let data = config.centerPanelBackground?.imageData {
            entries.append(("center.png", data))
            config.centerPanelBackground?.imageData = nil
        }
        if let data = config.rightPanelBackground?.imageData {
            entries.append(("right.png", data))
            config.rightPanelBackground?.imageData = nil
        }

        return entries
    }

    private static func loadImageIfExists(at dir: URL, filename: String, into config: inout ImageConfig?) {
        let url = dir.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: url) {
            if config == nil {
                config = ImageConfig(imageData: data)
            } else {
                config?.imageData = data
            }
        }
    }

    private static func findFile(named name: String, in directory: URL) -> URL? {
        let direct = directory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: direct.path) {
            return direct
        }

        // Check one level deep (ZIP may contain a wrapper directory)
        if let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for item in contents {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                    let nested = item.appendingPathComponent(name)
                    if FileManager.default.fileExists(atPath: nested.path) {
                        return nested
                    }
                }
            }
        }

        return nil
    }
}

// MARK: - Errors

enum ThemeImportError: LocalizedError {
    case missingThemeJson

    var errorDescription: String? {
        switch self {
        case .missingThemeJson: "The theme file does not contain a valid theme.json."
        }
    }
}
