# Table templates, tables and data sources (through a script, not REST)

> **Not a REST feature.** The REST module lists database schemas
> (`GET /templates/schemas/`) and stops there: it cannot create a table, a table template, its
> field-to-column mappings, its snippet or its data source (Content2), and it cannot read or write
> a table template's GOM, rules or output channel (`GET …/templates/table-templates/` → `404`).
> This file fills that gap with one BeanShell script that the REST API runs. Before using it,
> check the server's OpenAPI document (`/rest/v3/api-docs`) for table-template paths below
> `/templates/`: if your module version offers them, use the REST endpoints instead.

The work goes through one BeanShell script, `rest_table_template`, which the installer puts into
the project's ScriptStore and which is called via `POST /scripts/rest_table_template/execute`.
One `create` makes, in this order:

1. a **schema**, if asked for a new one,
2. the **database table**, from `<uid>.columns.txt`,
3. the **table template**: form (GOM), output channel, rules and **snippet** (what editors see
   for each dataset in lists, search and selection dialogs),
4. the **field-to-column mappings**; without them every dataset saves, and every column stays empty,
5. the **data source** (Content2) at the content store root, so editors can add datasets in
   ContentCreator. A template without one is useless to editors, so always create it.

`T` below is this skill's `scripts/table-templates/` folder (wherever the toolkit is installed).
Run every command **from the project root**: templates go to
`cms/templates/table-templates/<schema>/<uid>/`, backups to `backup/auto/`, scratch to `tmp/`.

## Why `/execute` is acceptable here

SKILL.md (*Scripts*) warns against using `/scripts/{name}/execute` as an RPC channel. This is
the one deliberate exception: the script is installed once, versioned with
this skill, and reports through one JSON log record that the client parses. Don't build further
throwaway execute calls on top of it.

Related skills:

| Need | Skill |
|---|---|
| Which GOM editor to pick, `CMS_INPUT_DATE` modes, output channel syntax | `firstspirit-templating-reference` |
| What the server-side BeanShell does (`rest_table_template.bsh`) | `firstspirit-scripting`, `firstspirit-api-reference` |
| Rendering datasets on a page (content projection, `FS_INDEX`, `FS_DATASET`) | `firstspirit-templating-reference` |
| Which snippet parts to fill | `firstspirit-template-design` |

## Setup (once per project, and after every toolkit update)

Credentials: the **same `.env` as the rest of this skill** (SKILL.md → *Setup*) in the project
root, or the file `$FS_ENV_FILE` names. Required: `FS_REST_BASE_URL` (ending in `/rest/v1`),
`FS_USERNAME`, `FS_PASSWORD`, `FS_PROJECT_ID`; optional `FS_TEMPLATE_SET_UID` (default `html`).
It must be gitignored; the installer warns if it isn't. Never echo `$FS_PASSWORD`.

```bash
$T/fs-table-install --check   # read only: target project + is the script current?
$T/fs-table-install           # shows the target, asks, backs up, uploads, reads back
```

The script lives in the ScriptStore folder **`rest-extension`** (override with
`FS_SCRIPT_FOLDER`). `POST /scripts/` ignores `location`, so the installer creates the script at the
root and then calls the script's own `relocate` action, which creates the folder if needed and moves
the script there. Calls by name keep working after the move. Script folders have no uid; they are
matched by name.

`--check` exits 0 if identical and in the folder, 2 if missing, 3 if different or in another
folder. **Read the `Target:` line and confirm the project with the user before installing
anything.** Trust the project id, not comments in the `.env`. An installed but outdated script
answers `Unknown action '<name>'`. Update it with `fs-table-install`.

A **401/403 is fatal**: fix the credentials, don't retry. A **429** whose body names failed logins
also means wrong credentials: fix them before trying again. (Values in single quotes are fine,
because the file is sourced by the shell.)

## Creating a table: the workflow

1. **Ask what the editor should enter**: each field's label, type, and whether it is per language.
   Ask for the template uid (`<schema>.<table>` by convention) and the display name. Decide which
   field names a dataset (the snippet label) and which adds meaning (the extract); propose it.
2. **Ask which schema it goes into.** Run `$T/fs-table schemas` and offer the existing
   schemas, or a new one. Never pick one silently. When running non-interactively, pass the
   answer as `--schema <s>` or `--new-schema <s>`.
3. **Write the directory** `<uid>/` in the project root. Start from
   `../assets/table-templates/myschema.event/` (title and text per language, a date,
   coordinates), and see [table-templates-file-formats.md](table-templates-file-formats.md) for
   which editor goes with which column type:
   - `<uid>.gom.xml`: the form. **Required.**
   - `<uid>.columns.txt`: the table, if it does not exist yet.
   - `<uid>.mappings.txt`: one `field=column` line per form field.
   - `<uid>.html`: the output channel. Use `<CMS_HEADER></CMS_HEADER>` if there is nothing to render yet.
   - `<uid>.snippet.txt`: the snippet. **Always write it** (see below); `create` warns without one.
   - `<uid>.rules.xml`: optional.
4. **Dry run, then create:**
   ```bash
   $T/fs-table create <uid> --new-schema <s> --name "Display name" --dry-run
   $T/fs-table create <uid> --new-schema <s> --name "Display name"
   ```
   The data-source uid defaults to the table name. It must be unique in the whole content store,
   so in a project that already has one by that name, pass `--content2 <schema>_<table>`.
   `create` checks this before it creates anything.
5. **Verify independently.** Don't rely on the create output:
   ```bash
   $T/fs-table schemas            # the table is listed under its schema
   $T/fs-table fields <uid>       # columns, with {LANG} expanded per language
   $T/fs-table diff <uid>         # "no differences"
   $T/fs-table snippet <uid>      # once a dataset exists: label/extract per language
   ```
   `create` already moved the directory to `cms/templates/table-templates/<schema>/<uid>/` and
   pulled it back, which writes `meta.json` and the server's `<uid>.mappings.txt`. Compare that
   mappings file with what you sent.
6. **Report what is now in the project**, and what was *not* verified. The tools do not check the
   form in ContentCreator. To check that a saved dataset lands in its columns, write one test
   dataset over REST and read it back (*Sample datasets over REST* below).

### The snippet: what editors see for a dataset

Without a snippet every dataset shows as `<data source>: #<id>` ("Events: #12") in
selection dialogs (`FS_INDEX`, `FS_DATASET`), search and reports, and editors cannot tell them
apart. The REST API cannot write snippets for any template type (SKILL.md → *Not available over
REST*); for **table templates** these tools write them through the same script.
`<uid>.snippet.txt` has three lines, each one snippet expression:

```
label=if(!tt_title.isEmpty, tt_title, if(!tt_text.isEmpty, truncate(tt_text.toText(false).trim(), 40), ""))
extract=if(!tt_start.isEmpty, tt_start.format("dd.MM.yyyy HH:mm"), "") + if(!tt_start.isEmpty && !tt_text.isEmpty, " | ", "") + if(!tt_text.isEmpty, truncate(tt_text.toText(false).trim(), 100), "")
thumbnail=
```

- **label**: the field(s) that name the object. Fall back to another field rather than to fixed
  text, so a broken expression still shows as empty in the check below.
- **extract**: what adds meaning (date, place, the start of the text). `CMS_INPUT_DOM`:
  `truncate(tt_text.toText(false).trim(), 100)`; `CMS_INPUT_DATE`: `tt_date.format("dd.MM.yyyy")`.
- **thumbnail**: only when the form has an image field (`if(!tt_image.isEmpty, tt_image, "")`).
- Give every `if` an else branch (`, ""`), and guard each optional field with `!x.isEmpty`.
- Syntax per input component: `firstspirit-templating-reference`, `templates/snippets.md`;
  which parts to fill: `firstspirit-template-design`, `snippets.md`.

**The server does not check a snippet** written over the Java API: an unclosed `if(` or a
misspelt field is stored, and evaluates to an empty label `[observed]` (2026-11-03, REST module `0.0.23-beta`). Two checks
stand in for it:

- `fs-lint` (runs before every push and create) refuses unknown keys, single quotes, unbalanced
  parentheses or quotes, and `tt_*` names that are not fields of `<uid>.gom.xml`.
- `fs-table snippet <uid>` evaluates the **local file** on the first datasets per language,
  before anything is saved; `--server` evaluates the saved one. It fails when every label is
  empty. `push` and `create` run it after writing a snippet.

To add a snippet to an existing table template: `pull`, write `<uid>.snippet.txt`, check it with
`fs-table snippet <uid>`, then `push <uid>`.

### Sample datasets over REST

Verified on REST module `0.0.23-beta` `[observed]` (2026-11-03); SKILL.md (*Data Sources &
Datasets*) notes dataset writes failing on `0.0.25-beta`, so check the module version first
(`GET /modules/`).

1. `POST /data-sources/<content2>/` with **no body** answers `201` with the new dataset's `gid`.
2. `GET …/<gid>/form/<field>[/<LANG>]` gives the FormEditorDTO; set `.content`, `PATCH` it back.
   An empty field's GET shows no value shape, so copy one from a filled field elsewhere:
   - `CMS_INPUT_DATE`: `"2026-11-05T00:00:00Z"`
   - `CMS_INPUT_DOM`: `"<p>…</p>"`
   - `CMS_INPUT_LINK`: `{"language","text","template":"external_link","form":{"editors":[…lt_link, lt_text…]}}`,
     taken from a filled link field (for example a section's) and changed with `jq`.
3. Read every field back with a separate GET; a `200` on the PATCH is not proof.

### What `create` refuses, and what it leaves behind

It validates the schema, a free template uid, a free data-source uid, every column type and every
mapped column before it creates anything. It also refuses a mapped column that an *existing* table
lacks: add columns to an existing table with `extend` (below). If a mapped field turns out not
to be in the GOM, or the server rejects the GOM, it deletes the new template again. **A schema or
table it already created stays**, and the error names it. Fix the files and run `create` again
with `--schema <s>`.

## Existing table templates

```bash
$T/fs-table list                       # every table template: uid, entity type, sizes
$T/fs-table pull <uid>                 # export, writes meta.json + mappings.txt
$T/fs-table diff <uid>                 # server vs files
$T/fs-table push <uid> [--dry-run]     # upload the changed GOM / rules / channel / snippet
$T/fs-table snippet <uid> [--server]   # evaluate the snippet on real datasets
$T/fs-table extend <uid> [--dry-run]   # add fields: new columns + GOM + all mappings
$T/fs-table content2 <uid> --name "…"  # add the data source a template lacks
```

`push` sends the hash of the source it last pulled. The server refuses the write if someone changed
the template in SiteArchitect meanwhile (`--force` overrides). The replaced source goes to
`backup/auto/`. Every push and create is gated by `fs-lint` (XML well-formedness, expression
quoting). **`push` does not send mappings**; use `extend` for that.

### Adding a field to an existing template: `extend`

1. `pull <uid>` first, so `meta.json` holds the current hashes.
2. Edit the files in `cms/templates/table-templates/<schema>/<uid>/`: the new editor in
   `<uid>.gom.xml`, the new column in `<uid>.columns.txt`, the new `field=column` line in
   `<uid>.mappings.txt`.
3. `extend <uid>`. It refuses if the form or mappings changed on the server since the pull
   (`--force` overrides). It **adds** missing columns (it never changes or drops existing ones),
   uploads the GOM, then re-maps **every** field from `<uid>.mappings.txt`. So that file must list all
   fields, not just the new one; a field missing from it ends up unmapped and is reported.
4. The previous GOM goes to `backup/auto/`; the template is pulled again. Verify with `fields` and
   `diff`.

The GOM is saved and checked **before** any column is created: if the server rejects it, or a
mapped field is not in it, the GOM is reverted and the table is untouched. Columns cannot be dropped
again from a script, so only a server error in the last step (saving the mappings, after every
target column was checked) can leave new, unused columns behind; the error names them and the GOM
and mappings are restored. Changing or dropping a column is a SiteArchitect step.

Changes reach the live site only after the project is regenerated and deployed.

## Removing a table

There is deliberately no delete action. In SiteArchitect, remove in this order: the data source
(content store), the table template, the table (in the schema's model), then the schema if it is
now empty.

## How it works, for debugging

- `/execute` answers with the script's **log output**, not its return value (SKILL.md →
  *Scripts*). The script logs one JSON object (`{"status":"ok",…}` or
  `{"status":"error","message":…}`), and every source travels base64. The log capture holds
  about 4000 characters per record.
- The credentials go to curl through a config file with permissions 600 under `tmp/`, never on
  the command line.
- `FS_TEMPLATE_SET_UID` (default `html`) is sent with every call, for projects whose template set
  has another name. `FS_PROJECT_ROOT` and `FS_TABLE_ROOT` move the working locations.
- FirstSpirit adds the system columns itself: `fs_id`, `FS_GID`, `FS_META_DATA`, `changed by`,
  `released by`, `release languages`, `wf id`, `wf col`.
- Requirements: `bash`, `curl`, `jq`, `base64`, `shasum`, `xmllint`.

## Removing the script from a project

The ScriptStore script `rest_table_template` (folder `rest-extension`) can be deleted in
SiteArchitect once a project no longer needs these tools. Table templates, tables and data
sources created with it are ordinary project content and stay.
