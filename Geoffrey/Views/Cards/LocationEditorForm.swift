import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LocationEditorForm: View {
    @Environment(\.modelContext) private var modelContext

    let world: World
    var location: Location?

    @Binding var isDirty: Bool
    @Binding var saveRequested: Bool
    @Binding var canSave: Bool
    var onSave: ((Location) -> Void)?

    @State private var name: String = ""
    @State private var stateLabel: String = "Default"
    @State private var descriptionText: String = ""
    @State private var notes: String = ""
    @State private var conditionDescription: String = ""
    @State private var accessibility: String = "Open"
    @State private var atmosphere: String = ""
    @State private var stateUpdatePermission: StateUpdatePermission = .locked
    @State private var imageData: Data?
    @State private var showingImagePicker: Bool = false
    @State private var hasLoaded: Bool = false

    private var snapshot: [String] {
        [name, stateLabel, descriptionText, notes, conditionDescription,
         accessibility, atmosphere, stateUpdatePermission.rawValue]
    }

    var body: some View {
        Form {
            // Image
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Group {
                            if let imageData, let nsImage = NSImage(data: imageData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                                            .strokeBorder(.separator, lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                                    .fill(.quaternary)
                                    .frame(width: 200, height: 120)
                                    .overlay {
                                        VStack(spacing: 4) {
                                            Image(systemName: "photo")
                                                .font(.title2)
                                                .foregroundStyle(.tertiary)
                                            Text("Drop image here")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                            }
                        }
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
                TextField("e.g. The Rusty Flagon", text: $name)
                TextField("e.g. Intact, On fire, Abandoned", text: $stateLabel)
            }

            Section("Description") {
                TextEditor(text: $descriptionText)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if descriptionText.isEmpty {
                            Text("Example: A dimly lit tavern with low oak beams and a stone hearth. The air smells of pipe smoke and spilled ale. Three round tables fill the main room, with a long bar along the far wall...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(6)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("State") {
                TextField("e.g. Charred beams, cold ash", text: $conditionDescription)
                TextField("Open, Restricted, Locked, Destroyed", text: $accessibility)
                TextField("e.g. Warm and lively, Eerie and silent", text: $atmosphere)
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
        guard let location else { return }
        name = location.name
        stateLabel = location.stateLabel
        descriptionText = location.descriptionText
        notes = location.notes
        conditionDescription = location.conditionDescription
        accessibility = location.accessibility
        atmosphere = location.atmosphere
        stateUpdatePermission = location.stateUpdatePermission
        imageData = location.imageData
        DispatchQueue.main.async {
            isDirty = false
            hasLoaded = true
        }
    }

    private func save() {
        let resizedImage = imageData.flatMap { ImageUtilities.resizeImage($0) }

        if let location {
            location.name = name
            location.stateLabel = stateLabel
            location.descriptionText = descriptionText
            location.notes = notes
            location.conditionDescription = conditionDescription
            location.accessibility = accessibility
            location.atmosphere = atmosphere
            location.stateUpdatePermission = stateUpdatePermission
            location.imageData = resizedImage
            try? modelContext.save()
            onSave?(location)
        } else {
            let loc = Location(
                name: name,
                stateLabel: stateLabel,
                descriptionText: descriptionText,
                notes: notes,
                conditionDescription: conditionDescription,
                accessibility: accessibility,
                atmosphere: atmosphere,
                stateUpdatePermission: stateUpdatePermission,
                imageData: resizedImage
            )
            loc.world = world
            modelContext.insert(loc)
            try? modelContext.save()
            onSave?(loc)
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
