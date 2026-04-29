import Foundation
import SwiftData

@Model
final class Location {
    var name: String
    var stateLabel: String
    var descriptionText: String
    var notes: String

    // State Layer
    var conditionDescription: String
    var accessibility: String
    var atmosphere: String

    var stateUpdatePermission: StateUpdatePermission

    @Attribute(.externalStorage) var imageData: Data?

    var world: World?

    @Relationship(deleteRule: .cascade, inverse: \CharacterResidency.location)
    var residencies: [CharacterResidency] = []

    @Relationship(deleteRule: .cascade, inverse: \LoreLink.location)
    var loreLinks: [LoreLink] = []

    @Relationship(deleteRule: .cascade, inverse: \StateHistory.location)
    var stateHistory: [StateHistory] = []

    init(
        name: String,
        stateLabel: String = "Default",
        descriptionText: String = "",
        notes: String = "",
        conditionDescription: String = "",
        accessibility: String = "Open",
        atmosphere: String = "",
        stateUpdatePermission: StateUpdatePermission = .locked,
        imageData: Data? = nil
    ) {
        self.name = name
        self.stateLabel = stateLabel
        self.descriptionText = descriptionText
        self.notes = notes
        self.conditionDescription = conditionDescription
        self.accessibility = accessibility
        self.atmosphere = atmosphere
        self.stateUpdatePermission = stateUpdatePermission
        self.imageData = imageData
    }
}
