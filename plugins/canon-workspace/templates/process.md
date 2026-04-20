# Process

*This document is the method for this canon. It is a maintained artifact. Revise it when the method evolves.*

## Purpose

<one-paragraph statement of what this canon is for — what effort it supports, who reads it, what downstream artifacts draw from it>

## Seven principles

These are the invariants. If practice drifts, return here.

1. **The canon is separate from the corpus, and both are addressable.** Raw conversations live in `sources/` as named files, read-only after capture. The canon lives in `synthesis.md` plus spin-off detail files as the material demands.

2. **The process is a document, not a habit.** This file describes how the work gets done. The method is itself a maintained artifact, inspectable and revisable. The agent follows it.

3. **The working loop is explicit and repeatable.** See below. Written down, not improvised.

4. **Uncertainty gets a notation.** Confidence markers let claims enter the canon before they're fully settled without pretending they're settled. See "Confidence markers" below.

5. **Provenance is structural, not narrative.** Every canonical element traces back to source fragments via `source-log.md`, `extractions/`, and the verbatim `sources/` directory.

6. **The division of labor is enforced by the method, not assumed.** The agent does mechanical work; the human does editorial work. See "Division of labor" and "Anti-patterns" below.

7. **Human-review artifacts are scaffolding, not product.** `review/` artifacts support directional-alignment passes and are gitignored.

{{SCHEMA}}

## The working loop

`/canon-workspace:integrate-source <path>` is a thin orchestrator. The per-unit work happens inside two subagents, each in its own context. The main agent's context stays light across the whole flow.

1. **Validate.** Confirm the source path exists and is markdown. Confirm `synthesis.md`, `process.md`, and `source-log.md` exist.
2. **Preserve source.** Copy the file into `sources/<source_id>.md` (e.g., `conv-NNN-<slug>.md`). Do not modify content. The stem is the `source_id`.
3. **Delegate extraction.** Invoke the `source-extractor` subagent, passing the preserved source path, `synthesis.md` path, `source_id`, and workspace root. The subagent writes `extractions/<source_id>.json` (schema v1) and returns one pointer line:
   ```
   EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)
   ```
4. **Delegate canon update.** Invoke the `canon-updater` subagent, passing the extraction path, `synthesis.md` path, `source-log.md` path, `process.md` path, `source_id`, and workspace root. The subagent reads the extraction, applies incremental edits to `synthesis.md` with confidence markers, appends an entry to `source-log.md`, and returns one summary line:
   ```
   UPDATED: synthesis.md (+Cc concepts, +Ll claims, +Aa assumptions, +Dd distinctions, +Qq questions, Ff flagged in-flight) · source-log.md (1 entry, Ss supports logged, Rr retired)
   ```
5. **Report to the user.** Surface the two lines above, note `git diff` is available for a raw-changes audit, and point the user at `/canon-workspace:canon-review` as the primary review surface — that is where editorial judgment (promotion, resolution, retirement, schema and UX shaping) actually happens. The working loop does not commit to git.

**What this flow buys:** atomic-unit detail lives in `extractions/<source_id>.json` and in the two subagents' disposable contexts. The main agent sees only pointer lines.

**Known gap:** deduplication is not performed in v0. `source-extractor` emits near-duplicates rather than collapsing them; `canon-updater` carries them into `synthesis.md`. The human resolves duplicates during review, or defers until a future `duplicate-detector` subagent is added.

## Artifact addressing

The canon workspace has a small, fixed set of addressable artifacts. Every reference across the system uses one of these forms:

| Form | Meaning | Who writes | Who reads |
|---|---|---|---|
| `sources/<source_id>.md` | Preserved verbatim source. Immutable after capture. | The integrator at capture time. | `source-extractor`; never the main agent directly. |
| `extractions/<source_id>.json` | Structured classification of one source. Schema v1. | Only `source-extractor`. Overwritten on re-extraction. | `canon-updater` (full walk), main agent (rare narrow reads). |
| `synthesis.md` | The canon. Single source of truth. | `canon-updater` via incremental edits. | Everyone. |
| `source-log.md` | Append-only integration log, newest-first. Cites extractions and sources by path. | `canon-updater` (prepends entries). | Humans, auditors, future subagents. |

**Resolving a pointer without flooding context.** The main agent never walks an extraction directly. Per-unit work is delegated to a subagent whose context is disposable. If ad-hoc narrow reads are needed, prefer Grep by classification, or Read with offset/limit.

**Schema versions.** Extractions carry a `"schema"` field. Consumers that encounter an unknown version refuse to proceed and surface the mismatch.

## Confidence markers

Three states, used inline in `synthesis.md`:

- **(tentative)** — the claim is a candidate; supported by ≥1 source but not yet corroborated. All `adds` enter with this marker.
- **(in flight)** — the claim is contested or being refined; a conflict was surfaced and not yet resolved. Inserted as an annotation beneath the conflicting element.
- **unmarked** — stable; corroborated, not contested, not pending review. Reached only via human promotion.

When a marker is removed, `source-log.md` records the reason (e.g., `"stabilized by conv-007"` or `"resolved via human review 2026-04-20"`).

## Division of labor

**The agents do:**
- `source-extractor` — read the source, classify atomic units against the canon, emit `extractions/<source_id>.json`.
- `canon-updater` — apply mechanical updates to `synthesis.md`, log the integration, retire resolved questions, flag conflicts.
- The main agent — orchestrate the two subagents; report pointer lines and the `git diff` path to the human.

**The human does:**
- Promote `(tentative)` claims to stable.
- Resolve `(in flight)` conflicts.
- Make directional-alignment calls about the framework overall.
- Decide whether two ideas are the same, whether an assumption is still active, whether a framing is central.
- Review every integration via `git diff` and commit.
- Revise this file when the method itself should change.

## Anti-patterns — the agents MUST NOT

1. **Auto-promote tentative claims to stable.** Marker removal requires human instruction or a clear integration event logged with reason.
2. **Auto-resolve conflicts.** Conflicts are flagged `(in flight)` and surfaced for human decision.
3. **Edit files in `sources/`.** Sources are immutable after capture (also enforced by a hook).
4. **Edit files in `extractions/` from anywhere except `source-extractor`.** Re-run the subagent to re-extract.
5. **Pull extraction contents into the main agent's context.** Per-unit work is delegated.
6. **Summarize sources.** Extraction is atomic-unit classification, not summarization.
7. **Rewrite `synthesis.md` wholesale.** Edits are incremental and traceable to extraction units.
8. **Proceed silently on ambiguous integrations.** Skip and flag rather than guess.
9. **Collapse distinct open questions.** Preserve them separately until explicitly merged or retired.
10. **Commit to git.** The human reviews via `git diff` and commits.

---

*This file is the authoritative method for this canon. If `/canon-workspace:integrate-source` or either subagent diverges from the working loop above, this file wins and the code is a bug.*
