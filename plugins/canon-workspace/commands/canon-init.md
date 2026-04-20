---
description: Scaffold a new canon workspace and sync up on its schema with the user.
argument-hint: [--force]
---

You are initializing a canon workspace in the current working directory. The plugin root is at `${CLAUDE_PLUGIN_ROOT}`; templates live at `${CLAUDE_PLUGIN_ROOT}/templates/`; schema templates live at `${CLAUDE_PLUGIN_ROOT}/templates/schemas/`.

This command has **two phases**: a mechanical scaffolding phase, and a **schema sync-up dialog** with the user. The dialog is the point where the user and system agree on the canon's shape for this effort. Do not skip it.

## Phase 1 — Preconditions

Run `pwd` to confirm the target directory. Run `ls -la` to see what is there.

- If `synthesis.md` exists and `$ARGUMENTS` does NOT contain `--force`: STOP. Tell the user this workspace is already initialized. Do not mention `--force` unless they ask — overwriting is destructive.
- If `synthesis.md` exists and `--force` is provided: warn the user explicitly, then proceed to overwrite.
- If the directory is non-empty (other than `.git/`) and `synthesis.md` does not exist: briefly confirm with the user before proceeding.

## Phase 2 — Scaffold the non-schema parts

Create these directories, each with a `.gitkeep` file inside:
- `sources/`
- `extractions/`
- `drafts/`
- `review/`

Read and write these files (copy as-is, unless transform noted):

| Source | Destination | Transform |
|---|---|---|
| `${CLAUDE_PLUGIN_ROOT}/templates/source-log.md` | `./source-log.md` | Copy as-is. |
| `${CLAUDE_PLUGIN_ROOT}/templates/schema-log.md` | `./schema-log.md` | Copy as-is (entry #1 is added in Phase 5 below). |
| `${CLAUDE_PLUGIN_ROOT}/templates/README.md` | `./README.md` | Copy as-is. |
| `${CLAUDE_PLUGIN_ROOT}/templates/gitignore` | `./.gitignore` | Copy as-is (note leading dot in destination). |

Do NOT yet write `synthesis.md` or `process.md` — those depend on the schema choice.

## Phase 3 — Schema sync-up dialog

This is the collaboration moment. The canon's shape for this effort will be decided here.

### 3a — Introduce the idea

Tell the user (in your own words, concise):

> A canon workspace has an explicit **schema** — what kinds of atomic units get extracted from sources, what sections appear in `synthesis.md`, and how classification flows. The schema lives in `process.md` and is the authority for every subagent. It can be revised later, but we pick a starting point now.

### 3b — List the available schema templates

Use Glob on `${CLAUDE_PLUGIN_ROOT}/templates/schemas/*.md` to find the schema template files. For each, Read its YAML frontmatter (lines between the leading `---` markers) and extract `title` and `description`.

Present them to the user as a numbered list, each with its title and one-to-two-sentence description. End with two more options:

> Or you can (A) **provide your own schema** inline, or (B) **collaborate with me** to draft one from scratch.

### 3c — Ask once

Ask the user a single clear question: which would they like?

Wait for the answer. Do not assume. If the answer is ambiguous, clarify.

### 3d — Branch on the answer

**If they pick a listed template:**
- Read that file. Strip the frontmatter (everything between the first `---` and the second `---`, inclusive). The remainder is the Schema section body — it starts with `## Schema` and contains all of Kinds, Sections, Classification rules, Display conventions.
- Record: `choice = "accept-default"`, `template = <name from frontmatter>`, `schema_body = <stripped content>`.

**If they choose (A) provide your own:**
- Ask them to provide the schema content. They may paste a full `## Schema` section (with all subsections), or describe it in prose for you to structure.
- If they pasted a full section: use it as `schema_body`. Record: `choice = "replace"`, `template = "custom"`.
- If they described it in prose: draft the full `## Schema` section (Kinds, Sections, Classification rules, Display conventions) based on their description, using the listed templates as structural guides. Show them your draft. Iterate until they accept. Record: `choice = "replace"`, `template = "custom"`.

**If they choose (B) collaborate from scratch:**
- Ask them about their effort: what are they trying to converge on? What kinds of things are their conversations producing? What sections would a useful synthesis have?
- Based on their answers, draft a complete `## Schema` section. Show it. Iterate until they accept.
- Record: `choice = "collaborate"`, `template = "custom"`.

In all three branches, the end state is: a complete `## Schema` section body the user has agreed to, plus metadata about the choice.

## Phase 4 — Compose `process.md` and `synthesis.md`

### 4a — `process.md`

Read `${CLAUDE_PLUGIN_ROOT}/templates/process.md`. It contains a `{{SCHEMA}}` placeholder. Replace that exact placeholder line with the `schema_body` you captured. Write the result to `./process.md`.

### 4b — `synthesis.md`

Read `${CLAUDE_PLUGIN_ROOT}/templates/synthesis.md`. It contains `{{DATE}}` and `{{SECTIONS}}` placeholders.

Parse the **Sections** list from the `schema_body` (it's a bulleted list under `### Sections`). For each section entry, generate a markdown block of the form:

```
## <Section name>

<placeholder text>
```

Where `<placeholder text>` is:
- For sections whose description includes "Populated by the human" or "not touched by subagents": use a brief human-facing prompt like `<one-paragraph statement of what this canon represents>` for Overview, or the description's guidance for others.
- For all other sections (receives units of kind X): use `<empty — populated via integration>`.

Join all section blocks with blank lines. Replace `{{SECTIONS}}` with that joined block. Replace `{{DATE}}` with today's date in `YYYY-MM-DD` format. Write the result to `./synthesis.md`.

## Phase 5 — Write schema-log.md entry #1

Open `./schema-log.md` and prepend (immediately after the `---` separator) a dated entry of the form:

```markdown
## <YYYY-MM-DD> — schema initialized

- Event: initial
- Choice: <the `choice` value: accept-default | replace | collaborate>
- Template: <the `template` value>
- Kinds: <comma-separated list of kind names from the schema>
- Sections: <comma-separated list of section names from the schema>
- Notes: <one sentence, optional — e.g., the user's framing of why this schema>

---
```

## Phase 6 — Initialize git

If the directory is not already a git repository (no `.git/`), run `git init`.

Then stage and commit:
```
git add .
git commit -m "canon-init: scaffold workspace with <template> schema"
```

Substitute the chosen template name (or `custom` if the user replaced/collaborated).

## Phase 7 — Report

Tell the user:

- Workspace initialized at the cwd.
- Schema: <template name>, with kinds <list> and sections <list>.
- Next steps: fill in the **Overview** section of `synthesis.md` (and Glossary if applicable), then run `/canon-workspace:integrate-source <path>` to add your first source.
- If at any point the schema needs to change, use `/canon-workspace:evolve-schema` (planned) or edit `process.md`'s `## Schema` section directly — subagents will pick up the new schema on their next invocation.

Do not volunteer further configuration steps. The workspace is intentionally minimal.
