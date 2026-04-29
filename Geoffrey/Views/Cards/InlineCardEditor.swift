import SwiftUI

struct InlineEditorHeader: View {
    let title: String
    let icon: String
    let accentColor: Color
    let isDirty: Bool
    let canSave: Bool
    var onSave: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(accentColor)
                    Text(title)
                        .font(.headline)
                    if isDirty {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Close") {
                        onClose()
                    }
                    .buttonStyle(.bordered)

                    Button("Save & Close") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()
        }
    }
}
