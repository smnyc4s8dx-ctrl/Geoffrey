import Foundation

enum StateUpdatePermission: String, Codable, CaseIterable, Identifiable {
    case locked
    case aiSuggested
    case aiManaged

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .locked: "Locked (Manual Only)"
        case .aiSuggested: "AI-Suggested"
        case .aiManaged: "AI-Managed"
        }
    }
}

enum LorePriority: String, Codable, CaseIterable, Identifiable {
    case high
    case normal
    case background

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .high: "High"
        case .normal: "Normal"
        case .background: "Background"
        }
    }
}
