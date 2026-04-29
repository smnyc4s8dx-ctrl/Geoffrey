import SwiftUI

/// Multi-segment resource status bar surfaced at the bottom of the main window.
/// Each segment surfaces a single facet of the inference setup without taking
/// action on the user's behalf — observability, not enforcement (per LEDGER).
struct ResourceStatusBar: View {
    let connectionMonitor: ConnectionMonitor
    let resourceMonitor: ResourceMonitor
    let estimatedTokens: Int
    let contextWindow: Int
    var onConnectionTapped: () -> Void = {}

    @State private var openSegment: Segment?

    enum Segment: Hashable {
        case connection, model, memory, context, latency
    }

    var body: some View {
        HStack(spacing: 0) {
            chip(for: .connection)
            divider
            chip(for: .model)
            divider
            chip(for: .memory)
            divider
            chip(for: .context)
            divider
            chip(for: .latency)
            Spacer()
        }
        .font(.caption.monospacedDigit())
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private var divider: some View {
        Divider()
            .frame(height: 12)
            .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func chip(for segment: Segment) -> some View {
        Button {
            openSegment = (openSegment == segment) ? nil : segment
        } label: {
            chipLabel(for: segment)
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { openSegment == segment },
            set: { if !$0 { openSegment = nil } }
        ), arrowEdge: .top) {
            popoverContent(for: segment)
                .padding(12)
                .frame(minWidth: 220)
        }
    }

    @ViewBuilder
    private func chipLabel(for segment: Segment) -> some View {
        switch segment {
        case .connection:
            HStack(spacing: 4) {
                Circle()
                    .fill(connectionMonitor.isConnected ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                Text(connectionMonitor.isConnected ? "Connected" : "Disconnected")
                    .foregroundStyle(.secondary)
            }
        case .model:
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .foregroundStyle(.secondary)
                Text(modelDisplay)
                    .foregroundStyle(.primary)
            }
        case .memory:
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .foregroundStyle(memoryColor)
                Text(memoryDisplay)
                    .foregroundStyle(memoryColor)
            }
        case .context:
            HStack(spacing: 4) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(contextColor)
                Text(contextDisplay)
                    .foregroundStyle(contextColor)
            }
        case .latency:
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundStyle(latencyColor)
                Text(latencyDisplay)
                    .foregroundStyle(latencyColor)
            }
        }
    }

    @ViewBuilder
    private func popoverContent(for segment: Segment) -> some View {
        switch segment {
        case .connection:
            connectionDetail
        case .model:
            modelDetail
        case .memory:
            memoryDetail
        case .context:
            contextDetail
        case .latency:
            latencyDetail
        }
    }

    // MARK: - Display helpers

    private var modelDisplay: String {
        let name = resourceMonitor.activeModelName
        if let name, !name.isEmpty { return name }
        return "auto"
    }

    private var memoryDisplay: String {
        let used = resourceMonitor.usedMemoryGB
        let total = resourceMonitor.totalMemoryGB
        return String(format: "%.1f / %.0f GB", used, total)
    }

    private var memoryColor: Color {
        let f = resourceMonitor.usedMemoryFraction
        if f >= 0.85 { return .red }
        if f >= 0.70 { return .orange }
        return .secondary
    }

    private var contextDisplay: String {
        formatTokens(estimatedTokens) + " / " + formatTokens(contextWindow)
    }

    private var contextFraction: Double {
        guard contextWindow > 0 else { return 0 }
        return Double(estimatedTokens) / Double(contextWindow)
    }

    private var contextColor: Color {
        if contextFraction >= 0.90 { return .red }
        if contextFraction >= 0.70 { return .orange }
        return .secondary
    }

    private var latencyDisplay: String {
        guard let ttft = resourceMonitor.lastFirstTokenLatency else { return "—" }
        if ttft < 1 { return String(format: "%.0f ms", ttft * 1000) }
        return String(format: "%.1f s", ttft)
    }

    private var latencyColor: Color {
        guard let ttft = resourceMonitor.lastFirstTokenLatency else { return .secondary }
        if ttft >= 3 { return .red }
        if ttft >= 1 { return .orange }
        return .secondary
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }

    // MARK: - Detail popovers

    private var connectionDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionMonitor.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(connectionMonitor.isConnected ? "Connected" : "Disconnected")
                    .font(.headline)
            }
            if let lastChecked = connectionMonitor.lastChecked {
                Text("Last checked \(lastChecked, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !connectionMonitor.isConnected {
                Text("LM Studio isn't reachable. Confirm the server is running and the URL in settings matches.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Open LLM Server settings…") {
                onConnectionTapped()
                openSegment = nil
            }
            .buttonStyle(.link)
            .font(.caption)
        }
    }

    private var modelDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(modelDisplay)
                .font(.headline)
            Text(resourceMonitor.activeModelName == nil
                 ? "No model name configured. LM Studio will use whichever model is currently loaded."
                 : "Configured model name. Geoffrey sends this with every request; LM Studio routes to the matching loaded model.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var memoryDetail: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(memoryDisplay)
                .font(.headline)
            Text(String(format: "%.0f%% in use", resourceMonitor.usedMemoryFraction * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("System-wide active + wired + compressed pages. Updated every 3 seconds.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contextDetail: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contextDisplay)
                .font(.headline)
            Text(String(format: "%.0f%% of claimed window", contextFraction * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Estimate counts the messages Geoffrey would send right now (system preamble + cards + dialogue). The window is the model's claimed maximum.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var latencyDetail: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Time to first token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(latencyDisplay)
                    .font(.headline)
            }
            if let total = resourceMonitor.lastTotalLatency {
                HStack {
                    Text("Total call duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatSeconds(total))
                        .font(.subheadline.monospacedDigit())
                }
            }
            Text("Recorded on the most recent generation.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func formatSeconds(_ s: TimeInterval) -> String {
        if s < 1 { return String(format: "%.0f ms", s * 1000) }
        return String(format: "%.1f s", s)
    }
}
