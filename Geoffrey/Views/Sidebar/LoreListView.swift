import SwiftUI
import SwiftData

struct LoreListView: View {
    let world: World
    let searchText: String
    var selectedCardID: PersistentIdentifier?
    var activeLoreIDs: Set<PersistentIdentifier>
    var onCardTapped: (LoreCard) -> Void
    var onToggleLore: (LoreCard) -> Void

    @Environment(\.modelContext) private var modelContext

    private var filteredLore: [LoreCard] {
        let cards = world.loreCards
        if searchText.isEmpty { return cards }
        return cards.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        List {
            ForEach(filteredLore) { lore in
                CardRowView(
                    name: lore.title,
                    subtitle: lore.tags.joined(separator: ", "),
                    icon: "book.fill",
                    badgeText: lore.priority.displayName,
                    accentColor: Theme.loreColor,
                    isChecked: activeLoreIDs.contains(lore.persistentModelID),
                    isSelected: selectedCardID == lore.persistentModelID,
                    onCheckToggle: { onToggleLore(lore) }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onCardTapped(lore)
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(lore)
                        try? modelContext.save()
                    }
                }
            }
        }
        .overlay {
            if filteredLore.isEmpty {
                ContentUnavailableView("No Lore", systemImage: "book", description: Text("Create lore cards to define your world's knowledge."))
            }
        }
    }
}
