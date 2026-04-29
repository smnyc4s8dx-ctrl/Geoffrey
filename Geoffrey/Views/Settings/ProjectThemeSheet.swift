import SwiftUI
import UniformTypeIdentifiers

struct ProjectThemeSheet: View {
    @Environment(ThemeEngine.self) private var themeEngine
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var config: ThemeConfig = .geoffreyClassic
    @State private var hasOverride: Bool = false
    @State private var showingImporter = false
    @State private var showingExporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Project Theme")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Content
            Form {
                Section {
                    Toggle("Use custom theme for this project", isOn: $hasOverride)
                        .onChange(of: hasOverride) { _, newValue in
                            if newValue {
                                saveToProject()
                            } else {
                                project.themeConfigData = nil
                                themeEngine.projectOverride = nil
                                themeEngine.clearImageCache()
                            }
                        }
                }

                if hasOverride {
                    // Starter Palettes
                    Section("Starter Palettes") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                            ForEach(ThemeConfig.allPalettes, id: \.name) { palette in
                                PaletteCard(palette: palette, isSelected: config.name == palette.name, compact: true)
                                    .onTapGesture {
                                        config = palette
                                        applyAndSave()
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Accent Colors
                    Section("Accent Colors") {
                        ColorPicker("Primary", selection: Binding(
                            get: { config.accentColor.color },
                            set: {
                                config.accentColor = CodableColor($0)
                                config.name = "Custom"
                                applyAndSave()
                            }
                        ), supportsOpacity: false)

                        ColorPicker("Secondary", selection: Binding(
                            get: { config.secondaryAccent?.color ?? config.accentColor.color.opacity(0.6) },
                            set: {
                                config.secondaryAccent = CodableColor($0)
                                config.name = "Custom"
                                applyAndSave()
                            }
                        ), supportsOpacity: false)
                    }

                    // Typography & Atmosphere
                    Section("Style") {
                        Picker("Dialogue Font", selection: Binding(
                            get: { config.dialogueFont },
                            set: { config.dialogueFont = $0; config.name = "Custom"; applyAndSave() }
                        )) {
                            ForEach(FontMood.allCases) { mood in
                                Text(mood.displayName).tag(mood)
                            }
                        }

                        Picker("Warmth", selection: Binding(
                            get: { config.backgroundTint },
                            set: { config.backgroundTint = $0; config.name = "Custom"; applyAndSave() }
                        )) {
                            ForEach(WarmthShift.allCases) { shift in
                                Text(shift.displayName).tag(shift)
                            }
                        }
                    }

                    // Background
                    Section("Background") {
                        Picker("Mode", selection: Binding(
                            get: { config.backgroundMode },
                            set: { config.backgroundMode = $0; config.name = "Custom"; applyAndSave() }
                        )) {
                            ForEach(BackgroundMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }

                        if config.backgroundMode == .single {
                            ProjectImageWell(label: "Background", imageConfig: singleBgBinding)
                        } else {
                            ProjectImageWell(label: "Left Panel", imageConfig: leftBgBinding)
                            ProjectImageWell(label: "Center Panel", imageConfig: centerBgBinding)
                            ProjectImageWell(label: "Right Panel", imageConfig: rightBgBinding)
                        }
                    }

                    // Export/Import
                    Section("Theme File") {
                        HStack {
                            Button("Export Theme...") {
                                showingExporter = true
                            }
                            .buttonStyle(.bordered)

                            Button("Import Theme...") {
                                showingImporter = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 480, minHeight: 500)
        .onAppear {
            if let existing = project.themeConfig {
                config = existing
                hasOverride = true
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType(filenameExtension: "geoffreytheme") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let imported = try? ThemeExporter.importTheme(from: data) {
                        config = imported
                        hasOverride = true
                        applyAndSave()
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: ThemeDocument(config: config),
            contentType: UTType(filenameExtension: "geoffreytheme") ?? .data,
            defaultFilename: "\(config.name).geoffreytheme"
        ) { _ in }
    }

    // MARK: - Helpers

    private func applyAndSave() {
        themeEngine.projectOverride = config
        themeEngine.clearImageCache()
        saveToProject()
    }

    private func saveToProject() {
        project.themeConfig = config
    }

    // MARK: - Bindings

    private var singleBgBinding: Binding<ImageConfig?> {
        Binding(
            get: { config.singleBackground },
            set: { config.singleBackground = $0; applyAndSave() }
        )
    }

    private var leftBgBinding: Binding<ImageConfig?> {
        Binding(
            get: { config.leftPanelBackground },
            set: { config.leftPanelBackground = $0; applyAndSave() }
        )
    }

    private var centerBgBinding: Binding<ImageConfig?> {
        Binding(
            get: { config.centerPanelBackground },
            set: { config.centerPanelBackground = $0; applyAndSave() }
        )
    }

    private var rightBgBinding: Binding<ImageConfig?> {
        Binding(
            get: { config.rightPanelBackground },
            set: { config.rightPanelBackground = $0; applyAndSave() }
        )
    }
}

// MARK: - Project Image Well (simplified)

private struct ProjectImageWell: View {
    let label: String
    @Binding var imageConfig: ImageConfig?
    @State private var showingFilePicker = false

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .frame(width: 80, alignment: .leading)

            if let config = imageConfig, let data = config.imageData, let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Button(imageConfig == nil ? "Choose..." : "Change...") {
                showingFilePicker = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if imageConfig != nil {
                Slider(
                    value: Binding(
                        get: { imageConfig?.opacity ?? 0.3 },
                        set: { imageConfig?.opacity = $0 }
                    ),
                    in: 0.05...1.0
                )
                .frame(maxWidth: 80)

                Button(role: .destructive) {
                    imageConfig = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first,
               let loaded = ImageConfig.loading(from: url) {
                if imageConfig == nil {
                    imageConfig = loaded
                } else {
                    imageConfig?.imageData = loaded.imageData
                }
            }
        }
    }
}

// MARK: - Theme Document (for fileExporter)

struct ThemeDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [UTType(filenameExtension: "geoffreytheme") ?? .data]
    }

    let config: ThemeConfig

    init(config: ThemeConfig) {
        self.config = config
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.config = try ThemeExporter.importTheme(from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try ThemeExporter.exportTheme(config)
        return FileWrapper(regularFileWithContents: data)
    }
}
