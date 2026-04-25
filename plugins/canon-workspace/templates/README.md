# Canon workspace

A maintained canon distilled from a corpus of exploratory conversations.

## Layout

- `synthesis.md` — the canon. Single source of truth for what has been learned.
- `process.md` — the method *and* the authoritative schema of this canon (kinds, sections, classification rules, display conventions). Revise when the method or schema evolves.
- `source-log.md` — append-only record of integration events.
- `schema-log.md` — append-only record of schema events (initial adoption, evolution, schema-fit observations).
- `sources/` — immutable preserved source files. Read-only after capture.
- `extractions/` — structured per-source classifications (schema v1). Written only by the `source-extractor` subagent.
- `drafts/` — spin-off detail files as material demands.
- `review/` — generated review artifacts (gitignored, disposable).

## Commands

- `/canon-workspace:integrate-source <path>` — integrate a new source into the canon.
- `/canon-workspace:canon-review` — render the canon for a directional-alignment pass.
- `/canon-workspace:evolve-schema` — revise the schema with migration.
- `/canon-workspace:evolve-ux` — revise the renderer.

See `process.md` for the working loop, the `## Schema` section, artifact addressing, confidence markers, and anti-patterns.
