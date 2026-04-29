import Foundation
import SwiftData

/// Saved inference-backend bundle. A profile names a specific backend
/// (LM Studio on the laptop, Ollama on the studio Mac LAN, OpenAI cloud,
/// etc.) plus its connection details and sampling parameters.
///
/// Per LEDGER capability (l), profiles split into two roles:
/// - **main** drives story generation (the active "writing" model).
/// - **helper** runs structured-extraction passes for capability (d) and
///   semantic-trigger evaluation for capability (g). Helper is optional;
///   when absent, those features either gracefully degrade (g) or
///   become unavailable (d).
///
/// Exactly one profile per role is `isActive` at a time. The
/// `BackendRegistry` enforces this invariant at switch time.
@Model
final class InferenceProfile {
    var id: UUID
    var name: String
    var createdAt: Date

    /// Raw value of `OpenAICompatibleBackend.Variant`. Stored as a string
    /// for SwiftData stability across enum reorderings.
    var backendVariantRaw: String

    /// Raw value of `Role` (main / helper).
    var roleRaw: String

    var baseURL: String
    var modelName: String?
    var apiKey: String?

    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var repetitionPenalty: Double
    var frequencyPenalty: Double
    var presencePenalty: Double

    var contextWindow: Int

    /// Only one profile per role is active. The registry enforces this.
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        variant: OpenAICompatibleBackend.Variant,
        role: Role,
        baseURL: String,
        modelName: String? = nil,
        apiKey: String? = nil,
        temperature: Double = 0.8,
        maxTokens: Int = 2048,
        topP: Double = 0.95,
        repetitionPenalty: Double = 1.1,
        frequencyPenalty: Double = 0.0,
        presencePenalty: Double = 0.0,
        contextWindow: Int = 8192,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = .now
        self.backendVariantRaw = variant.rawValue
        self.roleRaw = role.rawValue
        self.baseURL = baseURL
        self.modelName = modelName
        self.apiKey = apiKey
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.repetitionPenalty = repetitionPenalty
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.contextWindow = contextWindow
        self.isActive = isActive
    }

    enum Role: String, Codable, CaseIterable, Sendable {
        case main
        case helper

        var displayName: String {
            switch self {
            case .main: "Main (story)"
            case .helper: "Helper (extraction)"
            }
        }
    }

    @Transient
    var variant: OpenAICompatibleBackend.Variant {
        OpenAICompatibleBackend.Variant(rawValue: backendVariantRaw) ?? .lmStudio
    }

    @Transient
    var role: Role {
        Role(rawValue: roleRaw) ?? .main
    }

    /// Materialise a concrete backend actor from this profile's settings.
    /// Each call instantiates a fresh actor — the registry caches the
    /// active backends so most call sites don't need to.
    func makeBackend() -> OpenAICompatibleBackend {
        OpenAICompatibleBackend(
            variant: variant,
            baseURL: URL(string: baseURL),
            modelName: modelName,
            apiKey: apiKey,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            repetitionPenalty: repetitionPenalty,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )
    }
}
