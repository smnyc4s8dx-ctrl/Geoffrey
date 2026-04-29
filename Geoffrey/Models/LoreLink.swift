import Foundation
import SwiftData

@Model
final class LoreLink {
    var location: Location?
    var loreCard: LoreCard?

    init(location: Location? = nil, loreCard: LoreCard? = nil) {
        self.location = location
        self.loreCard = loreCard
    }
}
