# Canon Workspace — Claude Code Plugin Spec

**Version:** 0.8 (v0 scope)
**Changes from 0.7:** Introduces **Core structure** as a first-class section in every canon (the spine: 3–7 load-bearing pieces that organize the rest). Without it the canon is filing, not synthesis — so the section is mandatory in every schema and every rendered canon. Extraction JSON bumped to **schema v3** with a `spine_candidates` array; `source-extractor` proposes candidates, `canon-updater` surfaces them in the source-log entry (never populates Core structure — that section is human-owned). Skill gains principle 9 ("Synthesis ends at a picture, not a list"), a structural refinement lever, and a spine-check calibration move (the most important one). All four default schemas declare Core structure as the second section, after Overview.
**Changes from 0.6:** Adds `/canon-workspace:integrate-source` (completes Phase 4) and `/canon-workspace:canon-review` plus the `canon-renderer` subagent and HTML template (completes Phase 5).
**Changes from 0.5:** Extraction JSON bumped to **schema v2**: adds an optional top-level `schema_observations` array. `source-extractor` emits neutral schema-fit observations; `canon-updater` carries observations into a prepended entry in `schema-log.md` and counts them in its summary line. Completes Phase 3.
**Changes from 0.4:** `/canon-init` became a two-phase command — mechanical scaffolding followed by a schema sync-up dialog with the user. Four default schema templates ship under `templates/schemas/`; user accepts / replaces / collaborates. `process.md` and `synthesis.md` are composed from the chosen schema; `schema-log.md` records the initial adoption as entry #1. Completes build-plan Phase 2.
**Changes from 0.3:** `process.md` gains an authoritative `## Schema` section. Subagents read it on every invocation and defer to it; hardcoded lists in subagent prompts are fallbacks only. Completes build-plan Phase 1.
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

The primary review mode is a **chat with the main agent in the same Claude Code session**. The HTML review projection is a disposable **visual reference** that makes the canon legible while that chat happens. It is read-only; no interactive editing in the page.

1. **User action:** runs `/canon-workspace:canon-review`.
2. **Main agent action (subagent dispatch):** dispatches the `canon-renderer` subagent (tools: `Read`, `Write` scoped to `review/review-<timestamp>.html`). The subagent reads `synthesis.md`, `process.md`, `source-log.md`, and `schema-log.md`; composes a JSON data payload; substitutes it into the plugin's HTML template; writes the file. Returns one pointer line: `RENDERED: review/review-<timestamp>.html`.
3. **Main agent action:** reports the rendered path to the user *and* offers a brief, state-aware menu of common refinement moves — how many tentatives could be promoted, how many in-flight conflicts await resolution, that the rendering and the schema can also be tuned, and that provenance for any element can be traced. The menu seeds the dialog; the user does not have to know the available levers in advance. The detailed pattern is carried by the `canon-synthesis` skill (§4.7).
4. **User action:** opens the HTML in a browser. The render applies the Display conventions from `process.md` — confidence markers visually distinct (tentative soft, in-flight urgent); open questions isolated in a sidebar; schema events and recent integrations in sidebars; source attributions reachable via hover. The user reads, forms judgments, and identifies what needs to change.
5. **User action:** returns to the Claude Code session and **continues the conversation with the main agent**, responding to the offered menu or expressing a free-form observation. This dialog is the primary review surface — where editorial intent is expressed and where the agent applies it (Step 3). The user does not click through the HTML to edit; they talk to the agent.

`git diff` is an audit side-channel for inspecting raw changes before commit. It is not the review surface.

#### Step 3 — Refine

Refinements happen in the **chat that began in Step 2**. The user expresses editorial intent in natural language; the main agent applies it (directly or via a subagent/command dispatch). Each refinement that affects the canon is logged to `source-log.md` or `schema-log.md` as appropriate.

When the user gives an observation rather than a specific command, the main agent's job is to **translate the observation into a concrete lever** — content / schema / UX / provenance — and propose the specific action, rather than asking "what do you want to do?" The `canon-synthesis` skill carries the mapping.

Five common refinement patterns, each as an explicit exchange:

- **Promote a `(tentative)` claim to unmarked.**
  1. **User action (chat):** names the claim and the reason for promotion — e.g., *"Promote the cogency concept to stable; it's been corroborated by conv-002 and conv-005."*
  2. **Main agent action:** edits `synthesis.md` to remove the `(tentative)` marker from the named bullet; appends a dated entry to `source-log.md` noting the removal and the reason.

- **Resolve an `(in flight)` conflict.**
  1. **User action (chat):** names the in-flight element and the resolution — e.g., *"On linear vs nonlinear leverage, resolve in favor of nonlinear — conv-003's framing is stronger. Log: 'resolved via human review 2026-04-19.'"*
  2. **Main agent action:** edits `synthesis.md` so the canonical element reflects the resolution; removes the `(in flight)` annotation; appends an entry to `source-log.md` with the stated reason.

- **Retire or merge open questions.**
  1. **User action (chat):** identifies the questions and intent — e.g., *"Merge open questions 3 and 7; they're the same idea."*
  2. **Main agent action:** edits `synthesis.md`'s Open questions section to the merged form; appends an entry to `source-log.md`.

- **Evolve the schema.**
  1. **User action:** either `/canon-workspace:evolve-schema <intent>` or states intent in chat — e.g., *"Add a `signature` kind for observable symptoms of failure-modes."*
  2. **Main agent action:** drafts edits to `process.md`'s `## Schema` section plus a migration plan for `synthesis.md`.
  3. **User action:** reviews the diff, accepts or iterates.
  4. **Main agent action:** applies the accepted edits; appends an entry to `schema-log.md`. Subagents honor the new schema on their next invocation automatically.

- **Evolve the UX.**
  1. **User action:** either `/canon-workspace:evolve-ux <intent>` or states intent in chat — e.g., *"Render failure-modes with a warning icon."*
  2. **Main agent action (subagent dispatch):** dispatches the `renderer-editor` subagent (planned, Phase 8), which edits files under `plugins/canon-workspace/renderer/` while preserving alignment invariants.
  3. **User action:** re-renders (`/canon-workspace:canon-review`) to see the change.

After one or more refinements the user typically re-renders via `/canon-workspace:canon-review` to see the new state in the visual reference, then continues the chat. The cycle closes when the user is satisfied with this pass and moves to commit.

#### Step 4 — Commit

User commits via git. Nothing auto-commits.

### Projections of the canon

`synthesis.md` is the storage format. It is not the consumption format. The plugin generates projections on demand:

- **Review projection** — `/canon-workspace:canon-review` → `review/review-<timestamp>.html`. A disposable visual reference that supports the review chat (Step 2 / Step 3 of the working loop). Markers are loud; provenance is one click away; schema-fit observations are surfaced; read-only — editorial changes come through the chat, not through the page.
- **Consumption projection** — `/canon-workspace:canon-export <format>` (planned, post-v0) → a clean rendering for downstream use (proposal, thesis, onboarding doc). Markers stripped; organized for a reader; optionally scoped to a subset of sections or sources.

Both are derived from `synthesis.md` + `process.md`'s Schema and Display conventions. The review projection additionally consumes `source-log.md` and `extractions/` for provenance rendering.

### What is built today vs planned

**Built (v0.8):**
- `/canon-workspace:canon-init` — scaffold + schema sync-up dialog with accept / replace / collaborate (Phase 2).
- Four default schema templates under `templates/schemas/`, each declaring a class-specific **Convergence target**: framework-development (named framework of central concepts), research-synthesis (findings bounded by methods and limitations), product-discovery (user-problem-solution triangle with constraints and risks), thesis-argumentation (thesis with pillars and counters).
- Every canon has a `## Core structure` section — the spine — between Overview and the schema's classified sections. Populated by the human; never written by subagents.
- `/canon-workspace:integrate-source` — thin orchestrator: validate → preserve source → `source-extractor` → `canon-updater` → report (Phase 4).
- `/canon-workspace:canon-review` — thin wrapper over the `canon-renderer` subagent; produces `review/review-<timestamp>.html` (Phase 5).
- `source-extractor` subagent — schema-aware; emits `schema_observations` and `spine_candidates` (shaped by the schema's Convergence target) in the extraction JSON (schema v3).
- `canon-updater` subagent — schema-aware; prepends schema observations to `schema-log.md` and lists spine candidates in the source-log entry for human promotion.
- `canon-renderer` subagent — reads canon artifacts, substitutes into the plugin's review template, writes the HTML review projection (Phase 5).
- Review HTML template at `plugins/canon-workspace/renderer/review-template.html` — self-contained, embedded CSS + JS for in-browser markdown rendering.
- `canon-synthesis` skill — carries the discipline defaults including review dialog patterns, calibration moves, and principle 9 ("Synthesis ends at a picture, and the picture's shape is class-specific").
- `PreToolUse` hook — enforces `sources/` immutability.

**Planned** (see `docs/build-plan.md` for phase-by-phase detail):
- Schema ↔ UX alignment rules as a formal doc (Phase 6).
- `/canon-workspace:evolve-schema` and `/canon-workspace:evolve-ux` (Phases 7–8).
- Source collectors and `inbox/` staging — pull sources from Gmail, Google Docs, URLs, Claude chat exports, etc., normalize to markdown, stage for human review before integration (Phase 9; parallel-eligible).

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
├── extractions/                     # structured per-source classifications (schema v3)
│   └── .gitkeep                     # written only by the source-extractor subagent
├── synthesis.md                     # the canon — single source of truth
├── process.md                       # the method and authoritative schema, inspectable and revisable
├── source-log.md                    # append-only log of integration events
├── schema-log.md                    # append-only log of schema events (initial, evolution, fit-observations)
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

**Purpose:** One-time workspace scaffolding *plus* schema sync-up dialog with the user. The dialog is where the canon's shape for this effort gets decided.

**Behavior:**

*Phase 1 — Preconditions.* Verify the directory is empty or confirm with user. Refuse if `synthesis.md` already exists unless `--force` is passed.

*Phase 2 — Scaffold non-schema files.* Create `sources/`, `extractions/`, `drafts/`, `review/` with `.gitkeep` each. Write `source-log.md`, `schema-log.md` header, `README.md`, `.gitignore` from templates. Defer `synthesis.md` and `process.md` until the schema is chosen.

*Phase 3 — Schema sync-up dialog.*
1. Introduce the concept of the schema briefly (kinds, sections, classification rules, display conventions, **convergence target** — each schema declares what "done" looks like for its class of problem, and this is what the canon is driving toward).
2. List the available schema templates under `${CLAUDE_PLUGIN_ROOT}/templates/schemas/` — each has frontmatter with `title` and `description` (the description includes the convergence shape). Present all with descriptions. Offer two additional paths: **provide your own** schema inline, or **collaborate** to draft one from scratch (in which case the Convergence target is drafted as part of the collaboration).
3. Ask the user which to use.
4. Based on the answer:
   - **Accept a listed template** → strip frontmatter from that file; use the remainder as the Schema section body.
   - **Replace with user-provided** → take their pasted section, or draft one from their prose description and iterate until accepted.
   - **Collaborate** → dialog about their effort, draft a complete schema, iterate until accepted.
5. End state: a complete `## Schema` section body the user has agreed to, plus metadata about the choice.

*Phase 4 — Compose `process.md` and `synthesis.md`.*
- `process.md`: read the template (which has a `{{SCHEMA}}` placeholder), substitute the chosen schema body, write.
- `synthesis.md`: parse the Sections list from the schema, generate `## <Section name>` blocks with appropriate placeholder text, substitute `{{DATE}}` and `{{SECTIONS}}`, write.

*Phase 5 — Write `schema-log.md` entry #1.* Prepend a dated block recording the choice: event type, template name (or `custom`), kinds list, sections list, and any notes from the dialog.

*Phase 6 — Initialize git.* `git init` if needed, then `git add . && git commit -m "canon-init: scaffold workspace with <template> schema"`.

*Phase 7 — Report.* Workspace path, chosen schema summary, next steps: fill Overview and Glossary, run `/canon-workspace:integrate-source` when ready.

**Arguments:** `--force` (optional) — overwrite an existing workspace.

**Idempotency:** refuses to run if `synthesis.md` already exists unless passed `--force`.

### 4.2 Slash command: `/integrate-source <path>`

**Purpose:** Primary operation. Runs the working loop on a single source file. The command is a **thin orchestrator** — it calls two subagents that each do their work in isolated contexts, and it reports their short pointer/summary lines to the user. The main agent never walks the N atomic units.

**Behavior (the working loop, written down):**

1. **Validate.** Confirm `<path>` exists and is a markdown file. Confirm `synthesis.md`, `process.md`, and `source-log.md` exist.
2. **Preserve source.** Copy the file into `sources/<source_id>.md` (e.g., `conv-NNN-<slug>.md` where NNN is the next sequential number). Do not modify content. The stem is the `source_id`.
3. **Delegate extraction.** Invoke the `source-extractor` subagent (§4.4). Receive one pointer line:
   ```
   EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)[ · M schema observations]
   ```
4. **Delegate canon update.** Invoke the `canon-updater` subagent (§4.5). Receive one summary line:
   ```
   UPDATED: synthesis.md (+... per schema) · source-log.md (1 entry, Ss supports logged, Rr retired)[ · schema-log.md (M observations logged)]
   ```
5. **Report to the user.** Surface the two subagent lines verbatim, direct them to the UX review projection, and note that `git diff` is available for raw-changes audit before commit. Do not dump extraction contents. Do not commit.

**Arguments:** `<path>` (required) — path to the source file.

**Important:** This command does not commit to git. The human reviews through the UX (rendered via `/canon-review`) — the surface where editorial judgment happens — and uses `git diff` as a raw-changes audit before committing.

### 4.3 Slash command: `/canon-review`

**Purpose:** Produce the **review projection** — the HTML surface where the human exercises editorial judgment. Thin wrapper around the `canon-renderer` subagent.

**Behavior:**
1. Validate the workspace (cwd has `synthesis.md`, `process.md`, `source-log.md`, `schema-log.md`).
2. Dispatch `canon-renderer` (§4.6), passing the workspace root and the path to the plugin's review template.
3. Receive `RENDERED: review/review-<timestamp>.html`.
4. Report the path to the user and tell them to open it in a browser.

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
- Success: `EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)[ · M schema observations][ · brief note]`
- Failure: `FAILED: <reason>`

The invoking agent relies on this line — and the file on disk — exclusively. The subagent does NOT return atomic units inline.

**System prompt focus:**
- Read `process.md` first; the `## Schema` section's **Kinds** list is authoritative, and the **Convergence target** subsection declares what "done" looks like for this canon's class. Defaults below are fallbacks when the section is absent.
- Extract atomic units per the kinds defined in the schema (defaults: concepts, claims, assumptions, distinctions, objections, questions).
- While extracting, note schema friction as neutral observations in the JSON's `schema_observations` array — patterns that suggest a missing kind, units that straddled two kinds, source material that produced no atomic units because nothing fit. Observations are optional; only include when substantive.
- Propose **spine candidates** shaped by the Convergence target — atomic units that look like load-bearing material the canon's `## Core structure` section could anchor to. Emit these as `spine_candidates` entries (see §6). Never write to `synthesis.md`.
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

**Purpose:** Apply the mechanical consequences of an extraction: incremental edits to `synthesis.md` with confidence markers, a prepended entry in `source-log.md`, retirement of resolved open questions, and — if the extraction carried schema-fit observations — a prepended entry in `schema-log.md`. Runs in an isolated context so the invoking agent never ingests per-unit detail.

**Why a subagent:** walking N atomic units to propose canon updates is exactly the context-heavy work we want out of the main agent. This subagent does it; its context is discarded when it returns.

**Tools:** `Read`, `Edit`, `Write`. The system prompt constrains writes to `synthesis.md`, `source-log.md`, and `schema-log.md` only.

**Inputs (passed by invoking agent):**
- absolute path to `extractions/<source_id>.json`
- absolute path to `synthesis.md`
- absolute path to `source-log.md`
- absolute path to `schema-log.md`
- absolute path to `process.md` (authority)
- the `source_id`
- absolute path to the workspace root

**Output (final message, ≤ one line):**
- Success: `UPDATED: synthesis.md (+... per schema's Sections) · source-log.md (1 entry, Ss supports logged, Rr retired)[ · schema-log.md (M observations logged)][ · brief note]`
- Partial (ambiguous units skipped): `PARTIAL: <same counts> · skipped: <N> ambiguous units`
- Failure: `FAILED: <reason>`

**System prompt focus:**
- Read `process.md` first; its `## Schema` section is authoritative for kinds, sections, classification rules, and the section mapping. Hardcoded fallback table in the subagent prompt applies only if the schema section is missing.
- Validate the extraction's `schema` field is `"v3"`.
- For each atomic unit:
  - `adds` → append as a bulleted item under the section for its `kind`, prefixed `(tentative)`, suffixed with a source cite.
  - `supports` → no structural edit; record corroboration in the source-log entry.
  - `conflicts` → annotate the related element with an `(in flight)` note citing the conflicting unit. Never modify the existing claim.
- Retire any open question whose anchor is referenced by an `adds` or `supports` unit in this extraction.
- Prepend a dated source-log entry after the `---` separator at the top of `source-log.md`. The entry includes a **Spine candidates** line listing any candidates from the extraction's `spine_candidates` array (the human will decide which, if any, to promote into `## Core structure`).
- Do NOT populate `synthesis.md`'s `## Core structure` section. That section is human-owned; your job is to surface candidates via the source-log entry.
- Do NOT touch `sources/`, `extractions/`, `drafts/`, `review/`, or git.
- Do NOT resolve conflicts. Do NOT promote tentative claims. Do NOT paraphrase extractor text.
- Return one short line. No unit detail, no reasoning trace.

### 4.6 Subagent: `canon-renderer`

**Purpose:** Produce the review projection — an HTML rendering of the canon at `review/review-<timestamp>.html`. Runs in an isolated context so the invoking agent never ingests the canon's text into its own window.

**Why a subagent:** rendering the canon involves reading all four canon artifacts and composing a data blob; the main agent should not carry that text. This keeps `/canon-review` thin.

**Tools:** `Read`, `Write`. Write is constrained by the system prompt to `review/review-<timestamp>.html` only.

**Inputs (passed by invoking agent):**
- absolute path to the workspace root
- absolute path to the plugin's review template (`${CLAUDE_PLUGIN_ROOT}/renderer/review-template.html`)

**Output (final message, ≤ one line):**
- Success: `RENDERED: review/review-<timestamp>.html`
- Failure: `FAILED: <reason>`

**System prompt focus:**
- Read the template, then read `synthesis.md`, `process.md`, `source-log.md`, `schema-log.md`.
- Determine the schema name from `schema-log.md`'s initial adoption entry.
- Determine the last-updated date from the `*Last updated: <date>*` line in `synthesis.md`.
- Build a JSON data payload (see §6b below) with properly escaped strings.
- Substitute the JSON for the `{{CANON_DATA_JSON}}` placeholder in the template.
- Write the result to `review/review-<timestamp>.html` (timestamp in filesystem-safe form).
- Return only the pointer line.

The template's embedded JavaScript does the markdown-to-HTML rendering in-browser at page load — the subagent never handles HTML.

### 4.7 Skill: `canon-synthesis`

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

### 4.8 Hook: protect `sources/`

**Purpose:** Enforce the structural invariant that preserved sources are immutable.

**Type:** `PreToolUse` hook on `Write` and `Edit` tools.

**Behavior:** If the target path is inside `sources/`, reject the tool call with a message explaining that sources are immutable after capture. If the user genuinely needs to modify a source (e.g., correcting a capture error), they can do it manually outside the agent.

**This is the one hard block.** Everything else (anti-patterns, editorial drift) is handled via the skill's soft-warning discipline.

## 5. File templates

### 7.1 `synthesis.md` template

The actual file on disk is composed by `/canon-init` from the chosen schema. The template file itself is minimal:

```markdown
# Canon

*Last updated: {{DATE}}*

{{SECTIONS}}
```

`{{DATE}}` is substituted with today's date. `{{SECTIONS}}` is substituted with `## <Section name>\n\n<placeholder>\n` blocks generated from the Sections list in the chosen schema. Example result using the `framework-development` default:

```markdown
# Canon

*Last updated: 2026-04-19*

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

The `source-extractor` subagent **writes** JSON to `extractions/<source_id>.json` with this shape (schema v3):

```json
{
  "schema": "v3",
  "source_id": "conv-007-cognitive-leverage-recap",
  "source_path": "sources/conv-007-cognitive-leverage-recap.md",
  "extracted_at": "2026-04-19T14:30:00Z",
  "atomic_units": [
    {
      "id": "au-1",
      "kind": "concept",
      "text": "The Three Essentials: every agent call depends on three inputs — instructions, context, and tools.",
      "source_fragment": "<verbatim ≤3 sentences>",
      "classification": "adds",
      "relates_to": null,
      "notes": null
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
  ],
  "schema_observations": [
    {
      "observation": "3 units were placeholder-classified as `claim` but the source frames them as hypotheses being tested.",
      "unit_refs": ["au-4", "au-9", "au-21"],
      "suggestion": "Consider adding a `hypothesis` kind if this pattern recurs across sources."
    }
  ],
  "spine_candidates": [
    {
      "unit_ref": "au-1",
      "pattern": "framing-language",
      "rationale": "Source opens by naming this as 'the three essentials' and organizes subsequent failure-modes against it.",
      "dependents": ["au-2", "au-3", "au-4", "au-18", "au-27"]
    }
  ]
}
```

`kind` is one of the kinds declared in the workspace's `process.md` `## Schema` → Kinds (defaults: `concept`, `claim`, `assumption`, `distinction`, `objection`, `question`).

`classification` is one of: `supports`, `adds`, `conflicts`.

`relates_to` is an anchor into `synthesis.md` when applicable; null for pure `adds`.

`schema_observations` is optional. Empty or missing when the schema fits the source cleanly. Each entry is a neutral factual note — never a demand.

`spine_candidates` is optional. Empty when no unit in the source stands out as load-bearing. When present, each entry proposes an atomic unit that could anchor the canon's Core structure section. `source-extractor` proposes; `canon-updater` surfaces via the source-log entry; **neither subagent ever writes to `## Core structure` in `synthesis.md`.** Spine promotion is a human act taken in review dialog.

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
9. **Calibration is an explicit agent responsibility, not an assumption.** The system does not assume the user always recognizes when the canon has drifted from serving the effort. The runtime dialog includes proactive calibration moves — purpose-alignment checks, empty-space probes, adversarial framings, back-to-source cycles, ratio hygiene. The `canon-synthesis` skill (§4.7) carries the practical toolkit; the rationale lives in `docs/design-notes.md`.
10. **Synthesis converges on a picture, and the picture's shape is class-specific.** A well-classified list is filing, not synthesis. Every canon has a `## Core structure` section that holds the spine — the few load-bearing pieces that organize the rest. Every schema declares a **Convergence target**: what "done" looks like for its class (a named framework, a set of findings, a user-problem-solution triangle, a thesis-with-pillars, or a custom shape). Subagents propose spine candidates shaped by the target; the human promotes. The system actively pushes toward the target shape rather than accepting a flat corpus as converged.

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
