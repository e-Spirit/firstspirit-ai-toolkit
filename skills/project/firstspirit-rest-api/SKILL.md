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
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit REST API

## Critical Rules (read first — these cause most failures)

1. **PATCH on `/form/{editor}` requires the complete FormEditorDTO** — always including `configuration`, `description`, `language` and (for FS_REFERENCE) the full `content` object. Never hand-craft the payload. Use **GET → jq → PATCH**: the GET response is valid PATCH input.
2. **Never inline JSON with `-d '…'`**. Apostrophes/quotes in German content break shell parsing. Always write JSON to `./tmp/payload.json` and send with `--data-binary @./tmp/payload.json`.
3. **Language suffix `/{LANG}` is required when `usesLanguages: true`** in the editor's configuration. Codes are **UPPERCASE** (`DE`, `EN`, `FR`). Check via `GET /projects/{id}/languages/`.
4. **Content-Types are strict** (see table below). Wrong type = 415 or silent failure.
5. **Parallelize reads and independent writes.** GET of several fields, or PATCH of independent editors on the same section, can run concurrently. Only serialize when one call depends on the previous response.
6. **Configuration is required on every nested editor in FS_CATALOG.** Empty `configuration: {}` causes 500. Preserve the configuration from GET.

## Setup

Load credentials before any API call:
```bash
source .env
# Provides: $FS_USERNAME, $FS_PASSWORD, $FS_REST_BASE_URL, $FS_PROJECT_ID
# In .env, SINGLE-QUOTE any value containing `$` (e.g. FS_PASSWORD='$ecret'): `source`
# expands $… inside double-quoted or bare values, so the password silently becomes
# empty and every call fails with a misleading 401.
mkdir -p ./tmp   # JSON payloads go here; avoids shell-quoting issues
```

Standard curl pattern (read):
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/..."
```

Standard curl pattern (write — **always via file**):
```bash
# Write JSON to a file first, then send it
cat > ./tmp/payload.json <<'JSON'
{ ... }
JSON
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  --data-binary @./tmp/payload.json \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/..."
```
Use `--data-binary` (not `-d`) so newlines in JSON are preserved.

## Critical Content-Type Rules

Wrong Content-Type = silent failure or 415 error. Follow these exactly:

| Endpoint | Method | Content-Type (Request) | Body Format |
|----------|--------|----------------------|-------------|
| `/gom` | PUT | `application/xml` | Raw XML: `<CMS_MODULE>...</CMS_MODULE>` |
| `/rules` | PUT | `application/xml` | Raw XML: `<RULES>...</RULES>` |
| `/channel-sources/{ts}` | PUT | `text/plain` | Raw template code (no JSON, no XML wrapper; `application/json` also accepted) |
| `/form/{editor}` | PATCH | `application/json` | FormEditorDTO JSON (pages, sections **and datasets**) |
| `/form/{editor}/{lang}` | PATCH | `application/json` | FormEditorDTO JSON |
| Pages/PageRefs/Media create | POST | `application/json` | Create DTO JSON |
| `/media/{uid}/data` | PUT | `multipart/form-data` | File upload |
| `/media/{uid}/rename` | PATCH | `application/json` | `{"uid":"newUid"}` |
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

## Playbook: Duplicate a Page (e.g. city event variant)

Standard sequence for copying an existing page, registering it in the SiteStore and patching fields. Steps with *(∥)* may run in parallel.

1. **Copy the source page**
   ```bash
   curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
     -X POST -H "Content-Type: application/json" \
     -d '{"action":"copy"}' \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{sourceUid}/actions"
   ```
   Response contains the new `uid` (e.g. `{sourceUid}_2`).

2. **Rename the new page** *(∥ with step 3)*
   ```bash
   curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
     -X PATCH -H "Content-Type: application/json" \
     -d '{"uid":"{newUid}"}' \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{copiedUid}/rename"
   ```

3. **Create PageReference in the SiteStore** *(∥ with step 2 — uses numeric page id, not the uid)*
   ```bash
   PAGE_ID=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{newUid}" | jq '.id')
   curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
     -X POST -H "Content-Type: application/json" \
     -d "{\"uid\":\"{newUid}\",\"pageId\":$PAGE_ID,\"location\":\"/resources/discover/event/\"}" \
     "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-references/"
   ```

4. **GET all fields to mutate, in parallel**. Write each GET response to `./tmp/<editor>.json`.
5. **Mutate each file with `jq`** (change only `content`, never rebuild `configuration`).
6. **PATCH all fields in parallel** using `--data-binary @./tmp/<editor>.json`.
7. **Release** (optional): POST `{"action":"release", …}` to the page's `/actions` endpoint.

Key efficiency rules for this flow:
- Do **not** explore field structure by reading one field at a time — fetch the whole section form via `GET …/sections/{section}/form` once, then address fields by name.
- Use `search/by-uid` once up front to discover media UIDs you will reference (e.g. `skyline_trier`) instead of guessing.
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
```

Note: Format templates have no GOM or Rules endpoints. Link/Page/Section templates have all of GOM, Rules and channel-sources.

### Pages
```
GET|POST /projects/{id}/pages/
GET|DELETE /projects/{id}/pages/{uid}
GET    /projects/{id}/pages/{uid}?released=true
POST   /projects/{id}/pages/{uid}/actions
PATCH  /projects/{id}/pages/{uid}/rename
GET    /projects/{id}/pages/{uid}/bodies/
GET    /projects/{id}/pages/{uid}/bodies/{body}
PUT    /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}
DELETE /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}
GET    /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/form
GET|PATCH /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/form/{editor}
GET|PATCH /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/form/{editor}/{lang}
PATCH  /projects/{id}/pages/{uid}/bodies/{body}/sections/{section}/rename  # JSON: {"uid":"newName"}
GET    /projects/{id}/pages/{uid}/form
GET|PATCH /projects/{id}/pages/{uid}/form/{editor}
GET|PATCH /projects/{id}/pages/{uid}/form/{editor}/{lang}
GET    /projects/{id}/pages/{uid}/metadata
GET|PATCH /projects/{id}/pages/{uid}/metadata/{editor}
GET|PATCH /projects/{id}/pages/{uid}/metadata/{editor}/{lang}   # language-specific metadata
GET    /projects/{id}/pages/{uid}/usages
GET    /projects/{id}/pages/{uid}/revisions/    GET .../revisions/{revisionId}
```

### Page References (SiteStore)
```
GET|POST /projects/{id}/page-references/
GET|DELETE /projects/{id}/page-references/{uid}
POST   /projects/{id}/page-references/{uid}/actions
PATCH  /projects/{id}/page-references/{uid}/rename
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
PATCH  /projects/{id}/media/{uid}/rename                # JSON: {"uid":"newUid"}
POST   /projects/{id}/media/{uid}/actions
GET    /projects/{id}/media/{uid}/usages
GET    /projects/{id}/media/{uid}/revisions/    GET .../revisions/{revisionId}
```

### Data Sources & Datasets
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
POST   /projects/{id}/scripts/{name}/execute           # JSON in, text/plain out
```

### Global Content
```
GET    /projects/{id}/global-content/
GET    /projects/{id}/global-content/project-properties
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

List endpoints with large results return `PaginatedResponse`:
```json
{ "content": [...], "pageNumber": 0, "pageSize": 20, "hasNext": true }
```
Query params: `?page=0&size=20` (zero-based).

**Exception — Template endpoints return a direct array**, not a paginated response:
```bash
# Template listing → plain JSON array, use .[] not .content[]
curl -s ... "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/" | jq '.[]'
```
Affected: `GET /templates/section-templates/`, `/page-templates/`, `/format-templates/`, `/link-templates/`.

## Actions Pattern

Copy or release any element:
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"action":"release","options":{"checkOnly":false,"dependentReleaseType":"NO_DEPENDENT_RELEASE","ensureAccessibility":false,"recursive":false}}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{uid}/actions"
```

Actions: `copy`, `release`. Options for release:
- `checkOnly`: dry-run
- `dependentReleaseType`: `NO_DEPENDENT_RELEASE` | `DEPENDENT_RELEASE_NEW_AND_CHANGED`
- `ensureAccessibility`: ensure page is reachable in SiteStore
- `recursive`: include children

## Error Codes

| Code | Meaning |
|------|---------|
| 400 | Invalid input, unsupported operation, duplicate name |
| 404 | Element/language/template not found |
| 409 | Conflict (duplicate reference) |
| 415 | Wrong Content-Type |

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
