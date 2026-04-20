# Canon Workspace — Overview

*A narrative guide to what the plugin does, who it's for, and how the parts fit together. For the component-by-component build spec, see `spec.md`. For the underlying discipline, see `from-conversation-to-canon.md`.*

## What it is

A Claude Code plugin that packages a discipline: turning a corpus of exploratory conversations into a maintained canonical artifact. A canon workspace is a git-backed directory with a fixed anatomy — immutable `sources/`, structured `extractions/`, a living `synthesis.md`, an append-only `source-log.md`, and a `process.md` that states the method. Every canonical element traces back to a verbatim source fragment.

## Who it's for

Anyone who has spent weeks or months exploring a topic across many long conversations and wants the thinking to converge into an inspectable, reusable structure — the kind downstream artifacts (a proposal, a thesis, a product spec) can be drawn from. The canon *is* that structure. The workspace is where it lives.

## Flow for integrating one source

1. You export a transcript as markdown.
2. You point the plugin at it. (`/canon-workspace:integrate-source <path>` once built — currently the two subagents are invoked by hand.)
3. The main agent preserves the source to `sources/<source_id>.md` (frozen from there; a hook enforces it) and delegates.
4. `source-extractor` reads the source + current canon, writes a schema-v1 classification to `extractions/<source_id>.json`, and returns one line:
   ```
   EXTRACTED: extractions/<source_id>.json · N units (Ss/Aa/Cc)
   ```
   The units stay on disk. The main agent never ingests them.
5. `canon-updater` reads the extraction + `process.md`, applies incremental edits to `synthesis.md` — `adds` become `(tentative)` bullets under the right section; `conflicts` become `(in flight)` annotations beneath the existing element *without* modifying it; `supports` get logged; answered open questions are retired — then prepends a dated source-log entry. Returns one line:
   ```
   UPDATED: synthesis.md (…) · source-log.md (…)
   ```
6. You review with `git diff` and commit when satisfied. Nothing auto-commits.

## Over many integrations

Corroborated claims earn promotion from `(tentative)` to unmarked by human judgment. Flagged conflicts are resolved by human judgment. Questions get retired as sources answer them. The canon hardens incrementally — without the main agent ever walking hundreds of atomic units.

## What the architecture enforces structurally

- **Canon ≠ corpus.** Sources are frozen (hook); the canon evolves separately.
- **Provenance is addressable.** Four canonical artifacts, one form each; any claim can be walked back to its verbatim fragment via `source-log.md` → `extractions/<id>.json` → `sources/<id>.md`.
- **Mechanical for agents, editorial for humans.** Subagent prompts encode the anti-patterns — no auto-promotion, no auto-resolution, no wholesale rewrites, no silent guessing. The skill carries these forward into ad-hoc canon work between integrations.
- **Context curation by delegation.** The main agent stays thin because per-unit work happens only inside disposable subagent contexts. What flows back is one-line pointers.

## Current state

**Built and working:** `/canon-workspace:canon-init`, the `canon-synthesis` skill, the `sources/` immutability hook, the `source-extractor` subagent, the `canon-updater` subagent.

**Not yet built:** `/integrate-source` (the thin orchestrator around steps 3–5), `/canon-review` (a throwaway HTML renderer for directional-alignment passes).

**Known deferred:** deduplication — `source-extractor` emits near-duplicates and `canon-updater` carries them forward for human review until a `duplicate-detector` subagent is added (spec §11).

## The pattern worth pointing at

The discipline lives in structured hand-offs between disposable contexts, not in any one agent's head. That's why a simple `git diff` is sufficient as the human review surface — the work is already staged, typed, and provenanced by the time a human looks.
