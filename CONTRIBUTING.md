# Contributing to Geoffrey

Thanks for your interest in contributing.

## Maintenance posture

Active maintenance is **low**. PRs are welcome but merges may be slow. The maintainer reserves direction on the project's design invariants (see [README.md](README.md#design-invariants)). Before investing in a substantial change, please open an issue to discuss.

## Building locally

Requires macOS 14+ and Xcode 16+. No external Swift packages — the project is deliberately dependency-free.

```bash
xcodebuild -project Geoffrey.xcodeproj -scheme Geoffrey -destination 'platform=macOS' build
```

## How to submit a PR

1. **One topic per PR.** Schema additions, view-layer changes, and engine refactors should be separate PRs.
2. **Build clean.** No `--no-verify`, no `xcuserdata` commits.
3. **Match the existing style.** Look at neighboring code first. Default to no comments; only add when the *why* is non-obvious (a hidden constraint, a subtle invariant, a workaround for a specific bug).
4. **Don't add features beyond what's discussed.** A bug fix doesn't need surrounding cleanup. Three similar lines beats a premature abstraction.
5. **No new dependencies** unless discussed in an issue first.
6. **No content moderation, telemetry, or auto-uploads** — these violate invariant #8.

## Code areas

- `Geoffrey/Models/` — SwiftData `@Model` classes. Schema additions should be default-valued for lightweight migration safety.
- `Geoffrey/Services/` — engine layer (inference backends, response parser, context assembler, exporters, monitors).
- `Geoffrey/ViewModels/` — `@Observable @MainActor` view models.
- `Geoffrey/Views/` — SwiftUI views, organized by area (`Canvas/`, `Cards/`, `Inspector/`, `Settings/`, `Sidebar/`, `Components/`).

## What's actively wanted

Good first contributions:

- **Cloud backend implementations** — `AnthropicBackend`, `OpenRouterBackend` plugging into the `InferenceBackend` protocol. Translate `ChatMessage` to provider format, store API keys in Keychain, wire opt-in via an inference profile.
- **`FoundationModelsBackend`** — on-device helper inference (Apple Intelligence). Useful for the "helper backend" slot on capability (a)/(d) work.
- **Multi-character orchestration** — `SpeakerInitiativeRoller` (pure-function personality-weighted dice), per-character sequential generation refactor in `SessionViewModel`, stale-cascade UI on mid-chain rejection. Schema fields (`extroversion`, `mutedInScene`, `turnGroupID`, `isStale`) are already in place.
- **Lorebook keyword-trigger activation** — `TriggerRule` rows are already populated by Tavern card imports; runtime needs to read them and auto-include lore when keywords appear in recent dialogue.
- **Theme content** — additional palettes, font pairings, background imagery.
- **Tavern Card import/export edge cases** — handle more V3 fields, character book imports, regex-rule sanitization.

## What's intentionally out of scope

- **Content moderation / filters** — invariant #8 (content-agnostic).
- **Telemetry / analytics / crash auto-upload** — invariant #8. Local logging is fine; auto-uploading anything is not.
- **Memory stream / embeddings / RAG** — invariant #2 (the card *is* the memory). Forgetting is a feature.
- **Round-robin speaker selection** — invariant #4 (probabilistic, not round-robin).
- **Mocking LM Studio in tests** — if the local server is available, integration tests use it. Don't mock the wire format.

## Reporting issues

When filing a bug, include:

- macOS version
- Xcode version
- Inference backend (LM Studio / Ollama / etc.) and model name
- Steps to reproduce
- Expected vs actual behavior

## License

By contributing, you agree your contributions will be licensed under the [MIT License](LICENSE).
