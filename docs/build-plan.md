# Build Plan — Schema and UX as Co-evolving First-class Artifacts

*The next arc of plugin work. Takes v0.3 (built: `canon-init`, `canon-synthesis` skill, `sources/` hook, `source-extractor` subagent, `canon-updater` subagent) to a system where the canon's schema and the UX are living artifacts the user shapes, and the subagents inform that shaping with real-world friction data.*

## Invariants carried forward from v0.3

- Structured subagent hand-offs; main agent stays thin.
- Immutable `sources/`; provenance-addressable artifacts (`sources/` → `extractions/` → `synthesis.md` → `source-log.md`).
- Mechanical work for agents, editorial for humans.
- `process.md` is authoritative over any default.
- `git diff` is the human review surface; nothing auto-commits.

## Phases

### Phase 1 — Schema authority in `process.md`

**Deliverable:** `process.md` gains a structured `## Schema` section. This becomes the single authoritative record of the canon's shape.

**Scope:**
- Add subsections under `## Schema`: **Kinds** (atomic unit taxonomy), **Sections** (canon structure), **Classification rules** (how kinds map to sections), **Display conventions** (hints the renderer consults).
- Update `source-extractor` prompt: read `process.md`'s Schema section and use it as the taxonomy authority. Stop hardcoding kinds.
- Update `canon-updater` prompt: read the Schema section and use it as the section-mapping authority. Stop hardcoding sections.
- Update `synthesis.md` template: become a thin stub that `canon-init` populates from the schema (Overview + sections declared in Schema).

**Tests:**
- In a test workspace, edit the Schema section (e.g., rename `claim` to `finding`). Re-run the subagents against a source. Confirm they honor the rename without any subagent edits.

**Blocks:** Phases 3, 4, 5, 6.

---

### Phase 2 — Schema negotiation at init

**Deliverable:** `/canon-workspace:canon-init` becomes a dialog that presents the default schema and offers **accept / replace / collaborate**.

**Scope:**
- After scaffolding the defaults, show the user the current schema and prompt the choice.
- **Accept:** proceed with defaults.
- **Replace:** user provides an alternative (inline or via a file); schema section is overwritten; `synthesis.md` regenerated from it.
- **Collaborate:** the agent dialogs with the user — proposing, refining, asking what's missing — and iteratively edits the Schema section.
- Create `schema-log.md` with entry #1 = the agreed initial schema (date, source: "accepted default" / "replaced" / "collaborated").

**Tests:**
- Init accepting default → identical output to pre-Phase-2 `canon-init`.
- Init replacing → `synthesis.md` sections reflect the custom schema.
- Init collaborating → end state is a coherent schema the user signed off on.

**Depends on:** Phase 1.

---

### Phase 3 — Subagent schema-fit feedback channel

**Deliverable:** subagents flag real-world schema friction during their work; friction is captured in a durable log.

**Scope:**
- Bump extraction JSON to **schema v2**: adds an optional top-level `schema_observations: []` — each entry a neutral note from `source-extractor` about units that resisted the taxonomy (e.g., "3 units were placeholder-classified as `claim` but read like `finding`; suggest considering a Findings kind").
- Update `source-extractor` prompt: emit observations when units don't cleanly fit. Still classifies with the best-available kind to remain functional.
- Update `canon-updater` prompt: carry observations into its summary line and append them to `schema-log.md` as a dated entry tied to the `source_id`.
- `schema-log.md` now has two kinds of entries: schema-evolution events (from Phases 2, 7) and schema-fit observations (from this phase).

**Tests:**
- Integrate a source known to poorly fit the current schema. Confirm observations land in `schema-log.md` and are neutral (no editorial demands).

**Depends on:** Phase 1.

---

### Phase 4 — `/integrate-source` thin orchestrator

**Deliverable:** the command from spec §4.2 — the end-to-end integration flow.

**Scope:**
- Validate → preserve source → invoke `source-extractor` → invoke `canon-updater` → report pointer + summary + `git diff` pointer.
- Pass through schema observations surfaced by Phase 3.

**Tests:**
- End-to-end integration of `docs/from-conversation-to-canon.md` into a fresh workspace. Confirm synthesis, source-log, extraction, and schema-log all look right.

**Depends on:** Phases 1, 3.

---

### Phase 5 — Default UX renderer

**Deliverable:** `/canon-workspace:canon-review` generates `review/review-<timestamp>.html` from the current canon.

**Scope:**
- A renderer (script or agent-driven; decide in-phase) that converts `synthesis.md` + `process.md` Schema + `source-log.md` into an HTML page.
- Default rendering rules: confidence markers visually distinct; open questions pulled into a sidebar; every claim's source-log entry reachable in one click; schema sections rendered in declared order.
- Renderer reads the schema from `process.md`. Any declared section gets a render block — no hardcoded section names.
- Output in `review/` (gitignored, disposable).

**Tests:**
- Render the test workspace's canon; open in browser; confirm markers are visible, clickable refs work, open questions are isolated.
- Custom-schema workspace: render still works; all declared sections appear with default treatment.

**Depends on:** Phase 1.

---

### Phase 6 — Schema ↔ UX alignment rules

**Deliverable:** a small rules document that the renderer enforces. Codifies what "aligned" means between the canon's schema and its visual form.

**Scope:**
- A file `plugins/canon-workspace/renderer/alignment-rules.md` with invariants such as:
  - Every schema section declared in `process.md` has a render block.
  - Every confidence marker has a visual treatment.
  - Provenance (source-log entry) is reachable from every canonical element in one click.
  - Open questions are isolated from claims visually.
  - Unknown section types get a default treatment rather than being dropped.
  - **Differential rendering** — when a render is generated following a new integration, the template surfaces what was added/changed in the latest integration: per-bullet badges (e.g., a compact `+conv-N` tag), a "What's new since conv-N-1" sidebar panel, or equivalent. The data is already present in every bullet's source cite (`— conv-NNN-slug#au-X`) and in the top entry of `source-log.md`. Interim measure (pre-Phase-6): the main agent narrates the diff in chat after every post-integration `/canon-review` — see the `canon-synthesis` skill's "Diff narration" subsection.
- Renderer consults the rules; gracefully handles schema additions without code edits.

**Tests:**
- Add a new section type in `process.md` Schema. Re-render. Confirm the new section appears with default treatment and no manual renderer code change.
- Integrate a second source. Re-render. Confirm per-bullet integration badges appear on newly-added bullets, and a "What's new" summary panel is present.

**Depends on:** Phase 5.

---

### Phase 7 — Schema evolution loop

**Deliverable:** `/canon-workspace:evolve-schema` — a command (and/or dialog pattern) that lets the user revise the schema mid-effort, with safe migration of existing canon content.

**Scope:**
- Takes user intent in natural language: "add Frames as a top-level section"; "rename Claims to Findings"; "fold Assumptions into Claims."
- An agent drafts edits to `process.md` Schema section + a migration plan for `synthesis.md`.
- Human approves via `git diff`; edits applied.
- `schema-log.md` records the evolution event with reason and diff summary.
- Subagents pick up the new schema on their next invocation automatically (they read `process.md` each time).

**Tests:**
- Rename a section → canon content migrates; subagents honor the new name next invocation.
- Add a section → new extractions place units into it.
- Fold a section → existing content preserved under the absorbing section.

**Depends on:** Phases 1, 3, 5, 6.

---

### Phase 8 — UX evolution loop (with workspace-override layer)

**Deliverable:** the user can shape the UX in dialog; an agent edits the renderer at the **workspace** level (not the plugin level) while preserving alignment rules.

**Scope:**
- **Two-layer renderer composition.** Plugin ships defaults at `plugins/canon-workspace/renderer/`. Workspaces carry overrides at `.canon/renderer/` (or equivalent). `canon-renderer` composes workspace-over-plugin at render time: any file present in the workspace layer replaces the plugin default for that workspace only.
- **UX evolution writes to the workspace layer.** `/canon-workspace:evolve-ux` (and any dialog-driven UX edits) land in the workspace's override dir. Edits to plugin defaults are a separate, explicit act (not the default behavior).
- After seeing a render, the user expresses UX preferences in conversation.
- An agent (possibly a dedicated `renderer-editor` subagent) edits the workspace override files.
- Alignment rules (Phase 6) enforced on the composed output.
- Changes logged — decide in-phase whether in `schema-log.md` or a separate `ux-log.md`.
- Re-render confirms result.

**Tests:**
- Ask for a visual change ("move open questions to a bottom panel"; "compact marker rendering") in a workspace. Confirm the override lands in `.canon/renderer/` in that workspace, not in the plugin. Re-render in the same workspace reflects the change.
- Create a second workspace. Render it. Confirm it still uses plugin defaults (no leakage from the first workspace's override).
- Break an alignment rule via a proposed override; confirm the agent refuses with an explanation.

**Depends on:** Phase 6.

**Context.** Pre-Phase-8, UX edits silently write to the plugin directory, propagating across all workspaces on the machine. See `docs/design-notes.md` → "UX customization edits shared plugin infrastructure (flaw)" for why this is wrong and the intended fix shape.

---

### Phase 9 — Source collectors and inbox staging

**Deliverable:** users can pull sources from external systems (Gmail, Google Docs, URLs, Claude chat exports, LinkedIn, etc.) without hand-preparing markdown. Collectors fetch and normalize; staged files land in a new `inbox/` directory for human review before integration.

**Scope:**

- **New workspace directory: `inbox/`.** Staging area for collected-but-not-yet-integrated sources. Unlike `sources/`, `inbox/` is mutable — users rename, edit, or delete before integration. `canon-init` scaffolds it; `integrate-source` moves files out of it into `sources/`.
- **A collector subagent per source type.** Each:
  - Has narrowly scoped tools (Read, Write for `inbox/` only, plus whatever MCP or WebFetch it needs).
  - Authenticates through the relevant MCP server when required.
  - Fetches items per the user's filter (date range, label, URL, query, doc id).
  - Converts each fetched item to normalized markdown with YAML frontmatter carrying provenance.
  - Writes to `inbox/<collector>-<id-or-slug>.md`.
  - Returns a short pointer summary: `COLLECTED: <N> items in inbox/`.
- **Starter collector set** (build in this order; add more as appetite grows):
  - `url-collector` — WebFetch only, no auth, simplest.
  - `claude-chat-collector` — normalizes Claude chat exports (content is already markdown-ish).
  - `email-collector` — Gmail MCP (auth handled by MCP server).
  - `gdoc-collector` — Google Drive MCP.
- **One command per collector**: `/canon-workspace:collect-url <url>`, `/canon-workspace:collect-gmail --label foo`, etc. Commands are thin wrappers that dispatch the corresponding subagent.
- **Frontmatter convention** for files in `inbox/` and subsequently `sources/`:
  ```yaml
  ---
  source_type: gmail
  source_id: <thread-id or stable natural id>
  source_url: <original URL, when applicable>
  collected_at: <ISO 8601>
  original_format: html | docx | plain | markdown | …
  author: "…"
  title: "…"
  ---
  ```
  `source-extractor` strips frontmatter before extracting atomic units so the content is clean; the frontmatter remains in `sources/<source_id>.md` post-preservation as provenance.
- **Optional**: `/canon-workspace:integrate-inbox` — batch command that runs `/integrate-source` over every markdown file in `inbox/` in filename order.

**Design invariants:**

- Collectors **MUST NOT** write to `sources/`, `synthesis.md`, `source-log.md`, `schema-log.md`, or any canon artifact.
- Collectors **MUST NOT** integrate into the canon themselves — that's `/integrate-source`'s job after human review.
- Collectors **MUST** normalize to markdown; `sources/` stays markdown-only.

**Tests:**

- `url-collector`: fetch a known URL. Inbox file exists with sensible content and frontmatter.
- `email-collector`: pull threads by label. Inbox has N markdown files with provenance.
- End-to-end: collect → review inbox → `/integrate-source inbox/foo.md` → canon reflects the source with frontmatter preserved in `sources/`.
- Integrate a file with frontmatter — confirm `source-extractor` strips it from extraction content but doesn't error.

**Depends on:** nothing from Phases 2–8. Phase 9 is upstream of the working loop; its outputs feed into `/integrate-source` unchanged. Can be built in parallel with Phases 7 and 8.

## Out of scope for this plan

- `duplicate-detector`, `conflict-analyzer`, `provenance-auditor`, `canon-diff-narrator` (spec §11). Still deferred.
- Multi-user collaboration.
- Marketplace publication / distribution packaging.

## Build order

Primary path: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8.

**Phase 9 is parallel-eligible** — it has no dependency on Phases 2–8 and can be tackled at any point after v0.7 (Phase 5 complete). Natural candidate for parallel work alongside Phases 7–8.

- After Phase 4 the system is functional end-to-end for a fixed schema.
- After Phase 6 it's functional with customization + UX.
- Phases 7–8 add fluent schema/UX evolution on top.
- Phase 9 closes the input-side gap: users with real corpora (email, URLs, docs) can bring them into the system without manual markdown prep.
