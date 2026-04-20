# Canon workspace

A maintained canon distilled from a corpus of exploratory conversations.

## Layout

- `synthesis.md` — the canon. Single source of truth for what has been learned.
- `process.md` — the method. How synthesis is done in this workspace. Revise when the method evolves.
- `source-log.md` — append-only record of integration events.
- `sources/` — immutable preserved source files. Read-only after capture.
- `extractions/` — structured per-source classifications (schema v1). Written only by the `source-extractor` subagent.
- `drafts/` — spin-off detail files as material demands.
- `review/` — generated review artifacts (gitignored, disposable).

## Commands

- `/canon-workspace:integrate-source <path>` — integrate a new source into the canon.
- `/canon-workspace:canon-review` — render the canon for a directional-alignment pass.

See `process.md` for the working loop, artifact addressing, confidence markers, and anti-patterns.
