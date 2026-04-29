import Foundation
import SwiftData

@Model
final class TriggerRule {
    var ruleType: String
    var ruleValue: String
    var loreCard: LoreCard?

    init(ruleType: String, ruleValue: String, loreCard: LoreCard? = nil) {
        self.ruleType = ruleType
        self.ruleValue = ruleValue
        self.loreCard = loreCard
    }
}
