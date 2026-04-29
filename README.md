# Geoffrey

A native macOS app for worldbuilding and AI-assisted fiction writing. Build story worlds with locations, characters, and lore cards, then walk through them in live LLM-powered dialogue. The output is a manuscript of committed canonical exchanges.

## Status

**Active maintenance: low.** Open-sourced to invite community contribution. PRs are welcome; merges may be slow. The project's strategic direction is preserved — before investing in a substantial change, please open an issue to discuss.

## What it does

- **Worldbuilding** — Projects contain worlds; worlds contain Locations, Characters, and Lore cards. Per-project theme (palette, fonts, backgrounds).
- **Card-based memory** — The card *is* the memory. No embeddings, no memory stream — your character/location/lore cards carry the context the LLM sees. Forgetting is a feature.
- **D&D-style narration** — Play as Director (GM), Author, GM (narrator-only), or Character mode. The AI fills the other roles.
- **Multi-character scenes** — Multiple characters present and speaking; the LLM emits per-character tagged dialogue (`[CharacterName]`, `[Narrator]`, `[Action]`).
- **Regenerate / branch / commit** — Mid-stream cancel preserves partial output. Swipe deck for alternate takes. The `Exchange.committed` flag is the universal undo for everything you wrote.
- **Manuscript export** — Export committed canon to Markdown, RTF, or plain text. Right-click any exchange to mark a chapter break.
- **Tavern Card V2/V3** — Import & export character cards in PNG embed + JSON.
- **Inference profiles** — Saved bundles of (host, model, sampler config, helper backend). Switch between LM Studio, Ollama, llama.cpp server, or any OpenAI-compatible endpoint without restart.
- **Resource observability** — Status bar with connection, model, memory, context tokens, and latency.
- **Sandboxed, offline-first, content-agnostic.** No telemetry, no filters, no auto-uploads.

## Requirements

- **macOS 14+** (Sonoma or newer)
- **Xcode 16+**
- An OpenAI-compatible LLM endpoint. Recommended: [LM Studio](https://lmstudio.ai/) — free, runs locally on Mac. Geoffrey also works with Ollama, llama.cpp server, or the OpenAI API itself.

No external Swift packages. Geoffrey is deliberately dependency-free.

## Build & run

```bash
git clone https://github.com/<user>/Geoffrey.git
cd Geoffrey
open Geoffrey.xcodeproj
```

In Xcode: select the `Geoffrey` scheme, target macOS, build & run (⌘R). From the command line:

```bash
xcodebuild -project Geoffrey.xcodeproj -scheme Geoffrey -destination 'platform=macOS' build
```

## First-run setup

1. Install [LM Studio](https://lmstudio.ai/) (or Ollama / llama.cpp server / your OpenAI-compatible endpoint of choice).
2. Load any chat-tuned model and start the local server. LM Studio: Developer tab → Start Server (default `http://127.0.0.1:1234`).
3. Launch Geoffrey. The onboarding wizard tests the connection and verifies the model can follow Geoffrey's tag format. If the format test passes, you're done.

## Design invariants

The project is shaped by eight load-bearing principles. Contributions should respect them:

1. **D&D framing.** Turn-based-ish, GM-led, manuscript-as-output — not MMORPG.
2. **The card is the memory.** No memory stream. No embeddings. The card carries what's important; forgetting is a feature.
3. **`Exchange.committed` is the universal undo flag.** Every mutation is exchange-bound; rejecting an exchange un-applies its effects.
4. **Probabilistic speaker initiative.** Personality-weighted, per-character — not round-robin. (Foundation in place; main implementation is open work.)
5. **Hardware-tier gating is first-class.** Ship features at full capability; gate honestly ("recommended for 32GB+"); never cripple to fit baseline.
6. **Sequential small calls beat one big call.** Per-character generation, sub-exchanges with `turnGroupID`, stale-cascade UI on revert.
7. **Geoffrey is a client to external inference, offline-first.** Local servers are baseline. Cloud is opt-in only via inference profile.
8. **Content-agnostic.** Geoffrey is to AI models as Safari is to websites. No filters, no moderation, no NSFW blocking. The helper backend is for UX, never moderation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
