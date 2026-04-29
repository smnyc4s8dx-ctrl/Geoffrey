import SwiftUI
import SwiftData

/// Profile editor for capability (l). Shows all saved `InferenceProfile`
/// rows grouped by role, lets the user add / edit / delete / activate.
///
/// The editor is intentionally Settings-pane sized: list on the left,
/// inline detail beneath. New-profile flow opens a sheet with the
/// recommended-models picker as the suggestion source.
struct InferenceProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(BackendRegistry.self) private var backendRegistry
    @Query(sort: \InferenceProfile.createdAt) private var profiles: [InferenceProfile]

    @State private var editingProfile: InferenceProfile?
    @State private var showingAddSheet = false
    @State private var addRole: InferenceProfile.Role = .main

    private var mainProfiles: [InferenceProfile] {
        profiles.filter { $0.roleRaw == InferenceProfile.Role.main.rawValue }
    }

    private var helperProfiles: [InferenceProfile] {
        profiles.filter { $0.roleRaw == InferenceProfile.Role.helper.rawValue }
    }

    var body: some View {
        Form {
            Section {
                profileList(mainProfiles, role: .main)
            } header: {
                roleHeader(.main, count: mainProfiles.count) {
                    addRole = .main
                    showingAddSheet = true
                }
            } footer: {
                Text("Drives story generation. Exactly one main is active at a time.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section {
                profileList(helperProfiles, role: .helper)
            } header: {
                roleHeader(.helper, count: helperProfiles.count) {
                    addRole = .helper
                    showingAddSheet = true
                }
            } footer: {
                Text("Optional. Used by structured-extraction features (capability d) and semantic lore activation (capability g).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, idealWidth: 560)
        .frame(minHeight: 360)
        .navigationTitle("Inference Profiles")
        .sheet(isPresented: $showingAddSheet) {
            ProfileEditorSheet(
                mode: .add(role: addRole),
                onSave: { newProfile in
                    modelContext.insert(newProfile)
                    try? modelContext.save()
                    showingAddSheet = false
                },
                onCancel: { showingAddSheet = false }
            )
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditorSheet(
                mode: .edit(profile),
                onSave: { saved in
                    try? modelContext.save()
                    if saved.isActive {
                        backendRegistry.reloadActive()
                    }
                    editingProfile = nil
                },
                onCancel: { editingProfile = nil }
            )
        }
    }

    // MARK: - Section components

    private func roleHeader(_ role: InferenceProfile.Role, count: Int, onAdd: @escaping () -> Void) -> some View {
        HStack {
            Text(role.displayName)
            Text("(\(count))")
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                onAdd()
            } label: {
                Label("Add", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
    }

    @ViewBuilder
    private func profileList(_ list: [InferenceProfile], role: InferenceProfile.Role) -> some View {
        if list.isEmpty {
            Text("No \(role.displayName.lowercased()) profiles yet.")
                .foregroundStyle(.secondary)
                .font(.callout)
        } else {
            ForEach(list) { profile in
                profileRow(profile)
            }
        }
    }

    private func profileRow(_ profile: InferenceProfile) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.callout.weight(.medium))
                    if profile.isActive {
                        Text("ACTIVE")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.18), in: .capsule)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text("\(profile.variant.displayName) · \(profile.modelName ?? "default model")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(profile.baseURL)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Menu {
                if !profile.isActive {
                    Button("Activate") {
                        activate(profile)
                    }
                }
                Button("Edit…") { editingProfile = profile }
                Divider()
                Button("Delete", role: .destructive) {
                    delete(profile)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .contentShape(Rectangle())
        .onTapGesture { editingProfile = profile }
    }

    // MARK: - Actions

    private func activate(_ profile: InferenceProfile) {
        backendRegistry.activate(profile)
    }

    private func delete(_ profile: InferenceProfile) {
        let wasActive = profile.isActive
        let role = profile.role
        modelContext.delete(profile)
        try? modelContext.save()
        if wasActive {
            switch role {
            case .helper:
                backendRegistry.clearHelper()
            case .main:
                backendRegistry.reloadActive()
            }
        }
    }
}

// MARK: - Editor sheet

private struct ProfileEditorSheet: View {
    enum Mode {
        case add(role: InferenceProfile.Role)
        case edit(InferenceProfile)
    }

    let mode: Mode
    let onSave: (InferenceProfile) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var role: InferenceProfile.Role
    @State private var variant: OpenAICompatibleBackend.Variant
    @State private var baseURL: String
    @State private var modelName: String
    @State private var apiKey: String
    @State private var temperature: Double
    @State private var maxTokens: Int
    @State private var topP: Double
    @State private var repetitionPenalty: Double
    @State private var frequencyPenalty: Double
    @State private var presencePenalty: Double
    @State private var contextWindow: Int
    @State private var showSuggestions = false

    // Test-connection state
    @State private var testStatus: TestStatus = .idle
    @State private var testMessage: String?

    private enum TestStatus: Equatable {
        case idle
        case testing
        case ok
        case failed
    }

    private let editingProfile: InferenceProfile?

    init(mode: Mode, onSave: @escaping (InferenceProfile) -> Void, onCancel: @escaping () -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel

        switch mode {
        case .add(let role):
            self.editingProfile = nil
            _name = State(initialValue: "")
            _role = State(initialValue: role)
            _variant = State(initialValue: .lmStudio)
            _baseURL = State(initialValue: OpenAICompatibleBackend.Variant.lmStudio.defaultBaseURL.absoluteString)
            _modelName = State(initialValue: "")
            _apiKey = State(initialValue: "")
            _temperature = State(initialValue: 0.8)
            _maxTokens = State(initialValue: 2048)
            _topP = State(initialValue: 0.95)
            _repetitionPenalty = State(initialValue: 1.1)
            _frequencyPenalty = State(initialValue: 0.0)
            _presencePenalty = State(initialValue: 0.0)
            _contextWindow = State(initialValue: 8192)
        case .edit(let p):
            self.editingProfile = p
            _name = State(initialValue: p.name)
            _role = State(initialValue: p.role)
            _variant = State(initialValue: p.variant)
            _baseURL = State(initialValue: p.baseURL)
            _modelName = State(initialValue: p.modelName ?? "")
            _apiKey = State(initialValue: p.apiKey ?? "")
            _temperature = State(initialValue: p.temperature)
            _maxTokens = State(initialValue: p.maxTokens)
            _topP = State(initialValue: p.topP)
            _repetitionPenalty = State(initialValue: p.repetitionPenalty)
            _frequencyPenalty = State(initialValue: p.frequencyPenalty)
            _presencePenalty = State(initialValue: p.presencePenalty)
            _contextWindow = State(initialValue: p.contextWindow)
        }
    }

    private var isAdd: Bool {
        if case .add = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && URL(string: baseURL) != nil
            && (!variant.requiresAPIKey || !apiKey.isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Identity") {
                    TextField("Profile name", text: $name)
                        .help("e.g., \"MacBook Air LM Studio\" or \"Studio Mac LAN\"")
                    Picker("Role", selection: $role) {
                        ForEach(InferenceProfile.Role.allCases, id: \.self) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    .disabled(!isAdd)
                    Picker("Backend", selection: $variant) {
                        ForEach(OpenAICompatibleBackend.Variant.allCases, id: \.self) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                    .onChange(of: variant) { _, newValue in
                        if isAdd && (baseURL.isEmpty || baseURL.starts(with: "http://127.0.0.1") || baseURL.starts(with: "https://api.openai.com")) {
                            baseURL = newValue.defaultBaseURL.absoluteString
                        }
                    }
                }

                Section("Connection") {
                    TextField("Base URL", text: $baseURL)
                    TextField("Model name (optional)", text: $modelName)
                        .help("Leave empty to use the server's default model.")
                    if variant.requiresAPIKey {
                        SecureField("API key", text: $apiKey)
                    }
                    Button {
                        showSuggestions.toggle()
                    } label: {
                        HStack {
                            Label("Suggested models", systemImage: "lightbulb")
                            Spacer()
                            Image(systemName: showSuggestions ? "chevron.up" : "chevron.down")
                                .imageScale(.small)
                        }
                    }
                    .buttonStyle(.borderless)

                    if showSuggestions {
                        suggestedModelsList
                    }
                }

                Section("Generation parameters") {
                    sliderRow(label: "Temperature", value: $temperature, range: 0...2, step: 0.05, format: "%.2f")
                    HStack {
                        Text("Max tokens")
                        Spacer()
                        TextField("", value: $maxTokens, format: .number)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    sliderRow(label: "Top-P", value: $topP, range: 0...1, step: 0.05, format: "%.2f")

                    if variant.usesRepetitionPenalty {
                        sliderRow(label: "Repetition penalty", value: $repetitionPenalty, range: 1...2, step: 0.05, format: "%.2f")
                    } else {
                        sliderRow(label: "Frequency penalty", value: $frequencyPenalty, range: -2...2, step: 0.1, format: "%.1f")
                        sliderRow(label: "Presence penalty", value: $presencePenalty, range: -2...2, step: 0.1, format: "%.1f")
                    }

                    HStack {
                        Text("Context window")
                        Spacer()
                        TextField("", value: $contextWindow, format: .number)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("tokens")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack(spacing: 8) {
                Button {
                    runConnectionTest()
                } label: {
                    HStack(spacing: 6) {
                        switch testStatus {
                        case .idle:
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        case .testing:
                            ProgressView().controlSize(.small)
                        case .ok:
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        case .failed:
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        }
                        Text(testButtonLabel)
                    }
                }
                .disabled(testStatus == .testing || URL(string: baseURL) == nil)
                if let testMessage {
                    Text(testMessage)
                        .font(.caption)
                        .foregroundStyle(testStatus == .ok ? .green : (testStatus == .failed ? .red : .secondary))
                        .lineLimit(2)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                Button("Save", action: save)
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 540)
    }

    @ViewBuilder
    private var suggestedModelsList: some View {
        let entries = role == .main ? RecommendedModels.main : RecommendedModels.helper
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entries) { entry in
                Button {
                    if modelName.isEmpty || !entries.contains(where: { $0.id == modelName }) {
                        modelName = entry.id
                    } else {
                        modelName = entry.id
                    }
                } label: {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: modelName == entry.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(modelName == entry.id ? Color.accentColor : Color.secondary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.displayName)
                                .font(.callout.weight(.medium))
                            Text("\(entry.approximateSize) · \(entry.licenseLabel)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(entry.notes)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 4)
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double.Stride, format: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Slider(value: value, in: range, step: step)
                .frame(width: 200)
            Text(String(format: format, value.wrappedValue))
                .monospacedDigit()
                .frame(width: 48, alignment: .trailing)
        }
    }

    private var testButtonLabel: String {
        switch testStatus {
        case .idle: "Test connection"
        case .testing: "Testing…"
        case .ok: "Connected"
        case .failed: "Test connection"
        }
    }

    private func runConnectionTest() {
        guard let url = URL(string: baseURL) else {
            testStatus = .failed
            testMessage = "Invalid URL"
            return
        }
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespaces)
        let probe = OpenAICompatibleBackend(
            variant: variant,
            baseURL: url,
            modelName: trimmedModel.isEmpty ? nil : trimmedModel,
            apiKey: trimmedKey.isEmpty ? nil : trimmedKey
        )
        testStatus = .testing
        testMessage = nil
        Task {
            let healthy = await probe.checkHealth()
            await MainActor.run {
                if healthy {
                    testStatus = .ok
                    testMessage = "Server responded at /v1/models."
                } else {
                    testStatus = .failed
                    testMessage = "No response. Check that the server is running and the URL is correct."
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespaces)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)

        if let editing = editingProfile {
            editing.name = trimmedName
            editing.backendVariantRaw = variant.rawValue
            editing.baseURL = baseURL
            editing.modelName = trimmedModel.isEmpty ? nil : trimmedModel
            editing.apiKey = trimmedKey.isEmpty ? nil : trimmedKey
            editing.temperature = temperature
            editing.maxTokens = maxTokens
            editing.topP = topP
            editing.repetitionPenalty = repetitionPenalty
            editing.frequencyPenalty = frequencyPenalty
            editing.presencePenalty = presencePenalty
            editing.contextWindow = contextWindow
            onSave(editing)
        } else {
            let new = InferenceProfile(
                name: trimmedName,
                variant: variant,
                role: role,
                baseURL: baseURL,
                modelName: trimmedModel.isEmpty ? nil : trimmedModel,
                apiKey: trimmedKey.isEmpty ? nil : trimmedKey,
                temperature: temperature,
                maxTokens: maxTokens,
                topP: topP,
                repetitionPenalty: repetitionPenalty,
                frequencyPenalty: frequencyPenalty,
                presencePenalty: presencePenalty,
                contextWindow: contextWindow,
                isActive: false
            )
            onSave(new)
        }
    }
}
