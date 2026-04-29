import SwiftUI
import SwiftData

@main
@MainActor
struct GeoffreyApp: App {
    let modelContainer: ModelContainer
    @State private var themeEngine = ThemeEngine()
    @State private var backendRegistry: BackendRegistry

    init() {
        let schema = Schema([
            Project.self,
            World.self,
            Location.self,
            StoryCharacter.self,
            LoreCard.self,
            Session.self,
            Exchange.self,
            CharacterResidency.self,
            CharacterRelationship.self,
            LoreLink.self,
            TriggerRule.self,
            StateHistory.self,
            InferenceProfile.self
        ])
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        modelContainer = container
        _backendRegistry = State(initialValue: BackendRegistry(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(themeEngine)
                .environment(backendRegistry)
                .tint(themeEngine.accentColor)
                .frame(
                    minWidth: Theme.minWindowWidth,
                    minHeight: Theme.minWindowHeight
                )
        }
        .defaultSize(
            width: Theme.defaultWindowWidth,
            height: Theme.defaultWindowHeight
        )
        .modelContainer(modelContainer)

        #if os(macOS)
        Settings {
            TabView {
                InferenceProfilesView()
                    .environment(backendRegistry)
                    .tabItem {
                        Label("Profiles", systemImage: "rectangle.stack")
                    }
                AppearanceSettingsView()
                    .environment(themeEngine)
                    .tabItem {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                PrivacyPolicyView()
                    .tabItem {
                        Label("Privacy", systemImage: "lock.shield")
                    }
            }
            .frame(minWidth: 480, minHeight: 400)
            .modelContainer(modelContainer)
        }
        #endif
    }
}
