import Foundation
import SwiftData
import Observation

/// `@MainActor`-pinned for consistency with the other view models. No
/// async path mutates this VM today, but pinning preempts the same
/// data-race class that `SessionViewModel` and `ConnectionMonitor` had
/// (mutation of `@Observable` state from a non-isolated `Task`) if a
/// future async fetch is added here.
@MainActor
@Observable
final class WorldViewModel {
    var selectedProject: Project?
    var selectedWorld: World? { selectedProject?.world }

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func selectProject(_ project: Project) {
        selectedProject = project
    }

    func deleteProject(_ project: Project) {
        modelContext.delete(project)
        try? modelContext.save()
        if selectedProject?.persistentModelID == project.persistentModelID {
            selectedProject = nil
        }
    }
}
