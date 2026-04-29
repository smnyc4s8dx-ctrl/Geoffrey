import Foundation

/// Wire-format chat message shared by every backend conforming to
/// `InferenceBackend`. Lives here (not on a single concrete client) so
/// multiple backends can share the type without circular ownership.
struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

/// Protocol for any inference backend (local OpenAI-compatible server,
/// cloud API, on-device model). Per LEDGER capability (l).
///
/// `OpenAICompatibleBackend` is the current concrete type, covering
/// LM Studio / Ollama / llama.cpp server / OpenAI-spec via its variant
/// branching. Future implementations (`AnthropicBackend`,
/// `FoundationModelsBackend`) plug into the same call sites.
///
/// Helper-only capabilities (e.g., structured extraction for capability d)
/// live on the separate `StructuredExtractionCapable` protocol so backends
/// that can't reasonably support them (a streaming chat-completions
/// endpoint) aren't forced to throw at runtime.
protocol InferenceBackend: Actor {
    /// User-facing label for status bars and profile pickers.
    nonisolated var displayName: String { get }

    /// Lightweight reachability probe. Cheap; called by `ConnectionMonitor`
    /// every few seconds.
    func isAvailable() async -> Bool

    /// Stream chat-completion tokens for a message thread.
    func complete(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

/// Optional capability for backends that can return well-typed structured
/// output (e.g., Foundation Models guided generation, OpenAI tool-calling
/// JSON, Anthropic structured output). Capability (d) card-bound mutations
/// will route through this when a helper backend is configured.
protocol StructuredExtractionCapable {
    func extractStructured<T: Decodable>(prompt: String, schema: T.Type) async throws -> T
}

/// Result of a format-compliance probe (see
/// `OpenAICompatibleBackend.testFormatCompliance`). Used by the
/// onboarding flow to confirm the configured model can emit Geoffrey's
/// `[Narrator]` / `[CharacterName]` paragraph tags.
struct FormatTestResult {
    let passed: Bool
    let response: String
    let hasNarratorTag: Bool
    let hasCharacterTags: Bool
    let tagCount: Int

    var summary: String {
        if passed && hasNarratorTag && hasCharacterTags {
            return "Model follows Geoffrey's format correctly."
        } else if passed {
            return "Model partially follows the format. Some tags may be missing."
        } else if response.isEmpty {
            return "Model returned an empty response. It may not support this prompt style."
        } else {
            return "Model does not follow the required tagging format. Consider using a different model."
        }
    }
}

/// Backend-agnostic error surface. Concrete backends throw these for the
/// common failure modes; profile UI and status bar consume the
/// `errorDescription` for display.
enum InferenceError: LocalizedError {
    case badResponse
    case connectionFailed
    case unauthorized
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .badResponse: "Received an invalid response from the inference server."
        case .connectionFailed: "Could not connect to the inference server."
        case .unauthorized: "Authentication failed (check API key)."
        case .rateLimited: "Rate limit exceeded — slow down or upgrade the plan."
        }
    }
}
