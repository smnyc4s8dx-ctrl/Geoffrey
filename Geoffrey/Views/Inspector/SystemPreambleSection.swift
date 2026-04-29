import SwiftUI
import SwiftData

struct SystemPreambleSection: View {
    @Bindable var world: World

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("System Preamble", systemImage: "doc.text")
                .font(.headline)

            TextEditor(text: $world.systemPreamble)
                .frame(minHeight: 60)
                .font(.body)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.tertiary)
                )

            Text("Global style: tense, POV, prose register, content permissions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
