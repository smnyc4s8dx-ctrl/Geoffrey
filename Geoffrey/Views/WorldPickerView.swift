import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct WorldPickerView: View {
    let projects: [Project]
    @Bindable var worldVM: WorldViewModel
    var isSheet: Bool = false

    var onSelect: (Project) -> Void
    var onDismiss: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var showingImporter = false
    @State private var showingWizard = false
    @State private var importError: String?
    @State private var projectToDelete: Project?
    @State private var pendingImportData: Data?
    @State private var showingImportOptions = false
    @State private var showingDuplicateResolver = false
    @State private var pendingConflicts: [DuplicateConflict] = []
    @State private var mergeTargetWorld: World?
    @State private var pendingExportedWorld: ExportedWorld?
    @State private var pendingImages: [String: Data] = [:]
    @State private var pendingParsedWorld: ExportedWorld?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "text.book.closed.fill")
                        .font(.title2)
                        .foregroundStyle(.linearGradient(
                            colors: [Theme.locationColor, Theme.characterColor, Theme.loreColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Text("Geoffrey")
                        .font(.title2.bold())

                    Spacer()

                    if isSheet {
                        Button {
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 24)

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        showingWizard = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // Your Projects
                if !projects.isEmpty {
                    Divider().padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Projects")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)

                        ForEach(projects) { project in
                            projectRow(project)
                        }
                    }
                }

                Divider().padding(.horizontal, 24).padding(.top, 4)

                // Templates
                VStack(alignment: .leading, spacing: 4) {
                    Text("Templates")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    Text("Load a starter project to see how Geoffrey works.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    let templates = TemplateLibrary.allTemplates
                    ForEach(Array(templates.enumerated()), id: \.offset) { _, template in
                        HStack(spacing: 8) {
                            Button {
                                let world = TemplateLibrary.createWorld(from: template, in: modelContext)
                                let project = Project(name: template.name)
                                project.world = world
                                modelContext.insert(project)
                                try? modelContext.save()
                                onSelect(project)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.body)
                                        .foregroundStyle(Theme.loreColor)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .font(.body.weight(.medium))
                                        Text(template.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text("Load")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.accentColor)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                exportTemplate(template)
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Export as JSON to see the template format")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                    }
                }

                if let importError {
                    Text(importError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(24)
                }
            }
        }
        .background(.ultraThinMaterial)
        .frame(minWidth: 380, minHeight: 320)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json, .zip],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelected(result)
        }
        .alert("Delete Project?", isPresented: .init(
            get: { projectToDelete != nil },
            set: { if !$0 { projectToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { projectToDelete = nil }
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    worldVM.deleteProject(project)
                    projectToDelete = nil
                }
            }
        } message: {
            if let project = projectToDelete {
                Text("This will permanently delete \"\(project.name)\" and all its cards, sessions, and history.")
            }
        }
        .sheet(isPresented: $showingWizard) {
            ProjectWizardView(
                onComplete: { project in
                    showingWizard = false
                    onSelect(project)
                },
                onCancel: {
                    showingWizard = false
                }
            )
        }
        .sheet(isPresented: $showingImportOptions, onDismiss: {
            if !pendingConflicts.isEmpty {
                showingDuplicateResolver = true
            }
        }) {
            if let data = pendingImportData, let parsed = pendingParsedWorld {
                ImportOptionsView(
                    importData: data,
                    parsedWorld: parsed,
                    worlds: projects.compactMap(\.world),
                    onCreateNew: { data in
                        do {
                            let world = try CardExporter.importWorld(from: data, into: modelContext)
                            let project = Project(name: world.name)
                            project.world = world
                            modelContext.insert(project)
                            try? modelContext.save()
                            onSelect(project)
                        } catch {
                            importError = "Import failed: \(error.localizedDescription)"
                        }
                        showingImportOptions = false
                    },
                    onMergeInto: { world, exported in
                        let images = CardExporter.extractImages(from: data)
                        let conflicts = CardExporter.detectDuplicates(in: exported, against: world)
                        if conflicts.isEmpty {
                            CardExporter.mergeIntoWorld(world, from: exported, resolutions: [], images: images, context: modelContext)
                            if let project = world.project {
                                onSelect(project)
                            }
                            showingImportOptions = false
                        } else {
                            pendingConflicts = conflicts
                            mergeTargetWorld = world
                            pendingExportedWorld = exported
                            pendingImages = images
                            showingImportOptions = false
                        }
                    },
                    onCancel: {
                        showingImportOptions = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingDuplicateResolver) {
            if let world = mergeTargetWorld, let exported = pendingExportedWorld {
                DuplicateResolverView(
                    conflicts: $pendingConflicts,
                    onApply: { resolutions in
                        CardExporter.mergeIntoWorld(world, from: exported, resolutions: resolutions, images: pendingImages, context: modelContext)
                        showingDuplicateResolver = false
                        if let project = world.project {
                            onSelect(project)
                        }
                    },
                    onCancel: {
                        showingDuplicateResolver = false
                    }
                )
            }
        }
    }

    // MARK: - Project Row

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        HStack(spacing: 8) {
            Button {
                onSelect(project)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.body)
                        .foregroundStyle(Theme.locationColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .font(.body.weight(.medium))
                        if let world = project.world {
                            HStack(spacing: 10) {
                                Label("\(world.locations.count)", systemImage: "map")
                                Label("\(world.characters.count)", systemImage: "person.2")
                                Label("\(world.loreCards.count)", systemImage: "book")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                projectToDelete = project
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
            .help("Delete project")

            Button {
                if let world = project.world {
                    exportWorld(world, projectName: project.name)
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func exportTemplate(_ template: TemplateLibrary.WorldTemplate) {
        let exported = ExportedWorld(
            name: template.name,
            systemPreamble: template.systemPreamble,
            locations: template.locations.map {
                ExportedLocation(
                    name: $0.name, stateLabel: $0.stateLabel,
                    descriptionText: $0.descriptionText, notes: "",
                    conditionDescription: "", accessibility: "Open",
                    atmosphere: $0.atmosphere, stateUpdatePermission: "locked"
                )
            },
            characters: template.characters.map {
                ExportedCharacter(
                    name: $0.name, role: $0.role, persona: $0.persona,
                    voiceSample: $0.voiceSample, notes: "",
                    vitalityStatus: "Alive", psychologicalState: $0.psychologicalState,
                    knowledgeState: "", roleplayPosture: "Authentic",
                    narrativePresence: "Active", currentState: "",
                    stateUpdatePermission: "locked"
                )
            },
            loreCards: template.loreCards.map {
                ExportedLoreCard(
                    title: $0.title, content: $0.content, tags: $0.tags,
                    priority: $0.priority.rawValue, currency: "Current",
                    revelationStatus: "Universal", scopeChange: "",
                    stateUpdatePermission: "locked"
                )
            }
        )
        saveExportedJSON(exported, filename: "\(template.name).geoffrey.json")
    }

    private func exportWorld(_ world: World, projectName: String) {
        if CardExporter.worldHasImages(world) {
            // Export as ZIP with images
            do {
                let zipData = try CardExporter.exportWorldAsZip(world)
                #if os(macOS)
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.zip]
                panel.nameFieldStringValue = "\(projectName).geoffrey.zip"
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        try? zipData.write(to: url)
                    }
                }
                #endif
            } catch {
                importError = "Export failed: \(error.localizedDescription)"
            }
        } else {
            // Export as plain JSON
            let exported = CardExporter.exportWorld(world)
            saveExportedJSON(exported, filename: "\(projectName).geoffrey.json")
        }
    }

    private func saveExportedJSON(_ exported: ExportedWorld, filename: String) {
        guard let data = try? JSONEncoder.prettyEncoder.encode(exported) else { return }
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = filename
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
        #endif
    }

    private func handleFileSelected(_ result: Result<[URL], Error>) {
        importError = nil
        do {
            guard let url = try result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Cannot access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)

            // Validate and pre-parse (avoids double ZIP decompression)
            let parsed = try CardExporter.parseExportedWorld(from: data)

            pendingImportData = data
            pendingParsedWorld = parsed
            showingImportOptions = true
        } catch {
            importError = "Invalid file: \(error.localizedDescription)"
        }
    }
}

private extension JSONEncoder {
    static let prettyEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
