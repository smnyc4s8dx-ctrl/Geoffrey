import Foundation

/// Geoffrey's curated "tested with" model list. Per design invariant #7, this
/// is *recommendation*, never enforcement — Geoffrey works with any
/// OpenAI-compatible local server. Refreshed on the quarterly recheck routine.
///
/// Two categories: `main` (long-form prose generation) and `helper` (small
/// structured-extraction backend used by capability (d) once it ships).
enum RecommendedModels {
    struct Entry: Identifiable, Hashable {
        let id: String
        let displayName: String
        let approximateSize: String
        let notes: String
        let licenseLabel: String
    }

    static let main: [Entry] = [
        Entry(
            id: "glm-4.7-flash-q4",
            displayName: "GLM 4.7 Flash (Q4)",
            approximateSize: "~5 GB · 8B class",
            notes: "Fast, prose-friendly, fits comfortably on 16 GB Macs alongside the OS.",
            licenseLabel: "GLM license"
        ),
        Entry(
            id: "qwen-2.5-32b-instruct-q4",
            displayName: "Qwen 2.5 32B Instruct (Q4)",
            approximateSize: "~20 GB · 32B class",
            notes: "Strong literary output. Recommended for 32 GB+ Macs.",
            licenseLabel: "Apache 2.0"
        ),
        Entry(
            id: "llama-3.3-70b-instruct-q4",
            displayName: "Llama 3.3 70B Instruct (Q4)",
            approximateSize: "~40 GB · 70B class",
            notes: "Highest fidelity tier. Recommended for 64 GB+ Macs / Mac Studio.",
            licenseLabel: "Llama community"
        )
    ]

    static let helper: [Entry] = [
        Entry(
            id: "apple-foundation-models",
            displayName: "Apple Foundation Models",
            approximateSize: "Bundled · macOS 15+",
            notes: "Zero-setup helper backend. Strong at structured extraction; weak at long-form prose. Reserved for capability (d) once it ships.",
            licenseLabel: "System framework"
        ),
        Entry(
            id: "phi-3.5-mini-instruct-q4",
            displayName: "Phi 3.5 Mini Instruct (Q4)",
            approximateSize: "~2.5 GB · 3.8B",
            notes: "Pairs well as a helper alongside any main backend. Good extraction baseline.",
            licenseLabel: "MIT"
        ),
        Entry(
            id: "qwen-2.5-3b-instruct-q4",
            displayName: "Qwen 2.5 3B Instruct (Q4)",
            approximateSize: "~2 GB · 3B",
            notes: "Compact extraction helper. Pairs well alongside larger main models on memory-constrained machines.",
            licenseLabel: "Apache 2.0"
        )
    ]
}
