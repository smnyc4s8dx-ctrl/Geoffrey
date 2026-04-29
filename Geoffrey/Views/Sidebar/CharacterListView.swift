import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CharacterListView: View {
    let world: World
    let searchText: String
    var selectedCardID: PersistentIdentifier?
    var presentCharacterIDs: Set<PersistentIdentifier>
    var onCardTapped: (StoryCharacter) -> Void
    var onTogglePresence: (StoryCharacter) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var exportError: String?

    private var filteredCharacters: [StoryCharacter] {
        let characters = world.characters
        if searchText.isEmpty { return characters }
        return characters.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredCharacters) { character in
                CardRowView(
                    name: character.name,
                    subtitle: character.role,
                    icon: "person.fill",
                    badgeText: character.vitalityStatus,
                    accentColor: Theme.characterColor,
                    isChecked: presentCharacterIDs.contains(character.persistentModelID),
                    isSelected: selectedCardID == character.persistentModelID,
                    onCheckToggle: { onTogglePresence(character) }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onCardTapped(character)
                }
                .contextMenu {
                    Button {
                        exportTavernPNG(character)
                    } label: {
                        Label("Export as Tavern Card (PNG)…", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        exportTavernJSON(character)
                    } label: {
                        Label("Export as Tavern Card (JSON)…", systemImage: "doc.text")
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        modelContext.delete(character)
                        try? modelContext.save()
                    }
                }
            }
        }
        .overlay {
            if filteredCharacters.isEmpty {
                ContentUnavailableView("No Characters", systemImage: "person.2", description: Text("Create a character to populate your world."))
            }
        }
        .alert("Export Failed", isPresented: .init(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: - Export

    private func exportTavernPNG(_ character: StoryCharacter) {
        do {
            let data = try TavernCardExporter.exportPNG(character)
            saveAs(data: data, suggestedName: "\(sanitize(character.name)).card.png", utType: .png)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportTavernJSON(_ character: StoryCharacter) {
        do {
            let data = try TavernCardExporter.exportJSON(character)
            saveAs(data: data, suggestedName: "\(sanitize(character.name)).card.json", utType: .json)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func saveAs(data: Data, suggestedName: String, utType: UTType) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [utType]
        panel.nameFieldStringValue = suggestedName
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url)
            } catch {
                Task { @MainActor in exportError = error.localizedDescription }
            }
        }
    }

    private func sanitize(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_ "))
        let cleaned = name.unicodeScalars.filter { allowed.contains($0) }
            .map { String($0) }.joined()
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "character" : cleaned
    }
}
