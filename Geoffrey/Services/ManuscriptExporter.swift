import Foundation

enum ManuscriptFormat: String, CaseIterable, Identifiable {
    case markdown
    case plainText
    case rtf

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .markdown:  "Markdown (.md)"
        case .plainText: "Plain Text (.txt)"
        case .rtf:       "Rich Text (.rtf)"
        }
    }
    var fileExtension: String {
        switch self {
        case .markdown:  "md"
        case .plainText: "txt"
        case .rtf:       "rtf"
        }
    }
}

struct ManuscriptOptions {
    var title: String = ""
    var author: String = ""
    var includeUncommitted: Bool = false
}

/// Static walk over a Session's committed exchanges → formatted manuscript.
/// Pure function with no SwiftData mutation; safe to call from a preview pane.
enum ManuscriptExporter {

    static func export(
        session: Session,
        format: ManuscriptFormat,
        options: ManuscriptOptions = ManuscriptOptions()
    ) -> Data {
        let text = renderText(session: session, format: format, options: options)
        switch format {
        case .markdown, .plainText:
            return Data(text.utf8)
        case .rtf:
            return Data(text.utf8)
        }
    }

    /// Returns the rendered manuscript as a string. Use for live preview.
    static func renderText(
        session: Session,
        format: ManuscriptFormat,
        options: ManuscriptOptions = ManuscriptOptions()
    ) -> String {
        let exchanges = collectExchanges(session: session, options: options)
        let speakingNames = session.world?.characters.map(\.name) ?? []
        let chapters = chapterize(exchanges)

        switch format {
        case .markdown:
            return renderMarkdown(chapters: chapters, speakingNames: speakingNames, options: options)
        case .plainText:
            return renderPlainText(chapters: chapters, speakingNames: speakingNames, options: options)
        case .rtf:
            return renderRTF(chapters: chapters, speakingNames: speakingNames, options: options)
        }
    }

    // MARK: - Collection

    private static func collectExchanges(session: Session, options: ManuscriptOptions) -> [Exchange] {
        // Filter to active siblings (capability h regenerate / branch-from-here
        // hides inactive alternates) and skip stale sub-exchanges (capability a
        // stale-cascade flag — preserved in DB but not part of the canon).
        let all = session.exchanges
            .filter { $0.alternateActive && !$0.isStale }
            .sorted { $0.orderIndex < $1.orderIndex }
        return options.includeUncommitted ? all : all.filter(\.committed)
    }

    private struct Chapter {
        var title: String?
        var exchanges: [Exchange]
    }

    private static func chapterize(_ exchanges: [Exchange]) -> [Chapter] {
        var chapters: [Chapter] = []
        var current = Chapter(title: nil, exchanges: [])
        for exchange in exchanges {
            if exchange.isChapterStart && !current.exchanges.isEmpty {
                chapters.append(current)
                current = Chapter(title: nil, exchanges: [])
            }
            if exchange.isChapterStart {
                current.title = exchange.chapterTitle
            }
            current.exchanges.append(exchange)
        }
        if !current.exchanges.isEmpty { chapters.append(current) }
        return chapters
    }

    // MARK: - Segment expansion

    /// Logical segment to render, post-parse. User-character dialog flattens to
    /// a single .character segment; assistant text expands via ResponseParser.
    private struct RenderSegment {
        let kind: SegmentType
        let speaker: String
        let text: String
    }

    private static func segments(for exchange: Exchange, speakingNames: [String]) -> [RenderSegment] {
        let trimmed = exchange.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if exchange.role == "user" {
            // Only render user exchanges when attributable (character mode);
            // unattributed user input is a GM cue, not narrative content.
            guard let name = exchange.characterName, !name.isEmpty else { return [] }
            return [RenderSegment(kind: .character, speaker: name, text: trimmed)]
        }

        // Assistant: parse [Name] tags into segments. If none, treat as narration.
        if let parsed = ResponseParser.parseSegments(from: trimmed, speakingNames: speakingNames) {
            return parsed.map { RenderSegment(kind: $0.type, speaker: $0.characterName, text: $0.content) }
        }
        return [RenderSegment(kind: .narration, speaker: "", text: trimmed)]
    }

    // MARK: - Markdown

    private static func renderMarkdown(chapters: [Chapter], speakingNames: [String], options: ManuscriptOptions) -> String {
        var out: [String] = []
        if !options.title.isEmpty { out.append("# \(options.title)\n") }
        if !options.author.isEmpty { out.append("_by \(options.author)_\n") }

        for (idx, chapter) in chapters.enumerated() {
            let heading = chapter.title.flatMap { $0.isEmpty ? nil : $0 }
                ?? "Chapter \(idx + 1)"
            out.append("## \(heading)\n")

            for exchange in chapter.exchanges {
                for segment in segments(for: exchange, speakingNames: speakingNames) {
                    switch segment.kind {
                    case .character:
                        out.append("**\(segment.speaker):** \(segment.text)\n")
                    case .narration:
                        out.append("\(segment.text)\n")
                    case .action:
                        out.append("_\(segment.text)_\n")
                    }
                }
            }
        }
        return out.joined(separator: "\n")
    }

    // MARK: - Plain text

    private static func renderPlainText(chapters: [Chapter], speakingNames: [String], options: ManuscriptOptions) -> String {
        var out: [String] = []
        if !options.title.isEmpty { out.append(options.title) }
        if !options.author.isEmpty { out.append("by \(options.author)") }
        if !out.isEmpty { out.append("") }

        for (idx, chapter) in chapters.enumerated() {
            let heading = chapter.title.flatMap { $0.isEmpty ? nil : $0 }
                ?? "Chapter \(idx + 1)"
            out.append(heading)
            out.append(String(repeating: "-", count: heading.count))
            out.append("")

            for exchange in chapter.exchanges {
                for segment in segments(for: exchange, speakingNames: speakingNames) {
                    switch segment.kind {
                    case .character:
                        out.append("\(segment.speaker): \(segment.text)")
                    case .narration:
                        out.append(segment.text)
                    case .action:
                        out.append("(\(segment.text))")
                    }
                    out.append("")
                }
            }
        }
        return out.joined(separator: "\n")
    }

    // MARK: - RTF

    private static func renderRTF(chapters: [Chapter], speakingNames: [String], options: ManuscriptOptions) -> String {
        var body = ""
        if !options.title.isEmpty {
            body += "{\\b\\fs36 \(rtfEscape(options.title))}\\par\n"
        }
        if !options.author.isEmpty {
            body += "{\\i by \(rtfEscape(options.author))}\\par\n"
        }
        if !options.title.isEmpty || !options.author.isEmpty { body += "\\par\n" }

        for (idx, chapter) in chapters.enumerated() {
            let heading = chapter.title.flatMap { $0.isEmpty ? nil : $0 }
                ?? "Chapter \(idx + 1)"
            body += "{\\b\\fs28 \(rtfEscape(heading))}\\par\\par\n"

            for exchange in chapter.exchanges {
                for segment in segments(for: exchange, speakingNames: speakingNames) {
                    switch segment.kind {
                    case .character:
                        body += "{\\b \(rtfEscape(segment.speaker)):} \(rtfEscape(segment.text))\\par\n"
                    case .narration:
                        body += "\(rtfEscape(segment.text))\\par\n"
                    case .action:
                        body += "{\\i \(rtfEscape(segment.text))}\\par\n"
                    }
                }
            }
        }

        return """
        {\\rtf1\\ansi\\ansicpg1252\\deff0\\nouicompat
        {\\fonttbl{\\f0\\fnil\\fcharset0 Helvetica;}}
        {\\colortbl;\\red0\\green0\\blue0;}
        \\fs24
        \(body)}
        """
    }

    private static func rtfEscape(_ s: String) -> String {
        var out = ""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\\": out.append("\\\\")
            case "{":  out.append("\\{")
            case "}":  out.append("\\}")
            case "\n": out.append("\\par\n")
            default:
                if scalar.value < 128 {
                    out.append(Character(scalar))
                } else {
                    // RTF wants signed 16-bit ints for non-ASCII via \uN?
                    let v = Int32(scalar.value)
                    let signed = v > 32767 ? v - 65536 : v
                    out.append("\\u\(signed)?")
                }
            }
        }
        return out
    }
}
