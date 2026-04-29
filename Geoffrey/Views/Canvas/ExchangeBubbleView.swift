import SwiftUI

struct ExchangeBubbleView: View {
    @Environment(ThemeEngine.self) private var themeEngine

    let role: String
    let content: String
    var isCommitted: Bool = false
    var isStreaming: Bool = false
    var characterName: String?
    var characterImageData: Data?
    var isNarration: Bool = false
    var isAction: Bool = false
    /// When `true`, this character bubble is a continuation of the previous
    /// segment (same speaker). Hides the avatar + name header so adjacent
    /// segments visually fold into one speaker turn while remaining
    /// independently selectable. Only meaningful for character bubbles —
    /// narration and action bubbles ignore the flag.
    var isContinuation: Bool = false

    init(exchange: Exchange, characterImageData: Data? = nil) {
        self.role = exchange.role
        self.content = exchange.content
        self.isCommitted = exchange.committed
        self.isStreaming = false
        self.characterName = exchange.characterName
        self.characterImageData = characterImageData
    }

    init(role: String, content: String, isCommitted: Bool = false, isStreaming: Bool = false, characterName: String? = nil, characterImageData: Data? = nil, isNarration: Bool = false, isAction: Bool = false, isContinuation: Bool = false) {
        self.role = role
        self.content = content
        self.isCommitted = isCommitted
        self.isStreaming = isStreaming
        self.characterName = characterName
        self.characterImageData = characterImageData
        self.isNarration = isNarration
        self.isAction = isAction
        self.isContinuation = isContinuation
    }

    private var isUser: Bool { role == "user" }

    var body: some View {
        if isAction {
            actionBubble
        } else if isNarration {
            narrationBubble
        } else if isUser {
            userBubble
        } else {
            characterBubble
        }
    }

    // MARK: - Narration Bubble (full-width, no avatar)

    private var narrationBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "text.quote")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if isCommitted {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(themeEngine.committedAccent)
                }
                Spacer()
            }

            Text(content)
                .font(themeEngine.manuscriptFont)
                .italic()
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: Theme.bubbleCornerRadius)
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay(alignment: .leading) {
                            if isCommitted {
                                UnevenRoundedRectangle(
                                    topLeadingRadius: Theme.bubbleCornerRadius,
                                    bottomLeadingRadius: Theme.bubbleCornerRadius,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 0
                                )
                                .fill(themeEngine.committedAccent)
                                .frame(width: 3)
                            }
                        }
                }
        }
    }

    // MARK: - Action Bubble (compact, no avatar, indented to dialogue column)

    private var actionBubble: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if isCommitted {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(themeEngine.committedAccent)
            }
            Text(content)
                .font(themeEngine.manuscriptSmall)
                .italic()
                .foregroundStyle(.primary.opacity(0.7))
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .padding(.leading, Theme.avatarSize + 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Theme.bubbleCornerRadius)
                .fill(.fill.quinary)
                .overlay(alignment: .leading) {
                    if isCommitted {
                        UnevenRoundedRectangle(
                            topLeadingRadius: Theme.bubbleCornerRadius,
                            bottomLeadingRadius: Theme.bubbleCornerRadius,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                        .fill(themeEngine.committedAccent)
                        .frame(width: 3)
                    }
                }
        }
    }

    // MARK: - User Bubble (right-aligned, no avatar)

    private var userBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer(minLength: 40)

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if isCommitted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(themeEngine.committedAccent)
                    }

                    Text(characterName ?? "You")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    if characterName != nil {
                        Text("(you)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(content)
                    .font(characterName != nil ? themeEngine.manuscriptFont : .body)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.bubbleCornerRadius)
                            .fill(isCommitted ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.accentColor.opacity(0.1)))
                    )
                    .overlay(alignment: .leading) {
                        if isCommitted {
                            UnevenRoundedRectangle(
                                topLeadingRadius: Theme.bubbleCornerRadius,
                                bottomLeadingRadius: Theme.bubbleCornerRadius,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                            .fill(themeEngine.committedAccent)
                            .frame(width: 3)
                        }
                    }
            }

            if let characterName {
                CharacterAvatarView(
                    name: characterName,
                    imageData: characterImageData,
                    size: Theme.avatarSize
                )
            }
        }
    }

    // MARK: - Character Bubble (left-aligned, with avatar)

    private var characterBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            if isContinuation {
                // Reserve avatar gutter so the bubble stays in the same
                // dialogue column as the speaker's first segment.
                Color.clear.frame(width: Theme.avatarSize, height: 1)
            } else {
                CharacterAvatarView(
                    name: characterName ?? "Character",
                    imageData: characterImageData,
                    size: Theme.avatarSize
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                if !isContinuation {
                    HStack(spacing: 4) {
                        Text(characterName ?? "Character")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        if isCommitted {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(themeEngine.committedAccent)
                        }

                        if isStreaming {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }
                }

                Text(content)
                    .font(themeEngine.manuscriptFont)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.bubbleCornerRadius)
                            .fill(.ultraThinMaterial)
                            .overlay(alignment: .leading) {
                                if isCommitted {
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: Theme.bubbleCornerRadius,
                                        bottomLeadingRadius: Theme.bubbleCornerRadius,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: 0
                                    )
                                    .fill(themeEngine.committedAccent)
                                    .frame(width: 3)
                                }
                            }
                    }
            }

            Spacer(minLength: 40)
        }
    }
}
