import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProjectWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeEngine.self) private var themeEngine

    var onComplete: (Project) -> Void
    var onCancel: () -> Void

    @State private var currentStep = 0
    @State private var showingImporter = false

    // Step 1 — Basics
    @State private var projectName = ""
    @State private var worldName = ""

    // Step 2 — Preamble
    @State private var systemPreamble = ""
    @State private var preambleExample = ExampleContent.randomPreamble()

    // Step 3 — Locations
    @State private var locationName = ""
    @State private var locationDescription = ""
    @State private var locationAtmosphere = ""
    @State private var locationExample = ExampleContent.randomLocation()
    @State private var savedLocationCount = 0

    // Step 4 — Characters
    @State private var charName = ""
    @State private var charRole = ""
    @State private var charPersona = ""
    @State private var charVoice = ""
    @State private var charExample = ExampleContent.randomCharacter()
    @State private var savedCharCount = 0

    // Step 5 — Lore
    @State private var loreTitle = ""
    @State private var loreContent = ""
    @State private var loreTags = ""
    @State private var loreExample = ExampleContent.randomLore()
    @State private var savedLoreCount = 0

    // Internal
    @State private var createdProject: Project?

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            // Step label
            Text(stepTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Divider().padding(.top, 8)

            // Step content
            ScrollView {
                Group {
                    switch currentStep {
                    case 0: basicsStep
                    case 1: preambleStep
                    case 2: locationStep
                    case 3: characterStep
                    default: loreStep
                    }
                }
                .padding(24)
            }

            Divider()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                }

                if currentStep > 0 {
                    Button("Skip to Project") {
                        saveCurrentStepIfFilled()
                        finishWizard()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)

                if currentStep == 0 {
                    Button("Next") {
                        ensureProjectCreated()
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                } else if currentStep < 4 {
                    Button("Next") {
                        saveCurrentStepIfFilled()
                        resetCurrentStepFields()
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Finish") {
                        saveCurrentStepIfFilled()
                        finishWizard()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 420, minHeight: 400)
        .background(.ultraThinMaterial)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: "Step 1 of 5 — Project Basics"
        case 1: "Step 2 of 5 — System Preamble"
        case 2: "Step 3 of 5 — Locations"
        case 3: "Step 4 of 5 — Characters"
        default: "Step 5 of 5 — Lore"
        }
    }

    // MARK: - Step 1: Basics

    private var basicsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create a New Project")
                .font(.title2.bold())

            Text("A project is your story container. It holds a world with locations, characters, and lore.")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Project Name")
                    .font(.headline)
                TextField("e.g. The Thornfield Chronicles", text: $projectName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("World / Setting Name")
                    .font(.headline)
                TextField("e.g. Thornfield, Victorian London, The Meridian", text: $worldName)
                    .textFieldStyle(.roundedBorder)
                Text("The world is the setting your story takes place in. Optional — you can set this later.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Button {
                showingImporter = true
            } label: {
                Label("Import from File", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .help("Import a .geoffrey.json file — skips the rest of the wizard")
        }
    }

    // MARK: - Step 2: Preamble

    private var preambleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Preamble")
                .font(.title2.bold())

            Text("Set the tone, style, and rules for how the AI writes in this project.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextEditor(text: $systemPreamble)
                .frame(minHeight: 120)
                .font(themeEngine.manuscriptFont)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(.tertiary)
                )
                .overlay(alignment: .topLeading) {
                    if systemPreamble.isEmpty {
                        Text("Example: \(preambleExample)")
                            .font(themeEngine.manuscriptFont)
                            .foregroundStyle(.tertiary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }

            Button("Show Different Example") {
                preambleExample = ExampleContent.randomPreamble()
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
    }

    // MARK: - Step 3: Locations

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add a Location")
                    .font(.title2.bold())
                Spacer()
                if savedLocationCount > 0 {
                    Text("\(savedLocationCount) saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.fill.tertiary, in: Capsule())
                }
            }

            Text("Locations are the sets of your story — places your characters inhabit.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("e.g. \(locationExample.name)", text: $locationName)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $locationDescription)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(.tertiary)
                )
                .overlay(alignment: .topLeading) {
                    if locationDescription.isEmpty {
                        Text("Example: \(locationExample.description)")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(6)
                            .allowsHitTesting(false)
                    }
                }

            TextField("e.g. \(locationExample.atmosphere)", text: $locationAtmosphere)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Show Different Example") {
                    locationExample = ExampleContent.randomLocation()
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()

                Button("Save & Add Another") {
                    saveLocation()
                    resetLocationFields()
                }
                .buttonStyle(.bordered)
                .disabled(locationName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Step 4: Characters

    private var characterStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add a Character")
                    .font(.title2.bold())
                Spacer()
                if savedCharCount > 0 {
                    Text("\(savedCharCount) saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.fill.tertiary, in: Capsule())
                }
            }

            Text("Characters are your cast — the people (or creatures) the AI will portray.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("e.g. \(charExample.name)", text: $charName)
                .textFieldStyle(.roundedBorder)

            TextField("e.g. \(charExample.role)", text: $charRole)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $charPersona)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(.tertiary)
                )
                .overlay(alignment: .topLeading) {
                    if charPersona.isEmpty {
                        Text("Example: \(charExample.persona)")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(6)
                            .allowsHitTesting(false)
                    }
                }

            TextEditor(text: $charVoice)
                .frame(minHeight: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(.tertiary)
                )
                .overlay(alignment: .topLeading) {
                    if charVoice.isEmpty {
                        Text("Example: \(charExample.voiceSample)")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(6)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Button("Show Different Example") {
                    charExample = ExampleContent.randomCharacter()
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()

                Button("Save & Add Another") {
                    saveCharacter()
                    resetCharacterFields()
                }
                .buttonStyle(.bordered)
                .disabled(charName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Step 5: Lore

    private var loreStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add Lore")
                    .font(.title2.bold())
                Spacer()
                if savedLoreCount > 0 {
                    Text("\(savedLoreCount) saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.fill.tertiary, in: Capsule())
                }
            }

            Text("Lore is your story bible — history, rules, facts the AI should know.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("e.g. \(loreExample.title)", text: $loreTitle)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $loreContent)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(.tertiary)
                )
                .overlay(alignment: .topLeading) {
                    if loreContent.isEmpty {
                        Text("Example: \(loreExample.content)")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(6)
                            .allowsHitTesting(false)
                    }
                }

            TextField("e.g. \(loreExample.tags.joined(separator: ", "))", text: $loreTags)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Show Different Example") {
                    loreExample = ExampleContent.randomLore()
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()

                Button("Save & Add Another") {
                    saveLore()
                    resetLoreFields()
                }
                .buttonStyle(.bordered)
                .disabled(loreTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func ensureProjectCreated() {
        guard createdProject == nil else { return }
        let world = World(
            name: worldName.isEmpty ? projectName : worldName,
            systemPreamble: ""
        )
        let project = Project(name: projectName)
        project.world = world
        modelContext.insert(project)
        modelContext.insert(world)
        try? modelContext.save()
        createdProject = project
    }

    private func saveCurrentStepIfFilled() {
        switch currentStep {
        case 1:
            if let project = createdProject, let world = project.world, !systemPreamble.isEmpty {
                world.systemPreamble = systemPreamble
                try? modelContext.save()
            }
        case 2:
            if !locationName.trimmingCharacters(in: .whitespaces).isEmpty {
                saveLocation()
            }
        case 3:
            if !charName.trimmingCharacters(in: .whitespaces).isEmpty {
                saveCharacter()
            }
        case 4:
            if !loreTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                saveLore()
            }
        default: break
        }
    }

    private func resetCurrentStepFields() {
        switch currentStep {
        case 2: resetLocationFields()
        case 3: resetCharacterFields()
        case 4: resetLoreFields()
        default: break
        }
    }

    private func saveLocation() {
        ensureProjectCreated()
        guard let world = createdProject?.world else { return }
        let loc = Location(
            name: locationName,
            descriptionText: locationDescription,
            atmosphere: locationAtmosphere
        )
        loc.world = world
        modelContext.insert(loc)
        try? modelContext.save()
        savedLocationCount += 1
    }

    private func saveCharacter() {
        ensureProjectCreated()
        guard let world = createdProject?.world else { return }
        let char = StoryCharacter(
            name: charName,
            role: charRole,
            persona: charPersona,
            voiceSample: charVoice
        )
        char.world = world
        modelContext.insert(char)
        try? modelContext.save()
        savedCharCount += 1
    }

    private func saveLore() {
        ensureProjectCreated()
        guard let world = createdProject?.world else { return }
        let tags = loreTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let card = LoreCard(title: loreTitle, content: loreContent, tags: tags)
        card.world = world
        modelContext.insert(card)
        try? modelContext.save()
        savedLoreCount += 1
    }

    private func resetLocationFields() {
        locationName = ""
        locationDescription = ""
        locationAtmosphere = ""
        locationExample = ExampleContent.randomLocation()
    }

    private func resetCharacterFields() {
        charName = ""
        charRole = ""
        charPersona = ""
        charVoice = ""
        charExample = ExampleContent.randomCharacter()
    }

    private func resetLoreFields() {
        loreTitle = ""
        loreContent = ""
        loreTags = ""
        loreExample = ExampleContent.randomLore()
    }

    private func finishWizard() {
        ensureProjectCreated()
        if let project = createdProject, let world = project.world {
            if !systemPreamble.isEmpty {
                world.systemPreamble = systemPreamble
                try? modelContext.save()
            }
            onComplete(project)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)
            let world = try CardExporter.importWorld(from: data, into: modelContext)
            let project = Project(name: world.name)
            project.world = world
            modelContext.insert(project)
            try? modelContext.save()
            onComplete(project)
        } catch {
            // Import failed silently — could add error state
        }
    }
}
