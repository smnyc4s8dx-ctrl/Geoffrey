import Foundation
import SwiftData
import Observation

/// Resolves the saved-profile world into concrete backend actors.
///
/// The registry caches the active main + helper backends so call sites
/// (`SessionViewModel`, `ConnectionMonitor`, future `ResourceMonitor`)
/// can hold an `any InferenceBackend` reference without knowing about
/// any specific concrete type.
///
/// On first launch, `seedDefaultsIfNeeded` migrates legacy UserDefaults
/// (`lmStudioBaseURL`, `lmStudioModelName`, …) into a default LM Studio
/// profile so users with existing setups don't have to reconfigure. The
/// migration runs once per store; subsequent launches read profiles
/// directly.
///
/// `applyOnboardingDefaultsToActiveMain` is the bridge for first-run
/// users: onboarding still binds its form fields to the legacy
/// UserDefaults keys for now, so when onboarding finishes we re-read
/// those values onto the active main profile and rebuild the cached
/// backend. Without this call, onboarding edits would only take effect
/// on the next launch.
@Observable
final class BackendRegistry {
    /// Currently active main backend. Always present (registry seeds a
    /// default profile if none exist).
    private(set) var mainBackend: any InferenceBackend

    /// Currently active helper backend, if any. `nil` when the user
    /// hasn't configured a helper or when the helper profile has been
    /// deactivated.
    private(set) var helperBackend: (any InferenceBackend)?

    /// Snapshot of the active profile so views can read display name /
    /// model name without going through SwiftData. Mirrored from the
    /// store on every switch.
    private(set) var activeMainProfile: InferenceProfile?
    private(set) var activeHelperProfile: InferenceProfile?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        Self.seedDefaultsIfNeeded(in: modelContext)
        let (main, helper) = Self.loadActiveProfiles(from: modelContext)
        self.modelContext = modelContext
        self.activeMainProfile = main
        self.activeHelperProfile = helper
        self.mainBackend = main?.makeBackend() ?? Self.fallbackBackend()
        self.helperBackend = helper?.makeBackend()
    }

    // MARK: - Profile switching

    /// Designate `profile` as the active backend for its role. Deactivates
    /// any sibling-role profile so exactly one main + one helper is active
    /// at all times.
    func activate(_ profile: InferenceProfile) {
        let role = profile.role
        let roleString = profile.roleRaw
        let activatingID = profile.id
        let descriptor = FetchDescriptor<InferenceProfile>(
            predicate: #Predicate { $0.roleRaw == roleString && $0.isActive == true }
        )
        if let siblings = try? modelContext.fetch(descriptor) {
            for sibling in siblings where sibling.id != activatingID {
                sibling.isActive = false
            }
        }
        profile.isActive = true
        try? modelContext.save()

        let backend = profile.makeBackend()
        switch role {
        case .main:
            mainBackend = backend
            activeMainProfile = profile
        case .helper:
            helperBackend = backend
            activeHelperProfile = profile
        }
    }

    /// Reload from SwiftData. Call after the user edits the active
    /// profile in the editor — the cached backend instance still holds
    /// stale settings until we rebuild it.
    func reloadActive() {
        let (main, helper) = Self.loadActiveProfiles(from: modelContext)
        if let main {
            mainBackend = main.makeBackend()
            activeMainProfile = main
        }
        if let helper {
            helperBackend = helper.makeBackend()
            activeHelperProfile = helper
        } else {
            helperBackend = nil
            activeHelperProfile = nil
        }
    }

    /// Re-read legacy UserDefaults onto the active main profile and
    /// rebuild the cached backend. Called by `OnboardingView` on
    /// completion so first-run users don't have to relaunch for their
    /// chosen URL/model to take effect.
    func applyOnboardingDefaultsToActiveMain() {
        guard let active = activeMainProfile else { return }
        let defaults = UserDefaults.standard
        if let urlString = defaults.string(forKey: "lmStudioBaseURL"), !urlString.isEmpty {
            active.baseURL = urlString
        }
        let storedModel = defaults.string(forKey: "lmStudioModelName") ?? ""
        active.modelName = storedModel.isEmpty ? nil : storedModel
        try? modelContext.save()
        mainBackend = active.makeBackend()
        activeMainProfile = active
    }

    /// Drop the active helper assignment. Profiles persist; only the
    /// active flag flips.
    func clearHelper() {
        let descriptor = FetchDescriptor<InferenceProfile>(
            predicate: #Predicate { $0.roleRaw == "helper" && $0.isActive == true }
        )
        if let actives = try? modelContext.fetch(descriptor) {
            for p in actives { p.isActive = false }
            try? modelContext.save()
        }
        helperBackend = nil
        activeHelperProfile = nil
    }

    // MARK: - First-launch seeding

    private static func seedDefaultsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<InferenceProfile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let defaults = UserDefaults.standard
        let urlString = defaults.string(forKey: "lmStudioBaseURL") ?? "http://127.0.0.1:1234"
        let storedModel = defaults.string(forKey: "lmStudioModelName")
        let modelName = (storedModel?.isEmpty ?? true) ? nil : storedModel
        let storedTemp = defaults.double(forKey: "lmStudioTemperature")
        let storedMaxTokens = defaults.integer(forKey: "lmStudioMaxTokens")
        let storedTopP = defaults.double(forKey: "lmStudioTopP")
        let storedRepPenalty = defaults.double(forKey: "lmStudioRepetitionPenalty")

        let profile = InferenceProfile(
            name: "LM Studio (local)",
            variant: .lmStudio,
            role: .main,
            baseURL: urlString,
            modelName: modelName,
            temperature: storedTemp > 0 ? storedTemp : 0.8,
            maxTokens: storedMaxTokens > 0 ? storedMaxTokens : 2048,
            topP: storedTopP > 0 ? storedTopP : 0.95,
            repetitionPenalty: storedRepPenalty > 0 ? storedRepPenalty : 1.1,
            isActive: true
        )
        context.insert(profile)
        try? context.save()
    }

    private static func loadActiveProfiles(from context: ModelContext) -> (main: InferenceProfile?, helper: InferenceProfile?) {
        let descriptor = FetchDescriptor<InferenceProfile>(
            predicate: #Predicate { $0.isActive == true }
        )
        let actives = (try? context.fetch(descriptor)) ?? []
        let main = actives.first(where: { $0.roleRaw == "main" })
        let helper = actives.first(where: { $0.roleRaw == "helper" })
        return (main, helper)
    }

    /// Hard fallback for the very rare case where seeding fails (e.g.,
    /// SwiftData store rejected the insert). Keeps the app launchable
    /// against a default-port LM Studio.
    private static func fallbackBackend() -> any InferenceBackend {
        OpenAICompatibleBackend(variant: .lmStudio)
    }
}
