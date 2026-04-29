import Foundation
import SwiftData

@Model
final class Exchange {
    var role: String
    var content: String
    var committed: Bool
    var orderIndex: Int
    var createdAt: Date
    var characterName: String?
    var isChapterStart: Bool = false
    var chapterTitle: String?
    var retconnedFrom: Exchange?
    var alternateActive: Bool = true
    var session: Session?

    /// Groups together the per-character sub-exchanges that make up a single
    /// "turn" in capability (a) multi-character orchestration. All sequential
    /// per-speaker generations triggered by one user prompt share the same
    /// `turnGroupID`. Nil for legacy single-call exchanges and for user
    /// turns. Used by stale-cascade UI to scope downstream invalidation when
    /// a mid-chain exchange is rejected.
    var turnGroupID: UUID? = nil

    /// Capability (a) stale-cascade flag. Set on downstream sub-exchanges
    /// when an earlier sibling in the same `turnGroupID` is rejected or
    /// regenerated. The exchange is preserved (per invariant #3 — every
    /// mutation is reversible) but rendered with a stale badge offering
    /// keep / regenerate / cascade-regenerate. Defaults to `false`.
    var isStale: Bool = false

    init(
        role: String,
        content: String,
        orderIndex: Int,
        committed: Bool = false,
        characterName: String? = nil,
        isChapterStart: Bool = false,
        chapterTitle: String? = nil,
        retconnedFrom: Exchange? = nil,
        alternateActive: Bool = true,
        turnGroupID: UUID? = nil
    ) {
        self.role = role
        self.content = content
        self.orderIndex = orderIndex
        self.committed = committed
        self.characterName = characterName
        self.isChapterStart = isChapterStart
        self.chapterTitle = chapterTitle
        self.retconnedFrom = retconnedFrom
        self.alternateActive = alternateActive
        self.turnGroupID = turnGroupID
        self.createdAt = .now
    }
}
