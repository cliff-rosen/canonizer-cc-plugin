---
name: product-discovery
title: Product discovery
description: Converging on what to build from exploratory product conversations — user needs, candidate features, constraints, and risks. Converges on a user-problem-solution triangle with bounded scope. Use when the effort is about product scoping, roadmap thinking, or requirements synthesis.
---

## Schema

This section is the authoritative record of the canon's shape. Subagents read it on every invocation and defer to it; any hardcoded defaults in their system prompts are fallbacks, never overrides. When the schema changes here, subagents pick it up next invocation.

### Convergence target

This canon converges on **a user-problem-solution triangle with bounded scope**. The finished state has 4–6 named elements in `## Core structure`: the core user, the core job to be done, the candidate solution shape, the binding constraints, and the critical risks. A reader can answer "who, what, why, what's the shape, what's in the way" in one paragraph.

*Done is not "every candidate feature is catalogued."* Done is "the user and job are crisply named, the solution shape is coherent, and the constraints and risks that bound it are explicit." A feature list without a named user and job is filing, not synthesis.

### Kinds (atomic unit taxonomy)

Each atomic unit extracted from a source is classified as one of these kinds:

- **need** — a user or stakeholder need the source describes.
- **feature** — a candidate feature, capability, or behavior proposed in the source.
- **constraint** — a boundary the solution must respect (technical, business, regulatory, temporal).
- **risk** — a failure mode, open risk, or concern raised in the source.
- **question** — an open question the source poses without answering.

### Sections (canon structure)

`synthesis.md` has these sections, in this order:

- **Overview** — one-paragraph statement of what this canon represents. Populated by the human; not touched by subagents.
- **Core structure** — the few load-bearing pieces that organize the rest of the canon. A small named set (typically 3–7 elements), each a one-sentence gloss. Populated by the human; `source-extractor` proposes candidates via the extraction JSON and `canon-updater` surfaces them for human promotion. Subagents never write here directly.
- **User needs** — receives units of kind `need`.
- **Candidate features** — receives units of kind `feature`.
- **Constraints** — receives units of kind `constraint`.
- **Risks** — receives units of kind `risk`.
- **Open questions** — receives units of kind `question`. Retired when answered.
- **Glossary** — populated manually as terminology stabilizes. Not touched by subagents.

### Classification rules

- Every `adds` unit enters its section as a new bullet prefixed `(tentative)`, suffixed with `— <source_id>#<unit.id>`.
- Every `conflicts` unit becomes an `(in flight)` annotation immediately beneath the existing element it relates to, citing the conflicting unit. The existing element's text is NOT modified.
- Every `supports` unit is recorded in the source-log entry; no structural change to `synthesis.md`.
- Sections marked "Populated by the human" or "Not touched by subagents" are never edited by subagents.

### Display conventions

Hints the renderer consults when producing `review/` artifacts:

- Confidence markers must be visually distinct: `(tentative)` soft, `(in flight)` urgent, unmarked plain.
- Open questions and risks are visually distinct from features and needs.
- Every bullet is clickable through to its source-log entry and underlying source fragment.
- Sections render in the order declared above.
- Sections not declared above (if any are added later) get a default render block.
