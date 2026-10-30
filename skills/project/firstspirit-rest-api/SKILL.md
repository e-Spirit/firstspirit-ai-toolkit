---
name: firstspirit-rest-api
description: >
  FirstSpirit REST API expert for performing CMS operations via curl. Use this skill whenever working with the
  FirstSpirit REST API — creating/editing templates (GOM, Rules, Channel-Sources), managing pages and sections,
  writing form field values (all editor types including FS_CATALOG, FS_REFERENCE, CMS_INPUT_DOM), uploading media,
  searching content, or any other REST API interaction with FirstSpirit. Triggers on: REST API calls to FirstSpirit,
  curl commands against /rest/v1/, template development, page/section management, form field PATCH operations,
  media upload, content search. Also use when the user mentions "FirstSpirit REST API" or asks how to read/write
  content via the API.
metadata:
  source-commit: "1e54562"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit REST API

## Critical Rules (read first — these cause most failures)

1. **PATCH on `/form/{editor}` needs `name` (equal to the editor in the URL), `type` and `content`.** `configuration`, `description` and `language` are ignored on write; FS_REFERENCE content needs only `{"uid":"…","uidType":"…"}` (clear with `{"empty":true}`) `[core]` (REST module `0.0.23-beta` to `0.0.25-beta`; a minimal scalar PATCH verified live on `0.0.25-beta`). Still use **GET → jq → PATCH** for anything structured (FS_CATALOG cards, references, links): the GET response is valid PATCH input and already has the right `content` shape.
2. **Never inline JSON with `-d '…'`**. Apostrophes/quotes in German content break shell parsing. Always write JSON to `./tmp/payload.json` and send with `--data-binary @./tmp/payload.json`.
3. **Language suffix `/{LANG}` is required when `usesLanguages: true`** in the editor's configuration. Codes are **UPPERCASE** (`DE`, `EN`, `FR`). Check via `GET /projects/{id}/languages/`.
4. **Send the documented Content-Type** (see table below). The module never answers `415`: a wrong type on a JSON endpoint ends in `500` (a `text/plain` PATCH to `/form/{editor}` → `500`, verified live on `0.0.23-beta` and `0.0.25-beta`); endpoints with a raw text body and no declared input type (GOM, rules, channel sources) accept any type silently `[core]`.
5. **Parallelize reads and independent writes.** GET of several fields, or PATCH of independent editors on the same section, can run concurrently. Only serialize when one call depends on the previous response.
6. **Every card in an FS_CATALOG needs `id` and `templateUid`; every nested editor needs `name`, `type` and a matching `content`.** `configuration` is not read on write `[core]`. A `null` value on an option editor (RADIOBUTTON / COMBOBOX) inside a card is a `500`; keep the value from GET.

## Setup

Load credentials before any API call and hand them to curl through a config file, never on
the command line (`-u` shows the password in the process list for the duration of every call):
```bash
source .env
# Provides: $FS_USERNAME, $FS_PASSWORD, $FS_REST_BASE_URL, $FS_PROJECT_ID
# In .env, SINGLE-QUOTE any value containing `$` (e.g. FS_PASSWORD='$ecret'): `source`
# expands $… inside double-quoted or bare values, so the password silently becomes
# empty and every call fails with a misleading 401.
FS_CURLRC="$(mktemp)"                      # mode 600, owner only
printf 'user = "%s:%s"\n' "$FS_USERNAME" "$FS_PASSWORD" > "$FS_CURLRC"
mkdir -p ./tmp   # JSON payloads go here; avoids shell-quoting issues
```
Every call below passes `-K "$FS_CURLRC"`; delete the file when the session ends
(`rm -f "$FS_CURLRC"`). A `"` or `\` in the password is escaped as `\"` or `\\` inside the
config file. Add `.env` to your project's `.gitignore` (the smoke test's `results/` and `logs/` too, see below).
The smoke test reads the same `.env` line by line instead of sourcing it (nothing in it is executed): `KEY=VALUE`,
a value in single or double quotes with no escapes inside, or bare up to an inline ` #` comment. A password with
a quote in it goes in the other kind of quotes.

Standard curl pattern (read):
```bash
curl -s -K "$FS_CURLRC" "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/..."
```

Standard curl pattern (write — **always via file**):
```bash
# Write JSON to a file first, then send it
cat > ./tmp/payload.json <<'JSON'
{ ... }
JSON
curl -s -K "$FS_CURLRC" \
  -X PATCH -H "Content-Type: application/json" \
  --data-binary @./tmp/payload.json \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/..."
```
Use `--data-binary` (not `-d`) so newlines in JSON are preserved.

### Verify the skill against your server

Every rule above is a claim about the REST module's behaviour, and the module is still in
beta. `scripts/smoke-test.sh` probes each claim against the project in `.env` and prints
PASS/FAIL per rule (read-only by default; `--write` creates and deletes a throwaway page, page
reference, medium, dataset and section template — use a test project; `--scripts` exercises
`/scripts/…/execute`). It prints the target (host, project id and name, user) before the first
call; `--write` and `--scripts` run only with `--yes` after you have checked that line
(`FS_SMOKE_CONFIRM=<project id>` for unattended runs). Run it once on a new server or after a
REST-module update; report any FAIL with the `results/firstspirit-rest-api/<run>/` folder attached
(one line per run is appended to `logs/firstspirit-rest-api.log`; both sit under `FS_OUT_ROOT`,
else the working directory — add `results/`, `logs/` and `.env` to your
project's `.gitignore` when you run it inside a repo). The run
also keeps a snapshot of the server's OpenAPI spec (`results/firstspirit-rest-api/openapi/<host>/` under the shared output root; override with `FS_OPENAPI_SNAPSHOTS`) and prints a
WARN with a diff when the API surface changed since the last run — the cue to re-check the
sections that use the listed paths before trusting them.

## Critical Content-Type Rules

Wrong Content-Type = silent acceptance (raw-text endpoints without a declared input type: GOM, rules, channel sources) **or `500`** (every JSON endpoint — e.g. a `text/plain` PATCH to `/form/{editor}`; the module never answers `415`) `[core]`. Follow these exactly:

| Endpoint | Method | Content-Type (Request) | Body Format |
|----------|--------|----------------------|-------------|
| `/gom` | PUT | `application/xml` | Raw XML: `<CMS_MODULE>...</CMS_MODULE>` |
| `/rules` | PUT | `application/xml` | Raw XML: `<RULES>...</RULES>` |
| `/channel-sources/{ts}` | PUT | `text/plain` | Raw template code (no JSON, no XML wrapper; `application/json` also accepted) |
| `/form/{editor}` | PATCH | `application/json` | FormEditorDTO JSON (pages, sections **and datasets**) |
| `/form/{editor}/{lang}` | PATCH | `application/json` | FormEditorDTO JSON |
| Pages/PageRefs/Media create | POST | `application/json` | Create DTO JSON |
| `/media/{uid}/data` | PUT | `multipart/form-data` | File upload |
| `/media/{uid}/rename` | PATCH | `application/json` | `{"name":"…","language":"XX"}` (RenameRequestDTO — sets display name, **not** uid; `{uid}` → 500) |
| `/{page,page-reference,medium}-folders/**` | PATCH | `application/json` | Folder property DTO |
| `/scripts/{name}/template-sets/{ts}` | PUT | `text/plain` | Raw script code |
| `/scripts/{name}/gom` | PUT | `text/xml` | Script GOM XML |
| `/modules/` | POST | `multipart/form-data` | `.fsm` module upload |
| `/actions` | POST | `application/json` | Action JSON |

## Workflow: Use Case Routing

**Template Development** (create template, edit GOM/Rules/HTML):
Read [references/content-templates.md](references/content-templates.md)

**Content Management** (create pages, edit forms, all editor types):
Read [references/content-management.md](references/content-management.md)

**FS_CATALOG operations** (cards, nested forms — common pain point):
Read [references/content-catalog.md](references/content-catalog.md)

**Search & Discovery** (find elements, check references):
Read [references/search-and-discovery.md](references/search-and-discovery.md)

## Playbook: Duplicate a Page (e.g. event variant)

Standard sequence for copying an existing page, registering it in the SiteStore and patching fields. Steps with *(∥)* may run in parallel.

1. **Copy the source page**
   ```bash
   curl -s -K "$FS_CURLRC" \
     -X POST -H "Content-Type: application/json" \
     -d '{"action":"copy"}' \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{sourceUid}/actions"
   ```
   Response contains the new server-assigned `uid` (e.g. `{sourceUid}_2`). **This uid is fixed** —
   see the note in step 2. Capture it as `{copiedUid}` and use it for the rest of the playbook.

2. **Set the display name of the new page** *(∥ with step 3)*
   ```bash
   curl -s -K "$FS_CURLRC" \
     -X PATCH -H "Content-Type: application/json" \
     -d '{"name":"Example Event","language":"EN"}' \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{copiedUid}/rename"
   ```
   > **`/rename` sets the display name, not the uid** (verified 0.0.23-beta). The body is
   > `RenameRequestDTO {name, language}` — sending `{uid}` returns **500**. It writes
   > `displayNames` (observed: applied to *all* languages regardless of the `language` value);
   > the element's uid is unchanged. **A page's uid cannot be changed over REST in this version** —
   > it is fixed when the element is created (`copy` here, or `POST /pages/ {uid,…}`). If you need
   > a specific uid, skip `copy` and create the page directly with your chosen uid.

3. **Create PageReference in the SiteStore** *(∥ with step 2 — uses numeric page id, not the uid)*
   ```bash
   PAGE_ID=$(curl -s -K "$FS_CURLRC" \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{copiedUid}" | jq '.id')
   curl -s -K "$FS_CURLRC" \
     -X POST -H "Content-Type: application/json" \
     -d "{\"uid\":\"{copiedUid}\",\"pageId\":$PAGE_ID,\"location\":\"/events/\"}" \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/"
   ```

4. **GET all fields to mutate, in parallel**. Write each GET response to `./tmp/<editor>.json`.
5. **Mutate each file with `jq`** (change only `content`, never rebuild `configuration`).
6. **PATCH all fields in parallel** using `--data-binary @./tmp/<editor>.json`.
7. **Release** (optional): POST `{"action":"release", …}` to the page's `/actions` endpoint.

Key efficiency rules for this flow:
- Do **not** explore field structure by reading one field at a time — fetch the whole section form via `GET …/sections/{section}/form` once, then address fields by name.
- Use `search/by-uid` once up front to discover media UIDs you will reference (e.g. `hero_image`) instead of guessing.
- Keep the mutation list flat: one file per editor, one PATCH per editor, dispatched concurrently.

## Endpoint Quick Reference

> **API path is `/rest/v1`.** The OpenAPI spec is published at `/rest/v3/api-docs`
> (Swagger UI: `/rest/swagger-ui/index.html`), but `v3` is only the springdoc group
> name — every endpoint is still served under `/rest/v1/…`. Keep `FS_REST_BASE_URL`
> pointing at `…/rest/v1`.

### Server / Projects
```
GET    /projects/                                     # list projects
POST   /projects/                                     # create project (JSON)
GET|DELETE /projects/{id}
GET    /projects/{id}/languages/    GET /projects/{id}/languages/{abbr}
GET    /projects/{id}/template-sets/  GET /projects/{id}/template-sets/{abbr}
GET    /projects/{id}/settings
GET    /projects/{id}/resolutions
GET    /modules/                                      # list installed modules
POST   /modules/                                      # install module (multipart/form-data, .fsm)
GET|DELETE /modules/{moduleName}
```

### Templates (Section, Page, Format, Link)
```
GET    /projects/{id}/templates/{type}-templates/
POST   /projects/{id}/templates/{type}-templates/
GET    /projects/{id}/templates/{type}-templates/{uid}
DELETE /projects/{id}/templates/{type}-templates/{uid}
GET|PUT /projects/{id}/templates/{type}-templates/{uid}/gom          # XML (JSON also accepted)
GET    /projects/{id}/templates/{type}-templates/{uid}/gom/form      # JSON (read-only)
GET|PUT /projects/{id}/templates/{type}-templates/{uid}/rules        # XML (JSON also accepted)
GET    /projects/{id}/templates/{type}-templates/{uid}/channel-sources/
GET|PUT /projects/{id}/templates/{type}-templates/{uid}/channel-sources/{templateSetUid}  # text/plain
GET    /projects/{id}/templates/schemas/              # list DB schemas (read-only)
GET    /projects/{id}/templates/schemas/{schemaUid}
GET|POST /projects/{id}/templates/page-templates/{uid}/bodies/            # ≥ 0.0.25-beta: content areas of an existing page template
PUT|DELETE /projects/{id}/templates/page-templates/{uid}/bodies/{bodyName} # ≥ 0.0.25-beta: rename / re-whitelist / remove
```

Note: Format templates have no GOM or Rules endpoints. Link/Page/Section templates have all of GOM, Rules and channel-sources.
Before `0.0.25-beta` a page template's content areas are fixed at creation (`bodies` in the POST);
see [content-templates.md](references/content-templates.md) for the whitelist semantics.

### Pages

> **Version drift — sections are addressed by numeric id from `0.0.24-beta`** `[core]`. Up to
> `0.0.23-beta` (the version this skill was verified against live) `{section}` is the section
> **name** and a section is created with `PUT …/sections/{name}`. From `0.0.24-beta` the path
> variable is the section's numeric `id` (from `GET …/bodies/{body}` or the create response),
> because names are not unique within a body, and creation is `POST …/sections/` with
> `{"name","templateUid","index"?}` (`index` 0-based, omitted or out of range appends). The
> OpenAPI document carries no module version; check the installed REST module's version
> (`GET /modules/`, or the ServerManager) before choosing the form, or probe: a `0.0.24-beta`
> or newer document has no `PUT …/sections/{name}` operation (confirmed on the `0.0.25-beta`
> document, 2026-10-06; the id-based writes themselves are not yet probed live). Both forms are
> shown below.

```
GET|POST /projects/{id}/pages/
GET|DELETE /projects/{id}/pages/{uid}
GET    /projects/{id}/pages/{uid}?released=true
POST   /projects/{id}/pages/{uid}/actions
PATCH  /projects/{id}/pages/{uid}/rename                 # JSON: {"name","language"} (display name, not uid)
GET    /projects/{id}/pages/{uid}/bodies/
GET    /projects/{id}/pages/{uid}/bodies/{body}
PUT    /projects/{id}/pages/{uid}/bodies/{body}/sections/{name}      # ≤ 0.0.23-beta: JSON {"templateUid"}; name from the URL
POST   /projects/{id}/pages/{uid}/bodies/{body}/sections/           # ≥ 0.0.24-beta: JSON {"name","templateUid","index"?} → SectionDTO with "id"
DELETE /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}  # {section} = name ≤ 0.0.23, numeric id ≥ 0.0.24
GET    /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/form   # editor list only (FormSummaryDTO, no content)
GET|PATCH /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/form/{editor}
GET|PATCH /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/form/{editor}/{lang}
PATCH  /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/rename  # JSON: {"name":"newName"} (RenameSectionRequestDTO — name only, no language)
GET    /projects/{id}/pages/{uid}/form
GET|PATCH /projects/{id}/pages/{uid}/form/{editor}
GET|PATCH /projects/{id}/pages/{uid}/form/{editor}/{lang}
GET    /projects/{id}/pages/{uid}/metadata
GET|PATCH /projects/{id}/pages/{uid}/metadata/{editor}
GET|PATCH /projects/{id}/pages/{uid}/metadata/{editor}/{lang}   # language-specific metadata
GET    /projects/{id}/pages/{uid}/usages
GET    /projects/{id}/pages/{uid}/revisions/    GET .../revisions/{revisionId}   # metadata only (id, creationTime, comment, editor); no content read-back
```

### Page References (SiteStore)
```
GET|POST /projects/{id}/page-references/
GET|DELETE /projects/{id}/page-references/{uid}
POST   /projects/{id}/page-references/{uid}/actions
PATCH  /projects/{id}/page-references/{uid}/rename        # JSON: {"name","language"} (display name, not uid)
GET|PATCH /projects/{id}/page-references/{uid}/settings
GET    /projects/{id}/page-references/{uid}/revisions/   GET .../revisions/{revisionId}
GET|POST /projects/{id}/page-references/document-groups/
DELETE /projects/{id}/page-references/document-groups/{uid}
```

### Media
```
GET    /projects/{id}/media/?type=FILE|PICTURE        # enumerate MediaStore (200; JSON array w/ location). Since 0.0.23-beta — was 405
POST   /projects/{id}/media/                          # JSON create
GET|DELETE /projects/{id}/media/{uid}
GET|PUT /projects/{id}/media/{uid}/data                # GET=binary, PUT=multipart
GET|PUT /projects/{id}/media/{uid}/data/{lang}
GET    /projects/{id}/media/{uid}/resolutions            # list picture resolutions + dimensions
GET    /projects/{id}/media/{uid}/resolutions/{lang}
GET    /projects/{id}/media/{uid}/data/resolution/{resUid}       # binary at a resolution
GET    /projects/{id}/media/{uid}/data/resolution/{resUid}/{lang}
PATCH  /projects/{id}/media/{uid}/rename                # JSON: {"name","language"} (display name, not uid)
POST   /projects/{id}/media/{uid}/actions
GET    /projects/{id}/media/{uid}/usages
GET    /projects/{id}/media/{uid}/revisions/    GET .../revisions/{revisionId}
```

Media limits seen in `0.0.25-beta` `[observed]` (2026-10-14, one server):
- The `0.0.25-beta` OpenAPI document offers `GET` and `PATCH` on `medium-folders` and no create operation, and no operation that moves a medium into a folder. Where the folder matters, encode it in the uid (for example `<prefix>_<folder>_<stem>`) and reference by uid.
- Create with `POST /media/` (type `FILE` or `PICTURE`), then `PUT /media/{uid}/data` as multipart. SVG must be created as `FILE`, not `PICTURE`.
- `parseFile` (the "Parse file" switch on a CSS file) is readable on `GET` but a `POST` ignores it and a `PATCH` answers `405`; the `actions` endpoint documents `copy` and `release` only. Set it in the client: CSS that needs `$CMS_REF(media:"uid")$` for its assets is uploaded over REST and parsed in the client.

### Data Sources & Datasets
> **Dataset writes did not work on `0.0.25-beta`** (verified 2026-10-07). Creating a dataset answered
> `500 ValidationError` on every data source tried; treat the create / edit / delete operations below as the
> documented surface, not as verified behaviour, and read datasets only; re-test on a newer module.
> **Changed in this API version.** Datasets are now addressed **directly under the
> data-source** — the old `/datasets/` path segment is gone (returns 404). Dataset
> field editing has moved from `PATCH …/{gid}/entity` to the **form editor pattern**
> (`/form/{editor}`), identical to pages/sections. `/entity` is now **read-only**.
```
GET|POST /projects/{id}/data-sources/                        # list / create data-source
GET    /projects/{id}/data-sources/{ds}                      # data-source metadata
GET|POST /projects/{id}/data-sources/{ds}/                   # list / create datasets (note trailing slash)
GET|DELETE /projects/{id}/data-sources/{ds}/{gid}            # a single dataset (by GID)
GET    /projects/{id}/data-sources/{ds}/{gid}/entity         # read entity (READ-ONLY now)
GET    /projects/{id}/data-sources/{ds}/{gid}/form           # all editors of the dataset
GET|PATCH /projects/{id}/data-sources/{ds}/{gid}/form/{editor}         # FormEditorDTO (write here)
GET|PATCH /projects/{id}/data-sources/{ds}/{gid}/form/{editor}/{lang}  # language-specific
GET    /projects/{id}/data-sources/{ds}/{gid}/revisions/    GET .../revisions/{revisionId}
```
Write dataset fields with the same GET → jq → PATCH FormEditorDTO flow used for
page/section editors (see Critical Rule #1), **not** by PATCHing `/entity`.

### Search
```
GET    /projects/{id}/search?q={query}&page=0&size=20
GET    /projects/{id}/search/by-id/{elementId}
GET    /projects/{id}/search/by-uid?uid={uid}&type={uidType}
GET    /projects/{id}/search/invalid-references?page=0&size=20
GET    /projects/{id}/search/external-references?page=0&size=20
```

### Scripts
```
GET|POST /projects/{id}/scripts/
GET|DELETE /projects/{id}/scripts/{name}
GET|PUT /projects/{id}/scripts/{name}/gom              # XML
GET|PUT /projects/{id}/scripts/{name}/template-sets/{ts}  # text/plain
POST   /projects/{id}/scripts/{name}/execute           # JSON in
```

> **`POST /scripts/` answers `500`, not `409`, for a name that already exists** — the template
> collections answer 409 on a duplicate, the scripts collection has no conflict handling. Do not
> read the status; read the element back (`GET …/scripts/{name}`) and treat a 2xx as "exists".
> *(Observed 2026-08-07.)*
>
> **`POST /scripts/` does not fully honour the create DTO** (verified 0.0.23-beta): the stored
> element comes back with `type: MENU` regardless of the `type` you send, and `description` is
> dropped (`null`), and `location` is ignored too: the script lands in `/` whether you send an
> existing folder or a new one (re-tested 0.0.25-beta, 2026-10-12; the create DTO has only `name`
> in the module's OpenAPI). Only `name` is applied. Create the script, then set the source via
> `PUT …/template-sets/{ts}`.
>
> **`POST …/scripts/{name}/execute` runs the script but does not echo its return value** — the
> `2xx` body is the script's **log records** concatenated, without separator; a script that logs
> nothing answers with an **empty body** `[observed]` (5.2.261116 / 0.0.25-beta, 2026-10-09). An
> uncaught exception, including a BeanShell parse error, answers **500** with a JSON error body.
> So read the status, not the body length, and verify success by read-back. JSON in
> the request body binds as script context variables; the REST execute context has no
> `getElement()`, so element-dependent scripts cannot run here.
>
> Do not use `/execute` as a return channel for values: the body carries log records, not a
> result. The same goes for create → upload → execute → delete throwaway
> scripts as a general RPC channel. If a write is not available through REST, say so and use a
> proper script context or an `Executable` (`firstspirit-scripting`), not the execute endpoint.

### Global Content
```
GET    /projects/{id}/global-content/
GET    /projects/{id}/global-content/project-properties
PATCH  /projects/{id}/global-content/project-properties/form/{editor}
```

Added in `0.0.24-beta` `[core]` — GCA pages get the same body/section/form model as pages, sections
by numeric id. Create, write and fill verified live: `POST` with `{"uid","templateUid"}`, then `PATCH`
on `/form/{editor}` for text, `FS_REFERENCE` (`uidType` `MEDIASTORE_LEAF`) and `FS_CATALOG` `[observed]`
(REST module `0.0.25-beta`, 2026-10-14). The page template for a GCA page must exist first, with the form
fields the template defines. The endpoint list below has no whole-form `GET` for a GCA page; read one
editor at a time. How a template reads the content is the template language, not REST:
see `firstspirit-templating-reference`.

```
POST   /projects/{id}/global-content/                                  # create GCA page
GET|DELETE /projects/{id}/global-content/{gcaUid}
GET    /projects/{id}/global-content/{gcaUid}/bodies/     GET .../bodies/{body}
POST   /projects/{id}/global-content/{gcaUid}/bodies/{body}/sections/  # {"name","templateUid","index"?}
DELETE /projects/{id}/global-content/{gcaUid}/bodies/{body}/sections/{sectionId}
GET|PATCH /projects/{id}/global-content/{gcaUid}/form/{editor}[/{lang}]
GET|PATCH /projects/{id}/global-content/{gcaUid}/bodies/{body}/sections/{sectionId}/form/{editor}[/{lang}]
```

### Folders
```
GET|PATCH /projects/{id}/page-folders/**
GET|PATCH /projects/{id}/page-reference-folders/**
GET|PATCH /projects/{id}/medium-folders/**
```
PATCH (JSON) now supported to edit folder properties (e.g. metadata). `**` is the
folder path within the store.

## Pagination

> **As of `0.0.23-beta`, collection *listing* endpoints return a bare JSON array — parse with
> `.[]`, not `.content[]`.** Verified against the live OpenAPI spec and server: *every* endpoint
> ending in `/` (`/pages/`, `/media/`, `/scripts/`, `/data-sources/`, `/page-references/`,
> `/languages/`, `/template-sets/`, all `/templates/…/`, …) responds with a top-level array, and
> `?page`/`size` query params are **accepted but ignored** (`GET /pages/?size=5` returned all
> 110). Do not rely on server-side paging for listings; fetch the array and slice client-side.

```bash
# Any listing → plain JSON array
curl -s ... "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/" | jq '.[].uid'
```

> **`GET …/search` is the exception — it *does* return `PaginatedResponseDTO`** and honours
> `?page`/`size`: `{ "content": [...], "pageNumber": 0, "pageSize": 20, "hasNext": true }`
> (zero-based). See [search-and-discovery.md](references/search-and-discovery.md). To be safe
> against either shape, branch on `if type=="array" then .[] else .content[] end`.

## Actions Pattern

Copy or release a **page, page reference or medium** (the OpenAPI document has `…/actions` for
exactly these three). **Nothing in the TemplateStore can be released** (templates, scripts, schemas): there is no `actions` resource for templates
(`POST …/templates/page-templates/{uid}/actions` → `404` `[observed]`), and in SiteArchitect and
ContentCreator they cannot be released either `[observed]`. Template store content moves between projects by Template
Transport, Content Transport or Git, not by release.
```bash
curl -s -K "$FS_CURLRC" \
  -X POST -H "Content-Type: application/json" \
  -d '{"action":"release","options":{"checkOnly":false,"dependentReleaseType":"NO_DEPENDENT_RELEASE","ensureAccessibility":false,"recursive":false}}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{uid}/actions"
```

Actions: `copy`, `release`. Options for release:
- `checkOnly`: dry-run
- `dependentReleaseType`: `NO_DEPENDENT_RELEASE` | `DEPENDENT_RELEASE_NEW_AND_CHANGED`
- `ensureAccessibility`: ensure page is reachable in SiteStore
- `recursive`: include children

## Not available over REST

- **Snippets cannot be created over REST** `[observed]` 2026-10-16. A person creates them in the template store in
  SiteArchitect or in Template Development in ContentCreator; each client has a dedicated step for it. Do not look for an endpoint: write down what
  the snippet should contain (name, template, field values), say that you did not create it, and hand it over.
- Template store content cannot be released (see *Actions Pattern*).

## When a call fails

Read the status code and the response body, name the cause in one sentence, change one thing, and read the result back.
Pasting the error text into the same session is the fastest recovery; do not retry the identical request, and do not change several things at once.

## Error Codes

| Code | Meaning |
|------|---------|
| 400 | Invalid input, unsupported operation (e.g. writing `CMS_INPUT_DOMTABLE`), unreadable JSON body |
| 403 | FirstSpirit denied access to the element (permissions of the authenticated user) `[core]` |
| 404 | Element/language/template not found |
| 409 | Conflict: duplicate name or reference name, element locked by another session, element moved `[core]` |
| 410 | Element was deleted `[core]` |
| 413 | Upload too large `[core]` |
| 429 | Too many requests — the server is throttling the client; wait and retry `[core]` |
| 500 | Server error — also for: wrong Content-Type on any JSON endpoint (never `415`) `[core]`; `{uid}` sent to a `/rename` (wants `{name,language}`); a `name` in the body that differs from the editor in the URL (page forms); `null` RADIOBUTTON / COMBOBOX in a constructed card `[core]` |

Codes marked `[core]` are the status codes of REST module `0.0.25-beta`; the smoke test has
not provoked them all.

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
