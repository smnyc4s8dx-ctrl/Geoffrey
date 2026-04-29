import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CharacterEditorForm: View {
    @Environment(\.modelContext) private var modelContext

    let world: World
    var character: StoryCharacter?

    @Binding var isDirty: Bool
    @Binding var saveRequested: Bool
    @Binding var canSave: Bool
    var onSave: ((StoryCharacter) -> Void)?

    @State private var name: String = ""
    @State private var role: String = ""
    @State private var persona: String = ""
    @State private var voiceSample: String = ""
    @State private var notes: String = ""
    @State private var vitalityStatus: String = "Alive"
    @State private var psychologicalState: String = ""
    @State private var knowledgeState: String = ""
    @State private var roleplayPosture: String = "Authentic"
    @State private var narrativePresence: String = "Active"
    @State private var currentState: String = ""
    @State private var stateUpdatePermission: StateUpdatePermission = .locked
    @State private var imageData: Data?
    @State private var showingImagePicker: Bool = false
    @State private var hasLoaded: Bool = false

    private var snapshot: [String] {
        [name, role, persona, voiceSample, notes, vitalityStatus,
         psychologicalState, knowledgeState, roleplayPosture,
         narrativePresence, currentState, stateUpdatePermission.rawValue]
    }

    var body: some View {
        Form {
            // Avatar
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        CharacterAvatarView(
                            name: name.isEmpty ? "?" : name,
                            imageData: imageData,
                            size: 80
                        )
                        .onDrop(of: [.image], isTargeted: nil) { providers in
                            handleDrop(providers)
                        }

                        HStack(spacing: 12) {
                            Button("Choose Image") { showingImagePicker = true }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                            Button("Paste") { pasteImage() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                            if imageData != nil {
                                Button("Remove") { imageData = nil }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    Spacer()
                }
            }

            Section("Identity") {
                TextField("e.g. Marta Voss", text: $name)
                TextField("e.g. Bartender, Detective, Witness", text: $role)
            }

            Section("Persona") {
                TextEditor(text: $persona)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if persona.isEmpty {
                            Text("Example: Gruff but perceptive. Speaks in short, clipped sentences. Has a habit of polishing the same glass when she's thinking. Knows everyone's secrets but never volunteers them — you have to earn each detail...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(6)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("Voice Sample") {
                TextEditor(text: $voiceSample)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if voiceSample.isEmpty {
                            Text("Example: \"You want answers? Buy a drink first.\"\n\"The manor folk don't come 'round here anymore. Not since the fire.\"")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(6)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("State") {
                TextField("Alive, Injured, Dead, Ghost", text: $vitalityStatus)
                TextField("e.g. Guarded, suspicious of strangers", text: $psychologicalState)
                TextField("e.g. Knows the victim visited last Tuesday", text: $knowledgeState)
                TextField("Performing, Authentic, Fractured", text: $roleplayPosture)
                TextField("Active, Offscreen, Ghost, Memory", text: $narrativePresence)
                TextField("e.g. Behind the bar, cleaning glasses", text: $currentState)
                Picker("AI Update Permission", selection: $stateUpdatePermission) {
                    ForEach(StateUpdatePermission.allCases) { perm in
                        Text(perm.displayName).tag(perm)
                    }
                }
            }

            Section("Notes (private — not sent to model)") {
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        }
        .formStyle(.grouped)
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.png, .jpeg],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                imageData = ImageUtilities.loadImage(from: url)
            }
        }
        .onAppear { loadExisting() }
        .onChange(of: snapshot) {
            if hasLoaded { isDirty = true }
            canSave = !name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        .onChange(of: imageData) { if hasLoaded { isDirty = true } }
        .onChange(of: saveRequested) {
            if saveRequested {
                save()
                saveRequested = false
            }
        }
    }

    private func loadExisting() {
        guard let character else { return }
        name = character.name
        role = character.role
        persona = character.persona
        voiceSample = character.voiceSample
        notes = character.notes
        vitalityStatus = character.vitalityStatus
        psychologicalState = character.psychologicalState
        knowledgeState = character.knowledgeState
        roleplayPosture = character.roleplayPosture
        narrativePresence = character.narrativePresence
        currentState = character.currentState
        stateUpdatePermission = character.stateUpdatePermission
        imageData = character.imageData
        // Reset dirty after loading
        DispatchQueue.main.async {
            isDirty = false
            hasLoaded = true
        }
    }

    private func save() {
        let resizedImage = imageData.flatMap { ImageUtilities.resizeImage($0) }

        if let character {
            character.name = name
            character.role = role
            character.persona = persona
            character.voiceSample = voiceSample
            character.notes = notes
            character.vitalityStatus = vitalityStatus
            character.psychologicalState = psychologicalState
            character.knowledgeState = knowledgeState
            character.roleplayPosture = roleplayPosture
            character.narrativePresence = narrativePresence
            character.currentState = currentState
            character.stateUpdatePermission = stateUpdatePermission
            character.imageData = resizedImage
            try? modelContext.save()
            onSave?(character)
        } else {
            let char = StoryCharacter(
                name: name,
                role: role,
                persona: persona,
                voiceSample: voiceSample,
                notes: notes,
                vitalityStatus: vitalityStatus,
                psychologicalState: psychologicalState,
                knowledgeState: knowledgeState,
                roleplayPosture: roleplayPosture,
                narrativePresence: narrativePresence,
                currentState: currentState,
                stateUpdatePermission: stateUpdatePermission,
                imageData: resizedImage
            )
            char.world = world
            modelContext.insert(char)
            try? modelContext.save()
            onSave?(char)
        }
    }

    // MARK: - Image Input

    private func pasteImage() {
        imageData = ImageUtilities.imageFromPasteboard()
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            if let data {
                DispatchQueue.main.async {
                    imageData = ImageUtilities.resizeImage(data)
                }
            }
        }
        return true
    }
}
