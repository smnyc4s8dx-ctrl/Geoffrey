import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeEngine.self) private var themeEngine
    @Environment(BackendRegistry.self) private var backendRegistry
    @Query private var projects: [Project]

    @State private var worldVM: WorldViewModel?
    @State private var sessionVM: SessionViewModel?
    @State private var inspectorVM: SceneInspectorViewModel?
    @State private var connectionMonitor: ConnectionMonitor?
    @State private var resourceMonitor: ResourceMonitor?

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedCardTab: CardTab = .locations
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    @State private var showingProjectTheme = false
    @State private var showingManuscriptExport = false

    // Center panel state
    @State private var centerContent: CenterPanelContent = .dialogue
    @State private var isDirty = false
    @State private var editorCanSave = true
    @State private var saveRequested = false
    @State private var pendingNavigation: CenterPanelContent?
    @State private var showingDirtyAlert = false

    // Sidebar visibility
    @State private var showInspector = true

    var body: some View {
        Group {
            if let worldVM {
                if let world = worldVM.selectedWorld {
                    mainContent(world: world)
                } else {
                    WorldPickerView(
                        projects: projects,
                        worldVM: worldVM,
                        onSelect: { project in
                            worldVM.selectProject(project)
                            themeEngine.projectOverride = project.themeConfig
                            themeEngine.clearImageCache()
                            if let world = project.world {
                                setupSession(for: world)
                            }
                        }
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            initializeViewModels()
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
                .onDisappear { hasCompletedOnboarding = true }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(world: World) -> some View {
        ZStack {
            // Single-mode background image (behind everything)
            if themeEngine.resolved.backgroundMode == .single,
               let (nsImage, config) = themeEngine.backgroundImage(for: .full) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(config.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            }

            // Warmth tint overlay
            themeEngine.warmthOverlay
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header bar
                headerBar(world: world)

                NavigationSplitView(columnVisibility: $columnVisibility) {
                    CardBrowserView(
                        world: world,
                        selectedTab: $selectedCardTab,
                        selectedCardID: centerContent.editingCardID,
                        presentCharacterIDs: presentCharacterIDSet,
                        activeLoreIDs: activeLoreIDSet,
                        onCardTapped: { card in
                            handleCardTapped(card)
                        },
                        onNewCard: { tab in
                            handleNewCard(tab)
                        },
                        onToggleCharacterPresence: { character in
                            inspectorVM?.toggleCharacterPresence(character)
                        },
                        onToggleLore: { lore in
                            guard let inspectorVM else { return }
                            if inspectorVM.activeLoreCards.contains(where: { $0.persistentModelID == lore.persistentModelID }) {
                                inspectorVM.removeLoreCard(lore)
                            } else {
                                inspectorVM.addLoreCard(lore)
                            }
                        }
                    )
                    .themedPanelBackground(.left)
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 340)
                } content: {
                    centerPanel(world: world)
                        .themedPanelBackground(.center)
                } detail: {
                    if showInspector, let inspectorVM, let sessionVM {
                        SceneInspectorView(
                            inspectorVM: inspectorVM,
                            sessionVM: sessionVM,
                            world: world
                        )
                        .themedPanelBackground(.right)
                    } else {
                        Color.clear.frame(width: 0)
                    }
                }
                .toolbar(.hidden)

                // Bottom status bar
                if let connectionMonitor, let resourceMonitor {
                    Divider()
                    ResourceStatusBar(
                        connectionMonitor: connectionMonitor,
                        resourceMonitor: resourceMonitor,
                        estimatedTokens: sessionVM?.estimatedTokenCount ?? 0,
                        contextWindow: 8192,
                        onConnectionTapped: { showingOnboarding = true }
                    )
                }
            }
        }
        .sheet(isPresented: $showingProjectTheme) {
            if let project = worldVM?.selectedProject {
                ProjectThemeSheet(project: project)
            }
        }
        .sheet(isPresented: $showingManuscriptExport) {
            if let session = sessionVM?.currentSession {
                ManuscriptExportSheet(session: session, world: world)
            }
        }
        .alert("Unsaved Changes", isPresented: $showingDirtyAlert) {
            Button("Save & Close") {
                // saveRequested triggers form save → onSave callback navigates
                saveRequested = true
            }
            Button("Discard", role: .destructive) {
                isDirty = false
                if let pending = pendingNavigation {
                    centerContent = pending
                    pendingNavigation = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingNavigation = nil
            }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
    }

    // MARK: - Center Panel

    private func completeSave() {
        let destination = pendingNavigation ?? .dialogue
        centerContent = destination
        pendingNavigation = nil
        isDirty = false
        editorCanSave = true
    }

    @ViewBuilder
    private func centerPanel(world: World) -> some View {
        switch centerContent {
        case .dialogue:
            if let sessionVM {
                DialogueCanvasView(sessionVM: sessionVM, world: world)
            }

        case .editingCharacter(let character):
            VStack(spacing: 0) {
                InlineEditorHeader(
                    title: "Edit Character",
                    icon: "person.fill",
                    accentColor: Theme.characterColor,
                    isDirty: isDirty,
                    canSave: editorCanSave,
                    onSave: { saveRequested = true },
                    onClose: { requestNavigation(.dialogue) }
                )
                CharacterEditorForm(
                    world: world,
                    character: character,
                    isDirty: $isDirty,
                    saveRequested: $saveRequested,
                    canSave: $editorCanSave,
                    onSave: { _ in completeSave() }
                )
            }

        case .editingLocation(let location):
            VStack(spacing: 0) {
                InlineEditorHeader(
                    title: "Edit Location",
                    icon: "map",
                    accentColor: Theme.locationColor,
                    isDirty: isDirty,
                    canSave: editorCanSave,
                    onSave: { saveRequested = true },
                    onClose: { requestNavigation(.dialogue) }
                )
                LocationEditorForm(
                    world: world,
                    location: location,
                    isDirty: $isDirty,
                    saveRequested: $saveRequested,
                    canSave: $editorCanSave,
                    onSave: { _ in completeSave() }
                )
            }

        case .editingLore(let lore):
            VStack(spacing: 0) {
                InlineEditorHeader(
                    title: "Edit Lore",
                    icon: "book.fill",
                    accentColor: Theme.loreColor,
                    isDirty: isDirty,
                    canSave: editorCanSave,
                    onSave: { saveRequested = true },
                    onClose: { requestNavigation(.dialogue) }
                )
                LoreEditorForm(
                    world: world,
                    loreCard: lore,
                    isDirty: $isDirty,
                    saveRequested: $saveRequested,
                    canSave: $editorCanSave,
                    onSave: { _ in completeSave() }
                )
            }

        case .newCharacter:
            VStack(spacing: 0) {
                InlineEditorHeader(
                    title: "New Character",
                    icon: "person.fill",
                    accentColor: Theme.characterColor,
                    isDirty: isDirty,
                    canSave: editorCanSave,
                    onSave: { saveRequested = true },
                    onClose: { requestNavigation(.dialogue) }
                )
                CharacterEditorForm(
                    world: world,
                    isDirty: $isDirty,
                    saveRequested: $saveRequested,
                    canSave: $editorCanSave,
                    onSave: { _ in completeSave() }
                )
            }

        case .newLocation:
            VStack(spacing: 0) {
                InlineEditorHeader(
                    title: "New Location",
                    icon: "map",
                    accentColor: Theme.locationColor,
                    isDirty: isDirty,
                    canSave: editorCanSave,
                    onSave: { saveRequested = true },
                    onClose: { requestNavigation(.dialogue) }
                )
                LocationEditorForm(
                    world: world,
                    isDirty: $isDirty,
                    saveRequested: $saveRequested,
                    canSave: $editorCanSave,
                    onSave: { _ in completeSave() }
                )
            }

        case .newLore:
            VStack(spacing: 0) {
                InlineEditorHeader(
                    title: "New Lore Card",
                    icon: "book.fill",
                    accentColor: Theme.loreColor,
                    isDirty: isDirty,
                    canSave: editorCanSave,
                    onSave: { saveRequested = true },
                    onClose: { requestNavigation(.dialogue) }
                )
                LoreEditorForm(
                    world: world,
                    isDirty: $isDirty,
                    saveRequested: $saveRequested,
                    canSave: $editorCanSave,
                    onSave: { lore in
                        // Auto-activate new lore cards
                        inspectorVM?.addLoreCard(lore)
                        completeSave()
                    }
                )
            }
        }
    }

    // MARK: - Navigation Guard

    private func requestNavigation(_ destination: CenterPanelContent) {
        if isDirty {
            pendingNavigation = destination
            showingDirtyAlert = true
        } else {
            centerContent = destination
            isDirty = false
        }
    }

    private func handleCardTapped(_ card: any PersistentModel) {
        let cardID = card.persistentModelID

        // Toggle: if already editing this card, close it
        if centerContent.editingCardID == cardID {
            requestNavigation(.dialogue)
            return
        }

        if let location = card as? Location {
            requestNavigation(.editingLocation(location))
        } else if let character = card as? StoryCharacter {
            requestNavigation(.editingCharacter(character))
        } else if let lore = card as? LoreCard {
            requestNavigation(.editingLore(lore))
        }
    }

    private func handleNewCard(_ tab: CardTab) {
        switch tab {
        case .locations: requestNavigation(.newLocation)
        case .characters: requestNavigation(.newCharacter)
        case .lore: requestNavigation(.newLore)
        }
    }

    // MARK: - Computed State

    private var presentCharacterIDSet: Set<PersistentIdentifier> {
        Set(inspectorVM?.presentCharacters.map(\.persistentModelID) ?? [])
    }

    private var activeLoreIDSet: Set<PersistentIdentifier> {
        Set(inspectorVM?.activeLoreCards.map(\.persistentModelID) ?? [])
    }

    // MARK: - Header Bar

    private func headerBar(world: World) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Home button
                Button {
                    themeEngine.projectOverride = nil
                    themeEngine.clearImageCache()
                    worldVM?.selectedProject = nil
                    sessionVM?.currentSession = nil
                    inspectorVM?.reset()
                    centerContent = .dialogue
                } label: {
                    Image(systemName: "house")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Back to projects")

                // Left sidebar toggle
                Button {
                    withAnimation {
                        columnVisibility = columnVisibility == .all ? .doubleColumn : .all
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.body)
                        .foregroundStyle(columnVisibility == .all ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle card browser")

                // Project name
                Text(worldVM?.selectedProject?.name ?? world.name)
                    .font(.headline)

                Spacer()

                // Manuscript export button
                Button {
                    showingManuscriptExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Export Manuscript…")
                .disabled(sessionVM?.currentSession == nil)

                // Theme button
                Button {
                    showingProjectTheme = true
                } label: {
                    Image(systemName: "paintbrush")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Customize project theme")

                // Narrative mode picker
                if let sessionVM {
                    Menu {
                        Button {
                            sessionVM.narrativeMode = .director
                            sessionVM.playerCharacter = nil
                        } label: {
                            Label("Director", systemImage: NarrativeMode.director.icon)
                        }

                        Button {
                            sessionVM.narrativeMode = .author
                            sessionVM.playerCharacter = nil
                        } label: {
                            Label("Author", systemImage: NarrativeMode.author.icon)
                        }

                        Button {
                            sessionVM.narrativeMode = .gameMaster
                            sessionVM.playerCharacter = nil
                        } label: {
                            Label("Game Master", systemImage: NarrativeMode.gameMaster.icon)
                        }

                        Divider()

                        Menu {
                            ForEach(world.characters) { character in
                                Button {
                                    sessionVM.narrativeMode = .character
                                    sessionVM.playerCharacter = character
                                } label: {
                                    HStack {
                                        Text(character.name)
                                        if sessionVM.narrativeMode == .character,
                                           sessionVM.playerCharacter?.persistentModelID == character.persistentModelID {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Play as Character", systemImage: NarrativeMode.character.icon)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: sessionVM.narrativeMode.icon)
                                .font(.callout)
                            Text(sessionVM.narrativeMode == .character
                                 ? (sessionVM.playerCharacter?.name ?? "Character")
                                 : sessionVM.narrativeMode.rawValue)
                                .font(.callout)
                        }
                        .foregroundStyle(.primary)
                    }
                    .menuStyle(.borderlessButton)
                }

                // Right sidebar toggle
                Button {
                    withAnimation {
                        showInspector.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.right")
                        .font(.body)
                        .foregroundStyle(showInspector ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle inspector")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            Divider()
        }
        .background(.bar)
    }

    // MARK: - Initialization

    private func initializeViewModels() {
        guard worldVM == nil else { return }

        worldVM = WorldViewModel(modelContext: modelContext)
        let inspector = SceneInspectorViewModel(modelContext: modelContext)
        let session = SessionViewModel(modelContext: modelContext, backendRegistry: backendRegistry)
        // Mutual weak refs: session reads scene state from inspector;
        // inspector calls back to invalidate the token-count cache when
        // scene state mutates.
        session.inspectorVM = inspector
        inspector.sessionVM = session
        inspectorVM = inspector
        sessionVM = session

        let monitor = ConnectionMonitor(backendRegistry: backendRegistry)
        connectionMonitor = monitor
        monitor.startPolling()

        let resources = ResourceMonitor(backendRegistry: backendRegistry)
        resourceMonitor = resources
        resources.startPolling()
    }

    private func setupSession(for world: World) {
        sessionVM?.ensureSession(for: world)
    }
}

enum CardTab: String, CaseIterable, Identifiable {
    case locations = "Locations"
    case characters = "Characters"
    case lore = "Lore"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .locations: "map"
        case .characters: "person.2"
        case .lore: "book"
        }
    }
}
