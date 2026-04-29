import SwiftUI
import SwiftData

struct LocationListView: View {
    let world: World
    let searchText: String
    var selectedCardID: PersistentIdentifier?
    var onCardTapped: (Location) -> Void

    @Environment(\.modelContext) private var modelContext

    private var filteredLocations: [Location] {
        let locations = world.locations
        if searchText.isEmpty { return locations }
        return locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredLocations) { location in
                CardRowView(
                    name: location.name,
                    subtitle: location.stateLabel,
                    icon: "map",
                    badgeText: location.stateLabel,
                    accentColor: Theme.locationColor,
                    isSelected: selectedCardID == location.persistentModelID
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onCardTapped(location)
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(location)
                        try? modelContext.save()
                    }
                }
            }
        }
        .overlay {
            if filteredLocations.isEmpty {
                ContentUnavailableView("No Locations", systemImage: "map", description: Text("Create a location to define a place in your world."))
            }
        }
    }
}
