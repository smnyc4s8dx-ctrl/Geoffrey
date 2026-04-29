import Foundation
import Observation

/// `@MainActor`-pinned because SwiftUI status bars read `isConnected` and
/// `lastChecked` during body evaluation. Both properties are mutated from
/// the polling loop's continuation, so without the pin the writes happen
/// on whatever executor `URLSession`/`Task.sleep` yields from — a race
/// against the main-thread reads. Pin keeps mutations serialized; the
/// `await` hops in the loop yield the main thread between health checks
/// so the run loop stays responsive.
@MainActor
@Observable
final class ConnectionMonitor {
    var isConnected: Bool = false
    var lastChecked: Date?

    private let backendRegistry: BackendRegistry
    private var pollingTask: Task<Void, Never>?

    /// Always reads the current main backend through the registry, so
    /// profile activation in Settings flips the polled target on the
    /// next tick without restarting.
    private var client: any InferenceBackend { backendRegistry.mainBackend }

    init(backendRegistry: BackendRegistry) {
        self.backendRegistry = backendRegistry
    }

    func startPolling() {
        stopPolling()
        pollingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let healthy = await self.client.isAvailable()
                self.isConnected = healthy
                self.lastChecked = .now
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func checkNow() async {
        isConnected = await client.isAvailable()
        lastChecked = .now
    }
}
