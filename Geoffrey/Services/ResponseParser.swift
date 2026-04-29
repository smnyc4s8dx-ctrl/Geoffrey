import Foundation

enum SegmentType {
    case narration
    case character
    case action
}

struct CharacterSegment: Identifiable {
    let id = UUID()
    let type: SegmentType
    let characterName: String
    let content: String
}

enum ResponseParser {

    /// Resolve a `[Tag]` into a canonical character name from `speakingNames`,
    /// or `nil` if it should be treated as narration.
    ///
    /// Resolution rules (in priority order):
    /// 1. Exact case-insensitive match against a canonical name.
    /// 2. Canonical-starts-with-tag prefix match (the LLM emitted a
    ///    truncation of a canonical name). Only succeeds if **exactly one**
    ///    canonical name has the tag as a prefix.
    /// 3. Otherwise, ambiguous or unknown → `nil`. The caller will treat the
    ///    segment as narration and log a warning.
    ///
    /// Reserved tags `Narrator` and `Action` are handled by the caller, not
    /// here, so this resolver only ever sees character-name candidates.
    ///
    /// The previous implementation used bidirectional
    /// `localizedCaseInsensitiveContains`, which let a canonical "Tho"
    /// silently absorb a `[Thorne]` tag (and vice versa). Capability (a)
    /// multi-character orchestration cannot tolerate that — speaker
    /// attribution drifts and stale-cascade scoping breaks when the wrong
    /// canonical is recorded on `Exchange.characterName`.
    static func resolveCharacterTag(_ tag: String, speakingNames: [String]) -> String? {
        if let exact = speakingNames.first(where: {
            $0.localizedCaseInsensitiveCompare(tag) == .orderedSame
        }) {
            return exact
        }

        let prefixMatches = speakingNames.filter { canonical in
            guard canonical.count > tag.count else { return false }
            return canonical.range(of: tag, options: [.caseInsensitive, .anchored]) != nil
        }

        if prefixMatches.count == 1 {
            return prefixMatches.first
        }

        if prefixMatches.count > 1 {
            print("[ResponseParser] Ambiguous tag [\(tag)] matched canonicals: \(prefixMatches.joined(separator: ", ")) — treating as narration")
        }
        return nil
    }

    /// Parse a response into segments. Recognizes `[Name]` tags for character
    /// attribution, `[Narrator]` for scene description, and `[Action]` for
    /// non-dialogue character action.
    ///
    /// Tags that don't resolve to a canonical character name (per
    /// `resolveCharacterTag`) are dropped and their content is folded into
    /// the surrounding narration. Returns `nil` if no tags were found, so
    /// callers can fall back to rendering the response as a single block.
    static func parseSegments(from text: String, speakingNames: [String]) -> [CharacterSegment]? {
        let pattern = "\\[([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        struct ResolvedTag {
            let range: NSRange
            let kind: SegmentType
            let canonicalName: String  // empty for narration/action
        }

        let resolved: [ResolvedTag] = matches.compactMap { match in
            let name = nsText.substring(with: match.range(at: 1))
            if name.localizedCaseInsensitiveCompare("Narrator") == .orderedSame {
                return ResolvedTag(range: match.range, kind: .narration, canonicalName: "")
            }
            if name.localizedCaseInsensitiveCompare("Action") == .orderedSame {
                return ResolvedTag(range: match.range, kind: .action, canonicalName: "")
            }
            if let canonical = resolveCharacterTag(name, speakingNames: speakingNames) {
                return ResolvedTag(range: match.range, kind: .character, canonicalName: canonical)
            }
            print("[ResponseParser] Unresolved tag [\(name)] — treating as narration")
            return nil
        }

        guard !resolved.isEmpty else { return nil }

        var segments: [CharacterSegment] = []

        // Untagged text before the first tag → narration
        if let first = resolved.first, first.range.location > 0 {
            let preamble = nsText.substring(with: NSRange(location: 0, length: first.range.location))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !preamble.isEmpty {
                segments.append(CharacterSegment(type: .narration, characterName: "", content: preamble))
            }
        }

        for (i, tag) in resolved.enumerated() {
            let contentStart = tag.range.location + tag.range.length
            let contentEnd = i + 1 < resolved.count ? resolved[i + 1].range.location : nsText.length

            var content = nsText.substring(with: NSRange(location: contentStart, length: contentEnd - contentStart))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if content.hasPrefix(":") {
                content = String(content.dropFirst()).trimmingCharacters(in: .whitespaces)
            }

            guard !content.isEmpty else { continue }

            segments.append(CharacterSegment(
                type: tag.kind,
                characterName: tag.canonicalName,
                content: content
            ))
        }

        return segments.isEmpty ? nil : segments
    }
}
