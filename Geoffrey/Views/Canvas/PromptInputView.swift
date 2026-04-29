import SwiftUI

struct PromptInputView: View {
    @Environment(ThemeEngine.self) private var themeEngine
    @Binding var text: String
    let isGenerating: Bool
    var onSend: () -> Void
    var onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextEditor(text: $text)
                .font(themeEngine.manuscriptFont)
                .frame(minHeight: 36, maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
                .focused($isFocused)
                .onKeyPress(.return, phases: .down) { press in
                    if press.modifiers.contains(.command) &&
                       !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       !isGenerating {
                        onSend()
                        return .handled
                    }
                    return .ignored
                }

            if isGenerating {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("Stop generating")
            } else {
                Button {
                    onSend()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Send (Cmd+Return)")
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .onAppear { isFocused = true }
    }
}
