import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date
    var themeConfigData: Data?

    @Relationship(deleteRule: .cascade, inverse: \World.project)
    var world: World?

    @Transient
    var themeConfig: ThemeConfig? {
        get {
            guard let data = themeConfigData else { return nil }
            return try? JSONDecoder().decode(ThemeConfig.self, from: data)
        }
        set {
            themeConfigData = try? JSONEncoder().encode(newValue)
        }
    }

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }
}
