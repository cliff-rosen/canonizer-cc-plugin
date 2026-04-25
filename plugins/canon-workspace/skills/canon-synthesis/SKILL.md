---
name: canon-synthesis
description: This skill should be used when working in a canon workspace — a directory containing both `synthesis.md` and `process.md` — or when the user discusses canon, synthesis, confidence markers (tentative / in flight), the working loop, source integration, extractions, atomic units, or the discipline of turning a corpus of exploratory conversations into a maintained canonical representation.
version: 0.3.1
---

# Canon synthesis discipline

A canon workspace turns a corpus of exploratory conversations into a maintained canonical artifact. This skill teaches the discipline. The workspace's `process.md` teaches the method.

## Authority

**If a `process.md` exists in the current workspace, it is authoritative.** It may have been customized for this project. Read it before doing canon work.

This skill carries the defaults that `process.md` was seeded from. When the two disagree, `process.md` wins.

## What this is, and isn't

A canon workspace has:

- `synthesis.md` — the canon. The single maintained statement of what has been learned.
- `process.md` — the method. How synthesis is done here.
- `source-log.md` — append-only integration log, newest-first.
- `sources/` — immutable source files, read-only after capture.
- `extractions/` — structured per-source classifications (schema v1), written only by the `source-extractor` subagent.
- `drafts/`, `review/` — spin-off detail and disposable review artifacts.

The canon is **separate from the corpus**. Sources are inputs; `synthesis.md` is the product. Do not confuse them.

## The two-subagent flow

`/canon-workspace:integrate-source` orchestrates two subagents, each in its own context:

- **`source-extractor`** reads the source + `synthesis.md`, writes `extractions/<source_id>.json`, returns a one-line pointer.
- **`canon-updater`** reads the extraction + `synthesis.md` + `process.md`, applies incremental edits to `synthesis.md`, appends an entry to `source-log.md`, returns a one-line summary.

The main agent never walks the N atomic units. Per-unit detail lives in the extraction file and in the subagents' disposable contexts.

Synthesis is classically framed as six operations: extract, normalize, dedupe, reconcile, canonicalize, trace. Our subagents implement five of them (extract and normalize inside `source-extractor`; reconcile split across both; canonicalize and trace inside `canon-updater`). Dedupe is deferred — `source-extractor` emits near-duplicates rather than collapsing them.

## Artifact addressing

Every cross-system reference uses one of four forms:

- `sources/<source_id>.md` — preserved verbatim source.
- `extractions/<source_id>.json` — structured classification (schema v1), written only by `source-extractor`.
- `synthesis.md` — the canon, edited only by `canon-updater`.
- `source-log.md` — append-only log citing the others by path, prepended by `canon-updater`.

**Never pull an extraction into the main agent's context.** Per-unit work is delegated to `canon-updater`. If ad-hoc narrow reads are required, prefer Grep by classification or Read with offset/limit — but this is unusual.

**Schema versions.** If an extraction's `schema` field is unknown, refuse to proceed and surface the mismatch.

## Confidence markers

Three states, used inline in `synthesis.md`:

- **(tentative)** — candidate; supported by ≥1 source. All `adds` enter with this marker.
- **(in flight)** — contested or being refined; conflict annotation beneath the conflicting element.
- **unmarked** — stable; corroborated, not contested. Only via human promotion.

When a marker is removed, `source-log.md` records why.

## Division of labor

**The agents do:**
- `source-extractor` extracts and classifies.
- `canon-updater` applies mechanical updates and logs.
- The main agent orchestrates and reports pointer lines; pointing the user at the UX for review and `git diff` for raw-change audit.

**The human does:**
- Promote tentative claims to stable.
- Resolve `(in flight)` conflicts.
- Directional-alignment calls.
- Decide whether two ideas are the same, whether an assumption is still active, whether a framing is central.
- Review every integration through the UX (`/canon-workspace:canon-review`); `git diff` is an audit side-channel for raw changes before commit.
- Revise `process.md` when the method itself should change.

If you find yourself about to do editorial work, stop and surface the decision.

## Anti-patterns — the agents MUST NOT

1. **Auto-promote tentative claims to stable.** Marker removal requires human act.
2. **Auto-resolve conflicts.** Conflicts are flagged `(in flight)` only.
3. **Edit files in `sources/`.** Sources are immutable (also enforced by a hook).
4. **Edit files in `extractions/` from anywhere except `source-extractor`.**
5. **Pull extraction contents into the main agent's context.** Delegate to `canon-updater`.
6. **Summarize sources.** Extraction is classification, not summarization.
7. **Rewrite `synthesis.md` wholesale.** Incremental edits only.
8. **Proceed silently on ambiguous integrations.** Skip and flag.
9. **Collapse distinct open questions.**
10. **Commit to git.** Human reviews in the UX, audits via `git diff`, and commits.

## Review dialog patterns

After a `/canon-workspace:canon-review` render, the user typically comes back with observations rather than specific commands. Your job is to (a) proactively surface the available refinement moves — the user shouldn't need to know them in advance — (b) translate free-form observations into concrete levers, and (c) calibrate the user's recognition of whether the canon is actually serving the effort.

### Principles

These are directional. When the examples below don't cover a situation, fall back on these.

1. **The human owns editorial authority.** Your job is to prepare decisions — surface what's there, name the lever, propose the specific action. Never make the decision. Promotion, resolution, retirement, schema change, UX change — all require explicit human instruction or confirmation.
2. **Narrow to a decision; don't summarize.** The user already has the render. Your value is moving them from "I'm looking at the canon" to "here's a specific thing to decide and apply." Prefer one concrete refinement over a survey. If there are many candidates, suggest one as an entry point.
3. **Name the lever before acting.** When the user offers an observation, identify which layer it touches — content / UX / schema / provenance — say so out loud, and propose the specific action at that layer. Don't touch anything until the user confirms the lever.
4. **Every change carries a reason, in the log.** Any edit to `synthesis.md`, `process.md`, or the renderer gets an accompanying entry in `source-log.md` or `schema-log.md` capturing what changed and why. The canon is meant to be inspectable later — by the human, a future subagent, or a future reader.
5. **Changes flow through the right layer.** Content refinements → `synthesis.md`. Schema refinements → `process.md`'s `## Schema` with a migration. UX refinements → files under `plugins/canon-workspace/renderer/`. Don't paper over a schema mismatch with content edits, or over a content question with a UX tweak. If an observation genuinely straddles layers, name it and ask which to touch first.
6. **Ambiguity is a flag, not a guess.** When the right move is unclear — which element the user means, whether to batch or split, which layer applies — stop and ask a targeted question. Silent guessing is an anti-pattern (this is the same principle that governs the other subagents, applied to dialog).
7. **Purpose anchors hard calls.** When a refinement is genuinely hard and preferences conflict, return to `process.md`'s **Purpose** section. What this canon is *for* is the tiebreaker — not your sense of tidiness, not a default best-practice.
8. **Calibrate the user's recognition; don't rely on it.** Do not assume the user will always notice when the canon has drifted from serving the effort. Use the calibration moves below proactively — especially when the dialog starts going "sure, looks good" without scrutiny, or when a consequential decision (mass promotion, schema change, commit of a large integration) is on the table.
9. **Synthesis ends at a picture, and the picture's shape is class-specific.** The endpoint of canon work is a populated `## Core structure` section — the spine. But *what* the spine looks like depends on the class of problem, declared in the schema's **Convergence target** subsection. A framework-development canon converges on a named framework of 3–5 central concepts; a research-synthesis canon on 1–3 principal findings bounded by methods and limitations; a product-discovery canon on a user-problem-solution triangle with constraints and risks; a thesis-argumentation canon on a thesis with supporting pillars. **Read the workspace's Convergence target before proposing, testing, or shaping the spine.** A flat list — however well-classified — is filing, not synthesis. Actively push toward the target shape: use `spine_candidates` from extractions, propose, test coverage, converge. Don't let a review end with just "here are the parts" — surface what the parts are trying to coalesce into, in the specific shape this schema is driving toward.

### Diff narration (when the render followed an integration)

Every `/canon-workspace:canon-review` that happens shortly after a `/canon-workspace:integrate-source` must be accompanied by a short narration of what changed — **before** the proactive menu. Read the topmost entry in `source-log.md` (that is the most recent integration) and describe it to the user. Shape:

> Since the `conv-NNN-<slug>` integration: K units added (by kind: X concepts, Y claims, Z …); F flagged `(in flight)`; M supports recorded. **Spine candidates: <N> — [brief list with unit refs and one-line rationale]**; none of these are in the canon yet (Core structure is human-owned). The current render does not highlight newly-added elements — the diff lives here in chat until a future template update surfaces it visually.

Do this without being asked. The user who re-renders after an integration is looking specifically to see what changed; don't make them dig. If the render was NOT preceded by an integration in this session (or the user is running a review on the existing state), skip this section and go straight to the proactive menu.

Interim note: a future template (Phase 6 alignment rules) will surface this visually on the page (per-bullet integration badges, a "What's new" sidebar panel). Until then, the narration is the mechanism.

### Proactive menu (offer after every render)

When you report the rendered path, follow it with a short, state-aware menu of common next moves. Tune the numbers to what's actually in the canon. Example shape:

> Rendered: `review/review-<timestamp>.html`.
> 
> Common moves from here:
> - **Promote tentatives** — there are N `(tentative)` entries that could become stable once you see corroboration. Say which ones.
> - **Resolve conflicts** — there are M `(in flight)` annotations awaiting a decision. I can walk you through them.
> - **Tune the rendering** — typography, marker styling, source-attribution placement, sidebar contents, etc. Say what feels off.
> - **Evolve the schema** — add/rename kinds or sections if the material is pushing against the current shape.
> - **Trace provenance** — for any element, I can show the source-log entry, the extraction unit, and the verbatim source fragment.

Keep it brief. Do not enumerate specific canon contents (let the HTML speak); just name the levers available.

### Mapping user observations to levers

When the user's response is an observation rather than a command, recognize which lever applies and propose a specific action rather than asking "what do you want to do?"

- **Observation about content** ("this claim feels too cautious"; "these two bullets are really the same"; "this should be stable now") → **content refinement**. Edit `synthesis.md`; log in `source-log.md`.
- **Observation about structure / the "picture"** ("this is just a laundry list — what are the few load-bearing pieces?"; "nothing hangs off anything"; "I can't hold this in my head") → **structural refinement**. Read `process.md`'s `## Schema` → `### Convergence target` first — that's the shape this canon is driving toward, and it's class-specific (framework / findings / user-problem-solution / thesis / custom). Work with the user to populate or revise `## Core structure` against that target. Use `spine_candidates` from the most recent extraction as starting material; test coverage (how many units would hang off each proposed spine element); converge on the number and kind of elements the Convergence target calls for. Every edit to Core structure logs a source-log entry noting what was promoted and why.
- **Observation about the display** ("the source attribution is too prominent"; "markers are hard to see"; "open questions get lost") → **UX refinement**. Edit files under `plugins/canon-workspace/renderer/` while preserving the alignment invariants from `process.md`'s Display conventions. (Phase 8 will formalize this path.)
- **Observation about the structure** ("a new kind would fit this better"; "the sections feel wrong"; "classification is misfiring") → **schema refinement**. Edit `process.md`'s `## Schema` section; plan a migration for `synthesis.md`; log in `schema-log.md`. (Phase 7 will formalize this path.)
- **Observation about provenance** ("where did this come from?"; "which sources back this?") → **provenance trace**. Read the relevant `source-log.md` entry, the `extractions/<source_id>.json` unit, and the preserved source fragment. Present concisely.
- **Analytical question** ("where's this canon weakest?"; "what's unresolved?"; "which concepts are most corroborated?") → **guided read**. Answer from the canon directly without editing.

Do not wait for the user to name the lever. Translate their feeling into a proposed specific action and confirm before applying.

### Calibration moves

Recognition is a skill, not a reflex. Reach for these when the dialog needs a check on whether what the user is looking at actually serves the effort, not just whether it looks coherent.

- **Spine check (the most important one).** Ask: "Does this canon have a picture yet, or is it still parts?" Check against the schema's **Convergence target** in `process.md` — that's the shape this class of canon converges toward. Specifically: is `## Core structure` populated with the kind and number of elements the Convergence target describes (e.g., 3–5 central concepts, or 1–3 principal findings, or a user-problem-solution set, or a thesis-and-pillars)? If no (empty, stale, or wrong shape for the class), that is the priority — nothing else the user can do with the canon compensates for the missing spine. Use `spine_candidates` from recent extractions as starting material; test coverage; propose candidates shaped to the target; let the user decide. **Use when:** after every integration (not just the first), whenever the canon has grown, and always when the user's observation is about the canon feeling diffuse or overwhelming.
- **Purpose-alignment check.** Ask: "Does the canon in its current state support the Purpose declared in `process.md`?" If partial or no, drill into the gap. Use when: the dialog has been drifting without clear forward motion, or before finalizing a large set of edits.
- **Empty-space probe.** Ask: "For a canon of this kind, what would you expect to see that isn't here yet?" Absences are harder to recognize than presences. Use when: the canon feels dense but the user is approving passively.
- **Adversarial framing.** Ask: "If a skeptical reader disagreed with the current framing, what would they point at?" Use when: stable claims are accumulating without challenge, or when the canon is about to feed a downstream artifact.
- **Back-to-source cycle.** Prompt a re-read: "This is now a stable claim — want to re-read the source fragments behind it to confirm?" Use when: promoting a marker, or when the user hasn't inspected source fragments in a while.
- **Differential rendering.** Post-integration diffs are **automatic** — see the "Diff narration" subsection above; do not wait for the user to ask. For ad-hoc diffs the user requests outside the automatic trigger (e.g., "what's happened since Monday?"), compute from `source-log.md` entries in the relevant window.
- **Provenance stress-test on promotion.** Before removing a `(tentative)` marker, ask the user to articulate why it's stable. If they can't, the promotion is premature — back off and ask a back-to-source question first.
- **Ratio hygiene.** Watch for stagnation: high tentative-to-stable ratio over many integrations, or no marker removals in a long time. Surface it: "It's been N integrations without a promotion — does the canon feel stuck, or is staying tentative right?"

Use calibration moves sparingly. Over-calibrating is its own anti-pattern — it paralyzes a user who already has the judgment to direct the canon. The goal is to break up "sure, looks good" moments, not to second-guess every decision.

### Seeding when the user doesn't know where to start

If the user just says "okay I'm looking at it" or similar, suggest an entry point tuned to the state: the most in-flight conflicts, the most recently-added section, the biggest open question. The goal is to get from "I'm looking" to "here's a concrete thing to decide" within a turn.

## How to work

For integrating a new source: `/canon-workspace:integrate-source <path>`.

For the review-and-refine loop: after `/canon-workspace:canon-review`, follow the review dialog patterns above.

For ad-hoc canon work (questions about the canon, human-directed edits to settle an `(in flight)` conflict, revising `process.md`): follow the principles above. Read `process.md` first if you have not this session.
