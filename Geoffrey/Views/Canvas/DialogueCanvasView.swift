import SwiftUI
import SwiftData

struct DialogueCanvasView: View {
    @Environment(ThemeEngine.self) private var themeEngine
    @Bindable var sessionVM: SessionViewModel
    let world: World

    @State private var promptText: String = ""
    @State private var editingExchange: Exchange?
    @State private var hoveredExchangeID: Exchange.ID?
    @State private var viewingRawExchange: Exchange?
    @State private var showingClearConfirmation: Bool = false
    @State private var chapterTitleEditing: Exchange?
    @State private var branchFromExchange: Exchange?

    var body: some View {
        VStack(spacing: 0) {
            // Dialogue scroll
            ScrollViewReader { proxy in
                ScrollView {
                    if sessionVM.sortedExchanges.isEmpty && !sessionVM.isGenerating {
                        emptyState
                    } else {
                        LazyVStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                            ForEach(sessionVM.sortedExchanges) { exchange in
                                exchangeGroup(for: exchange)
                                    .id(exchange.persistentModelID)
                            }
                        }
                        .padding()
                    }
                }
                .onChange(of: sessionVM.sortedExchanges.count) {
                    if let last = sessionVM.sortedExchanges.last {
                        withAnimation {
                            proxy.scrollTo(last.persistentModelID, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: sessionVM.streamingText) {
                    if let target = sessionVM.currentStreamingTarget {
                        withAnimation {
                            proxy.scrollTo(target.persistentModelID, anchor: .bottom)
                        }
                    }
                }
            }

            // Error message
            if let error = sessionVM.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Dismiss") {
                        sessionVM.errorMessage = nil
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }

            // Prompt input
            PromptInputView(
                text: $promptText,
                isGenerating: sessionVM.isGenerating,
                onSend: {
                    let text = promptText
                    promptText = ""
                    sessionVM.sendPrompt(text, world: world)
                },
                onCancel: {
                    sessionVM.cancelGeneration()
                }
            )

            // Canvas bottom bar — kept lean; resource info lives in the
            // window-level ResourceStatusBar.
            if hasNonCommittedExchanges {
                HStack {
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear Non-Committed", systemImage: "eraser.line.dashed")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
                    Spacer()
                }
                .padding(.bottom, 4)
            }
        }
        .sheet(item: $viewingRawExchange) { exchange in
            RawResponseSheet(exchange: exchange) {
                viewingRawExchange = nil
            }
        }
        .sheet(item: $editingExchange) { exchange in
            ExchangeEditorSheet(
                exchange: exchange,
                onSave: { newContent in
                    sessionVM.updateExchangeContent(exchange, newContent: newContent)
                    editingExchange = nil
                },
                onCancel: {
                    editingExchange = nil
                }
            )
        }
        .sheet(item: $chapterTitleEditing) { exchange in
            ChapterTitleSheet(
                exchange: exchange,
                onSave: { title in
                    sessionVM.setChapterTitle(exchange, title: title)
                    chapterTitleEditing = nil
                },
                onCancel: { chapterTitleEditing = nil }
            )
        }
        .alert("Clear Non-Committed Exchanges?", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                sessionVM.clearNonCommitted()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let count = sessionVM.sortedExchanges.filter({ !$0.committed }).count
            Text("This will delete \(count) uncommitted exchange\(count == 1 ? "" : "s"). This cannot be undone.")
        }
        .alert(
            "Regenerate from Here?",
            isPresented: .init(
                get: { branchFromExchange != nil },
                set: { if !$0 { branchFromExchange = nil } }
            ),
            presenting: branchFromExchange
        ) { exchange in
            Button("Regenerate", role: .destructive) {
                sessionVM.branchFromHere(exchange)
                branchFromExchange = nil
            }
            Button("Cancel", role: .cancel) {
                branchFromExchange = nil
            }
        } message: { exchange in
            let count = exchangeCountAfter(exchange)
            Text("This will hide the \(count) exchange\(count == 1 ? "" : "s") that came after this one and re-roll the assistant's response. The hidden exchanges remain in the database but will no longer appear in the canvas or manuscript.")
        }
    }

    // MARK: - Exchange Group (bubbles + action bar on hover)

    @ViewBuilder
    private func exchangeGroup(for exchange: Exchange) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if exchange.isChapterStart {
                chapterDivider(for: exchange)
            }

            // Render the exchange content
            exchangeContent(for: exchange)

            // Action bar — only visible on hover
            if hoveredExchangeID == exchange.id {
                exchangeActionBar(for: exchange)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredExchangeID = hovering ? exchange.id : nil
            }
        }
        .contextMenu {
            Button {
                sessionVM.toggleChapterMarker(exchange)
            } label: {
                Label(
                    exchange.isChapterStart ? "Remove Chapter Break" : "Mark Chapter Break Here",
                    systemImage: exchange.isChapterStart ? "book.closed" : "book"
                )
            }
            Button {
                chapterTitleEditing = exchange
            } label: {
                let hasTitle = exchange.chapterTitle.flatMap { $0.isEmpty ? nil : $0 } != nil
                Label(
                    hasTitle ? "Edit Chapter Title…" : "Set Chapter Title…",
                    systemImage: "textformat"
                )
            }
            if exchange.role == "assistant" {
                Divider()
                Button {
                    sessionVM.regenerate(exchange)
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
                .disabled(sessionVM.isGenerating)

                if exchangeCountAfter(exchange) > 0 {
                    Button {
                        branchFromExchange = exchange
                    } label: {
                        Label("Regenerate from Here…", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(sessionVM.isGenerating)
                }
            }
        }
    }

    private func chapterDivider(for exchange: Exchange) -> some View {
        let label = exchange.chapterTitle.flatMap { $0.isEmpty ? nil : $0 } ?? "Chapter Break"
        return HStack(spacing: 8) {
            VStack { Divider() }
            Image(systemName: "book.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack { Divider() }
        }
        .padding(.vertical, 8)
    }

    private func exchangeCountAfter(_ exchange: Exchange) -> Int {
        let visible = sessionVM.sortedExchanges
        guard let idx = visible.firstIndex(where: { $0 === exchange }) else { return 0 }
        return max(0, visible.count - idx - 1)
    }

    @ViewBuilder
    private func exchangeContent(for exchange: Exchange) -> some View {
        let isStreamingTarget = (exchange === sessionVM.currentStreamingTarget)

        if exchange.role == "user" {
            if let charName = exchange.characterName {
                // User playing as a character — show their avatar, right-aligned
                ExchangeBubbleView(
                    role: "user",
                    content: exchange.content,
                    isCommitted: exchange.committed,
                    characterName: charName,
                    characterImageData: characterImage(for: charName)
                )
            } else {
                ExchangeBubbleView(exchange: exchange)
            }
        } else if isStreamingTarget {
            // Live token stream lands here, in-place at the bubble's eventual
            // position. Strip [Tag] prefixes so the preview reads cleanly.
            let cleanedText = sessionVM.streamingText
                .replacingOccurrences(of: #"\[[^\]]+\]\s*"#, with: "", options: .regularExpression)
            ExchangeBubbleView(
                role: "assistant",
                content: cleanedText,
                isCommitted: exchange.committed,
                isStreaming: true,
                characterName: exchange.characterName,
                characterImageData: characterImage(for: exchange.characterName)
            )
        } else {
            // Try structured parsing (works for any count of characters)
            let names = (exchange.characterName ?? "")
                .components(separatedBy: " & ")
                .filter { !$0.isEmpty }
            if let segments = ResponseParser.parseSegments(from: exchange.content, speakingNames: names) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let prev = index > 0 ? segments[index - 1] : nil
                    let isContinuation = segment.type == .character
                        && prev?.type == .character
                        && prev?.characterName == segment.characterName
                    ExchangeBubbleView(
                        role: "assistant",
                        content: segment.content,
                        isCommitted: exchange.committed,
                        characterName: segment.type == .character ? segment.characterName : nil,
                        characterImageData: segment.type == .character ? characterImage(for: segment.characterName) : nil,
                        isNarration: segment.type == .narration,
                        isAction: segment.type == .action,
                        isContinuation: isContinuation
                    )
                }
            } else {
                // No tags found — render as plain character bubble
                ExchangeBubbleView(
                    exchange: exchange,
                    characterImageData: characterImage(for: exchange.characterName)
                )
            }
        }
    }

    private func exchangeActionBar(for exchange: Exchange) -> some View {
        HStack(spacing: 8) {
            if exchange.role == "assistant" {
                Button {
                    sessionVM.regenerate(exchange)
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .disabled(sessionVM.isGenerating)

                let group = sessionVM.siblings(of: exchange)
                if group.count > 1 {
                    siblingNavigator(for: exchange, group: group)
                }
            }

            Spacer()

            Button {
                sessionVM.toggleCommitted(exchange)
            } label: {
                Label(
                    exchange.committed ? "Committed" : "Commit",
                    systemImage: exchange.committed ? "lock.fill" : "lock.open"
                )
                .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(exchange.committed ? themeEngine.committedAccent : .secondary)

            Button {
                editingExchange = exchange
            } label: {
                Label("Edit", systemImage: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Button {
                sessionVM.deleteExchange(exchange)
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red.opacity(0.7))

            if exchange.role == "assistant" {
                Button {
                    viewingRawExchange = exchange
                } label: {
                    Label("View Raw", systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private func siblingNavigator(for exchange: Exchange, group: [Exchange]) -> some View {
        let activeIndex = group.firstIndex(where: { $0 === exchange }) ?? 0
        let canPrev = activeIndex > 0
        let canNext = activeIndex < group.count - 1

        return HStack(spacing: 4) {
            Button {
                if canPrev { sessionVM.setActiveSibling(group[activeIndex - 1]) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(canPrev ? .secondary : .tertiary)
            .disabled(!canPrev || sessionVM.isGenerating)

            Text("\(activeIndex + 1) / \(group.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                if canNext { sessionVM.setActiveSibling(group[activeIndex + 1]) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(canNext ? .secondary : .tertiary)
            .disabled(!canNext || sessionVM.isGenerating)
        }
    }

    private var hasNonCommittedExchanges: Bool {
        sessionVM.sortedExchanges.contains { !$0.committed }
    }

    // MARK: - Character Image Resolution

    private func characterImage(for name: String?) -> Data? {
        guard let name, !name.isEmpty else { return nil }
        if let exact = world.characters.first(where: { $0.name == name }) {
            return exact.imageData
        }
        // Fallback: resolve via the same prefix-match logic ResponseParser
        // uses for tag attribution. Keeps avatar lookup and tag attribution
        // on the same matching rule so a renamed character can't drift one
        // and not the other.
        let canonicalNames = world.characters.map(\.name)
        guard let resolved = ResponseParser.resolveCharacterTag(name, speakingNames: canonicalNames) else {
            return nil
        }
        return world.characters.first(where: { $0.name == resolved })?.imageData
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text("Begin Your Story")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Select a location and character from the sidebar,\nthen type your first line below.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Exchange Editor Sheet

private struct ExchangeEditorSheet: View {
    @Environment(ThemeEngine.self) private var themeEngine
    let exchange: Exchange
    var onSave: (String) -> Void
    var onCancel: () -> Void

    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Edit Exchange")
                    .font(.headline)
                Spacer()
                if let name = exchange.characterName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            TextEditor(text: $text)
                .font(exchange.role == "user" ? .body : themeEngine.manuscriptFont)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(.tertiary)
                )

            HStack {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save") { onSave(text) }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 200)
        .onAppear { text = exchange.content }
    }
}

// MARK: - Chapter Title Sheet

private struct ChapterTitleSheet: View {
    let exchange: Exchange
    var onSave: (String?) -> Void
    var onCancel: () -> Void

    @State private var title: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Chapter Title")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("e.g. The Storm Breaks", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onSave(title) }

            Text("This exchange will be marked as a chapter break. Leave the title blank to use \"Chapter N\".")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save") { onSave(title) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(minWidth: 360, minHeight: 160)
        .onAppear { title = exchange.chapterTitle ?? "" }
    }
}

// MARK: - Raw Response Sheet

private struct RawResponseSheet: View {
    let exchange: Exchange
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Raw LLM Response")
                    .font(.headline)
                Spacer()
                if let name = exchange.characterName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView {
                Text(exchange.content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 120)
            .padding(8)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))

            HStack {
                Text("\(exchange.content.count) characters")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Done") { onDismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 250)
    }
}
