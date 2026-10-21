# Content Management via REST API

## Table of Contents
- [Pages](#pages)
- [Sections](#sections)
- [Form Editing — All Editor Types](#form-editing)
- [Page References (SiteStore)](#page-references)
- [Media](#media)
- [Data Sources & Datasets](#data-sources)
- [Release Workflow](#release-workflow)

---

## Pages

### Create Page
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"homepage","templateUid":"standard_page"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/"
```
Response includes `id` (numeric) — needed for creating PageReferences.

### Read Page
```bash
# Current (working copy)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage"

# Released version
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage?released=true"
```

### Rename Page
Body is `RenameRequestDTO {name, language}` (both required; `{uid}` → 500). This sets the
**display name** (`displayNames`), **not the uid** — a page's uid cannot be changed over REST in
0.0.23-beta, it is fixed at creation. Observed: the name is applied to *all* languages regardless
of the `language` value.
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d '{"name":"Homepage","language":"DE"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/rename"
```

### Delete Page
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" -X DELETE \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage"
```

---

## Sections

### List Bodies
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/"
```

### Add Section to Body

**Up to `0.0.23-beta`** (verified live) the section name is the last path segment:
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/json" \
  -d '{"templateUid":"hero_teaser"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero"
```
The `{sectionName}` in the URL (`hero`) becomes the section's name.

**From `0.0.24-beta`** `[core]` sections are created with POST and addressed by their numeric
`id`, because a body may hold several sections of the same name:
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"name":"hero","templateUid":"hero_teaser","index":0}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/"
# → SectionDTO; keep .id for every later call on this section
```
`index` is 0-based; omit it or pass an out-of-range value to append. Creation and positioning
are not atomic: if positioning fails the section stays appended. Do not retry blindly — read the
body (`GET …/bodies/content`) and delete the stray section by id. Section ids are also in the
body's section list, so an existing section is found by listing the body, not by guessing.

### Delete Section
```bash
# ≤ 0.0.23-beta: by name        ≥ 0.0.24-beta: by numeric id (e.g. …/sections/4711)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" -X DELETE \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero"
```
- **Never rebuild a page blind.** Deleting every section and re-creating them from a source
  overwrites what editors changed in the client since the last import; the delete is a new
  revision, not a loss, but `GET …/revisions/{id}` returns metadata only (`id`, `creationTime`,
  `comment`, `editor`), so an older state cannot be read back over REST and merged `[observed]`
  (2026-10-09). Read the page first, say what would be overwritten, and replace single sections
  by id instead of the whole set.
- After deleting a page, section or other element, tell the user to reload the store in the open
  client; a client that still has the element open works on stale state.

### Rename Section
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d '{"name":"new_name"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero/rename"
```
Same `{section}` rule: name up to `0.0.23-beta`, numeric id from `0.0.24-beta`. The examples
below keep the name form; substitute the id on newer servers.

---

## Form Editing

### Read Form (overview of all editors)
```bash
# Page-level form
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/form"

# Section form
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero/form"
```
The whole-form response is an object wrapping the editor list: `{ "editors": [ … ] }`.
List editor names with `jq -r '.editors[].name'` (not `.[].name`). Individual
`GET …/form/{editor}` responses are a flat FormEditorDTO (`name`, `type`,
`configuration`, `content`, `description`, `language`).

Use the whole-form GET for the **editor list only**: the page and section `…/form` endpoints
return a summary (`FormSummaryDTO` in the OpenAPI document) whose editors carry `name`,
`type` and `description` and **no content field** `[observed]`. Content comes from the per-editor GET. The only
whole-form response *with* content is the `FormDTO` used for FS_CATALOG cards; there a field
that exists in the template but was never stored in this element yields `content: null`
(stale content after a template change) instead of an error.

### Read Single Editor (with content)
```bash
# All languages
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero/form/st_headline"

# Specific language (UPPERCASE abbreviation — check GET /projects/{id}/languages/)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero/form/st_headline/EN"
```

**Language codes are UPPERCASE** (`EN`, `FR`, `DE`). Lowercase codes like `en` return 404. Always verify with `GET /projects/{id}/languages/` first.

### PATCH Pattern (write editor value)

All PATCH bodies are `FormEditorDTO` JSON. Required are `name` (equal to the editor in the URL — a different name is rejected), `type` and `content`; `configuration`, `description` and `language` are ignored on write `[core]` (REST module `0.0.23-beta` to `0.0.25-beta`).

This holds for every editor type:
- **FS_REFERENCE** needs only `{"name","type","content":{"uid":"…","uidType":"…"}}`; **FS_CATALOG** needs `id` + `templateUid` per card and `name` + `type` + `content` per nested editor (see [content-catalog.md](content-catalog.md)). `configuration` is never required.
- A **plain scalar editor** (`CMS_INPUT_TEXT`/`TEXTAREA`) accepts a minimal `{name,type,content}` PATCH (`200`, verified live on `0.0.23-beta` and `0.0.25-beta`).

GET → mutate → PATCH stays the reliable pattern because the GET response already has the `content` shape right; a minimal payload is correct, not safer.

**Reliable pattern — GET → mutate → PATCH:**
```bash
# 1. Read the current DTO (includes all required fields)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/{editor}/DE" \
  > ./tmp/{editor}.json

# 2. Mutate only content (keep configuration, description, language untouched)
jq '.content = "Neuer Titel"' ./tmp/{editor}.json > ./tmp/{editor}.patched.json

# 3. Send the whole DTO back via file (never via -d '...')
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  --data-binary @./tmp/{editor}.patched.json \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/{editor}/DE"
```

**Never use `-d '…'` for JSON containing German content.** Apostrophes in values like `Mehr erfahren` or quotes in text break shell parsing. Write to a file and use `--data-binary @file.json`.

For language-specific editors: append `/{lang}` to URL (UPPERCASE: `DE`, `EN`).

**A 200 is not proof of a write.** Two traps:
- PATCHing a language path (`…/form/{editor}/DE`) on an editor whose GOM says
  `useLanguages="no"` answered **200 and changed nothing** `[observed]` on an FS_CATALOG. Check
  the GOM before choosing the language-scoped URL.
- A GET straight after a write may show the server's in-memory state rather than what was
  persisted. Confirm important writes with a second,
  fresh read (new request, a moment later) or in ContentCreator.

**Parallelize** independent GETs and independent PATCHes on the same section. Only serialize when one call depends on another's output.

### Editor Type Reference

#### CMS_INPUT_TEXT / CMS_INPUT_TEXTAREA
```json
{
  "name": "st_headline",
  "type": "CMS_INPUT_TEXT",
  "content": "Welcome to our website"
}
```

#### CMS_INPUT_NUMBER
```json
{
  "name": "st_count",
  "type": "CMS_INPUT_NUMBER",
  "content": 42
}
```

#### CMS_INPUT_TOGGLE
```json
{
  "name": "st_active",
  "type": "CMS_INPUT_TOGGLE",
  "content": true
}
```

#### CMS_INPUT_DATE
ISO 8601 instant format:
```json
{
  "name": "st_date",
  "type": "CMS_INPUT_DATE",
  "content": "2025-12-25T00:00:00Z"
}
```

#### CMS_INPUT_DOM (Rich Text)
Content is an HTML/text string:
```json
{
  "name": "st_richtext",
  "type": "CMS_INPUT_DOM",
  "content": "<p>This is <b>formatted</b> text.</p>"
}
```
- A PATCH whose content contains **inline links** answered `500` `[observed]`; the cause
  is not isolated (link markup, or the link's reference attributes). Read the field back
  from an element that already holds such a link and send that shape, or leave the link to
  an editor.
- **Lists: write `<p><ul style="N" [start="M"]>…</ul></p>`, not a bare `<ul>` and never `<ol>`**
  `[observed]` (REST `0.0.25-beta`, FS 5.2.261116, repeated tests 2026-10-09 to 2026-10-12). The
  clients store a list as `<ul data-list-attributes="…" style="list-style-type:…;">` where
  `data-list-attributes` carries URL-encoded `name=value` pairs joined by `:|:` (for example
  `start%3D4%3A%7C%3Astyle%3D2`), and `style` is the list type: `1` bullet, `2` numbered, `3` to
  `6` alphabetical and Roman, `0`, `7`, `8` paragraph, indent only and user-defined (the
  templating skill's `#list.style`). The server converts HTML attributes of a `<ul>` into those
  list properties **only when the `<ul>` sits inside a `<p>`**; a `<ul>` outside a `<p>` is stored
  plain with its attributes dropped; both clients then show a bullet list, and when an editor
  changes its type, saving the section in ContentCreator resets it to the default again (also for
  SiteArchitect). So write bullet lists as `<p><ul style="1">` too. `style="list-style-type:decimal"`
  does **not** set the type; `<p><ul>` without attributes is stored with `data-list-attributes=""`.
  The smoke test probes both forms (W26, W27). A sent `<ol>` is kept as `<ol>` but is not
  a FirstSpirit list: ContentCreator shows it as inline formatting and format templates get an
  empty `#list.style`.
- **A DOM field is not round-trip safe when it holds lists with properties** `[observed]`
  (2026-10-12). GET followed by PATCH of the same content makes the server read the stored
  `data-list-attributes` and `style` attributes as list properties again and nest them
  (`data-list-attributes%3D…`, `style=list-style-type:decimal;`), and the stored list properties no
  longer match what you sent. Rebuild the field from your source in the
  `<p><ul style="N">` form instead of echoing what you read; do not diff on the stored attributes.
- ContentCreator rendering of REST-written DOM `[observed]` (2026-10-12): a `<p>` inside an
  `<li>` draws a frame per item, so write `<li>text</li>`; a `<br/>` after a list becomes an empty
  paragraph; a list inside a `<p>` is one framed block with its type in the list properties; the
  `start` value shows in the list properties and the preview, in the ContentCreator form only
  after reopening (SiteArchitect shows it in the form at once).

#### CMS_INPUT_COMBOBOX (single-select)
```json
{
  "name": "st_color",
  "type": "CMS_INPUT_COMBOBOX",
  "content": {"key": "red", "value": "red"}
}
```

#### CMS_INPUT_RADIOBUTTON (single-select)
```json
{
  "name": "st_layout",
  "type": "CMS_INPUT_RADIOBUTTON",
  "content": {"key": "left", "value": "left"}
}
```

#### CMS_INPUT_CHECKBOX (multi-select)
Content is an **array** of options:
```json
{
  "name": "st_tags",
  "type": "CMS_INPUT_CHECKBOX",
  "content": [
    {"key": "featured", "value": "featured"},
    {"key": "new", "value": "new"}
  ]
}
```

#### CMS_INPUT_LIST (multi-select)
```json
{
  "name": "st_categories",
  "type": "CMS_INPUT_LIST",
  "content": [
    {"key": "news", "value": "news"},
    {"key": "blog", "value": "blog"}
  ]
}
```

#### FS_REFERENCE
Content is a `TargetReferenceDTO`:
```json
{
  "name": "st_image",
  "type": "FS_REFERENCE",
  "content": {
    "uid": "logo",
    "uidType": "MEDIASTORE",
    "empty": false
  }
}
```

For a reference that points at one medium (a picture or file) use `MEDIASTORE_LEAF`; `MEDIASTORE` answered `400` there `[observed]` (`0.0.25-beta`, 2026-10-14). Valid `uidType` values: `PAGESTORE`, `SITESTORE`, `MEDIASTORE`, `MEDIASTORE_LEAF`, `TEMPLATESTORE`, `GLOBALSTORE`, `CONTENTSTORE`.

To clear a reference:
```json
{
  "name": "st_image",
  "type": "FS_REFERENCE",
  "content": {
    "empty": true
  }
}
```

#### FS_CATALOG
See [references/content-catalog.md](content-catalog.md) for full documentation.

#### FS_DATASET
```json
{
  "name": "st_product",
  "type": "FS_DATASET",
  "content": {
    "templateUid": "products",
    "language": {"abbreviation": "EN", "name": "English", "htmlEncoding": "UTF-8", "masterLanguage": true},
    "dataset": {
      "id": 4711,
      "gid": "00000000-0000-4000-8000-000000000001",
      "projectId": 1234,
      "name": "Widget",
      "parentName": "products",
      "released": false,
      "header": "Widget",
      "extract": ""
    },
    "gid": "00000000-0000-4000-8000-000000000002"
  }
}
```

#### FS_INDEX
Content is an array of identifier strings:
```json
{
  "name": "st_index",
  "type": "FS_INDEX",
  "content": [
    "{\"schema\":\"MySchema\",\"gid\":\"\",\"table\":\"MyTable\"}"
  ]
}
```

#### CMS_INPUT_LINK
```json
{
  "name": "st_link",
  "type": "CMS_INPUT_LINK",
  "content": {
    "language": "EN",
    "text": "Read more",
    "form": {
      "editors": [
        {"name": "lt_text", "type": "CMS_INPUT_TEXT", "content": "Read more"}
      ]
    }
  }
}
```

#### CMS_INPUT_DOMTABLE
**Not supported for writing via REST API.** Read-only — returns XML table string.

---

## Page References

PageReferences live in the SiteStore and connect Pages to the URL structure.

### Create PageReference
```bash
# First get the page ID from the create-page response or from search
PAGE_ID=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage" | jq '.id')

curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d "{\"uid\":\"homepage\",\"pageId\":$PAGE_ID,\"location\":\"/\"}" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/"
```
`location` is the folder path in the SiteStore (e.g., `/` for root, `/products/` for subfolder).

### Page Reference Settings (filename, sitemap)
`…/settings` is a `PageReferenceSettingsDTO` with exactly two fields — `filename` (output
filename) and `showInSitemap`. GET it, change a field, PATCH the whole object back:
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/homepage/settings" > ./tmp/settings.json
jq '.showInSitemap = false' ./tmp/settings.json > ./tmp/settings.patch.json
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  --data-binary @./tmp/settings.patch.json \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/homepage/settings"
```
There is **no `startNode` field** here or anywhere else in the REST API (0.0.23-beta OpenAPI
spec, verified 2026-09-14; smoke-test W11) — the start node of a site folder cannot be set over
REST. Use SiteArchitect or the Access API (`SiteStoreFolder.setStartNode(StartNode)` — a
`PageRef` is a `StartNode`).

### Document Groups
```bash
# Create
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"doc_group"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/document-groups/"

# List
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/document-groups/"
```

---

## Media

> **⚠ Version drift — re-tested live 2026-09-11 (REST `0.0.23-beta`).** Two of the facts below moved
> since they were first observed (2026-08-27):
> - **`GET …/media/` now enumerates the MediaStore** — returns **`200`** with a JSON array
>   (was `405`). `?type=PICTURE` / `?type=FILE` filter it; each element carries a `location`
>   folder path. `OPTIONS …/media/` → `Allow: GET,HEAD,POST,OPTIONS`. So BeanShell enumeration
>   is no longer required.
> - **`…/media/{uid}` now allows `DELETE`** — `OPTIONS` → `Allow: DELETE,GET,HEAD,OPTIONS`.
>   A medium CAN be deleted (was "no delete verb"), so a PICTURE-vs-FILE mistake is now
>   recoverable by delete + recreate rather than being one-shot.
>
> **Still true (re-confirmed 2026-09-11):**
> - A medium's **type is immutable via the element endpoint**: `OPTIONS …/media/{uid}` has **no
>   `PATCH`/`PUT`** in `Allow`, so you cannot change `type` in place. `type` is only a
>   *declaration* — the server does not check it against the bytes.
> - Creating a medium is **two calls**: `POST …/media/` mints an empty element (`Allow` includes
>   `POST`), `PUT …/media/{uid}/data` (multipart part named `file`) fills it
>   (`OPTIONS …/media/{uid}/data` → `Allow: PUT,GET,HEAD,OPTIONS`).
> - **`GET …/medium-folders/{uid}` lists subfolders only** (`children`), not media — but this no
>   longer blocks enumeration, since `GET …/media/` returns every medium with its `location`.
>
> *(Original facts verified live 2026-08-27. Drift and re-confirmation verified via `OPTIONS` Allow headers,
> 2026-09-11, REST `0.0.23-beta`.)*

### Create Medium
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"hero_image","filename":"hero","type":"PICTURE"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/"
```

Types: `PICTURE`, `FILE`, `ANIMATION`

> **`PICTURE` means "FirstSpirit will process this", not "this is an image".** WebP and SVG
> uploaded as `PICTURE` are accepted (201 on create, 2xx on upload), `$CMS_REF(media:…)$` renders a
> URL, and the served `…/ORIGINAL/<name>` is a **broken image** — the server cannot decode them
> for resolutions. Nothing on the write path reports it. Upload WebP and SVG as `FILE` (no
> resolutions, served as-is), and keep `PICTURE` for JPEG, PNG and GIF. Since the type cannot be
> changed in place (see the version-drift note above), decide it from the bytes before the POST.
> *(Observed 2026-08-08 on one project, 56 media.)*

### Upload File Data
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -F "file=@/path/to/image.jpg" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/hero_image/data"
```

Language-specific upload: append `/{lang}` (e.g., `/DE`).

### Download File Data
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -o image.jpg \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/hero_image/data"
```

### Get with Resolution
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -o thumb.jpg \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/hero_image/data/resolution/thumbnail"
```

### List Resolutions
Which renditions exist for a picture, with pixel size and whether the file is stored or
computed on demand (`ORIGINAL` is always present). Append `/{LANG}` for language-dependent
media.
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/hero_image/resolutions" \
  | jq -r '.[] | "\(.uid)\t\(.width)x\(.height)\t\(.mimeType)\tstored=\(.stored)"'
```
*(Observed 2026-09-14, REST 0.0.23-beta; smoke-test W15b.)*

---

## Data Sources

### Create Data Source
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"products","schemaUid":"product_schema","tableTemplateUid":"product_table"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/"
```

> **Path change (current API version):** datasets are addressed **directly under the
> data-source** — the `/datasets/` segment has been removed (it now returns 404).
> Dataset **field editing moved to the form-editor pattern** (`/form/{editor}`); the
> `/entity` endpoint is **read-only**.

### List / Create Datasets
```bash
# List datasets of a data-source (note trailing slash)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/"

# Create a new (empty) dataset — response contains the new GID
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/"
```
**Did not work on `0.0.25-beta`** (verified 2026-10-07). The empty
dataset is saved on creation, so a table template whose rules require a field on save rejects it:
the `POST` answers `500` with a `ValidationError … MultiFormValidationReport` body that names the
field and the message, and nothing is created. `[observed]` on `0.0.25-beta` on every data source of
the test project. Read datasets; do not build a write flow on this without re-testing on your module version.

### Read Entity (read-only)
```bash
# Flat view of all field values for one dataset
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/{gid}/entity"
```

> **Table templates are not readable over REST** `[observed]`: `GET …/templates/table-templates/`
> answers `404`. To learn a dataset's **database column names**, read its `/entity`. The data
> source *listing* also omitted some data sources `[observed]`, so an absent entry is not proof
> the data source does not exist; address it by uid.

### Write Dataset Fields (form-editor pattern)
Dataset editing works exactly like page/section editors: **GET the editor → mutate
`content` with jq → PATCH** the complete FormEditorDTO. Do **not** PATCH `/entity`.
```bash
# 1. Read the whole form once to discover editor names
#    (response is { "editors": [ … ] } — same shape as page/section forms)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/{gid}/form" \
  | jq -r '.editors[].name'

# 2. GET one editor (add /{LANG} when configuration.usesLanguages is true)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/{gid}/form/title/DE" \
  > ./tmp/title_de.json

# 3. Mutate only content, then PATCH the full DTO back
jq '.content = "Neuer Titel"' ./tmp/title_de.json > ./tmp/title_de.patch.json
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  --data-binary @./tmp/title_de.patch.json \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/{gid}/form/title/DE"
```

---

## Release Workflow

### Release a Page
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"action":"release","options":{"checkOnly":false,"dependentReleaseType":"NO_DEPENDENT_RELEASE","ensureAccessibility":false,"recursive":false}}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/actions"
```

### Release with Dependencies
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"action":"release","options":{"checkOnly":false,"dependentReleaseType":"DEPENDENT_RELEASE_NEW_AND_CHANGED","ensureAccessibility":true,"recursive":true}}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/actions"
```

### Copy a Page
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"action":"copy"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/actions"
```

Actions work on: pages, page-references, media. **Not on anything in the TemplateStore**: templates, scripts and schemas cannot be released
(`POST …/templates/page-templates/{uid}/actions` → `404` `[observed]`; the OpenAPI document lists
`actions` for these three only). See the note in SKILL.md → Actions Pattern.
