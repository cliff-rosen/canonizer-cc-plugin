---
description: Integrate a new source into the canon — the add step of the working loop.
argument-hint: <path-to-markdown-source>
---

You are integrating a single source into a canon workspace. This command is a **thin orchestrator**: it preserves the source, dispatches two subagents (each in its own context), and reports two short lines to the user. You do not walk atomic units. You do not edit the canon. The subagents do that work in contexts you never see.

## Inputs

- `$ARGUMENTS` is expected to be the path to a markdown source file.
- The current working directory is the canon workspace root.

If `$ARGUMENTS` is empty, ask the user for the source path before proceeding.

## Phase 1 — Validate

1. Run `pwd` to confirm the workspace root.
2. Check that all of these exist in the cwd:
   - `synthesis.md`
   - `process.md`
   - `source-log.md`
   - `schema-log.md`
3. Check that `$ARGUMENTS` points to an existing markdown file.

If any check fails, STOP and tell the user precisely what's missing. Do not proceed with partial prerequisites.

## Phase 2 — Pick a `source_id`

Look at `sources/` and find the existing `conv-NNN-*.md` files. Pick the next sequential `NNN` (three-digit, zero-padded) that is not taken.

Derive a slug from the input file's basename:
- Strip the `.md` extension.
- If the basename already matches `conv-\d{3}-.+`, use it verbatim as the `source_id` (so: the file is being re-preserved with the same id).
- Otherwise, the slug is the basename lowercased, with non-alphanumeric characters replaced by `-`, leading/trailing `-` stripped, collapsed runs of `-` compressed. Prefix with `conv-NNN-`.

Result: `source_id = conv-NNN-<slug>`. Surface this id briefly to the user ("Assigning source_id: conv-NNN-...").

## Phase 3 — Preserve the source

Use Bash to copy the input file to `sources/<source_id>.md`:

```
cp "<input_path>" "sources/<source_id>.md"
```

Verify the copy succeeded. From this point on, the file under `sources/` is immutable — a `PreToolUse` hook enforces this for `Write`/`Edit`/`MultiEdit`.

## Phase 4 — Delegate extraction

Dispatch the `canon-workspace:source-extractor` subagent via the Task tool. Pass a prompt containing **exactly** these inputs as a clear list:

- **Source path:** `<absolute path to sources/<source_id>.md>`
- **Synthesis path:** `<absolute path to synthesis.md>`
- **Process path:** `<absolute path to process.md>`
- **Source ID:** `<source_id>`
- **Workspace root:** `<absolute path to cwd>`

The subagent will read the source, classify atomic units, write `extractions/<source_id>.json`, and return one pointer line. Capture that line verbatim.

If the line starts with `FAILED:`, STOP and surface the failure to the user. Do not proceed to Phase 5.

## Phase 5 — Delegate canon update

Dispatch the `canon-workspace:canon-updater` subagent via the Task tool. Pass a prompt containing **exactly** these inputs:

- **Extraction path:** `<absolute path to extractions/<source_id>.json>`
- **Synthesis path:** `<absolute path to synthesis.md>`
- **Source-log path:** `<absolute path to source-log.md>`
- **Schema-log path:** `<absolute path to schema-log.md>`
- **Process path:** `<absolute path to process.md>`
- **Source ID:** `<source_id>`
- **Workspace root:** `<absolute path to cwd>`

The subagent will apply incremental edits to `synthesis.md`, prepend a source-log entry, prepend a schema-log entry if the extraction carried observations, and return one summary line. Capture that line verbatim.

If the line starts with `FAILED:` or `PARTIAL:`, surface it prominently.

## Phase 6 — Report

Report to the user in this exact form (fill in the captured lines):

```
Integration complete.

  <EXTRACTED: ...>
  <UPDATED: ...>

Review the result through the UX:
  /canon-workspace:canon-review

Audit the raw changes with `git diff`; commit when satisfied.
```

Do NOT dump extraction contents. Do NOT summarize the atomic units. Do NOT suggest specific edits to `synthesis.md`. The review projection and `git diff` are the surfaces the human uses.

## Anti-patterns — you MUST NOT

1. **Walk the extraction.** Per-unit work belongs to `canon-updater`. You orchestrate; it executes.
2. **Edit `synthesis.md` yourself.** Only `canon-updater` does that.
3. **Commit to git.** The human reviews via the UX and commits.
4. **Skip the subagent dispatch.** Inline substitution defeats the whole context-curation design.
5. **Guess when a subagent reports FAILED.** Surface the reason and stop.
