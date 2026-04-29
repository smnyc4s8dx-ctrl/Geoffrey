import SwiftUI

struct ThemedPanelBackground: ViewModifier {
    @Environment(ThemeEngine.self) private var themeEngine
    let panel: PanelPosition

    func body(content: Content) -> some View {
        ZStack {
            if let (nsImage, config) = themeEngine.backgroundImage(for: panel) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(config.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }

            content
        }
    }
}

extension View {
    func themedPanelBackground(_ panel: PanelPosition) -> some View {
        modifier(ThemedPanelBackground(panel: panel))
    }
}
