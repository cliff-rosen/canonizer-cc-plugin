---
name: thesis-argumentation
title: Thesis argumentation
description: Building a thesis argument — organizing the arguments, the supporting evidence, counter-arguments, and unresolved questions. Converges on a thesis with supporting pillars and handled counters. Use when the effort is to produce a defensible position, paper, or persuasive document.
---

## Schema

This section is the authoritative record of the canon's shape. Subagents read it on every invocation and defer to it; any hardcoded defaults in their system prompts are fallbacks, never overrides. When the schema changes here, subagents pick it up next invocation.

### Convergence target

This canon converges on **a thesis with supporting pillars and handled counters**. The finished state has the thesis sentence at the top of `## Core structure`, followed by 3–5 pillars (the independent arguments that support it) and a brief summary of the key counter-arguments addressed. A reader can state the thesis, anticipate its defense, and see which challenges have been engaged.

*Done is not "every argument and piece of evidence is recorded."* Done is "the thesis is sharp, the pillars are named and mutually-reinforcing, and the counter-arguments that could undo the thesis have been surfaced and addressed." Evidence without a spine is filing, not argumentation.

### Kinds (atomic unit taxonomy)

Each atomic unit extracted from a source is classified as one of these kinds:

- **argument** — a reason advanced in support of the thesis.
- **evidence** — a fact, citation, observation, or example that supports an argument.
- **counter-argument** — a challenge or opposing consideration raised in the source.
- **question** — an open question the source poses without answering.

### Sections (canon structure)

`synthesis.md` has these sections, in this order:

- **Overview** — one-paragraph statement of what this canon represents, including the thesis itself. Populated by the human; not touched by subagents.
- **Core structure** — the few load-bearing pieces that organize the rest of the canon. A small named set (typically 3–7 elements), each a one-sentence gloss. Populated by the human; `source-extractor` proposes candidates via the extraction JSON and `canon-updater` surfaces them for human promotion. Subagents never write here directly.
- **Arguments** — receives units of kind `argument`.
- **Evidence** — receives units of kind `evidence`.
- **Counter-arguments** — receives units of kind `counter-argument`.
- **Open questions** — receives units of kind `question`. Retired when answered.
- **Glossary** — populated manually as terminology stabilizes. Not touched by subagents.

### Classification rules

- Every `adds` unit enters its section as a new bullet prefixed `(tentative)`, suffixed with `— <source_id>#<unit.id>`.
- Every `conflicts` unit becomes an `(in flight)` annotation immediately beneath the existing element it relates to, citing the conflicting unit. The existing element's text is NOT modified.
- Every `supports` unit is recorded in the source-log entry; no structural change to `synthesis.md`.
- **Counter-arguments** against a specific argument may optionally also be inlined beneath that argument as `(in flight)`; otherwise they live in the Counter-arguments section.
- Sections marked "Populated by the human" or "Not touched by subagents" are never edited by subagents.

### Display conventions

Hints the renderer consults when producing `review/` artifacts:

- Confidence markers must be visually distinct: `(tentative)` soft, `(in flight)` urgent, unmarked plain.
- Counter-arguments render visually distinct from arguments.
- Evidence bullets link prominently to their source fragment.
- Every bullet is clickable through to its source-log entry and underlying source fragment.
- Sections render in the order declared above.
- Sections not declared above (if any are added later) get a default render block.
