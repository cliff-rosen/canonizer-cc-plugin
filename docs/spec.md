# Canon Workspace — Claude Code Plugin Spec

**Version:** 0.4 (v0 scope)
**Changes from 0.3:** `process.md` gains an authoritative `## Schema` section (Kinds, Sections, Classification rules, Display conventions). Subagents read it on every invocation and defer to it; hardcoded lists in the subagent prompts are fallbacks only. This is the foundation for schema + UX co-evolution — see `docs/build-plan.md` Phases 1–8.
**Changes from 0.2:** synthesis is delegated to a second subagent, `canon-updater` (§4.5). `/integrate-source` becomes a thin four-step orchestrator; the main agent never walks the N atomic units.
**Changes from 0.1:** extraction output is persisted to `extractions/<source_id>.json` by the `source-extractor` subagent, which returns only a short pointer rather than inline JSON.
**Audience:** Claude Code, building this plugin
**Source of truth for behavior:** `from-conversation-to-canon.md` (Rosen, April 2026)

---

## 1. Overview

A Claude Code plugin that packages a discipline: turning a corpus of exploratory conversations into a maintained canonical artifact. A canon workspace is a git-backed directory with a fixed anatomy — immutable `sources/`, structured `extractions/`, a living `synthesis.md`, an append-only `source-log.md`, and a `process.md` that states the method *and* carries the authoritative schema of the canon.

The plugin does not impose a schema. It ships a small set of default schema templates and enters a collaboration with the user at initialization to choose or customize one. Every subagent reads `process.md`'s schema on every invocation — the canon's shape is a product of dialog, not a hardcoded assumption.

### Who it's for

Anyone who has spent weeks or months exploring a topic across many long conversations and wants the thinking to converge into an inspectable, reusable structure — the kind downstream artifacts (a proposal, a thesis, a product spec) are drawn from. The canon *is* that structure; the workspace is where it lives.

### One-time setup — the schema sync-up

This is where the collaboration begins. The user is introduced to the notion of a schema, picks one that fits, and commits to it (for now — schema is revisable later).

1. **User action:** runs `/canon-workspace:canon-init` in a fresh directory.
2. **Main agent action:** scaffolds the workspace (directories, `synthesis.md`, `process.md`, `source-log.md`, `schema-log.md`, `.gitignore`, initial git commit).
3. **Main agent action:** presents the default schema templates — each with a short description of what it's suited for. Examples the plugin ships (illustrative; final set TBD):
   - **Framework development** — concepts, claims, assumptions, distinctions, objections, questions.
   - **Research synthesis** — hypotheses, findings, methods, limitations, open questions.
   - **Product discovery** — user needs, features, constraints, risks, open questions.
   - **Thesis argumentation** — arguments, evidence, counter-arguments, open questions.
4. **User choice:** accept the selected default, replace with a provided alternative, or collaborate with the agent to draft a custom schema from scratch.
5. **Main agent action:** writes the agreed schema into `process.md`'s `## Schema` section, generates `synthesis.md`'s section headers from it, and records the event in `schema-log.md` as entry #1.

The schema defines:
- **Kinds** — the atomic-unit taxonomy (varies by template).
- **Sections** — how those kinds are organized in `synthesis.md`.
- **Classification rules** — how atomic units become canon entries with confidence markers.
- **Display conventions** — how the canon renders in the review projection.

### The working loop — add, review, refine

For each new source, the loop has three steps. It may iterate (add several sources, review the accumulated canon, refine across them) before committing.

#### Step 1 — Add

1. **User action:** exports a source transcript as markdown; runs `/canon-workspace:integrate-source <path>`.
2. **Main agent action:** validates inputs; copies the source to `sources/<source_id>.md`. From here `sources/` is immutable, enforced by a `PreToolUse` hook.
3. **Main agent action (subagent dispatch):** invokes the `source-extractor` subagent with paths to the preserved source, `synthesis.md`, `process.md`, the `source_id`, and the workspace root. The subagent (tools: `Read`, `Write` scoped to `extractions/<source_id>.json`) reads source + canon + schema in its own context, writes the extraction file, and returns a single pointer line: `EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)`.
4. **Main agent action (subagent dispatch):** invokes the `canon-updater` subagent with the extraction path plus `synthesis.md`, `source-log.md`, `process.md`, `source_id`, and workspace root. The subagent (tools: `Read`, `Edit`, `Write` scoped to `synthesis.md` + `source-log.md`) reads the extraction and schema, applies incremental edits to `synthesis.md` with confidence markers, prepends a dated entry to `source-log.md`, and returns a single summary line: `UPDATED: synthesis.md (…) · source-log.md (…)`.
5. **Main agent action:** reports the two pointer lines to the user and directs them to run `/canon-workspace:canon-review`.

No atomic-unit detail passes through the main agent's context. All per-unit work happens in the two subagents' disposable contexts.

#### Step 2 — Review

1. **User action:** runs `/canon-workspace:canon-review`.
2. **Main agent action:** generates the **review projection** — an HTML render at `review/review-<timestamp>.html`. The render applies the Display conventions from `process.md`: confidence markers visually distinct (tentative soft, in-flight urgent); every canonical element clickable through to its provenance (source-log entry → extraction → source fragment); open questions isolated from claims; schema-fit observations from the subagents surfaced in a sidebar. The file is disposable (gitignored).
3. **User action:** opens the HTML in a browser. Reads. Forms judgments.

The review projection is where editorial work and schema/UX feedback originate. It is the primary review surface. `git diff` is an audit side-channel for inspecting raw changes before commit; it is not the review surface.

#### Step 3 — Refine

Based on what the review shows, the human refines *both* the synthesis content *and* the schema/UX themselves. Refinements:

- **Promote `(tentative)` claims to unmarked.** User directs the main agent to edit `synthesis.md`, or edits directly. Each removal is logged in `source-log.md` with a reason.
- **Resolve `(in flight)` conflicts.** User decides; main agent applies the decision; `source-log.md` records it.
- **Retire or merge open questions.**
- **Evolve the schema.** User action: `/canon-workspace:evolve-schema <intent>` (or a dialog). Main agent drafts edits to `process.md`'s `## Schema` section plus a migration plan for `synthesis.md`. User reviews and accepts. Entry added to `schema-log.md`. Subagents honor the new schema on their next invocation.
- **Evolve the UX.** User action: `/canon-workspace:evolve-ux <intent>` (or a dialog). Main agent (via a renderer-editor subagent) edits the renderer while preserving alignment invariants.

Refinements complete when the user is satisfied with this pass.

#### Step 4 — Commit

User commits via git. Nothing auto-commits.

### Projections of the canon

`synthesis.md` is the storage format. It is not the consumption format. The plugin generates projections on demand:

- **Review projection** — `/canon-workspace:canon-review` → `review/review-<timestamp>.html`. Geared for editorial work. Markers are loud; provenance is one click away; schema-fit observations are surfaced; disposable.
- **Consumption projection** — `/canon-workspace:canon-export <format>` (planned, post-v0) → a clean rendering for downstream use (proposal, thesis, onboarding doc). Markers stripped; organized for a reader; optionally scoped to a subset of sections or sources.

Both are derived from `synthesis.md` + `process.md`'s Schema and Display conventions. The review projection additionally consumes `source-log.md` and `extractions/` for provenance rendering.

### What is built today vs planned

**Built (v0.4):**
- `/canon-workspace:canon-init` — simple scaffold (schema-negotiation dialog is a Phase 2 upgrade).
- `source-extractor` and `canon-updater` subagents — schema-aware as of Phase 1; both defer to `process.md`'s `## Schema`.
- `canon-synthesis` skill — carries the discipline defaults and defers to `process.md`.
- `PreToolUse` hook — enforces `sources/` immutability.

**Planned** (see `docs/build-plan.md` for phase-by-phase detail):
- Schema negotiation dialog at init, with multiple default templates (Phase 2).
- Subagent schema-fit feedback channel (Phase 3).
- `/canon-workspace:integrate-source` thin orchestrator (Phase 4).
- Default renderer and `/canon-workspace:canon-review` (Phase 5).
- Schema ↔ UX alignment rules (Phase 6).
- `/canon-workspace:evolve-schema` and `/canon-workspace:evolve-ux` (Phases 7–8).

**Post-v0:** consumption projection (`/canon-workspace:canon-export`); duplicate-detector and other synthesis subagents (§11).

### Invariants summarized

- Canon ≠ corpus. Sources are frozen (hook).
- Provenance is addressable: every canonical element walks back to its verbatim fragment via `source-log.md` → `extractions/<id>.json` → `sources/<id>.md`.
- Schema is authoritative in `process.md`. Subagents read it every invocation.
- Mechanical work for agents, editorial work for humans. Editorial judgment surfaces in the review projection.
- Context curation by delegation. The main agent stays thin; per-unit work happens in subagent contexts that are discarded after use.

## 2. Non-goals (for v0)

- Not a full synthesis *editor*. The review projection is HTML and disposable — designed to inform editorial judgment, not execute it. Edits flow back through commands/dialog, not in-page manipulation.
- Not a consumption rendering pipeline. A polished consumption projection (`canon-export`, §11) is planned post-v0.
- Not a multi-user collaboration system. Single-user, git-backed.
- Not automating judgment calls (promotion, reconciliation, directional alignment, schema decisions). Those remain human.
- Not an ingestion pipeline for arbitrary formats. Sources are markdown files captured into `sources/`.

## 3. Workspace layout (what `/canon-init` creates)

```
<project-root>/
├── .claude-plugin/                  # if building inside a plugin marketplace
├── sources/                         # immutable source corpus (read-only after capture)
│   └── .gitkeep
├── extractions/                     # structured per-source classifications (schema v1)
│   └── .gitkeep                     # written only by the source-extractor subagent
├── synthesis.md                     # the canon — single source of truth
├── process.md                       # the method, inspectable and revisable
├── source-log.md                    # append-only log of integration events
├── drafts/                          # spin-off detail files as material demands
│   └── .gitkeep
├── review/                          # generated review artifacts (gitignored)
│   └── .gitkeep
├── .gitignore
└── README.md                        # orientation for a new contributor
```

Git is initialized on creation. Initial commit captures the scaffold.

## 4. Components

The plugin ships six components, mapped to the primitives Claude Code supports.

### 4.1 Slash command: `/canon-init`

**Purpose:** One-time workspace scaffolding.

**Behavior:**
1. Verify current directory is empty or confirm with user before proceeding.
2. Create the directory structure in §3.
3. Write `synthesis.md` seeded with an empty canon template (see §7.1).
4. Write `process.md` from the template in §7.2. This is the opinionated method document — it encodes the seven principles from *From Conversation to Canon* Part 3, the working loop, the confidence markers, and the anti-patterns.
5. Write `source-log.md` with its header.
6. Write `README.md` with orientation.
7. Write `.gitignore` (at minimum: `review/`, `*.tmp`, `.DS_Store`).
8. Run `git init` and make an initial commit: `"canon-init: scaffold workspace"`.

**Arguments:** none.

**Idempotency:** refuses to run if `synthesis.md` already exists unless passed `--force`.

### 4.2 Slash command: `/integrate-source <path>`

**Purpose:** Primary operation. Runs the working loop on a single source file. The command is a **thin orchestrator** — it calls two subagents that each do their work in isolated contexts, and it reports their short pointer/summary lines to the user. The main agent never walks the N atomic units.

**Behavior (the working loop, written down):**

1. **Validate.** Confirm `<path>` exists and is a markdown file. Confirm `synthesis.md`, `process.md`, and `source-log.md` exist.
2. **Preserve source.** Copy the file into `sources/<source_id>.md` (e.g., `conv-NNN-<slug>.md` where NNN is the next sequential number). Do not modify content. The stem is the `source_id`.
3. **Delegate extraction.** Invoke the `source-extractor` subagent (§4.4). Receive one pointer line:
   ```
   EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)
   ```
4. **Delegate canon update.** Invoke the `canon-updater` subagent (§4.5). Receive one summary line:
   ```
   UPDATED: synthesis.md (+Cc concepts, +Ll claims, +Aa assumptions, +Dd distinctions, +Qq questions, Ff flagged in-flight) · source-log.md (1 entry, Ss supports logged, Rr retired)
   ```
5. **Report to the user.** Surface the two subagent lines verbatim and point at `git diff` for review. Do not dump extraction contents. Do not commit.

**Arguments:** `<path>` (required) — path to the source file.

**Important:** This command does not commit to git. The human reviews through the UX (rendered via `/canon-review`) — the surface where editorial judgment happens — and uses `git diff` as a raw-changes audit before committing.

### 4.3 Slash command: `/canon-review`

**Purpose:** Generate a throwaway HTML rendering of the canon for a directional-alignment pass.

**Behavior:**
1. Read `synthesis.md`.
2. Render to `review/review-<timestamp>.html` with:
   - confidence markers visually highlighted (tentative, in-flight, stable)
   - internal cross-references made clickable
   - open questions surfaced in a sidebar
   - source-log entries accessible via hover or link
3. Open the file path for the user (don't attempt to launch a browser — just report the path).

**Arguments:** none.

**Note:** `review/` is gitignored. These artifacts are scaffolding, not product.

### 4.4 Subagent: `source-extractor`

**Purpose:** Read a full source file and **write** a structured classification to `extractions/<source_id>.json`, returning only a short pointer to the invoking agent. This keeps atomic-unit detail off the main agent's context entirely until the main agent explicitly decides to read it.

**Why a subagent:** sources are long conversations. The main agent needs its context for synthesis judgment, not raw reading. This is context curation.

**Tools:** `Read`, `Write`. Write is constrained by the system prompt to a single path: `extractions/<source_id>.json`.

**Inputs (passed by invoking agent):**
- absolute path to preserved source file (in `sources/`)
- absolute path to current `synthesis.md`
- absolute path to `process.md` (schema authority)
- `source_id` (typically the preserved source's filename stem)
- absolute path to the workspace root

**Output (final message, ≤ one line):**
- Success: `EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)[ · brief note]`
- Failure: `FAILED: <reason>`

The invoking agent relies on this line — and the file on disk — exclusively. The subagent does NOT return atomic units inline.

**System prompt focus:**
- Read `process.md` first; the `## Schema` section's **Kinds** list is authoritative. Defaults below are fallbacks when the section is absent.
- Extract atomic units per the kinds defined in the schema (defaults: concepts, claims, assumptions, distinctions, objections, questions).
- For each atomic unit, classify against current canon:
  - `supports` — reinforces an existing canonical claim.
  - `adds` — introduces something not yet in canon.
  - `conflicts` — contradicts, refines, or supersedes an existing claim.
- Include a verbatim source fragment (≤3 sentences) for each atomic unit.
- Write the full classification to `extractions/<source_id>.json` (schema v1, §6).
- Do NOT write anywhere else — not to the canon, the source, the log, or drafts.
- Do NOT propose canon edits. Classification only.
- Do NOT attempt reconciliation. Flag conflicts; don't resolve them.
- Do NOT return atomic units inline. Return only the pointer line.

### 4.5 Subagent: `canon-updater`

**Purpose:** Apply the mechanical consequences of an extraction: incremental edits to `synthesis.md` with confidence markers, a prepended entry in `source-log.md`, and retirement of resolved open questions. Runs in an isolated context so the invoking agent never ingests per-unit detail.

**Why a subagent:** walking N atomic units to propose canon updates is exactly the context-heavy work we want out of the main agent. This subagent does it; its context is discarded when it returns.

**Tools:** `Read`, `Edit`, `Write`. The system prompt constrains writes to `synthesis.md` and `source-log.md` only.

**Inputs (passed by invoking agent):**
- absolute path to `extractions/<source_id>.json`
- absolute path to `synthesis.md`
- absolute path to `source-log.md`
- absolute path to `process.md` (authority)
- the `source_id`
- absolute path to the workspace root

**Output (final message, ≤ one line):**
- Success: `UPDATED: synthesis.md (+Cc concepts, +Ll claims, +Aa assumptions, +Dd distinctions, +Qq questions, Ff flagged in-flight) · source-log.md (1 entry, Ss supports logged, Rr retired)[ · brief note]`
- Partial (ambiguous units skipped): `PARTIAL: <same counts> · skipped: <N> ambiguous units`
- Failure: `FAILED: <reason>`

**System prompt focus:**
- Read `process.md` first; its `## Schema` section is authoritative for kinds, sections, classification rules, and the section mapping. Hardcoded fallback table in the subagent prompt applies only if the schema section is missing.
- Validate the extraction's `schema` field is `"v1"`.
- For each atomic unit:
  - `adds` → append as a bulleted item under the section for its `kind`, prefixed `(tentative)`, suffixed with a source cite.
  - `supports` → no structural edit; record corroboration in the source-log entry.
  - `conflicts` → annotate the related element with an `(in flight)` note citing the conflicting unit. Never modify the existing claim.
- Retire any open question whose anchor is referenced by an `adds` or `supports` unit in this extraction.
- Prepend a dated source-log entry after the `---` separator at the top of `source-log.md`.
- Do NOT touch `sources/`, `extractions/`, `drafts/`, `review/`, or git.
- Do NOT resolve conflicts. Do NOT promote tentative claims. Do NOT paraphrase extractor text.
- Return one short line. No unit detail, no reasoning trace.

### 4.6 Skill: `canon-synthesis`

**Purpose:** Auto-activating context that ensures the main agent behaves correctly during ad-hoc canon work (not just during `/integrate-source`).

**Location:** `skills/canon-synthesis/SKILL.md`

**Activation description** (for the skill's frontmatter): activate when the conversation involves working on a canon workspace — detected by the presence of `synthesis.md` and `process.md` in the project root, or when the user discusses canon, synthesis, confidence markers, or the working loop.

**Content:** the skill teaches the *discipline*, not a single procedure:
- the two-subagent flow (`source-extractor` + `canon-updater`)
- artifact addressing and pointer resolution
- confidence marker conventions (§7.3)
- the anti-patterns (§7.4) — specifically what the agent must NOT do
- the division of labor: mechanical work for the agents, editorial judgment for the human

**Crucially,** the skill defers to `process.md` in the current workspace as the authoritative method. In particular, `process.md`'s `## Schema` section is authoritative for kinds, sections, classification rules, and display conventions. The skill carries defaults; `process.md` overrides.

### 4.7 Hook: protect `sources/`

**Purpose:** Enforce the structural invariant that preserved sources are immutable.

**Type:** `PreToolUse` hook on `Write` and `Edit` tools.

**Behavior:** If the target path is inside `sources/`, reject the tool call with a message explaining that sources are immutable after capture. If the user genuinely needs to modify a source (e.g., correcting a capture error), they can do it manually outside the agent.

**This is the one hard block.** Everything else (anti-patterns, editorial drift) is handled via the skill's soft-warning discipline.

## 5. File templates

### 7.1 `synthesis.md` initial template

Matches the sections declared by the default schema in `process.md`. If the user customizes the schema at init (forthcoming in `docs/build-plan.md` Phase 2), `synthesis.md` is generated to match.

```markdown
# Canon

*Last updated: <date>*

## Overview

<one-paragraph statement of what this canon represents>

## Core concepts

<empty — populated via integration>

## Claims

<empty — populated via integration>

## Assumptions

<empty — populated via integration>

## Distinctions

<empty — populated via integration>

## Open questions

<empty — populated via integration>

## Glossary

<empty — populated as terminology stabilizes>
```

### 7.2 `process.md` template

The template encodes:

- **Purpose** of the canon for this effort (user fills in).
- **The seven principles** from *From Conversation to Canon* Part 3.
- **Schema** — the authoritative structure: Kinds (atomic unit taxonomy), Sections (canon structure), Classification rules, Display conventions. Subagents read this on every invocation.
- **The working loop** as a numbered procedure (matches §4.2).
- **Confidence markers** (§7.3 below).
- **Anti-patterns** (§7.4 below).
- **Division of labor** — what the agent does vs. what the human does.

The file header notes: "This document is the method for this canon. It is a maintained artifact. Revise it when the method evolves."

### 7.3 Confidence markers

Three states, used inline in `synthesis.md`:

- **(tentative)** — the claim is a candidate; supported by ≥1 source but not yet corroborated.
- **(in flight)** — the claim is contested or being refined; a conflict was surfaced and not yet resolved.
- **unmarked** — stable; corroborated, not contested, not pending review.

When a marker is removed, the source log records the reason (`"stabilized by conv-NNN"` or `"resolved via human review <date>"`).

### 7.4 Anti-patterns (the agent MUST NOT do these)

1. **Auto-promote tentative claims to stable.** Removing a confidence marker requires either human instruction or a clear integration event logged.
2. **Auto-resolve conflicts.** Conflicts are flagged `(in flight)` and surfaced for human decision.
3. **Edit files in `sources/`.** Blocked by the hook (§4.6).
4. **Summarize sources.** Extraction is atomic-unit classification, not summarization.
5. **Rewrite `synthesis.md` wholesale.** Edits are incremental and traceable to sources.
6. **Proceed silently on ambiguous integrations.** If an atomic unit's classification is uncertain, flag it and ask.
7. **Collapse distinct open questions.** Open questions are preserved separately until explicitly merged or retired.

## 6. Structured hand-off schema

The `source-extractor` subagent **writes** JSON to `extractions/<source_id>.json` with this shape (schema v1):

```json
{
  "schema": "v1",
  "source_id": "conv-007-cognitive-leverage-recap",
  "source_path": "sources/conv-007-cognitive-leverage-recap.md",
  "extracted_at": "2026-04-19T14:30:00Z",
  "atomic_units": [
    {
      "id": "au-1",
      "kind": "claim",
      "text": "<the atomic idea, normalized>",
      "source_fragment": "<verbatim ≤3 sentences>",
      "classification": "adds",
      "relates_to": null,
      "notes": "<optional — extractor's observation, never a judgment>"
    },
    {
      "id": "au-2",
      "kind": "claim",
      "text": "<...>",
      "source_fragment": "<...>",
      "classification": "conflicts",
      "relates_to": "synthesis.md#core-concepts::leverage-is-linear",
      "notes": "Source frames leverage as nonlinear; canon currently says linear."
    }
  ]
}
```

`kind` is one of: `concept`, `claim`, `assumption`, `distinction`, `objection`, `question`.

`classification` is one of: `supports`, `adds`, `conflicts`.

`relates_to` is an anchor into `synthesis.md` when applicable; null for pure `adds`.

This schema is the contract between the extractor and every downstream consumer. The `schema` field is pinned; any consumer that encounters an unknown version refuses to proceed and surfaces the mismatch. Future subagents (duplicate-detector, conflict-analyzer) will also consume it. **Do not change it casually — bump the version.**

## 7. Plugin manifest

`plugin.json` (in `.claude-plugin/`):

```json
{
  "name": "canon-workspace",
  "version": "0.1.0",
  "description": "Turn a corpus of exploratory conversations into a maintained canon. Implements the discovery-to-canon synthesis discipline from 'From Conversation to Canon'.",
  "author": "Cliff Rosen / Orchestrator Studios"
}
```

Component directories (`commands/`, `agents/`, `skills/`, `hooks/`) live at the plugin root, NOT inside `.claude-plugin/`. Only the manifest belongs in `.claude-plugin/`.

## 8. Build order

Build in this order so each step is testable:

1. `plugin.json` + directory skeleton.
2. `/canon-init` — testable immediately (scaffolds a workspace).
3. `canon-synthesis` skill — test by asking Claude to discuss canon work in an initialized workspace.
4. Hook on `sources/` — test by asking Claude to edit a file in `sources/`; confirm rejection.
5. `source-extractor` subagent — test standalone by feeding it a source; confirm it writes `extractions/<source_id>.json` and returns a pointer line.
6. `canon-updater` subagent — test standalone by feeding it an extraction; inspect `synthesis.md` + `source-log.md` edits via `git diff`.
7. `/integrate-source` — thin orchestrator tying §5 and §6 together. Test end-to-end with one of the seven cognitive-leverage conversations as a source.
8. `/canon-review` — last, since it's cosmetic relative to the core loop.

## 9. Design principles to preserve through implementation

These are the invariants. If implementation pressure pushes against one, surface the tension rather than silently drifting.

1. **The canon is separate from the corpus.** Sources are inputs; `synthesis.md` is the product.
2. **Structured hand-offs, not prose.** Subagent outputs are parseable data, not narratives.
3. **`process.md` is the orchestration spec AND the schema authority.** The working loop in `process.md` matches `/integrate-source`'s steps; the `## Schema` section governs subagent classification and placement behavior. If either diverges, `process.md` wins and the code is a bug.
4. **One skill for discipline, many subagents for operations.** Don't split the skill by operation. Do split subagents by operation as the pipeline grows.
5. **Mechanical work for the agent, editorial work for the human.** Any behavior the agent exhibits that requires editorial judgment is a bug.
6. **Provenance is structural.** Every canonical element is traceable to source fragments via the source log and the preserved `sources/` directory.
7. **Review artifacts are scaffolding.** `/canon-review` output is gitignored and disposable.
8. **Schema and UX co-evolve in dialog with the user.** The canon's structure is a product of the effort, not a fixed template. Schema evolution, schema-fit feedback, and UX shaping are first-class operations (see `docs/build-plan.md` Phases 2–8).

## 10. Artifact addressing and pointer resolution

Every cross-system reference uses one of four forms:

| Form | Meaning | Who writes | Who reads |
|---|---|---|---|
| `sources/<source_id>.md` | Preserved verbatim source. Immutable after capture. | Integrator at capture time. | Subagents that need raw text. |
| `extractions/<source_id>.json` | Structured classification (schema v1). Overwritten on re-extraction. | `source-extractor` only. | Main agent (narrow reads), downstream subagents. |
| `synthesis.md` | The canon. | `canon-updater` via incremental edits. | Everyone. |
| `source-log.md` | Append-only integration log. Cites extractions and sources by path. Newest-first. | `canon-updater` (prepends). | Humans, auditors. |

**Resolving a pointer without flooding context.** The main agent never walks an extraction directly. Per-unit work is delegated to `canon-updater` (or, in v1+, further specialized subagents). If ad-hoc narrow reads are needed by the main agent, prefer grep by classification or Read with offset/limit — this should be rare.

## 11. Future expansion (design toward, don't build yet)

These are planned subagents for v1+. The v0 structure should make adding them cheap:

- `duplicate-detector` — compares new atomic units against canon for near-duplicates.
- `conflict-analyzer` — classifies flagged conflicts (contradiction / refinement / supersession / tension).
- `provenance-auditor` — verifies every canonical element's source fragments still exist and support the claim.
- `canon-diff-narrator` — given two git versions of the canon, produces a human-readable changelog.

Each maps to one of the six synthesis operations (§1). The main agent's role evolves from doing synthesis to orchestrating subagents that do synthesis — task graph where nodes are subagents and edges are confidence-marker conventions.

---

*End of spec.*
