import Foundation
import SwiftData

@Model
final class LoreCard {
    var title: String
    var content: String
    var tags: [String]
    var priority: LorePriority

    // State Layer
    var currency: String
    var revelationStatus: String
    var scopeChange: String

    var stateUpdatePermission: StateUpdatePermission

    var world: World?

    @Relationship(deleteRule: .cascade, inverse: \TriggerRule.loreCard)
    var triggerRules: [TriggerRule] = []

    @Relationship(deleteRule: .cascade, inverse: \LoreLink.loreCard)
    var loreLinks: [LoreLink] = []

    init(
        title: String,
        content: String = "",
        tags: [String] = [],
        priority: LorePriority = .normal,
        currency: String = "Current",
        revelationStatus: String = "Universal",
        scopeChange: String = "",
        stateUpdatePermission: StateUpdatePermission = .locked
    ) {
        self.title = title
        self.content = content
        self.tags = tags
        self.priority = priority
        self.currency = currency
        self.revelationStatus = revelationStatus
        self.scopeChange = scopeChange
        self.stateUpdatePermission = stateUpdatePermission
    }
}
