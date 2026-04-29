import SwiftUI
import SwiftData

struct LoreEditorForm: View {
    @Environment(\.modelContext) private var modelContext

    let world: World
    var loreCard: LoreCard?

    @Binding var isDirty: Bool
    @Binding var saveRequested: Bool
    @Binding var canSave: Bool
    var onSave: ((LoreCard) -> Void)?

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var tagsText: String = ""
    @State private var priority: LorePriority = .normal
    @State private var currency: String = "Current"
    @State private var revelationStatus: String = "Universal"
    @State private var scopeChange: String = ""
    @State private var stateUpdatePermission: StateUpdatePermission = .locked
    @State private var hasLoaded: Bool = false

    private var snapshot: [String] {
        [title, content, tagsText, priority.rawValue, currency,
         revelationStatus, scopeChange, stateUpdatePermission.rawValue]
    }

    var body: some View {
        Form {
            Section("Identity") {
                TextField("e.g. The Silver Spoon of Blackwood Manor", text: $title)
                TextField("e.g. crime, evidence, manor-history", text: $tagsText)
                Picker("Priority", selection: $priority) {
                    ForEach(LorePriority.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
            }

            Section("Content") {
                TextEditor(text: $content)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Example: The Silver Spoon of Blackwood Manor was forged in 1847 by the Thornfield silversmiths. It bears the Blackwood family crest — a raven clutching a key. Only three were ever made. Two remain in the family vault. The third was reported missing after the fire...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(6)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("State") {
                TextField("Current, Superseded, Outdated", text: $currency)
                TextField("Universal, Known to protagonist only", text: $revelationStatus)
                TextField("e.g. Spoon identified as manor property", text: $scopeChange)
                Picker("AI Update Permission", selection: $stateUpdatePermission) {
                    ForEach(StateUpdatePermission.allCases) { perm in
                        Text(perm.displayName).tag(perm)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { loadExisting() }
        .onChange(of: snapshot) {
            if hasLoaded { isDirty = true }
            canSave = !title.trimmingCharacters(in: .whitespaces).isEmpty
        }
        .onChange(of: saveRequested) {
            if saveRequested {
                save()
                saveRequested = false
            }
        }
    }

    private func loadExisting() {
        guard let loreCard else { return }
        title = loreCard.title
        content = loreCard.content
        tagsText = loreCard.tags.joined(separator: ", ")
        priority = loreCard.priority
        currency = loreCard.currency
        revelationStatus = loreCard.revelationStatus
        scopeChange = loreCard.scopeChange
        stateUpdatePermission = loreCard.stateUpdatePermission
        DispatchQueue.main.async {
            isDirty = false
            hasLoaded = true
        }
    }

    private var parsedTags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func save() {
        if let loreCard {
            loreCard.title = title
            loreCard.content = content
            loreCard.tags = parsedTags
            loreCard.priority = priority
            loreCard.currency = currency
            loreCard.revelationStatus = revelationStatus
            loreCard.scopeChange = scopeChange
            loreCard.stateUpdatePermission = stateUpdatePermission
            try? modelContext.save()
            onSave?(loreCard)
        } else {
            let lore = LoreCard(
                title: title,
                content: content,
                tags: parsedTags,
                priority: priority,
                currency: currency,
                revelationStatus: revelationStatus,
                scopeChange: scopeChange,
                stateUpdatePermission: stateUpdatePermission
            )
            lore.world = world
            modelContext.insert(lore)
            try? modelContext.save()
            onSave?(lore)
        }
    }
}
