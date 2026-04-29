import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LocationEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let world: World
    var location: Location?

    @State private var isDirty = false
    @State private var saveRequested = false
    @State private var canSave = true

    var body: some View {
        NavigationStack {
            LocationEditorForm(
                world: world,
                location: location,
                isDirty: $isDirty,
                saveRequested: $saveRequested,
                canSave: $canSave,
                onSave: { _ in dismiss() }
            )
            .navigationTitle(location != nil ? "Edit Location" : "New Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(location != nil ? "Save" : "Create") {
                        saveRequested = true
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 420)
    }
}
