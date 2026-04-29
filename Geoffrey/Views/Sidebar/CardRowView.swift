import SwiftUI

struct CardRowView: View {
    let name: String
    let subtitle: String
    let icon: String
    var badgeText: String = ""
    var accentColor: Color = .secondary
    var isChecked: Bool? = nil
    var isSelected: Bool = false
    var onCheckToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !badgeText.isEmpty && badgeText != "Default" {
                Text(badgeText)
                    .font(.caption2)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.1), in: Capsule())
            }

            if let isChecked {
                Button {
                    onCheckToggle?()
                } label: {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isChecked ? .green : .secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, isSelected ? 4 : 0)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(accentColor.opacity(0.1))
            }
        }
    }
}
