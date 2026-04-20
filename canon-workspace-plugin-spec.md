# Canon Workspace — Claude Code Plugin Spec

**Version:** 0.1 (v0 scope)
**Audience:** Claude Code, building this plugin
**Source of truth for behavior:** `from-conversation-to-canon.md` (Rosen, April 2026)

---

## 1. Purpose

Package the discovery-to-canon synthesis discipline described in *From Conversation to Canon* into an installable Claude Code plugin, so the workflow can be reproduced on a new effort without reconstructing the discipline from scratch.

The plugin encodes a specific anatomy:

- a canon separate from the corpus
- an explicit synthesis pipeline (extract → normalize → dedupe → reconcile → canonicalize → trace)
- confidence markers as a first-class concept
- provenance via source preservation and a source log
- a division of labor that keeps editorial judgment with the human
- scaffolding for directional-alignment review passes

## 2. Non-goals (for v0)

- Not a full synthesis UI. The review artifact is deliberately throwaway HTML.
- Not a multi-user collaboration system. Single-user, git-backed.
- Not automating judgment calls (promotion, reconciliation, directional alignment). Those remain human decisions.
- Not an ingestion pipeline for arbitrary formats. Sources are markdown files captured into `sources/`.

## 3. Workspace layout (what `/canon-init` creates)

```
<project-root>/
├── .claude-plugin/                  # if building inside a plugin marketplace
├── sources/                         # immutable source corpus (read-only after capture)
│   └── .gitkeep
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

**Purpose:** Primary operation. Runs the working loop on a single source file.

**Behavior (the working loop, written down):**

1. **Validate.** Confirm `<path>` exists and is a markdown file. Confirm `synthesis.md` and `process.md` exist.
2. **Preserve source.** Copy the file into `sources/` with a conventional filename (e.g., `conv-NNN-<slug>.md` where NNN is the next sequential number). Do not modify content.
3. **Delegate extraction.** Invoke the `source-extractor` subagent (§4.4) with the preserved source. It returns a structured classification (see §8).
4. **Propose canon updates.** In the main agent, walk the classification and propose edits to `synthesis.md`:
   - `supports` → existing canonical claims strengthened (no structural change, note in source log).
   - `adds` → new candidate elements, added with appropriate confidence marker.
   - `conflicts` → flagged inline with `(in flight)` markers and surfaced for human resolution. Do NOT auto-resolve.
5. **Apply edits** to `synthesis.md` with confidence markers per §7.3.
6. **Append to `source-log.md`** — a dated entry naming the source, summarizing what was integrated, and listing any questions retired or raised.
7. **Retire resolved questions.** If a question in `synthesis.md`'s open-questions section is now answered, move it to the source log with note `"resolved by <source>"`.
8. **Summarize to the user.** Report: what was added, what conflicts need human attention, what questions were retired, what uncertainty remains.

**Arguments:** `<path>` (required) — path to the source file.

**Important:** This command does not commit to git. The human reviews and commits. The agent MAY suggest a commit message.

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

**Purpose:** Read a full source file and return a structured classification, without polluting the main agent's context with the raw source.

**Why a subagent:** sources are long conversations. The main agent needs its context for synthesis judgment, not raw reading. This is context curation.

**Tools:** Read only. No Write, no Edit, no Bash.

**Inputs:**
- path to preserved source file (in `sources/`)
- current `synthesis.md` contents (for comparison)

**Output:** structured classification — see §8 for schema.

**System prompt focus:**
- Extract atomic units: concepts, claims, assumptions, distinctions, objections, questions.
- For each atomic unit, classify against current canon:
  - `supports` — reinforces an existing canonical claim.
  - `adds` — introduces something not yet in canon.
  - `conflicts` — contradicts, refines, or supersedes an existing claim.
- Include a verbatim source fragment (≤3 sentences) for each atomic unit.
- Do NOT propose canon edits. Classification only.
- Do NOT attempt reconciliation. Flag conflicts; don't resolve them.

### 4.5 Skill: `canon-synthesis`

**Purpose:** Auto-activating context that ensures the main agent behaves correctly during ad-hoc canon work (not just during `/integrate-source`).

**Location:** `skills/canon-synthesis/SKILL.md`

**Activation description** (for the skill's frontmatter): activate when the conversation involves working on a canon workspace — detected by the presence of `synthesis.md` and `process.md` in the project root, or when the user discusses canon, synthesis, confidence markers, or the working loop.

**Content:** the skill teaches the *discipline*, not a single procedure:
- the six synthesis operations (extract, normalize, dedupe, reconcile, canonicalize, trace)
- confidence marker conventions (§7.3)
- the anti-patterns (§7.4) — specifically what the agent must NOT do
- the division of labor: mechanical work for the agent, editorial judgment for the human

**Crucially,** the skill defers to `process.md` in the current workspace as the authoritative method. `process.md` can be customized per project; the skill carries the defaults.

### 4.6 Hook: protect `sources/`

**Purpose:** Enforce the structural invariant that preserved sources are immutable.

**Type:** `PreToolUse` hook on `Write` and `Edit` tools.

**Behavior:** If the target path is inside `sources/`, reject the tool call with a message explaining that sources are immutable after capture. If the user genuinely needs to modify a source (e.g., correcting a capture error), they can do it manually outside the agent.

**This is the one hard block.** Everything else (anti-patterns, editorial drift) is handled via the skill's soft-warning discipline.

## 5. File templates

### 7.1 `synthesis.md` initial template

```markdown
# Canon

*Last updated: <date>*

## Overview

<one-paragraph statement of what this canon represents>

## Core concepts

<empty — populated via integration>

## Claims

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

The `source-extractor` subagent returns JSON like:

```json
{
  "source_id": "conv-007-cognitive-leverage-recap",
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

This schema is the contract between the extractor and the main agent. It is also the contract future subagents (duplicate-detector, conflict-analyzer) will consume. **Do not change it casually.**

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
3. `canon-synthesis` skill — no subagent needed; test by asking Claude to discuss canon work in an initialized workspace.
4. Hook on `sources/` — test by asking Claude to edit a file in `sources/`; confirm rejection.
5. `source-extractor` subagent — test standalone by feeding it a source and inspecting its JSON output.
6. `/integrate-source` — integrates all of the above. Test end-to-end with one of the seven cognitive-leverage conversations as a source.
7. `/canon-review` — last, since it's cosmetic relative to the core loop.

## 9. Design principles to preserve through implementation

These are the invariants. If implementation pressure pushes against one, surface the tension rather than silently drifting.

1. **The canon is separate from the corpus.** Sources are inputs; `synthesis.md` is the product.
2. **Structured hand-offs, not prose.** Subagent outputs are parseable data, not narratives.
3. **`process.md` is the orchestration spec.** The working loop in `process.md` matches the steps in `/integrate-source`. If they diverge, `process.md` is authoritative and the command is a bug.
4. **One skill for discipline, many subagents for operations.** Don't split the skill by operation. Do split subagents by operation as the pipeline grows.
5. **Mechanical work for the agent, editorial work for the human.** Any behavior the agent exhibits that requires editorial judgment is a bug.
6. **Provenance is structural.** Every canonical element is traceable to source fragments via the source log and the preserved `sources/` directory.
7. **Review artifacts are scaffolding.** `/canon-review` output is gitignored and disposable.

## 10. Future expansion (design toward, don't build yet)

These are planned subagents for v1+. The v0 structure should make adding them cheap:

- `duplicate-detector` — compares new atomic units against canon for near-duplicates.
- `conflict-analyzer` — classifies flagged conflicts (contradiction / refinement / supersession / tension).
- `provenance-auditor` — verifies every canonical element's source fragments still exist and support the claim.
- `canon-diff-narrator` — given two git versions of the canon, produces a human-readable changelog.

Each maps to one of the six synthesis operations (§1). The main agent's role evolves from doing synthesis to orchestrating subagents that do synthesis — task graph where nodes are subagents and edges are confidence-marker conventions.

---

*End of spec.*
