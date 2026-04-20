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
- The main agent orchestrates and reports pointer lines + a pointer to `git diff`.

**The human does:**
- Promote tentative claims to stable.
- Resolve `(in flight)` conflicts.
- Directional-alignment calls.
- Decide whether two ideas are the same, whether an assumption is still active, whether a framing is central.
- Review every integration via `git diff` and commit.
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
10. **Commit to git.** Human reviews `git diff` and commits.

## How to work

For integrating a new source: `/canon-workspace:integrate-source <path>`.

For ad-hoc canon work (questions about the canon, human-directed edits to settle an `(in flight)` conflict, revising `process.md`): follow the principles above. Read `process.md` first if you have not this session.
