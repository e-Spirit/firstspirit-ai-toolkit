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
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/json" \
  -d '{"templateUid":"hero_teaser"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero"
```
The `{sectionName}` in the URL (`hero`) becomes the section's name.

### Delete Section
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" -X DELETE \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero"
```

### Rename Section
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d '{"name":"new_name"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/bodies/content/sections/hero/rename"
```

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

All PATCH bodies are `FormEditorDTO` JSON. **Always send the full DTO** (GET → mutate → PATCH), including `configuration` (non-null), `description`, and for language-dependent editors `language`.

How strictly this is enforced **depends on the editor type** (verified 0.0.23-beta):
- **FS_CATALOG nested editors** and **FS_REFERENCE** genuinely require the full DTO — omitting `configuration` triggers 500 "parameter configuration specified as non-null is null" (see [content-catalog.md](content-catalog.md)).
- A **plain scalar editor** (`CMS_INPUT_TEXT`/`TEXTAREA`) will *accept* a minimal `{name,type,content}` PATCH (returns 200) on this version — the "always fails" rule is softer than it reads.

Because you cannot tell per editor which case applies, the GET → mutate → PATCH round-trip is the one reliable pattern for all of them; don't hand-build minimal payloads.

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

Valid `uidType` values: `PAGESTORE`, `SITESTORE`, `MEDIASTORE`, `TEMPLATESTORE`, `GLOBALSTORE`, `CONTENTSTORE`.

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
      "gid": "ee8d6a8e-bfa4-4df2-bec5-017743fc5783",
      "projectId": 4943,
      "name": "Widget",
      "parentName": "products",
      "released": false,
      "header": "Widget",
      "extract": ""
    },
    "gid": "9eb6b400-152d-4995-a1ec-207020c2f898"
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

### Set as Start Node
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d '{"startNode":true}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/homepage/settings"
```

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
> since the PS migration measurement (2026-08-27):
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
> *(Original facts confirmed live 2026-08-27 — source: PS website-migration tool,
> `knowledge/fs-facts.md` §1–§2. Drift and re-confirmation verified via `OPTIONS` Allow headers,
> 2026-09-11, ROI test instance.)*

### Create Medium
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"hero_image","filename":"hero","type":"PICTURE"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/"
```

Types: `PICTURE`, `FILE`, `ANIMATION`

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

### Read Entity (read-only)
```bash
# Flat view of all field values for one dataset
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/data-sources/products/{gid}/entity"
```

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

Actions work on: pages, page-references, media, templates.
