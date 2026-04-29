import Foundation
import SwiftData

@Model
final class Session {
    var startedAt: Date
    var world: World?

    @Relationship(deleteRule: .cascade, inverse: \Exchange.session)
    var exchanges: [Exchange] = []

    init() {
        self.startedAt = .now
    }
}
