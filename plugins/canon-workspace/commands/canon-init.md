---
description: Scaffold a new canon workspace in the current directory.
argument-hint: [--force]
---

You are initializing a canon workspace in the current working directory. The plugin that defines this command is installed at `${CLAUDE_PLUGIN_ROOT}`; the templates you need live at `${CLAUDE_PLUGIN_ROOT}/templates/`.

## 1. Check preconditions

Run `pwd` to confirm the target directory. Run `ls -la` to see what is already there.

Determine whether this workspace is already initialized by checking for `synthesis.md`:

- **If `synthesis.md` exists and `$ARGUMENTS` does NOT contain `--force`:** STOP. Tell the user this workspace is already initialized and do not proceed. Mention that `--force` would overwrite files, but do NOT suggest it unless the user asks — overwriting is destructive.
- **If `synthesis.md` exists and `--force` is provided:** proceed; you will overwrite the canon files. Warn the user explicitly before writing.
- **If the directory is non-empty** (files other than a `.git/` directory) and `synthesis.md` does not exist: briefly confirm with the user before proceeding, so they know the scaffold will land alongside their existing files.

## 2. Write the scaffold

For each template file below, Read it from `${CLAUDE_PLUGIN_ROOT}/templates/` and Write it to the workspace. Apply the noted transform:

| Source (under `${CLAUDE_PLUGIN_ROOT}/templates/`) | Destination (under cwd) | Transform |
|---|---|---|
| `synthesis.md` | `./synthesis.md` | Replace `{{DATE}}` with today's date in `YYYY-MM-DD` format. |
| `process.md` | `./process.md` | Copy as-is. |
| `source-log.md` | `./source-log.md` | Copy as-is. |
| `README.md` | `./README.md` | Copy as-is. |
| `gitignore` | `./.gitignore` | Copy as-is (note the leading dot in the destination filename). |

Create these directories, each containing a `.gitkeep` file:

- `sources/`
- `extractions/`
- `drafts/`
- `review/`

## 3. Initialize git

If the directory is not already a git repository (no `.git/`), run `git init`.

Then create the initial commit:

```
git add .
git commit -m "canon-init: scaffold workspace"
```

## 4. Report

Tell the user:

- Workspace initialized at the cwd path.
- Next step: fill in the **Overview** section of `synthesis.md` and the **Purpose** section of `process.md`.
- To integrate a source: `/canon-workspace:integrate-source <path-to-markdown>`.

Do not volunteer additional configuration, customization, or "next improvements" — the workspace is intentionally minimal.
