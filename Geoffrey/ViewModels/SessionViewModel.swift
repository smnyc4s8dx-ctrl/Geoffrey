import Foundation
import SwiftData
import Observation

/// `@MainActor`-pinned because SwiftUI views read every property here
/// during body evaluation, while the streaming task mutates
/// `streamingText`, `isGenerating`, and `errorMessage` from the
/// `AsyncThrowingStream` continuation — which has no guaranteed
/// executor. The pin keeps all mutations serialized on main; the
/// streaming loop's `await` between tokens yields the main thread so
/// the UI stays responsive while accumulating output.
@MainActor
@Observable
final class SessionViewModel {
    var currentSession: Session? {
        didSet { didMutateExchanges() }
    }
    var streamingText: String = ""
    var isGenerating: Bool = false
    var directorsNote: String = "" {
        didSet { invalidateTokenCount() }
    }
    var errorMessage: String?

    // Narrative mode
    var narrativeMode: NarrativeMode = .director
    var playerCharacter: StoryCharacter?

    /// Scene state (location / characters / lore) lives on
    /// `SceneInspectorViewModel`; this VM reads from it at call time
    /// rather than maintaining a synced copy. Same `MainView` owns both,
    /// so lifetimes match. Weak to avoid retaining the inspector if the
    /// dependency is ever re-pointed; nil during the brief window between
    /// the two VMs being constructed in `MainView.initializeViewModels()`.
    weak var inspectorVM: SceneInspectorViewModel?

    private var modelContext: ModelContext
    private let backendRegistry: BackendRegistry
    private let assembler = ContextAssembler()
    private var streamingTask: Task<Void, Never>?
    private(set) var currentStreamingTarget: Exchange?

    /// Always read through the registry so profile activations in
    /// Settings take effect on the next call without restarting any
    /// view models.
    private var client: any InferenceBackend { backendRegistry.mainBackend }

    /// `estimatedTokenCount` is read from `DialogueCanvasView.body`, which
    /// re-evaluates on every `streamingText` mutation — i.e., once per
    /// streamed token. The cache below avoids rebuilding the full message
    /// array (and re-sorting exchanges) on each tick. Invalidated at every
    /// known mutation that affects the token count: scene/inspector state
    /// changes, exchange list changes, director's-note edits, session
    /// switch. `streamingText` itself is *not* in the dependency set —
    /// the in-flight assistant message isn't included until it's saved.
    @ObservationIgnored private var _cachedTokenCount: Int = 0
    @ObservationIgnored private var _tokenCacheValid: Bool = false

    /// `sortedExchanges` is read 5–6× per `DialogueCanvasView` body pass
    /// (`ForEach`, `onChange`, `last`, alert count, `hasNonCommitted`,
    /// empty check). Each access re-sorted the underlying SwiftData
    /// relationship — fine for one body pass, expensive when body
    /// re-evaluates per streamed token. The cache invalidates on
    /// exchange insert/delete/edit/commit-toggle and session switch.
    @ObservationIgnored private var _cachedSortedExchanges: [Exchange] = []
    @ObservationIgnored private var _exchangesCacheValid: Bool = false

    /// Public because `SceneInspectorViewModel` calls back here when scene
    /// state mutates — that affects the count but not the exchange list.
    func invalidateTokenCount() {
        _tokenCacheValid = false
    }

    /// Called from every code path that adds, removes, edits, or
    /// commit-toggles an exchange, plus from the `currentSession` didSet.
    /// Both caches are affected by exchange-list mutations, so they
    /// invalidate together — one helper means future mutation paths
    /// can't forget to bump one of them.
    private func didMutateExchanges() {
        _tokenCacheValid = false
        _exchangesCacheValid = false
    }

    init(modelContext: ModelContext, backendRegistry: BackendRegistry) {
        self.modelContext = modelContext
        self.backendRegistry = backendRegistry
    }

    func ensureSession(for world: World) {
        guard currentSession == nil else { return }

        // Resume the most recent existing session for this world
        if let existing = world.sessions.sorted(by: { $0.startedAt > $1.startedAt }).first {
            currentSession = existing
            return
        }

        let session = Session()
        session.world = world
        modelContext.insert(session)
        try? modelContext.save()
        currentSession = session
    }

    func sendPrompt(_ text: String, world: World) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !isGenerating else { return }

        ensureSession(for: world)
        guard let session = currentSession else { return }

        let nextIndex = (session.exchanges.map(\.orderIndex).max() ?? -1) + 1
        let userCharName: String? = narrativeMode == .character ? playerCharacter?.name : nil
        let framedPrompt = framePrompt(text, characterName: userCharName)

        // Build context BEFORE inserting either exchange to avoid double-counting.
        let messages = buildContextMessages(world: world, userPrompt: framedPrompt)

        let speakingNames: String? = {
            let names = (inspectorVM?.speakingCharacters ?? []).map(\.name)
            return names.isEmpty ? nil : names.joined(separator: " & ")
        }()

        let userExchange = Exchange(role: "user", content: text, orderIndex: nextIndex, characterName: userCharName)
        userExchange.session = session
        modelContext.insert(userExchange)

        let assistantExchange = Exchange(
            role: "assistant",
            content: "",
            orderIndex: nextIndex + 1,
            characterName: speakingNames,
            alternateActive: true
        )
        assistantExchange.session = session
        modelContext.insert(assistantExchange)
        try? modelContext.save()
        didMutateExchanges()

        startStream(messages: messages, into: assistantExchange)
    }

    private func framePrompt(_ text: String, characterName: String?) -> String {
        if let name = characterName {
            return "[\(name)] \(text)"
        }
        switch narrativeMode {
        case .director: return "[Director's Cue] \(text)"
        case .author: return text
        case .character:
            if let pc = playerCharacter { return "[\(pc.name)] \(text)" }
            return text
        case .gameMaster: return "[Narrator] \(text)"
        }
    }

    private func startStream(messages: [ChatMessage], into target: Exchange) {
        isGenerating = true
        streamingText = ""
        errorMessage = nil
        currentStreamingTarget = target

        streamingTask = Task { @MainActor in
            var accumulated = ""
            do {
                let stream = await client.complete(messages: messages)
                for try await token in stream {
                    accumulated += token
                    streamingText = accumulated
                }
                finalizeStream(accumulated, into: target, error: nil, cancelled: false)
            } catch {
                let cancelled = Task.isCancelled || (error is CancellationError)
                finalizeStream(accumulated, into: target, error: cancelled ? nil : error, cancelled: cancelled)
            }
        }
    }

    private func finalizeStream(_ accumulated: String, into target: Exchange, error: Error?, cancelled: Bool) {
        let trimmed = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            modelContext.delete(target)
            if let error {
                errorMessage = error.localizedDescription
            } else if !cancelled {
                errorMessage = "The model returned an empty response. Try rephrasing your prompt."
            }
        } else {
            target.content = trimmed
            // Activate this sibling, deactivate prior alternates in the same group.
            let group = siblings(of: target)
            for s in group {
                s.alternateActive = (s === target)
            }
            if let error {
                errorMessage = error.localizedDescription
            }
        }
        try? modelContext.save()
        didMutateExchanges()
        streamingText = ""
        currentStreamingTarget = nil
        streamingTask = nil
        isGenerating = false
    }

    func cancelGeneration() {
        streamingTask?.cancel()
        // finalizeStream runs from the stream task's catch block and preserves the partial.
    }

    // MARK: - Sibling Alternates

    private func anchor(of exchange: Exchange) -> Exchange {
        exchange.retconnedFrom ?? exchange
    }

    func siblings(of exchange: Exchange) -> [Exchange] {
        guard let session = currentSession else { return [exchange] }
        let target = anchor(of: exchange)
        return session.exchanges
            .filter { anchor(of: $0) === target }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func setActiveSibling(_ exchange: Exchange) {
        let group = siblings(of: exchange)
        for s in group {
            s.alternateActive = (s === exchange)
        }
        try? modelContext.save()
        didMutateExchanges()
    }

    func regenerate(_ exchange: Exchange) {
        guard !isGenerating, let session = currentSession, let world = session.world else { return }
        guard exchange.role == "assistant" else { return }

        let visible = sortedExchanges
        guard let idx = visible.firstIndex(where: { $0 === exchange }), idx > 0 else { return }
        let priorUser = visible[idx - 1]
        guard priorUser.role == "user" else { return }

        let priorDialogue = Array(visible.prefix(idx - 1))
        let framedPrompt = framePrompt(priorUser.content, characterName: priorUser.characterName)
        let messages = buildContextMessages(
            world: world,
            userPrompt: framedPrompt,
            exchanges: priorDialogue
        )

        let anchorEx = anchor(of: exchange)
        let newSibling = Exchange(
            role: "assistant",
            content: "",
            orderIndex: exchange.orderIndex,
            characterName: exchange.characterName,
            retconnedFrom: anchorEx,
            alternateActive: false
        )
        newSibling.session = session
        modelContext.insert(newSibling)
        try? modelContext.save()
        didMutateExchanges()

        startStream(messages: messages, into: newSibling)
    }

    func branchFromHere(_ exchange: Exchange) {
        // Hide post-N exchanges (recoverable: alternateActive=false, data preserved),
        // then regenerate at this exchange. v1 caveat: hidden chain isn't yet
        // re-reachable via swipe — restoring requires future tooling.
        guard !isGenerating, exchange.role == "assistant" else { return }
        let visible = sortedExchanges
        guard let idx = visible.firstIndex(where: { $0 === exchange }) else { return }
        for ex in visible.suffix(from: idx + 1) {
            ex.alternateActive = false
        }
        try? modelContext.save()
        didMutateExchanges()
        regenerate(exchange)
    }

    var sortedExchanges: [Exchange] {
        if _exchangesCacheValid { return _cachedSortedExchanges }
        guard let session = currentSession else {
            _cachedSortedExchanges = []
            _exchangesCacheValid = true
            return []
        }
        let all = session.exchanges.sorted { $0.orderIndex < $1.orderIndex }
        var seen = Set<ObjectIdentifier>()
        var result: [Exchange] = []
        for ex in all {
            let group = siblings(of: ex)
            // Prefer the in-flight streaming target as the active take so live
            // tokens appear in-place during regen.
            let chosen: Exchange?
            if let target = currentStreamingTarget, group.contains(where: { $0 === target }) {
                chosen = target
            } else {
                chosen = group.last(where: \.alternateActive)
            }
            guard let active = chosen else { continue }
            if seen.insert(ObjectIdentifier(active)).inserted {
                result.append(active)
            }
        }
        _cachedSortedExchanges = result
        _exchangesCacheValid = true
        return result
    }

    // MARK: - Exchange Management

    func deleteExchange(_ exchange: Exchange) {
        modelContext.delete(exchange)
        try? modelContext.save()
        didMutateExchanges()
    }

    func updateExchangeContent(_ exchange: Exchange, newContent: String) {
        exchange.content = newContent
        try? modelContext.save()
        didMutateExchanges()
    }

    func toggleCommitted(_ exchange: Exchange) {
        exchange.committed.toggle()
        try? modelContext.save()
        didMutateExchanges()
    }

    func clearNonCommitted() {
        let toDelete = sortedExchanges.filter { !$0.committed }
        for exchange in toDelete {
            modelContext.delete(exchange)
        }
        try? modelContext.save()
        didMutateExchanges()
    }

    func toggleChapterMarker(_ exchange: Exchange) {
        exchange.isChapterStart.toggle()
        if !exchange.isChapterStart { exchange.chapterTitle = nil }
        try? modelContext.save()
    }

    func setChapterTitle(_ exchange: Exchange, title: String?) {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        exchange.chapterTitle = (trimmed?.isEmpty == false) ? trimmed : nil
        if exchange.chapterTitle != nil { exchange.isChapterStart = true }
        try? modelContext.save()
    }

    var estimatedTokenCount: Int {
        if _tokenCacheValid { return _cachedTokenCount }
        guard let session = currentSession,
              let world = session.world else {
            _cachedTokenCount = 0
            _tokenCacheValid = true
            return 0
        }
        let messages = buildContextMessages(world: world, userPrompt: "")
        _cachedTokenCount = TokenEstimator.estimate(messages: messages)
        _tokenCacheValid = true
        return _cachedTokenCount
    }

    private func buildContextMessages(
        world: World,
        userPrompt: String,
        exchanges: [Exchange]? = nil
    ) -> [ChatMessage] {
        let scenePresent = inspectorVM?.presentCharacters ?? []
        let sceneSpeaking = inspectorVM?.speakingCharacters ?? []
        let sceneLore = inspectorVM?.activeLoreCards ?? []

        let locationCtx: LocationContext? = inspectorVM?.activeLocation.map {
            LocationContext(
                name: $0.name,
                stateLabel: $0.stateLabel,
                descriptionText: $0.descriptionText,
                conditionDescription: $0.conditionDescription,
                atmosphere: $0.atmosphere
            )
        }

        let characterCtxs: [CharacterContext] = scenePresent.map { char in
            CharacterContext(
                name: char.name,
                role: char.role,
                persona: char.persona,
                voiceSample: char.voiceSample,
                psychologicalState: char.psychologicalState,
                knowledgeState: char.knowledgeState,
                roleplayPosture: char.roleplayPosture,
                relationships: char.relationships.map {
                    RelationshipContext(
                        targetName: $0.targetCharacterName,
                        description: $0.relationshipDescription
                    )
                }
            )
        }

        let speakingNames = sceneSpeaking.map(\.name)

        let loreCtxs: [LoreContext] = sceneLore.map { lore in
            LoreContext(
                title: lore.title,
                content: lore.content,
                priorityOrder: lore.priority == .high ? 0 : lore.priority == .normal ? 1 : 2
            )
        }

        let exchangeList = exchanges ?? sortedExchanges
        let committed = exchangeList.filter(\.committed).map {
            ExchangeContext(role: $0.role, content: $0.content)
        }
        let working = exchangeList.filter { !$0.committed }.map {
            ExchangeContext(role: $0.role, content: $0.content)
        }

        return assembler.assemble(
            systemPreamble: world.systemPreamble,
            location: locationCtx,
            loreCards: loreCtxs,
            characters: characterCtxs,
            speakingCharacterNames: speakingNames,
            committedExchanges: committed,
            workingDialogue: working,
            directorsNote: directorsNote.isEmpty ? nil : directorsNote,
            userPrompt: userPrompt
        )
    }
}
