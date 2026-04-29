import SwiftUI

struct DuplicateResolverView: View {
    @Binding var conflicts: [DuplicateConflict]
    var onApply: ([DuplicateConflict]) -> Void
    var onCancel: () -> Void

    @State private var currentIndex = 0

    private var conflict: DuplicateConflict {
        conflicts[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Duplicate Detected", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
                Text("Conflict \(currentIndex + 1) of \(conflicts.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Card info
            HStack(spacing: 4) {
                Image(systemName: conflict.cardType.icon)
                    .foregroundStyle(colorForType(conflict.cardType))
                Text(conflict.cardType.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(colorForType(conflict.cardType))
                Text("—")
                    .foregroundStyle(.secondary)
                Text(conflict.name)
                    .font(.body.bold())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Side-by-side comparison
            HStack(alignment: .top, spacing: 1) {
                // Existing
                VStack(alignment: .leading, spacing: 8) {
                    Text("EXISTING")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    Text(conflict.existingSummary)
                        .font(.callout)
                        .textSelection(.enabled)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.green.opacity(0.05))

                // Incoming
                VStack(alignment: .leading, spacing: 8) {
                    Text("INCOMING")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    Text(conflict.incomingSummary)
                        .font(.callout)
                        .textSelection(.enabled)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.blue.opacity(0.05))
            }
            .frame(minHeight: 150)

            Divider()

            // Resolution picker
            VStack(spacing: 8) {
                Text("What would you like to do?")
                    .font(.callout)

                Picker("Resolution", selection: $conflicts[currentIndex].resolution) {
                    ForEach(DuplicateResolution.allCases, id: \.self) { res in
                        Text(res.displayName).tag(res)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()

            Divider()

            // Navigation + actions
            HStack {
                // Page navigation
                HStack(spacing: 12) {
                    Button {
                        withAnimation { currentIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex == 0)

                    Button {
                        withAnimation { currentIndex += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentIndex >= conflicts.count - 1)
                }
                .buttonStyle(.bordered)

                Spacer()

                // Apply to all menu
                if conflicts.count > 1 {
                    Menu("Apply to All") {
                        Button("Keep All Existing") {
                            applyToAll(.keepExisting)
                        }
                        Button("Replace All") {
                            applyToAll(.replace)
                        }
                        Button("Keep All (Both Copies)") {
                            applyToAll(.keepBoth)
                        }
                    }
                    .menuStyle(.borderlessButton)
                }

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Apply & Import") {
                    onApply(conflicts)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 480, minHeight: 380)
    }

    private func colorForType(_ type: CardType) -> Color {
        switch type {
        case .location: Theme.locationColor
        case .character: Theme.characterColor
        case .lore: Theme.loreColor
        }
    }

    private func applyToAll(_ resolution: DuplicateResolution) {
        for i in conflicts.indices {
            conflicts[i].resolution = resolution
        }
    }
}
