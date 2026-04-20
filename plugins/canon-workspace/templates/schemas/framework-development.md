---
name: framework-development
title: Framework development
description: Developing a conceptual framework from exploratory conversations — finding the right vocabulary, distinctions, and claims. Use this when the effort is about hardening a way of thinking about something.
---

## Schema

This section is the authoritative record of the canon's shape. Subagents read it on every invocation and defer to it; any hardcoded defaults in their system prompts are fallbacks, never overrides. When the schema changes here, subagents pick it up next invocation.

### Kinds (atomic unit taxonomy)

Each atomic unit extracted from a source is classified as one of these kinds:

- **concept** — a named idea, frame, or object the source introduces or uses.
- **claim** — an assertion the source makes about how something is.
- **assumption** — something the source takes as given, whether stated or implied.
- **distinction** — a named contrast between two things.
- **objection** — a challenge or counter-consideration raised in the source.
- **question** — an open question the source poses without answering.

### Sections (canon structure)

`synthesis.md` has these sections, in this order:

- **Overview** — one-paragraph statement of what this canon represents. Populated by the human; not touched by subagents.
- **Core concepts** — receives units of kind `concept`.
- **Claims** — receives units of kind `claim`.
- **Assumptions** — receives units of kind `assumption`.
- **Distinctions** — receives units of kind `distinction`.
- **Open questions** — receives units of kind `question`. Retired when answered.
- **Glossary** — populated manually as terminology stabilizes. Not touched by subagents.

### Classification rules

- Every `adds` unit enters its section as a new bullet prefixed `(tentative)`, suffixed with `— <source_id>#<unit.id>`.
- Every `conflicts` unit becomes an `(in flight)` annotation immediately beneath the existing element it relates to, citing the conflicting unit. The existing element's text is NOT modified.
- Every `supports` unit is recorded in the source-log entry; no structural change to `synthesis.md`.
- **Objections** are treated as conflicts against the claim they `relates_to`. Same `(in flight)` annotation pattern beneath the claim.
- Sections marked "Populated by the human" or "Not touched by subagents" are never edited by subagents.

### Display conventions

Hints the renderer consults when producing `review/` artifacts:

- Confidence markers must be visually distinct: `(tentative)` soft, `(in flight)` urgent, unmarked plain.
- Open questions are isolated from claims — a sidebar, a separate pane, or an explicitly distinct region.
- Every bullet is clickable through to its source-log entry and underlying source fragment.
- Sections render in the order declared above.
- Sections not declared above (if any are added later) get a default render block.
