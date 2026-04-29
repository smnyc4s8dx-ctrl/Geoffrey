import SwiftUI
import SwiftData

struct SceneInspectorView: View {
    @Environment(ThemeEngine.self) private var themeEngine
    @Bindable var inspectorVM: SceneInspectorViewModel
    @Bindable var sessionVM: SessionViewModel
    let world: World

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                // Director's Note first — most used during active writing
                VStack(alignment: .leading, spacing: 6) {
                    Label("Director's Note", systemImage: "megaphone")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    TextEditor(text: $sessionVM.directorsNote)
                        .frame(minHeight: 50)
                        .font(themeEngine.manuscriptSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                                .strokeBorder(.tertiary)
                        )

                    Text("Out-of-character instruction to the model.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // Location picker
                VStack(alignment: .leading, spacing: 6) {
                    Label("Location", systemImage: "map")
                        .font(.headline)
                        .foregroundStyle(Theme.locationColor)

                    Picker("Location", selection: locationBinding) {
                        Text("None").tag(nil as Location?)
                        ForEach(world.locations) { location in
                            Text(location.name).tag(location as Location?)
                        }
                    }
                    .labelsHidden()

                    if let location = inspectorVM.activeLocation {
                        if !location.atmosphere.isEmpty {
                            Text(location.atmosphere)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Speaking characters (only those present in scene via sidebar checkmarks)
                VStack(alignment: .leading, spacing: 6) {
                    Label("Speaking", systemImage: "mic")
                        .font(.headline)
                        .foregroundStyle(Theme.characterColor)

                    if inspectorVM.presentCharacters.isEmpty {
                        Text("No characters in scene")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Use checkmarks in the sidebar to add characters.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(inspectorVM.presentCharacters) { character in
                            let isSpeaking = inspectorVM.speakingCharacters.contains(where: {
                                $0.persistentModelID == character.persistentModelID
                            })

                            HStack(spacing: 8) {
                                Button {
                                    inspectorVM.toggleCharacterSpeaking(character)
                                } label: {
                                    Image(systemName: isSpeaking ? "mic.fill" : "mic.slash")
                                        .foregroundStyle(isSpeaking ? .green : .secondary)
                                        .frame(width: 20)
                                }
                                .buttonStyle(.borderless)
                                .help(isSpeaking ? "Stop speaking" : "Enable speaking")

                                Text(character.name)
                                    .font(.body)
                                if !character.role.isEmpty {
                                    Text(character.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                Divider()

                SystemPreambleSection(world: world)
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 380)
    }

    private var locationBinding: Binding<Location?> {
        Binding(
            get: { inspectorVM.activeLocation },
            set: { newLocation in
                inspectorVM.setLocation(newLocation)
            }
        )
    }
}
