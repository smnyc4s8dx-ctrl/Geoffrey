import SwiftUI

struct ImportOptionsView: View {
    let importData: Data
    let parsedWorld: ExportedWorld
    let worlds: [World]
    var onCreateNew: (Data) -> Void
    var onMergeInto: (World, ExportedWorld) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Label("Import World Data", systemImage: "square.and.arrow.down")
                .font(.title2.bold())

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("File: \(parsedWorld.name)")
                    .font(.headline)

                HStack(spacing: 16) {
                    Label("\(parsedWorld.locations.count) locations", systemImage: "map")
                        .foregroundStyle(Theme.locationColor)
                    Label("\(parsedWorld.characters.count) characters", systemImage: "person.2")
                        .foregroundStyle(Theme.characterColor)
                    Label("\(parsedWorld.loreCards.count) lore cards", systemImage: "book")
                        .foregroundStyle(Theme.loreColor)
                }
                .font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))

            Divider()

            // Option 1: Create new world
            Button {
                onCreateNew(importData)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create as New World")
                            .font(.body.bold())
                        Text("Import as a separate world named \"\(parsedWorld.name)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .padding(12)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Option 2: Merge into existing
            if !worlds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or merge into an existing world:")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    ForEach(worlds) { world in
                        Button {
                            onMergeInto(world, parsedWorld)
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(Theme.locationColor)
                                Text(world.name)
                                    .font(.body)
                                Spacer()
                                Text("Merge")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.accentColor)
                            }
                            .padding(10)
                            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(minWidth: 380, minHeight: 320)
    }
}
