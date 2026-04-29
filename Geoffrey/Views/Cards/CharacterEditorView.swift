import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let world: World
    var character: StoryCharacter?

    @State private var isDirty = false
    @State private var saveRequested = false
    @State private var canSave = true

    var body: some View {
        NavigationStack {
            CharacterEditorForm(
                world: world,
                character: character,
                isDirty: $isDirty,
                saveRequested: $saveRequested,
                canSave: $canSave,
                onSave: { _ in dismiss() }
            )
            .navigationTitle(character != nil ? "Edit Character" : "New Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(character != nil ? "Save" : "Create") {
                        saveRequested = true
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 420)
    }
}
