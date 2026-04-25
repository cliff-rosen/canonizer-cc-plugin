---
description: Render the canon's review projection — an HTML page for directional-alignment review.
argument-hint:
---

You are generating the review projection of the current canon workspace. This command is a thin wrapper: it verifies the workspace, dispatches the `canon-renderer` subagent, and reports the output path. You do not render yourself.

## Phase 1 — Validate

1. Run `pwd` to confirm the workspace root.
2. Verify these exist in the cwd:
   - `synthesis.md`
   - `process.md`
   - `source-log.md`
   - `schema-log.md`
3. Verify `review/` exists (create it if somehow missing — it should have been scaffolded by `/canon-workspace:canon-init`).

If any check fails, surface the problem and stop.

## Phase 2 — Dispatch the renderer

Dispatch the `canon-workspace:canon-renderer` subagent via the Task tool. Pass these inputs clearly in the prompt:

- **Workspace root:** `<absolute path to cwd>`
- **Template path:** `${CLAUDE_PLUGIN_ROOT}/renderer/review-template.html`

Capture the returned line verbatim.

If the line starts with `FAILED:`, surface the failure and stop.

## Phase 3 — Report

Report to the user in this form, filling in the rendered path:

```
Review projection rendered.

  <RENDERED: review/review-<timestamp>.html>

Open that file in your browser to review. It is disposable (gitignored); regenerate any time with `/canon-workspace:canon-review`.
```

Do NOT describe the contents of the canon. Do NOT summarize what's in the review. The file speaks for itself.

## Anti-patterns — you MUST NOT

1. **Render the HTML yourself.** Always dispatch `canon-renderer`.
2. **Open the file in a browser.** Report the path; the user opens it.
3. **Include a preview.** The file is the preview.
