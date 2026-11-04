# File formats for `fs-table create`

A template directory is named after the template uid, by convention `<schema>.<table>`
(`events.event`). Every file name starts with that uid. A complete example is
`../assets/table-templates/myschema.event/`.

## `<uid>.columns.txt`: the database table

Read only when the table does not exist yet. One `column=type` line each; blank lines and `#`
comments are ignored.

```
title_{LANG}=string 256      # one column per project language: title_DE, title_EN, ...
text_{LANG}=dom
start=date
lat=double
lng=double
```

| Type | Stored as | Note |
|---|---|---|
| `string [size]` | `String` | size in characters, default 256 |
| `dom` | XML | rich text, and every editor whose value is stored as XML |
| `double` | `Double` | |
| `long` | `Long` | |
| `integer` | `Integer` | |
| `boolean` | `Boolean` | |
| `date` | `java.util.Date` | |

- `{LANG}` expands to the project's language abbreviations **as the server spells them**,
  usually upper case (`name_DE`, `name_EN`). Check with `GET /projects/{id}/languages/`.
- Don't add `fs_id`, `FS_GID`, `FS_META_DATA`, `changed by`, `released by`,
  `release languages`, `wf id` or `wf col`: FirstSpirit adds them itself.
- Avoid SQL type names as column names (`long`, `date`, ...): they are not portable across
  databases. Use `lng` rather than `long`.
- On an **existing** table, `create` refuses a mapping to a missing column. Add columns with
  `fs-table extend` (it reads the same file and adds only what is missing). Changing or dropping
  a column is a SiteArchitect step.

## `<uid>.mappings.txt`: which column stores which field

One `field=column` line per form field:

```
tt_title=title_{LANG}        # language dependent: one column per language
tt_start=start               # language independent: the same column for every language
```

A field without a line is created **unmapped**: the editor shows it, the dataset saves, and the
value is never stored. `create` reports such fields as `unmapped`. A mapped field that is
not in the GOM makes `create` delete the new template again.

`pull` writes this file from the server. A mapping that does not follow the
column-per-language pattern cannot be expressed in it, so it appears as a comment.

## `<uid>.gom.xml`: the form

A `<CMS_MODULE>` with one editor per field. Name the fields `tt_*`.
Set `useLanguages="yes"` exactly when the mapping uses `{LANG}`.

| Editor | Column type | Verified here |
|---|---|---|
| `CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA` | `string` | yes (TEXT) |
| `CMS_INPUT_DOM` | `dom` | yes |
| `CMS_INPUT_DATE` | `date` | yes |
| `CMS_INPUT_NUMBER type="double"` | `double` | yes |
| `CMS_INPUT_NUMBER` (integer types) | `long` / `integer` | no |
| `CMS_INPUT_TOGGLE` | `boolean` | no |
| `FS_REFERENCE` (picture, one for all languages) | `dom` | yes `[observed]` 2026-11-04, REST `0.0.23-beta` |
| `CMS_INPUT_LINK`, `CMS_INPUT_IMAGEMAP`, lists, checkboxes | `dom` | no |

Pitfalls the server catches only at create time:

- `CMS_INPUT_DATE mode` takes `DATETIME`, `DATE` or `TIME`. Any other value (for example
  `date_time`) makes the server reject the GOM. `create` then removes the template, but keeps the
  schema and table it had already made.
- Relations to another table (`FS_DATASET`/foreign keys) need a relation in the schema model,
  which `columns.txt` cannot express. Create those in SiteArchitect.

Every GOM goes through `fs-lint` first: well-formed XML, and double-quoted string literals in
expressions.

## `<uid>.html`: output channel

Written to template set `$FS_TEMPLATE_SET_UID` (default `html`). If the table has no detail
page (yet), use the minimum:

```
<CMS_HEADER>
</CMS_HEADER>
```

## `<uid>.snippet.txt`: what editors see for each dataset

Three `key=expression` lines, in this order (the form `pull` writes, so `diff` stays clean):

```
label=if(!tt_title.isEmpty, tt_title, "")
extract=if(!tt_start.isEmpty, tt_start.format("dd.MM.yyyy"), "")
thumbnail=
```

- `label` is the snippet header (Snippet tab: *Label*), `extract` the *Extract*, `thumbnail` the
  *Thumbnail*. A key left out is set to empty.
- An expression that spans lines continues on the next line behind **one** space. Blank lines and
  `#` lines are ignored.
- No file means no snippet; `pull` writes none when all three are empty. A file sends all three,
  so emptying a line clears that part.
- Expression syntax: the toolkit's `firstspirit-templating-reference`, `templates/snippets.md`.
  Verified here on 2026-11-03 (REST module `0.0.23-beta`): `x.isEmpty`, `if(c, a, b)`, `+`, `truncate(…)`,
  `dom.toText(false).trim()`, `date.format("dd.MM.yyyy")`, per-language text fields.
- The server stores what it gets without parsing it. `fs-lint` checks keys, quotes, parentheses
  and field names; `fs-table snippet <uid>` evaluates it on real datasets.

## `<uid>.rules.xml`: rules

Optional. Leave the file out rather than writing an empty `<RULES></RULES>`.

## `meta.json`: written by the tools, never by hand

`pull` and a successful `create` write the template id, uid, schema, entity type and the hashes of
gom, rules, channel, snippet and mappings. A `meta.json` from before snippets were supported has
no snippet hash; `push` then asks for a `pull` first. `push` sends those hashes as its precondition.
