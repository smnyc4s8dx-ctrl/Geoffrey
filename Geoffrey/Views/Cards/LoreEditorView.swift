import SwiftUI
import SwiftData

struct LoreEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let world: World
    var loreCard: LoreCard?

    @State private var isDirty = false
    @State private var saveRequested = false
    @State private var canSave = true

    var body: some View {
        NavigationStack {
            LoreEditorForm(
                world: world,
                loreCard: loreCard,
                isDirty: $isDirty,
                saveRequested: $saveRequested,
                canSave: $canSave,
                onSave: { _ in dismiss() }
            )
            .navigationTitle(loreCard != nil ? "Edit Lore" : "New Lore Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loreCard != nil ? "Save" : "Create") {
                        saveRequested = true
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 360)
    }
}
