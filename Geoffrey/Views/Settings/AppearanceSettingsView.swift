import SwiftUI
import UniformTypeIdentifiers

struct AppearanceSettingsView: View {
    @Environment(ThemeEngine.self) private var themeEngine

    // Binding helper — auto-marks name as "Custom" and persists
    private func configBinding<V: Equatable>(
        _ keyPath: WritableKeyPath<ThemeConfig, V>
    ) -> Binding<V> {
        Binding(
            get: { themeEngine.appDefaultConfig[keyPath: keyPath] },
            set: {
                themeEngine.appDefaultConfig[keyPath: keyPath] = $0
                themeEngine.appDefaultConfig.name = "Custom"
                themeEngine.saveAppDefault()
            }
        )
    }

    var body: some View {
        Form {
            // MARK: - Starter Palettes
            Section("Starter Palettes") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                    ForEach(ThemeConfig.allPalettes, id: \.name) { palette in
                        PaletteCard(
                            palette: palette,
                            isSelected: themeEngine.appDefaultConfig.name == palette.name
                        )
                        .onTapGesture {
                            themeEngine.appDefaultConfig = palette
                            themeEngine.saveAppDefault()
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Accent Colors
            Section("Accent Colors") {
                ColorPicker(
                    "Primary Accent",
                    selection: Binding(
                        get: { themeEngine.appDefaultConfig.accentColor.color },
                        set: {
                            themeEngine.appDefaultConfig.accentColor = CodableColor($0)
                            themeEngine.appDefaultConfig.name = "Custom"
                            themeEngine.saveAppDefault()
                        }
                    ),
                    supportsOpacity: false
                )

                ColorPicker(
                    "Secondary Accent",
                    selection: Binding(
                        get: { themeEngine.appDefaultConfig.secondaryAccent?.color ?? themeEngine.accentColor.opacity(0.6) },
                        set: {
                            themeEngine.appDefaultConfig.secondaryAccent = CodableColor($0)
                            themeEngine.appDefaultConfig.name = "Custom"
                            themeEngine.saveAppDefault()
                        }
                    ),
                    supportsOpacity: false
                )
            }

            // MARK: - Typography
            Section("Typography") {
                Picker("Dialogue Font", selection: configBinding(\.dialogueFont)) {
                    ForEach(FontMood.allCases) { mood in
                        Text(mood.displayName).tag(mood)
                    }
                }

                Text("The quick brown fox jumps over the lazy dog.")
                    .font(themeEngine.manuscriptFont)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            // MARK: - Atmosphere
            Section("Atmosphere") {
                Picker("Background Warmth", selection: configBinding(\.backgroundTint)) {
                    ForEach(WarmthShift.allCases) { shift in
                        Text(shift.displayName).tag(shift)
                    }
                }
            }

            // MARK: - Background Image
            Section("Background Image") {
                Picker("Mode", selection: configBinding(\.backgroundMode)) {
                    ForEach(BackgroundMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                if themeEngine.appDefaultConfig.backgroundMode == .single {
                    ImageWell(
                        label: "Background",
                        imageConfig: Binding(
                            get: { themeEngine.appDefaultConfig.singleBackground },
                            set: {
                                themeEngine.appDefaultConfig.singleBackground = $0
                                themeEngine.clearImageCache()
                                themeEngine.saveAppDefault()
                            }
                        )
                    )
                } else {
                    ImageWell(
                        label: "Left Panel",
                        imageConfig: Binding(
                            get: { themeEngine.appDefaultConfig.leftPanelBackground },
                            set: {
                                themeEngine.appDefaultConfig.leftPanelBackground = $0
                                themeEngine.clearImageCache()
                                themeEngine.saveAppDefault()
                            }
                        )
                    )
                    ImageWell(
                        label: "Center Panel",
                        imageConfig: Binding(
                            get: { themeEngine.appDefaultConfig.centerPanelBackground },
                            set: {
                                themeEngine.appDefaultConfig.centerPanelBackground = $0
                                themeEngine.clearImageCache()
                                themeEngine.saveAppDefault()
                            }
                        )
                    )
                    ImageWell(
                        label: "Right Panel",
                        imageConfig: Binding(
                            get: { themeEngine.appDefaultConfig.rightPanelBackground },
                            set: {
                                themeEngine.appDefaultConfig.rightPanelBackground = $0
                                themeEngine.clearImageCache()
                                themeEngine.saveAppDefault()
                            }
                        )
                    )
                }
            }

            // MARK: - Reset
            Section {
                Button("Reset to Geoffrey Classic") {
                    themeEngine.appDefaultConfig = .geoffreyClassic
                    themeEngine.clearImageCache()
                    themeEngine.saveAppDefault()
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Palette Card (shared)

struct PaletteCard: View {
    let palette: ThemeConfig
    let isSelected: Bool
    var compact: Bool = false

    private var circleSize: CGFloat { compact ? 14 : 20 }
    private var vPad: CGFloat { compact ? 8 : 10 }
    private var hPad: CGFloat { compact ? 6 : 8 }
    private var radius: CGFloat { compact ? 6 : 8 }

    var body: some View {
        VStack(spacing: compact ? 4 : 6) {
            HStack(spacing: compact ? 3 : 4) {
                Circle()
                    .fill(palette.accentColor.color)
                    .frame(width: circleSize, height: circleSize)
                if let secondary = palette.secondaryAccent {
                    Circle()
                        .fill(secondary.color)
                        .frame(width: circleSize, height: circleSize)
                }
            }

            Text(palette.name)
                .font(compact ? .caption2 : .caption)
                .lineLimit(1)

            if !compact {
                Text(palette.dialogueFont.displayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, vPad)
        .padding(.horizontal, hPad)
        .background {
            RoundedRectangle(cornerRadius: radius)
                .fill(isSelected ? palette.accentColor.color.opacity(0.15) : Color.clear)
                .stroke(isSelected ? palette.accentColor.color : Color(.separatorColor), lineWidth: isSelected ? 2 : 1)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Image Well

private struct ImageWell: View {
    let label: String
    @Binding var imageConfig: ImageConfig?

    @State private var showingFilePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.bold())

            HStack(spacing: 12) {
                // Preview
                if let config = imageConfig, let data = config.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.separator)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.fill.quaternary)
                        .frame(width: 80, height: 50)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Button("Choose Image...") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.bordered)

                    if imageConfig != nil {
                        HStack(spacing: 8) {
                            Text("Opacity:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(
                                value: Binding(
                                    get: { imageConfig?.opacity ?? 0.3 },
                                    set: { imageConfig?.opacity = $0 }
                                ),
                                in: 0.05...1.0,
                                step: 0.05
                            )
                            .frame(maxWidth: 120)
                            Text("\(Int((imageConfig?.opacity ?? 0.3) * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 35, alignment: .trailing)
                        }

                        Button("Remove", role: .destructive) {
                            imageConfig = nil
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
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
