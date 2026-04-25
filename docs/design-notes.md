# Design notes

*Dated memos capturing the reasoning behind design decisions. This file is descriptive and historical — it preserves the "why" of choices, so future design work doesn't have to reconstruct it from the "what" in `spec.md` or the "how to" in the skill.*

*Each entry states the context at the time, the tension or observation that surfaced, the resolution, why it matters, and where in the system the resolution is encoded. Newest entries first.*

---

## 2026-04-20 — The spine, and why its shape is class-specific

**Context.** v0.7 shipped the system end-to-end (init → integrate → review). Testing exposed something more fundamental than a UX issue: the output was a well-classified list of parts, not a picture. The schemas encoded *what the parts are* (kinds and sections) but nothing about *what those parts should coalesce into*. Two insights surfaced in close succession.

**Tension — in two layers.**

1. **Lists don't synthesize into pictures on their own.** A user can approve a canon of 60 atomic units, organized into schema-declared sections, and still walk away with no mental model. The salient view — the few load-bearing pieces that everything else hangs off — is what makes the canon usable downstream. Without it, the system produces filing, not synthesis.

2. **The shape of the picture is class-specific.** "Spine" isn't a universal concept: a framework-development canon converges on a named framework (3–5 central concepts), a research-synthesis canon on principal findings bounded by methods and limitations, a product-discovery canon on a user-problem-solution triangle, a thesis-argumentation canon on a thesis with pillars. These aren't variations of the same shape — they're different convergence targets. A schema that only declares kinds-and-sections is descriptive (how we file) but not directional (where we're driving); both are needed.

**Resolution.**

- Every schema template gains a **`### Convergence target`** subsection describing the class-specific shape of "done." Four defaults populated; custom schemas include it as part of the collaborate path.
- Every canon has a first-class **`## Core structure`** section — the spine. Human-owned; subagents never write there. Sits between Overview and the kind-populated sections.
- Extraction JSON bumped to **schema v3** with a `spine_candidates` array: atomic units that `source-extractor` flags as possible spine material, shaped by the workspace's Convergence target.
- `canon-updater` surfaces spine candidates in the source-log entry; never populates `Core structure` (editorial authority stays human).
- Skill principle 9 encodes both layers: *"synthesis ends at a picture, and the picture's shape is class-specific."*
- Spec §9 adds principle 10 at the system-design level.
- `canon-init` presents Convergence targets at schema selection, so users pick knowingly.

**Why it matters.**

The move is shifting what the schema *is*. Before: a taxonomy. After: a taxonomy *and* a target. Without the taxonomy, the system can't classify. Without the target, the system can't converge. We had been treating schemas as purely descriptive ("here's how we file things") when they also need to be directional ("here's where we're driving").

The class-specificity matters equally. If the system applies one spine-shape universally, it either forces everything into framework-language or stays so generic that it guides nothing. The shape must come *from* the schema, which is why Convergence target lives inside the Schema section and is declared by each template — not as a plugin-global convention.

**Connection to prior insights.**

- Extends *"schema as living artifact"* — the schema isn't just structure; it's also goal. Evolution applies to both.
- Operationalizes *"calibrate the user's recognition"* — the system now has a named thing to calibrate *against* (the spine populated to the shape the Convergence target calls for).
- Sharpens *"narrow to a decision; don't summarize"* — a decision about spine candidates is almost always the most productive next decision, post-integration.

**Where it lives.**

- `plugins/canon-workspace/templates/schemas/*.md` — each schema's `### Convergence target` subsection and the `Core structure` entry in its Sections list. Frontmatter descriptions updated with convergence shape so canon-init surfaces it at selection.
- `plugins/canon-workspace/agents/source-extractor.md` — extracts spine candidates shaped by the target; JSON v3 schema includes `spine_candidates` field with pattern/rationale/dependents.
- `plugins/canon-workspace/agents/canon-updater.md` — surfaces spine candidates in the source-log entry; explicit anti-pattern "never populate `## Core structure`."
- `plugins/canon-workspace/skills/canon-synthesis/SKILL.md` — principle 9, spine-check calibration move (the most important one), structural refinement lever in observation-to-lever map.
- `docs/spec.md` v0.8 — changelog, §1 Overview Built list, §4.1 canon-init, §4.4 source-extractor, §4.5 canon-updater, §6 extraction schema v3, §9 principle 10.
- `docs/design-notes.md` — this entry.

---

## 2026-04-19 — UX customization edits shared plugin infrastructure (flaw)

**Context.** The plugin was installed during development via `/plugin marketplace add C:\code\canonizer-cc-plugin` — a local marketplace that points Claude Code at the repo directly, rather than copying files into `~/.claude/plugins/`. `${CLAUDE_PLUGIN_ROOT}` resolves live to the dev repo path. The renderer template lives at `plugins/canon-workspace/renderer/review-template.html` — deliberately plugin-level, not workspace-level, on the assumption that rendering is shared infrastructure.

**Tension.** When the user chats with the main agent *inside a specific canon workspace* and expresses a UX preference ("render source attribution on hover"), the skill's observation-to-lever map classifies that as a UX refinement and directs the edit to `plugins/canon-workspace/renderer/…`. That path resolves to the live plugin repo. Two problems:

1. **Mental-model mismatch.** The user's intent is "refine this canon's review," but the action is "edit shared plugin infrastructure." The system performs the edit without making the distinction visible.
2. **Silent cross-workspace propagation.** A user with a research canon and a product canon would see a template tweak made while reviewing one bleed into the other. That's the wrong semantics for what the user believes they are doing.

The "plugin-level is fine for now because the user has one workspace and is the plugin developer" stance is developer-convenience, not correct design. It was not an explicit choice — it fell out of the dev-install setup and the decision to put the renderer under the plugin directory.

**Intended resolution (Phase 8).**

Introduce a workspace-override layer for UX. Shape:

- Plugin ships defaults at `plugins/canon-workspace/renderer/` (current location) — baseline template, CSS, JS.
- Workspace carries overrides at `.canon/renderer/` (or similar hidden dir) — any files present there replace the plugin defaults for *that workspace only*.
- `canon-renderer` subagent composes workspace-over-plugin at render time: workspace files win where present; plugin defaults fill in everything else.
- UX evolution (`/canon-workspace:evolve-ux`) writes to the workspace's override dir, never the plugin defaults. If the user genuinely wants a change at the plugin level (i.e., a new default for future workspaces), that's a separate, explicit act.
- Alignment invariants from Phase 6 apply to the composed output, not to either layer alone.

**Interim mitigation (optional, not yet applied).**

Until Phase 8 ships, the skill's UX-refinement guidance can require the agent to surface the scope implication before editing:

> *"This UX change will edit the shared plugin template — it will affect every canon workspace on this machine, not just this one. Proceed?"*

One sentence so the user's consent is informed rather than implicit.

**Why it matters.**

The system already treats **schema** as workspace-level (rightly — `process.md` is per-workspace). Treating **UX** as plugin-level infrastructure is inconsistent with the "schema + UX co-evolve with the effort" principle in spec §9 principle 8. The inconsistency only shows up the moment there's more than one workspace on a machine — at which point the flaw becomes a sharp edge. Naming it now keeps it from being re-discovered as a bug under Phase 8's delivery pressure.

**Where it lives.**

- `docs/design-notes.md` — this entry.
- `docs/build-plan.md` Phase 8 — to be expanded with the workspace-override architecture.
- `plugins/canon-workspace/skills/canon-synthesis/SKILL.md` — interim mitigation sentence, not yet added; would live in the "Mapping user observations to levers" section where UX refinements are handled.

---

## 2026-04-19 — Differential rendering: principle without implementation

**Context.** Phase 5 shipped the review projection. The skill's calibration moves (added alongside the principles earlier the same day) named *differential rendering* — show what changed since the last review — as one of seven calibration tools. First real test with a second integration exposed that the principle wasn't operational.

**Tension.** The user ran `/canon-workspace:canon-review` after a second integration expecting to see what had changed. The render showed the full current canon with source-log counts in a sidebar; nothing in the main column flagged which bullets came from the latest integration. The main agent also didn't narrate the diff in chat after reporting the rendered path — it went straight to the proactive menu without doing the one thing the user was explicitly there for. Two distinct failures:

1. The calibration move was specified as a *dialog action* by the main agent, but the skill framed it as a "reach for when useful" tool — not a requirement on every post-integration render.
2. The template renders only current state. The data needed for a diff is present (every bullet carries `— conv-N#au-X`; source-log entries are dated and typed), but the template doesn't surface it.

**Resolution.**

- **Skill (immediate):** the skill now **requires** the main agent to narrate the diff after any `/canon-review` that follows an integration — before the proactive menu, not as an optional calibration move. Source of truth is the topmost entry in `source-log.md`. The calibration-moves entry for differential rendering is updated to reflect automatic triggering.
- **Phase 6 alignment rules (structural):** differential rendering becomes a first-class UX invariant. The alignment-rules doc specifies that any review template must surface what changed in the latest integration — per-bullet integration badges, a "What's new" sidebar panel, or equivalent. The current template is updated when Phase 6 ships.

**Why it matters.**

Calibration principles can't live in dialog-only form if they require information the agent has to remember to go fetch on every turn. When the data is already structural (source cites on every bullet; dated source-log entries), the template should surface it — otherwise every calibration call depends on the agent remembering the move. Making it structural means the user sees it automatically; the agent's job becomes responding to it, not producing it.

More broadly: this is a worked example of the gap between "principle named" and "principle operational." The skill can carry principles, but not all principles can be enforced purely through runtime dialog. Some need a home in code or template; the skill is the fallback while that home is being built.

**Where it lives.**

- `plugins/canon-workspace/skills/canon-synthesis/SKILL.md` → new "Diff narration" subsection before "Proactive menu"; "Calibration moves" entry for differential rendering marked as automatic.
- `docs/build-plan.md` Phase 6 — differential rendering added as an alignment-rules invariant with a concrete test.
- `docs/design-notes.md` — this entry.

---

## 2026-04-19 — Review principles and the calibration problem

**Context.** Phase 5 landed (HTML review projection, `canon-renderer`, `/canon-workspace:canon-review`). The integration pipeline was end-to-end usable, but the review step was under-specified — the spec described it procedurally without naming principles, and the skill had examples without durable directional guidance. Testing exposed two gaps.

**Tensions that surfaced.**

1. *The user won't always know which levers exist.* During testing, the user wanted source attribution to render on hover rather than inline — a UX-level lever (editing the renderer template). The lever was available, but non-obvious. The user had to guess it existed. Examples in the skill can help, but a different user with a different observation may not connect their observation to the right lever. Examples are brittle; underlying principles are durable.

2. *Recognition is a skill, not a reflex.* Even with good affordance surfacing, a user may approve a canon that looks coherent but doesn't actually serve the effort. The render looks good; individual claims look plausible; the user says "yes, this." But the canon could be plausible-but-hollow, schema-locked, or missing content the user can't see because they're too close. Assuming the user will always recognize drift is brittle; the system must help calibrate.

**Resolution.**

- Named eight principles for the review-and-refine dialog, from first principles rather than examples:
  1. The human owns editorial authority.
  2. Narrow to a decision; don't summarize.
  3. Name the lever before acting.
  4. Every change carries a reason, in the log.
  5. Changes flow through the right layer.
  6. Ambiguity is a flag, not a guess.
  7. Purpose anchors hard calls.
  8. Calibrate the user's recognition; don't rely on it.
- Added seven concrete **calibration moves** the agent reaches for proactively: purpose-alignment check, empty-space probe, adversarial framing, back-to-source cycle, differential rendering, provenance stress-test on promotion, ratio hygiene.
- Added a proactive-menu requirement: after every render, the agent offers a state-aware list of available moves rather than waiting for the user to already know what to ask.

**Why it matters.**

The integration pipeline prepares a typed, provenanced canon — necessary but not sufficient. Without a directed review-and-refine dialog the canon accumulates without converging on something that actually serves the effort. Dialog design isn't cosmetic; it is the surface where the human's judgment enters the system. Calibration is what keeps that judgment productive over time — without it, the user can approve their way into a hollow canon that looks fine on every individual axis.

**Where it lives.**

- `plugins/canon-workspace/skills/canon-synthesis/SKILL.md` → "Review dialog patterns": principles, proactive menu, observation-to-lever mapping, calibration moves, seeding.
- `docs/spec.md` §9 principle 9 (calibration as first-class).
- `docs/spec.md` §1 Overview Step 2 (proactive menu) and Step 3 (observation-to-lever translation).

---

## 2026-04-19 — Chat-as-primary; HTML-as-visual-reference

**Context.** Early spec wording described `/canon-review` as generating "a throwaway HTML rendering of the canon for a directional-alignment pass." The Overview's Step 2 had the user opening the HTML and then "forming judgments" — leaving it ambiguous whether review meant *reading* the HTML, *interacting with* the HTML, or something else.

**Tension.** Conflating the visual reference with the review mechanism would mis-direct investment in two directions: we'd build HTML affordances that duplicate work the chat does better (in-page editing, form controls, persisted annotations), and we'd leave the chat under-designed because the HTML seemed to carry the review surface.

**Resolution.**

- Named the **chat with the main agent in the same Claude Code session** as the primary review mode.
- Named the HTML render as a **disposable visual reference** that makes the canon legible enough for the chat to be productive. Read-only by design. Editorial changes come through the chat, not the page.
- Rewrote Overview Steps 2 and 3 with explicit actor labels (User action / Main agent action / Main agent action (subagent dispatch)) and numbered sub-steps, so the flow is unambiguous.

**Why it matters.**

The two surfaces do different things well: the HTML surfaces structure and state at a glance; the chat handles expression of intent and the agent's translation of intent into mechanical edits. Keeping them separate lets each do its job. Also makes a natural place for *calibration* (previous entry) — the chat is where the agent can proactively probe, not the page.

**Where it lives.**

- `docs/spec.md` §1 Overview Step 2 (opening paragraph names the chat as primary, HTML as visual reference).
- `docs/spec.md` §4.3 `/canon-review` description.
- `docs/spec.md` §1 Projections — review projection described as "a disposable visual reference that supports the review chat."

---

## 2026-04-19 — Source collectors and inbox staging (Phase 9)

**Context.** The working loop assumed sources arrive as markdown files the user has hand-prepared. `/canon-workspace:integrate-source <path-to-markdown>` was the only entry point.

**Tension.** Real corpora are not pre-normalized markdown. Users have email threads, Google Docs, URLs, LinkedIn posts, Claude chat transcripts. Requiring them to export, strip, and convert by hand is significant friction before the canon workspace's value kicks in, and it pushes work into the user's head that the system could do.

**Resolution.**

- Added an upstream layer: **source collectors**. One subagent per source type (`url-collector`, `claude-chat-collector`, `email-collector`, `gdoc-collector`, with room to grow). Each uses the relevant MCP tools or `WebFetch`, fetches items per the user's filter, converts to markdown with YAML frontmatter carrying provenance, and writes to `inbox/<collector>-<slug>.md`.
- Added a new workspace directory: `inbox/`. Unlike `sources/`, it is **mutable** — users review, rename, or delete staged files before integration. `/integrate-source` preserves from `inbox/` (or any path) into the immutable `sources/`.
- Kept `sources/` markdown-only. Normalization is the collector's job, not the integrator's.
- Scheduled as Phase 9 in `build-plan.md`. **Parallel-eligible** with Phases 7–8 — nothing in the integration loop depends on how sources arrive, only that they are markdown when they hit `/integrate-source`.

**Why it matters.**

Without collectors, the plugin is useful only to users willing to pre-normalize their corpus — close to nobody. Adding collectors changes the plugin's accessible surface without changing the core discipline. Immutability of `sources/`, the provenance chain, and the two-subagent synthesis flow all remain untouched. Staging in `inbox/` preserves the human editorial gate: collectors pull, the user reviews, then integration proceeds.

**Where it lives.**

- `docs/build-plan.md` — Phase 9.
- `docs/spec.md` §1 Overview "Planned" list — Phase 9 summary.

---

## 2026-04-19 — Schema as living artifact

**Context.** Earliest design had a fixed `synthesis.md` template (Core concepts, Claims, Distinctions, Open questions, Glossary). Subagents had hardcoded section mappings. The canon's shape was a plugin decision, not a user decision.

**Tension.** Different efforts want different shapes. Research: Hypotheses / Findings / Methods / Limitations. Product: User needs / Features / Constraints / Risks. Thesis: Arguments / Evidence / Counter-arguments. Imposing a framework-development shape forces every other kind of effort to misfile material into categories that don't match the user's thinking. Worse, the user may not notice the misfit — the canon fills in plausibly, but each claim sits under the wrong heading.

**Deepening insight.** The canon's schema is itself a product of the effort. Both the schema and the UX that renders it need to co-evolve in dialog with the user. Three things evolve together:

1. The schema (kinds, sections, classification rules, display conventions).
2. The UX (how the schema renders for review).
3. The subagents' behavior (source-extractor's taxonomy, canon-updater's section mapping — both driven by the schema).

And the subagents themselves should feed the evolution: as they work, they notice material that resists the current schema and report those observations as structured feedback, giving the human data rather than just their own intuition to act on.

**Resolution.**

- Moved the schema into `process.md` as an authoritative `## Schema` section (Kinds, Sections, Classification rules, Display conventions). Subagents read it on every invocation and defer to it. (Phase 1.)
- Made `/canon-init` a schema sync-up dialog with multiple default templates (framework-development, research-synthesis, product-discovery, thesis-argumentation) and **accept / replace / collaborate** paths. (Phase 2.)
- Bumped extraction JSON to schema v2 with a `schema_observations` field — `source-extractor` flags friction, `canon-updater` prepends the observations to a new `schema-log.md`. (Phase 3.)
- Planned `/canon-workspace:evolve-schema` (Phase 7) and `/canon-workspace:evolve-ux` (Phase 8) to handle mid-effort changes with migration and alignment invariants.

**Why it matters.**

Treating the schema as fixed would silently corrupt canons built on any material that doesn't match the default. Treating it as *negotiable* requires making the negotiation visible and first-class — at init (so the user picks knowingly), during use (so the system reports friction the user can't self-volunteer), and over time (so changes have recorded evolution and a migration path).

**Where it lives.**

- `plugins/canon-workspace/templates/schemas/*.md` — the default schema templates.
- `plugins/canon-workspace/templates/process.md` — `{{SCHEMA}}` placeholder filled at init.
- `plugins/canon-workspace/templates/schema-log.md` — evolution and fit-observation log.
- `docs/spec.md` §4.1 (canon-init dialog), §4.4 (source-extractor schema-awareness), §4.5 (canon-updater schema-awareness), §6 (extraction schema v2), §9 principles 3 and 8.
- `docs/build-plan.md` Phases 1–3 (done), 7–8 (planned).

---

## 2026-04-19 — Context curation by delegation

**Context.** The first working `source-extractor` returned its full classification as JSON *inline* — the subagent's final message was a fenced JSON block containing all N atomic units. That JSON landed in the main agent's context via the Task tool's result.

**Tensions, discovered in two passes.**

1. *Returning the JSON inline flooded the main agent's context.* A test extraction produced 79 units and ~22.7k tokens of JSON. Every subsequent step in the main agent's context paid that cost.

2. *First fix (persist + pointer) solved half.* Subagent now writes `extractions/<source_id>.json` and returns a short pointer line. But the main agent still had to *walk* the extraction to apply canon updates — and that walk was going to happen in the main agent's context, costing the same tokens one step later. Deferral isn't a solution.

3. *Correct fix: delegate the walk itself.* Introduced a second subagent (`canon-updater`) that reads the extraction, applies incremental edits to `synthesis.md`, prepends to `source-log.md`, and returns a one-line summary. The main agent now stays thin end-to-end.

**Resolution.**

- Two-subagent synthesis pipeline. Both return pointer lines. Main agent's total context accumulation per integration = the two pointer lines plus its own orchestration prompt.
- Extraction persistence remains — enables future subagents (duplicate-detector, conflict-analyzer) to consume extractions without re-running extraction, and enables audit.
- When the HTML renderer was added, the same pattern applied: `canon-renderer` is a subagent that reads canon artifacts, writes the HTML, returns a pointer. Main agent never ingests the render's contents.
- When collectors arrive (Phase 9), same pattern: each collector runs in its own context, writes to `inbox/`, returns a pointer summary.

**Why it matters.**

The context-curation principle didn't come from a design review; it came from watching the first design fail in practice. Naming and enforcing the principle is what prevents regression as the pipeline grows. New operations become new subagents with short return contracts, not new logic in the main agent.

**Where it lives.**

- `plugins/canon-workspace/agents/source-extractor.md` — writes to disk, returns pointer.
- `plugins/canon-workspace/agents/canon-updater.md` — consumes extraction in its own context, returns summary.
- `plugins/canon-workspace/agents/canon-renderer.md` — same pattern applied to rendering.
- `docs/spec.md` §1 Overview (working loop), §4 subagent sections, §9 principle 2 (structured hand-offs), §10 (artifact addressing and pointer resolution).
