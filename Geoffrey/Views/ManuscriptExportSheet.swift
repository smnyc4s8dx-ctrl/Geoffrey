import SwiftUI
import UniformTypeIdentifiers

struct ManuscriptExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: Session
    let world: World

    @State private var format: ManuscriptFormat = .markdown
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var includeUncommitted: Bool = false
    @State private var saveError: String?

    private var options: ManuscriptOptions {
        ManuscriptOptions(title: title, author: author, includeUncommitted: includeUncommitted)
    }

    private var renderedText: String {
        ManuscriptExporter.renderText(session: session, format: format, options: options)
    }

    private var committedCount: Int {
        session.exchanges.filter(\.committed).count
    }

    private var totalCount: Int {
        session.exchanges.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            HSplitView {
                optionsPane
                    .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)

                previewPane
                    .frame(minWidth: 380)
            }

            Divider()

            footer
        }
        .frame(minWidth: 760, minHeight: 480)
        .alert("Save Failed", isPresented: .init(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Export Manuscript")
                    .font(.headline)
                Text("\(committedCount) committed exchange\(committedCount == 1 ? "" : "s") in \(world.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    private var optionsPane: some View {
        Form {
            Section("Format") {
                Picker("Format", selection: $format) {
                    ForEach(ManuscriptFormat.allCases) { fmt in
                        Text(fmt.displayName).tag(fmt)
                    }
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }

            Section("Document") {
                TextField("Title", text: $title, prompt: Text(world.name))
                TextField("Author", text: $author, prompt: Text("optional"))
            }

            Section("Scope") {
                Toggle("Include uncommitted exchanges", isOn: $includeUncommitted)
                    .toggleStyle(.checkbox)
                Text("\(committedCount) of \(totalCount) exchanges are committed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(renderedText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 6)

            ScrollView {
                if renderedText.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Export",
                        systemImage: "tray",
                        description: Text(includeUncommitted
                            ? "This session has no exchanges yet."
                            : "Commit at least one exchange, or enable \"Include uncommitted\" to preview drafts.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    Text(renderedText)
                        .font(.system(.callout, design: format == .rtf ? .monospaced : .default))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
            .background(.fill.quinary)
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Export…") { exportToFile() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(renderedText.isEmpty)
        }
        .padding(16)
    }

    private func exportToFile() {
        let data = ManuscriptExporter.export(session: session, format: format, options: options)
        let baseName = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? sanitize(world.name)
            : sanitize(title)
        let suggested = "\(baseName).\(format.fileExtension)"

        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggested
        switch format {
        case .markdown:
            panel.allowedContentTypes = [.init(filenameExtension: "md") ?? .plainText, .plainText]
        case .plainText:
            panel.allowedContentTypes = [.plainText]
        case .rtf:
            panel.allowedContentTypes = [.rtf]
        }
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url)
                Task { @MainActor in dismiss() }
            } catch {
                Task { @MainActor in saveError = error.localizedDescription }
            }
        }
    }

    private func sanitize(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_ "))
        let cleaned = name.unicodeScalars.filter { allowed.contains($0) }
            .map { String($0) }.joined()
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "manuscript" : cleaned
    }
}
