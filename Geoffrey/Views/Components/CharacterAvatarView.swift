import SwiftUI

struct CharacterAvatarView: View {
    let name: String
    var imageData: Data?
    var size: CGFloat = 48

    var body: some View {
        if let imageData, let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.separator, lineWidth: 1))
        } else {
            ZStack {
                Circle()
                    .fill(avatarColor)
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
        }
    }

    private var initials: String {
        // Strip parenthetical content: "Xelia (Xev Talinder)" → "Xelia"
        let cleaned = name.replacingOccurrences(of: "\\s*\\(.*?\\)", with: "", options: .regularExpression)
        let words = cleaned.split(separator: " ").filter { !$0.isEmpty }
        switch words.count {
        case 0:
            return String(name.prefix(1)).uppercased()
        case 1:
            return String(words[0].prefix(1)).uppercased()
        default:
            return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased()
        }
    }

    private var avatarColor: Color {
        let index = abs(name.hashValue) % Theme.avatarPalette.count
        return Theme.avatarPalette[index]
    }
}
