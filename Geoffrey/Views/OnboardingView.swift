import SwiftUI

struct OnboardingView: View {
    @AppStorage("lmStudioBaseURL") private var baseURLString: String = "http://127.0.0.1:1234"
    @AppStorage("lmStudioModelName") private var modelName: String = ""
    @Environment(BackendRegistry.self) private var backendRegistry
    @Binding var isPresented: Bool

    @State private var currentStep = 0
    @State private var connectionStatus: ConnectionTestStatus = .untested
    @State private var formatTestResult: FormatTestResult?
    @State private var formatTestError: String?
    @State private var isTesting = false

    enum ConnectionTestStatus {
        case untested, testing, connected, failed
    }

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: connectStep
                default: getStartedStep
                }
            }
            .frame(maxWidth: 500)

            Spacer()

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < 2 {
                    Button("Next") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        backendRegistry.applyOnboardingDefaultsToActiveMain()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 420, minHeight: 480)
        .background(.ultraThinMaterial)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(.linearGradient(
                    colors: [Theme.locationColor, Theme.characterColor, Theme.loreColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Welcome to Geoffrey")
                .font(.title.bold())

            Text("Geoffrey is an interactive worldbuilding studio. You build story worlds using **cards** — Locations, Characters, and Lore — then walk through them in live AI-powered dialogue.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "map", color: Theme.locationColor, text: "**Locations** are the sets of your story")
                featureRow(icon: "person.2", color: Theme.characterColor, text: "**Characters** are your cast members")
                featureRow(icon: "book", color: Theme.loreColor, text: "**Lore** is your story bible")
            }
            .padding(.top, 8)
        }
        .padding(24)
    }

    // MARK: - Step 2: Connect

    private var connectStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "network")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)

                Text("Connect to an LLM")
                    .font(.title2.bold())

                Text("Geoffrey needs a local LLM server to generate dialogue. It works with **LM Studio** or **Ollama** — both are free and run entirely on your Mac.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(number: "1", text: "Download **LM Studio** from lmstudio.ai (or install Ollama)")
                    instructionRow(number: "2", text: "Launch it and **load a model** (any chat model works)")
                    instructionRow(number: "3", text: "Start the **local server** (LM Studio: Developer tab → Start Server)")
                }
                .padding(.vertical, 8)

                // Connection URL
                HStack {
                    Text("Server URL:")
                        .font(.callout)
                    TextField("http://127.0.0.1:1234", text: $baseURLString)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                // Model name (optional)
                HStack {
                    Text("Model Name:")
                        .font(.callout)
                    TextField("(auto-detect)", text: $modelName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                // Test connection button
                Button {
                    testConnection()
                } label: {
                    HStack(spacing: 6) {
                        switch connectionStatus {
                        case .untested:
                            Image(systemName: "bolt.circle")
                            Text("Test Connection")
                        case .testing:
                            ProgressView().controlSize(.small)
                            Text("Testing...")
                        case .connected:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connected")
                        case .failed:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Not reachable — is the server running?")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isTesting)

                // Format test (appears after connection succeeds)
                if connectionStatus == .connected {
                    Divider()

                    VStack(spacing: 12) {
                        Text("Format Validation")
                            .font(.headline)

                        Text("Geoffrey requires the LLM to follow a structured response format. This test sends a sample prompt to verify your model can follow the rules.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            testFormat()
                        } label: {
                            HStack(spacing: 6) {
                                if isTesting {
                                    ProgressView().controlSize(.small)
                                    Text("Testing format...")
                                } else if let result = formatTestResult {
                                    Image(systemName: result.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(result.passed ? .green : .orange)
                                    Text(result.passed ? "Format test passed" : "Format test failed")
                                } else {
                                    Image(systemName: "text.badge.checkmark")
                                    Text("Test Response Format")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTesting)

                        // Show test results
                        if let result = formatTestResult {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(result.summary)
                                    .font(.callout)
                                    .foregroundStyle(result.passed ? .green : .orange)

                                if !result.response.isEmpty {
                                    Text("Model response:")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    Text(result.response.prefix(500))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }

                        if let error = formatTestError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Text("You can change these settings later in **Geoffrey → Settings**.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(24)
        }
    }

    // MARK: - Step 3: Get Started

    private var getStartedStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            Text("You're All Set")
                .font(.title2.bold())

            Text("Create a new project from scratch, or load one of the bundled templates to see how Geoffrey works.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                tipRow(text: "Start by creating a **Location** and a **Character**")
                tipRow(text: "Select them in the **Scene Inspector** (right panel)")
                tipRow(text: "Type a message to begin the dialogue")
                tipRow(text: "Use **Director's Notes** for out-of-character instructions")
            }
            .padding(.vertical, 8)
        }
        .padding(24)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.callout)
        }
    }

    private func instructionRow(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor, in: Circle())
            Text(text)
                .font(.callout)
        }
    }

    private func tipRow(text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(text)
                .font(.callout)
        }
    }

    // MARK: - Tests

    private func makeProbeBackend(url: URL) -> OpenAICompatibleBackend {
        OpenAICompatibleBackend(
            variant: .lmStudio,
            baseURL: url,
            modelName: modelName.isEmpty ? nil : modelName
        )
    }

    private func testConnection() {
        connectionStatus = .testing
        formatTestResult = nil
        formatTestError = nil
        guard let url = URL(string: baseURLString) else {
            connectionStatus = .failed
            return
        }
        let probe = makeProbeBackend(url: url)
        Task {
            let result = await probe.checkHealth()
            connectionStatus = result ? .connected : .failed
        }
    }

    private func testFormat() {
        isTesting = true
        formatTestResult = nil
        formatTestError = nil
        guard let url = URL(string: baseURLString) else {
            formatTestError = "Invalid URL"
            isTesting = false
            return
        }
        let probe = makeProbeBackend(url: url)
        Task {
            do {
                let result = try await probe.testFormatCompliance()
                formatTestResult = result
            } catch {
                formatTestError = "Test failed: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}
