# CaaS Connect — the FirstSpirit → CaaS delivery module

The FirstSpirit **module** (FSM) that serialises editorial content to JSON and
pushes it into the [CaaS Platform](caas-platform.md), near-real-time and
event-driven. It is the successor to the deprecated "CaaS module v2".

> **Division of labour.** FirstSpirit = authoring (templates, workflows).
> CaaS Connect = the synchronisation layer (this file). CaaS Platform = stores
> the JSON and serves it ([caas-platform.md](caas-platform.md)). FirstSpirit
> templating/rendering is **not** in the delivery path.

Sources:
[FSM docs](https://docs.e-spirit.com/module/caas-connect/CaaS_Connect_FSM_Documentation_EN.html) ·
[Server Administrator](https://docs.e-spirit.com/module/caas-connect/CaaS_Connect_ServerAdministrator_EN.html).

---

## The load-bearing constraint: the JSON is not template-driven

**You cannot shape the CaaS JSON through a template output channel or transform.
There is no "CaaS Connect" output channel.** The JSON is generated automatically
from FirstSpirit's standard **`toJson`** (with CaaS-specific extensions), and the
docs state the format **cannot be customised** — deliberately, so every consumer
gets one standardised format. The docs also warn: do **not** write your own
documents into the collections CaaS Connect owns.

**Therefore the way to change the delivered JSON is to change the model**, not the
output: the JSON mirrors the GOM form/`FormData`, so field names/types come from
the form definitions and templates. Designing that model well for a headless
consumer (flat nesting, clean keys) is `firstspirit-template-design`'s job — see
its principles on output mode, structure, and naming. This skill does not restate
them.

What a developer/template author *can* influence:
1. **URL factory** selection — determines `route` values and media binary URLs.
2. **Project settings page → `CaaS` tag** — which media resolutions are
   transmitted; exposes `projectConfiguration.masterLocale`.
3. **Which languages generate** — the `Generate language` flags.
4. **Sync scheduling** — Smart Sync / Total Sync schedules + manual per-element
   sync.

---

## What gets synchronised

Page references, media, global content pages, project settings pages, and
datasets. **Each element produces multiple documents: one per language flagged
`Generate language`, in both preview and release state.**

### Collections (per project + state)
```
<project-GID>.preview.content   <project-GID>.release.content   # documents
<project-GID>.preview.files     <project-GID>.release.files     # media/binaries
```
Full document URL:
`https://<CAAS-BASE-URL>/<tenant-id>/<project-GID>.<collection>/<document-id>`
where `document-id` = **GID + locale suffix** (`<gid>.en_GB`).

---

## The JSON document shape

Top-level fields documented on a content document:

- `_id` / `identifier` — the GID (`_id` carries the `.locale` suffix)
- `fsType` — the FirstSpirit element type (`PageRef`, `Media`, `Content2Section`,
  `DatasetReference`, `FS_REFERENCE`, …)
- `locale` — `{ identifier, country, language }`
- `uid` / `uidType`, `displayName`, `template` (where applicable)
- `route` — URL from the configured URL factory (present on **PageRef** and
  **Dataset** documents)

### Page → body → section nesting (confirmed via `fsxa-api`)
A **PageRef** document nests as follows (confirmed against the official
`fsxa-api` mapper, `CaaSMapper.mapPageRef` — see [Reading it](#reading-it-the-official-client)):

```
pageRef.identifier            # the PageRef's own GID
pageRef.page                  # the Page
  .identifier                 # page GID
  .name
  .template.uid               # the page template (layout)
  .formData                   # page fields (see below)
  .metaFormData               # page metadata fields
  .children[]                 # bodies (CaaSApi_Body): { name, identifier, children[] }
      .children[]             # the sections in that body
```
So the array that nests sections is **`children`** at both levels
(`page.children` = bodies, `body.children` = sections).

### Form fields (FormData)
Each field serialises as an object carrying at least **`fsType`, `name`,
`value`** — FirstSpirit's standard `toJson` FormData representation (a keyed map
of self-describing fields). Fields sit under `formData` (page: `page.formData`;
section: `section.formData`; catalog card: `card.formData`), so a consumer reads a
page field as `pageRef.page.formData.<fieldName>.value` (use optional chaining —
any field can be absent).

### What each input component looks like in the JSON

The per-component CaaS representation, from the `fsxa-api` **Type Mapping** table
(its README + `CaaSMapper`) — the authoritative map of GOM input component →
CaaS JSON value. The third column is the shape the client maps it *to*, useful as
a hint to the raw meaning:

| Input component | CaaS `value` (raw) | Client maps to |
| --- | --- | --- |
| `CMS_INPUT_TEXT` / `CMS_INPUT_TEXTAREA` | `string` | string |
| `CMS_INPUT_NUMBER` | `number` | number |
| `CMS_INPUT_TOGGLE` | `boolean`\|`null` | boolean |
| `CMS_INPUT_DATE` | `string` (**ISO 8601**)\|`null` | Date |
| `CMS_INPUT_DOM` / `CMS_INPUT_DOMTABLE` | `string` (**FS-XML, not HTML**) | rich-text nodes |
| `CMS_INPUT_COMBOBOX` / `CMS_INPUT_RADIOBUTTON` | `Option`\|`null` | Option |
| `CMS_INPUT_CHECKBOX` / `CMS_INPUT_LIST` | array of options | Option[] |
| `CMS_INPUT_LINK` | object | Link |
| `CMS_INPUT_IMAGEMAP` | image-map object | ImageMap |
| `CMS_INPUT_PERMISSION` | `PermissionActivity[][]` | Permission |
| `FS_REFERENCE` | a reference object (`BaseRef`/`PageRefRef`/`GCARef`/`MediaRef`)\|`null` | resolved target |
| `FS_CATALOG` | `Card[]` (each card has its own `formData`) | Section[] |
| `FS_INDEX` | `Record[]` | data entries |
| `FS_DATASET` | dataset\|data-entries\|`null` | Dataset |

> **`CMS_INPUT_DOM` is FS-XML, not HTML.** The raw CaaS value is FirstSpirit's
> rich-text XML; a consumer parses it (the `fsxa-api` has an `XMLParser` for
> exactly this). Do **not** assume you can drop the value straight into
> `innerHTML` — that only holds if a template rendered HTML into the field.

### Sections
A section carries `fsType` (`Section` / `SectionReference` / `Content2Section`),
`displayName`, `template`, and `formData`. **`Content2Section`** is the section
type that embeds a dataset content projection; content-projection sections
serialise the projection as a **`query` object** rather than embedding the records
(the dataset documents are referenced, not inlined).

### References (not inlined)
- **Media:** `"fsType": "FS_REFERENCE"`, a `value` object + a `url` to the media
  document in CaaS.
- **Dataset:** `"fsType": "DatasetReference"`, a `target` object + a `url`:
  ```json
  { "fsType": "DatasetReference",
    "target": { "schema": "...", "entityType": "...", "identifier": "..." },
    "url": "https://<CAAS-BASE-URL>/<TENANT>/<PROJECT>.preview.content/<ID>.<locale>" }
  ```
  Dataset documents also carry a `routes` array (`{ pageRef, route }` per
  available content projection).
- **Broken references:** `brokenReference: true` + a `url` for later resolution.

### Media documents and binary URLs
```json
{ "_id": "3b3fe5b6-....en_US", "fsType": "Media", "name": "thisisatest",
  "resolutionsMetaData": { "ORIGINAL": { "url": "https://<CAAS-BASE-URL>/defaultTenant/..." } } }
```
Binaries can come from three sources → three URL shapes:
1. **CaaS storage:** `.../<tenant>/<project-GID>.{release|preview}.files/<media-GID>.<lang>_<country>_<resolution>/binary`
2. **S3 via CloudFront:** `https://<cloudfront-base-url>/<s3-object-path>`
3. **S3 REST API:** `https://<s3-rest-api-url>/<s3-object-path>`

Which resolutions are transmitted is set on the project settings page's `CaaS`
tag ("Transmitted resolutions"). Media cache headers on S3: preview is always
`private, no-cache`; release is `public, max-age=<n>, s-maxage=<n>` with both values
taken from the module's cache-control configuration (the documented defaults are 300
and 900 seconds) `[core]`.

> The FirstSpirit PWA reference implementation (JavaScript Content API)'s rule holds: an `FS_REFERENCE` media value points
> at a media *document*, not an image — fetch it, read `resolutionsMetaData`,
> pick a rendition. Never hand-build binary URLs. That consumer-side detail lives
> in the FirstSpirit PWA reference implementation (JavaScript Content API).

---

## Preview vs release

- Two separate collection families per project (`*.preview.*` / `*.release.*`).
- **Preview** updates on every content change (near-real-time, event-driven).
  **Release** updates **only on release actions**. Projects without release
  enabled transfer preview data only.
- **Initial / repair sync is manual:** **Smart Sync** and **Total Sync**
  schedules reconcile state; a manual executable can sync selected elements.
- If the CaaS Connect service is stopped, no synchronisation happens.

---

## Reading it: the official client

The JSON shape above is easiest to learn from the **`fsxa-api`** (JavaScript
Content API Library) — e-Spirit's official, Apache-2.0 client and the **reference
implementation** for parsing CaaS + Navigation Service output:
<https://github.com/e-Spirit/javascript-content-api-library>.

- Its **`CaaSMapper`** is the canonical map from raw CaaS JSON to a friendly
  model (the source of the nesting and the input-component table above).
- Its **`XMLParser`** shows how `CMS_INPUT_DOM` FS-XML is turned into rich-text
  nodes.
- The raw CaaS document (what this file describes) is what you get *before* the
  mapper runs — the README notes you can fetch it directly with the API key to
  discover the exact key names to filter on.

For querying/auth/streams see [caas-platform.md](caas-platform.md); for building a
Next.js frontend on top, the FirstSpirit PWA reference implementation (JavaScript Content API).

---

## Read side

CaaS Connect adds **no custom read endpoints** — reads go through the CaaS
Platform's standard REST + GraphQL ([caas-platform.md](caas-platform.md)). What
CaaS Connect contributes to the read side: the collection/URL scheme above, the
extra attributes (`route`, `routes[]`, `url` on references, `brokenReference`,
`projectConfiguration.masterLocale`), the predefined indexes, the default `crud`
change stream, and the per-state consumer API keys.

Facts read in the module source `[core]`, useful when filtering or sizing:

- **Predefined indexes** on each `*.content` collection: `identifier` +
  `locale.language`/`locale.country`; `identifier` + `locale.identifier`; `entityType`,
  `fsType` and `fsType` + `template.uid` / `page.template.uid` / `mediaType`, each with
  language and country; `route`; `routes.route`; `changeInfo.lastSynced`. Filter on these
  fields and the 408 timeout stays away.
- **Six generated API keys per project**, named "Project `<id>` …": Read (Preview),
  Read/Write (Preview), Read, Read/Write, GraphQL (Preview), GraphQL. Read keys carry
  `GET`/`HEAD`/`OPTIONS` on the project's content *and* files collection.
- **Binary documents** for files end in `/binary`; pictures carry the resolution in the
  document path.

Module install, service configuration (`caasConnect.json`, master API key, tenant
id, S3 config), project activation, and requirements are parked →
[for-later-configuration-and-install.md](for-later-configuration-and-install.md).
