import Foundation
import Observation
import Darwin
import Darwin.Mach

@Observable
final class ResourceMonitor {
    var usedMemoryBytes: UInt64 = 0
    var totalMemoryBytes: UInt64
    var lastFirstTokenLatency: TimeInterval?
    var lastTotalLatency: TimeInterval?
    var activeModelName: String?

    private let backendRegistry: BackendRegistry
    private var pollingTask: Task<Void, Never>?

    init(backendRegistry: BackendRegistry) {
        self.backendRegistry = backendRegistry
        self.totalMemoryBytes = ProcessInfo.processInfo.physicalMemory
    }

    func startPolling() {
        stopPolling()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.refreshMemory()
                await self.refreshClientMetrics()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func refreshMemory() {
        usedMemoryBytes = systemUsedMemoryBytes() ?? usedMemoryBytes
    }

    /// Reads metrics from the active main backend via the registry, so profile
    /// switches (capability l) are picked up automatically on the next poll.
    /// Cast guards the latency fields, which live on `OpenAICompatibleBackend`
    /// specifically; future backend types (`FoundationModelsBackend`) can
    /// implement their own metric pathway when added.
    private func refreshClientMetrics() async {
        guard let backend = backendRegistry.mainBackend as? OpenAICompatibleBackend else { return }
        let ttft = await backend.lastFirstTokenLatency
        let total = await backend.lastTotalLatency
        let model = await backend.modelName
        lastFirstTokenLatency = ttft
        lastTotalLatency = total
        activeModelName = model
    }

    var usedMemoryGB: Double { Double(usedMemoryBytes) / 1_073_741_824 }
    var totalMemoryGB: Double { Double(totalMemoryBytes) / 1_073_741_824 }

    var usedMemoryFraction: Double {
        guard totalMemoryBytes > 0 else { return 0 }
        return min(1.0, Double(usedMemoryBytes) / Double(totalMemoryBytes))
    }
}

/// Reads system-wide memory usage via Mach `host_statistics64`.
/// Returns "used" as active + wired + compressed pages (matches Activity Monitor's
/// "Memory Used" definition). Returns nil if the Mach call fails.
private func systemUsedMemoryBytes() -> UInt64? {
    let hostInfoCount = MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
    var size = mach_msg_type_number_t(hostInfoCount)
    var stats = vm_statistics64_data_t()
    let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
        ptr.withMemoryRebound(to: integer_t.self, capacity: hostInfoCount) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
        }
    }
    guard result == KERN_SUCCESS else { return nil }
    let pageSize = UInt64(vm_kernel_page_size)
    let usedPages = UInt64(stats.active_count)
        + UInt64(stats.wire_count)
        + UInt64(stats.compressor_page_count)
    return usedPages * pageSize
}
