import SwiftUI
import SwiftData

struct TavernCardImportView: View {
    let imported: ImportedTavernCharacter
    let world: World
    var onCommit: (StoryCharacter) -> Void
    var onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    if !imported.card.data.scenario.isEmpty {
                        section("Scenario", accent: .secondary, body: imported.card.data.scenario)
                    }
                    if !imported.card.data.firstMes.isEmpty {
                        section("First Message", accent: .secondary, body: imported.card.data.firstMes)
                    }
                    if !imported.card.data.mesExample.isEmpty {
                        section("Example Dialogue", accent: .secondary, body: imported.card.data.mesExample)
                    }
                    advisories
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(minWidth: 520, minHeight: 560)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(imported.card.data.name.isEmpty ? "Untitled Character" : imported.card.data.name)
                    .font(.title2.bold())
                Text(imported.sourceFormat.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !imported.card.data.creator.isEmpty {
                    Text("by \(imported.card.data.creator)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(20)
    }

    @ViewBuilder
    private var avatar: some View {
        if let png = imported.avatarPNG, let nsImage = NSImage(data: png) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.separator, lineWidth: 1))
        } else {
            CharacterAvatarView(name: imported.card.data.name, size: 72)
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                summaryStat(
                    icon: "person.fill",
                    value: "1 character",
                    color: Theme.characterColor
                )
                if imported.lorebookEntryCount > 0 {
                    summaryStat(
                        icon: "book.fill",
                        value: "\(imported.lorebookEntryCount) lore card\(imported.lorebookEntryCount == 1 ? "" : "s")",
                        color: Theme.loreColor
                    )
                }
                if !imported.card.data.tags.isEmpty {
                    summaryStat(
                        icon: "tag.fill",
                        value: "\(imported.card.data.tags.count) tag\(imported.card.data.tags.count == 1 ? "" : "s")",
                        color: .secondary
                    )
                }
            }

            if !imported.card.data.tags.isEmpty {
                tagFlow(imported.card.data.tags)
            }

            if !imported.card.data.description.isEmpty || !imported.card.data.personality.isEmpty {
                let persona = [imported.card.data.description, imported.card.data.personality]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n\n")
                Text(persona)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func summaryStat(icon: String, value: String, color: Color) -> some View {
        Label {
            Text(value).font(.callout)
        } icon: {
            Image(systemName: icon).foregroundStyle(color)
        }
    }

    private func tagFlow(_ tags: [String]) -> some View {
        // Simple wrapping HStack via FlowLayout-ish approach using LazyVGrid for v1.
        let columns = [GridItem(.adaptive(minimum: 60), spacing: 6)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
    }

    // MARK: - Sections

    private func section(_ title: String, accent: Color, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(accent)
            Text(body)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Advisories

    @ViewBuilder
    private var advisories: some View {
        let advisories = collectAdvisories()
        if !advisories.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("On import")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                ForEach(advisories, id: \.self) { line in
                    Label {
                        Text(line).font(.callout)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func collectAdvisories() -> [String] {
        var lines: [String] = []
        if imported.hasScenario {
            lines.append("Scenario text is included in the card; Geoffrey will not overwrite this world's preamble — set it manually if you want.")
        }
        if imported.hasSystemPrompt {
            lines.append("Card has a system prompt; Geoffrey ignores it (your world's preamble takes precedence).")
        }
        if imported.hasAlternateGreetings {
            lines.append("Card has \(imported.card.data.alternateGreetings.count) alternate greetings; only the first message would be used today.")
        }
        if imported.lorebookEntryCount > 0 {
            lines.append("\(imported.lorebookEntryCount) embedded lore entries will be imported as Lore cards with keyword triggers.")
        }
        if world.characters.contains(where: { $0.name == imported.card.data.name }) {
            lines.append("A character named \"\(imported.card.data.name)\" already exists; the import will be renamed to keep both.")
        }
        return lines
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { onCancel() }
            Button {
                let character = TavernCardImporter.commit(imported, into: world, context: modelContext)
                onCommit(character)
            } label: {
                Text("Add to \(world.name)")
                    .frame(minWidth: 140)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(16)
    }
}
