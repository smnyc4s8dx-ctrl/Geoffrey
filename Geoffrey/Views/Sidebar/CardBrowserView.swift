import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CardBrowserView: View {
    let world: World
    @Binding var selectedTab: CardTab
    var selectedCardID: PersistentIdentifier?
    var presentCharacterIDs: Set<PersistentIdentifier>
    var activeLoreIDs: Set<PersistentIdentifier>
    var onCardTapped: (any PersistentModel) -> Void
    var onNewCard: (CardTab) -> Void
    var onToggleCharacterPresence: (StoryCharacter) -> Void
    var onToggleLore: (LoreCard) -> Void

    @State private var searchText = ""
    @State private var showingTavernImporter = false
    @State private var pendingTavernImport: ImportedTavernCharacter?
    @State private var importErrorMessage: String?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Card Type", selection: $selectedTab) {
                ForEach(CardTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

            HStack(spacing: 6) {
                Spacer()
                if selectedTab == .characters {
                    Button {
                        showingTavernImporter = true
                    } label: {
                        Label("Import Card", systemImage: "square.and.arrow.down")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Import a Tavern Card V2/V3 (PNG or JSON)")
                }
                Button {
                    onNewCard(selectedTab)
                } label: {
                    Label("New \(selectedTab.rawValue.dropLast())", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            Divider()

            switch selectedTab {
            case .locations:
                LocationListView(
                    world: world,
                    searchText: searchText,
                    selectedCardID: selectedCardID,
                    onCardTapped: { location in onCardTapped(location) }
                )
            case .characters:
                CharacterListView(
                    world: world,
                    searchText: searchText,
                    selectedCardID: selectedCardID,
                    presentCharacterIDs: presentCharacterIDs,
                    onCardTapped: { character in onCardTapped(character) },
                    onTogglePresence: onToggleCharacterPresence
                )
            case .lore:
                LoreListView(
                    world: world,
                    searchText: searchText,
                    selectedCardID: selectedCardID,
                    activeLoreIDs: activeLoreIDs,
                    onCardTapped: { lore in onCardTapped(lore) },
                    onToggleLore: onToggleLore
                )
            }
        }
        .overlay(alignment: .top) {
            if isDropTargeted {
                Text("Drop Tavern Card")
                    .font(.callout.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.thickMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.accentColor, lineWidth: 2))
                    .padding(.top, 60)
            }
        }
        .onDrop(of: [.png, .json, .fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $showingTavernImporter,
            allowedContentTypes: [.png, .json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelected(result)
        }
        .sheet(item: $pendingTavernImport) { imported in
            TavernCardImportView(
                imported: imported,
                world: world,
                onCommit: { _ in
                    pendingTavernImport = nil
                    selectedTab = .characters
                },
                onCancel: { pendingTavernImport = nil }
            )
        }
        .alert("Import Failed", isPresented: .init(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK") { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    // MARK: - Import handling

    private func handleFileSelected(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Cannot access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            try parseAndShow(data)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
            _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.png.identifier) { data, _ in
                guard let data else { return }
                Task { @MainActor in tryParse(data) }
            }
            return true
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
            _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, _ in
                guard let data else { return }
                Task { @MainActor in tryParse(data) }
            }
            return true
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                let started = url.startAccessingSecurityScopedResource()
                defer { if started { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else { return }
                Task { @MainActor in tryParse(data) }
            }
            return true
        }
        return false
    }

    @MainActor
    private func tryParse(_ data: Data) {
        do { try parseAndShow(data) }
        catch { importErrorMessage = error.localizedDescription }
    }

    private func parseAndShow(_ data: Data) throws {
        let imported = try TavernCardImporter.parse(data)
        pendingTavernImport = imported
    }
}

extension ImportedTavernCharacter: Identifiable {}
