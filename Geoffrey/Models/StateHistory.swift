import Foundation
import SwiftData

@Model
final class StateHistory {
    var timestamp: Date
    var fieldName: String
    var previousState: String
    var newState: String
    var source: String
    var location: Location?

    init(
        fieldName: String,
        previousState: String,
        newState: String,
        source: String = "manual",
        location: Location? = nil
    ) {
        self.timestamp = .now
        self.fieldName = fieldName
        self.previousState = previousState
        self.newState = newState
        self.source = source
        self.location = location
    }
}
