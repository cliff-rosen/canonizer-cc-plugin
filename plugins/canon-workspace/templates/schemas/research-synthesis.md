---
name: research-synthesis
title: Research synthesis
description: Synthesizing findings from research-oriented conversations — distilling what has been learned about a question, what methods produced those findings, and what limits apply. Use this when the effort is investigative, evidence-oriented, or empirical.
---

## Schema

This section is the authoritative record of the canon's shape. Subagents read it on every invocation and defer to it; any hardcoded defaults in their system prompts are fallbacks, never overrides. When the schema changes here, subagents pick it up next invocation.

### Kinds (atomic unit taxonomy)

Each atomic unit extracted from a source is classified as one of these kinds:

- **hypothesis** — a proposition being tested or considered.
- **finding** — a result or observation supported by the source.
- **method** — how a finding was produced; a technique, procedure, or approach.
- **limitation** — a caveat, boundary condition, or acknowledged weakness.
- **question** — an open question the source poses without answering.

### Sections (canon structure)

`synthesis.md` has these sections, in this order:

- **Overview** — one-paragraph statement of what this canon represents. Populated by the human; not touched by subagents.
- **Hypotheses** — receives units of kind `hypothesis`.
- **Findings** — receives units of kind `finding`.
- **Methods** — receives units of kind `method`.
- **Limitations** — receives units of kind `limitation`.
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
- Open questions are isolated from findings and hypotheses.
- Every bullet is clickable through to its source-log entry and underlying source fragment.
- Sections render in the order declared above.
- Sections not declared above (if any are added later) get a default render block.
