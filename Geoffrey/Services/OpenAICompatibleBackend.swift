import Foundation

/// Generalised OpenAI-compatible backend. Supports LM Studio, Ollama,
/// llama.cpp server, and the OpenAI spec itself by branching the request
/// body on `Variant`. The wire endpoint is `/v1/chat/completions` for all
/// variants — only the sampling-penalty fields differ.
///
/// All backends in Geoffrey today flow through this type. Profiles
/// instantiate it via `InferenceProfile.makeBackend()` and the registry
/// caches the result.
actor OpenAICompatibleBackend: InferenceBackend {

    /// Wire-shape variant. Local-server variants use llama.cpp's
    /// `repetition_penalty`; the OpenAI spec uses `frequency_penalty` +
    /// `presence_penalty`. Default sampling values for each variant track
    /// the upstream defaults.
    enum Variant: String, Codable, Sendable, CaseIterable {
        case lmStudio
        case ollama
        case llamaCppServer
        case openAISpec

        var displayName: String {
            switch self {
            case .lmStudio: "LM Studio"
            case .ollama: "Ollama"
            case .llamaCppServer: "llama.cpp server"
            case .openAISpec: "OpenAI-compatible"
            }
        }

        var defaultBaseURL: URL {
            switch self {
            case .lmStudio: URL(string: "http://127.0.0.1:1234")!
            case .ollama: URL(string: "http://127.0.0.1:11434")!
            case .llamaCppServer: URL(string: "http://127.0.0.1:8080")!
            case .openAISpec: URL(string: "https://api.openai.com")!
            }
        }

        var requiresAPIKey: Bool {
            switch self {
            case .lmStudio, .ollama, .llamaCppServer: false
            case .openAISpec: true
            }
        }

        var usesRepetitionPenalty: Bool {
            switch self {
            case .lmStudio, .ollama, .llamaCppServer: true
            case .openAISpec: false
            }
        }
    }

    nonisolated let displayName: String
    let variant: Variant

    var baseURL: URL
    var modelName: String?
    var apiKey: String?
    var temperature: Double
    var maxTokens: Int
    var topP: Double

    /// `1.0` is "off" in llama.cpp's repetition penalty. Used by
    /// `lmStudio`, `ollama`, `llamaCppServer`. Ignored by `openAISpec`.
    var repetitionPenalty: Double

    /// `0.0` is "off" in OpenAI's spec. Used by `openAISpec`. Ignored by
    /// the local-server variants.
    var frequencyPenalty: Double
    var presencePenalty: Double

    /// Latency telemetry surfaced to `ResourceMonitor` / `ResourceStatusBar`.
    /// Recorded from inside the streaming Task; nil before the first call.
    private(set) var lastFirstTokenLatency: TimeInterval?
    private(set) var lastTotalLatency: TimeInterval?

    private let session: URLSession

    func isAvailable() async -> Bool { await checkHealth() }

    init(
        variant: Variant,
        baseURL: URL? = nil,
        modelName: String? = nil,
        apiKey: String? = nil,
        temperature: Double = 0.8,
        maxTokens: Int = 2048,
        topP: Double = 0.95,
        repetitionPenalty: Double = 1.1,
        frequencyPenalty: Double = 0.0,
        presencePenalty: Double = 0.0
    ) {
        self.variant = variant
        self.displayName = variant.displayName
        self.baseURL = baseURL ?? variant.defaultBaseURL
        self.modelName = modelName
        self.apiKey = apiKey
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.repetitionPenalty = repetitionPenalty
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.session = URLSession(configuration: .default)
    }

    func updateSettings(
        baseURL: URL? = nil,
        modelName: String? = nil,
        apiKey: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        repetitionPenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil
    ) {
        if let baseURL { self.baseURL = baseURL }
        if let modelName { self.modelName = modelName }
        if let apiKey { self.apiKey = apiKey }
        if let temperature { self.temperature = temperature }
        if let maxTokens { self.maxTokens = maxTokens }
        if let topP { self.topP = topP }
        if let repetitionPenalty { self.repetitionPenalty = repetitionPenalty }
        if let frequencyPenalty { self.frequencyPenalty = frequencyPenalty }
        if let presencePenalty { self.presencePenalty = presencePenalty }
    }

    private func apiURL(_ path: String) -> URL {
        var base = baseURL.absoluteString
        if base.hasSuffix("/") { base = String(base.dropLast()) }
        return URL(string: base + path)!
    }

    private func authHeader() -> (key: String, value: String)? {
        guard let apiKey, !apiKey.isEmpty else { return nil }
        return ("Authorization", "Bearer \(apiKey)")
    }

    func checkHealth() async -> Bool {
        let url = apiURL("/v1/models")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        if let auth = authHeader() {
            request.setValue(auth.value, forHTTPHeaderField: auth.key)
        }
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func fetchModels() async throws -> [String] {
        let url = apiURL("/v1/models")
        var request = URLRequest(url: url)
        if let auth = authHeader() {
            request.setValue(auth.value, forHTTPHeaderField: auth.key)
        }
        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["data"] as? [[String: Any]] else {
            return []
        }
        return models.compactMap { $0["id"] as? String }
    }

    /// Sends a structured prompt that asks the model to emit Geoffrey's
    /// `[Narrator]` / `[CharacterName]` paragraph tags, then inspects the
    /// response. Used by the onboarding flow to confirm the configured
    /// model can follow the response format Geoffrey relies on.
    func testFormatCompliance() async throws -> FormatTestResult {
        let testMessages: [ChatMessage] = [
            ChatMessage(role: "user", content: """
                RESPONSE FORMAT TEST. You must tag every paragraph. Use [Narrator] for scene description. Use [CharacterName] for character dialogue or actions. Write exactly 3 tagged paragraphs about two characters named Alice and Bob meeting in a library. Example format:
                [Narrator] Description here.
                [Alice] Dialogue or action here.
                [Bob] Dialogue or action here.
                """),
            ChatMessage(role: "assistant", content: "Understood. I will follow the tagging format exactly.")
        ]

        let url = apiURL("/v1/chat/completions")
        var body = chatBody(messages: testMessages, stream: false)
        body["temperature"] = 0.7
        body["max_tokens"] = 512
        let auth = authHeader()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        if let auth {
            request.setValue(auth.value, forHTTPHeaderField: auth.key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw InferenceError.badResponse
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw InferenceError.badResponse
        }

        let hasNarratorTag = content.contains("[Narrator]")
        let hasAliceTag = content.contains("[Alice]")
        let hasBobTag = content.contains("[Bob]")
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let passed = hasContent && (hasNarratorTag || hasAliceTag || hasBobTag)
        let tagCount = [hasNarratorTag, hasAliceTag, hasBobTag].filter { $0 }.count

        return FormatTestResult(
            passed: passed,
            response: content,
            hasNarratorTag: hasNarratorTag,
            hasCharacterTags: hasAliceTag && hasBobTag,
            tagCount: tagCount
        )
    }

    /// Variant-aware request body. The local-server variants emit
    /// `repetition_penalty`; the OpenAI spec emits `frequency_penalty` +
    /// `presence_penalty`. Skipping the wrong fields keeps strict servers
    /// (e.g., the OpenAI gateway) from 400-ing on unknown keys.
    private func chatBody(messages: [ChatMessage], stream: Bool) -> [String: Any] {
        var body: [String: Any] = [
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": stream,
            "temperature": temperature,
            "max_tokens": maxTokens,
            "top_p": topP
        ]
        if variant.usesRepetitionPenalty {
            body["repetition_penalty"] = repetitionPenalty
        } else {
            body["frequency_penalty"] = frequencyPenalty
            body["presence_penalty"] = presencePenalty
        }
        if let modelName, !modelName.isEmpty {
            body["model"] = modelName
        }
        return body
    }

    func complete(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        let url = apiURL("/v1/chat/completions")
        let body = chatBody(messages: messages, stream: true)
        let auth = authHeader()
        let urlSession = session

        return AsyncThrowingStream { continuation in
            Task {
                let startedAt = Date()
                var firstTokenSeen = false
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let auth {
                        request.setValue(auth.value, forHTTPHeaderField: auth.key)
                    }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await urlSession.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw InferenceError.badResponse
                    }
                    switch httpResponse.statusCode {
                    case 200: break
                    case 401, 403: throw InferenceError.unauthorized
                    case 429: throw InferenceError.rateLimited
                    default: throw InferenceError.badResponse
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }

                        if !firstTokenSeen {
                            firstTokenSeen = true
                            self.recordFirstTokenLatency(Date().timeIntervalSince(startedAt))
                        }
                        continuation.yield(content)
                    }

                    self.recordTotalLatency(Date().timeIntervalSince(startedAt))
                    continuation.finish()
                } catch {
                    self.recordTotalLatency(Date().timeIntervalSince(startedAt))
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func recordFirstTokenLatency(_ latency: TimeInterval) {
        lastFirstTokenLatency = latency
    }

    private func recordTotalLatency(_ latency: TimeInterval) {
        lastTotalLatency = latency
    }
}
