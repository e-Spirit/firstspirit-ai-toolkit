# CaaS Platform — the headless content repository

**CaaS = Content as a Service.** The MongoDB-backed content store that fronts
FirstSpirit's headless delivery: JSON documents in, REST + GraphQL out, secured
with API keys. FirstSpirit content is written into it by the **CaaS Connect**
module ([caas-connect.md](caas-connect.md)); frontends read it directly.

> **Boundary.** This file is the *platform* — how content is stored and read.
> How FirstSpirit content becomes those JSON documents is
> [caas-connect.md](caas-connect.md). How a frontend consumes it in practice
> (a Next.js app) is the the FirstSpirit PWA reference implementation (JavaScript Content API) skill. How to *shape/name/nest*
> templates for headless JSON is `firstspirit-template-design` (not here).

> **Engine.** The REST interface (`caas-rest-api`) is **RESTHeart** over
> **MongoDB** (`caas-mongo`). Much of the query/write/index/change-stream
> behaviour is standard RESTHeart that the CaaS docs reference rather than
> restate. Where a feature is RESTHeart's, it is flagged as such.

Sources:
[Product](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Product_Documentation_EN.html) ·
[Technical](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Documentation_EN.html) ·
[Operations (admin)](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Operations_Guide_EN.html) ·
RESTHeart: <https://restheart.org/docs/>. Documented version at research time: **21.1.4**.

---

## Storage hierarchy and identity

Three tiers, Mongo-style: **Database → Collection → Document**.

```
https://REST-HOST:PORT/<database>/<collection>/<document>
```
On Cloud the REST host is tenant-specific, e.g.
`https://{TENANT_ID}-caas-api.e-spirit.cloud`.

- **Database** ≈ tenant/project scope. **Collection** encodes content type *and*
  state (see preview vs release below). **Document** = one content item.
- **Reserved databases:** `caas_admin`, `_logic`, `graphql`.
  **Reserved collections:** `apikeys`, `gql-apps`.
- **Document `_id`** = FirstSpirit **GID** + locale suffix, e.g.
  `f6910b22-6ae8-4ce1-af45-c7b364b3117a.en_GB`. (CaaS Connect owns the exact
  document shape — see [caas-connect.md](caas-connect.md).)

The collection/URL scheme CaaS Connect writes into:

```
https://<CAAS-BASE-URL>/<tenant-id>/<project-GID>.<collection>/<document-id>.<locale>
```

---

## Read API (REST / RESTHeart)

CRUD maps to HTTP verbs on the hierarchy. For a public frontend the relevant
verb is **`GET`**; writes are done by CaaS Connect, not by consumers.

| Verb | Purpose | Pattern |
| --- | --- | --- |
| GET | query collection / single doc | `/<db>/<collection>[/<doc>]` |
| POST | create / bulk write (array body) | `/<db>/<collection>` |
| PUT | create/replace a doc | `/<db>/<collection>/<doc>` |
| PATCH | partial update | `/<db>/<collection>/<doc>` |
| DELETE | remove doc/collection/db | `/<db>/<collection>/<doc>` |
| HEAD | metadata check | `/<db>/<collection>` |

Default write mode is `upsert` (RESTHeart).

### Pagination
- `?page=<n>` (1-based) and `?pagesize=<n>`.
- **CaaS defaults:** `pagesize` default **20**, max **100** (configurable
  on-prem only). *(Note: these override bare RESTHeart defaults of 100/1000.)*

### Filtering (MongoDB-style)
- `?filter={<mongo query>}`. Documented example — all English docs in `products`:
  ```
  GET https://REST-HOST:PORT/<db>/products?filter={fs_language:"EN"}
  ```
- Operators are delegated to MongoDB: `$gt`,`$lt`,`$gte`,`$lte`,`$and`,`$or`,
  `$in`,`$regex`,`$exists`,`$text`. Multiple `filter` params AND together
  (RESTHeart behaviour — **(UNVERIFIED)** for CaaS's own examples).
- **`np` is auto-appended** by CaaS to filter queries, so collection metadata is
  omitted from the response by default (disable on-prem).
- **An empty filter `{}` answers `400`** `[observed]`. Leave `filter` out when there is
  nothing to filter on.

### Sort / projection / count — RESTHeart params
CaaS docs explicitly document only `filter`, `page`, `pagesize`, `np`, but the
official `fsxa-api` client sends **`sort`** and **`keys`** (projection) straight
to CaaS via its `fetchByFilter` (`additionalParams: { keys: { identifier: 0 } }`,
`sort: [{ name, order }]`), so both are confirmed usable against CaaS:
- `sort=<field>` / `-<field>` / `{"a":1,"b":-1}` (1 asc, -1 desc) — the client
  defaults to `_id` descending
- `keys={"item":1}` (include) / `{"item":0}` (exclude); dot notation for nested
- `count` / `count=estimated`, `hint=...` — engine params, **(UNVERIFIED for CaaS)**

### Reference resolution (server-side join)
- `?resolveRef=<path>` inlines referenced documents. Transitive:
  `?resolveRef=$1.<path>` … `$<depth>.<path>`.
- Path syntax: `data.url`, `data[*].url`, `data[0].url`, `data[*][*].url`.
- **Limits:** default max depth **3**; **max 100 unique refs per request**; only
  absolute URLs resolved; bad paths silently ignored; no URL normalisation.
- **Response:** resolved refs attached under `_resolvedRefs`
  (keyed by the referenced URL). For collection responses a synthetic
  `_resolvedRefs` document is appended to the array.

### Response envelope (HAL)
Collection queries return a HAL envelope; single-document queries return the raw
document JSON.
```json
{ "_size": 5, "_total_pages": 1, "_returned": 3,
  "_embedded": { "...": "payload" }, "_links": { "...": "navigation" } }
```
(`np` suppresses this metadata on filter queries by default — see above.)

### Media / binaries
- Bucket collections use a **`.files`** suffix (e.g. `images.files`).
- Querying a media document returns **metadata only** (URLs + resolution
  metadata), never the binary.
- **SaaS:** binaries are not stored in CaaS buckets — they are served elsewhere
  via the URL factory (see [caas-connect.md](caas-connect.md) for the media
  document shape and rendition URLs).

### No dedicated full-text endpoint
There is **no `_search` endpoint**. Text search is the Mongo `$text` operator
inside `filter` (needs a text index). **(UNVERIFIED — none found.)**

### Aggregations (named server-side pipelines)

When `filter` + `sort` + `keys` + `resolveRef` are not enough — grouping, counting,
computed fields, joins across collections — CaaS runs **MongoDB aggregation
pipelines** server-side. The platform documentation names "custom aggregations"
as a feature of the REST interface `[odfs]` but documents them only inside
GraphQL apps (next section) and points to the RESTHeart documentation for the
rest. The REST form below is RESTHeart's; it was exercised against CaaS in an
internal prototype in 2022 `[observed]` and the CaaS release notes have fixed
its behaviour repeatedly since `[core]`, so the mechanism exists in the product.
Treat the exact request shapes as **UNVERIFIED against a current CaaS** until a
live run confirms them.

**Two ways to run a pipeline:**

| Form | Where the pipeline lives | Called as | Status |
| --- | --- | --- | --- |
| **Named REST aggregation** | collection metadata, property `aggrs` | `GET /<db>/<collection>/_aggrs/<uri>?avars={…}` | RESTHeart form; CaaS prototype 2022 `[observed]` |
| **GraphQL app mapping** | the app's `mappings`, a query field with `db`, `collection`, `stages` | `POST /graphql/<app-uri>` with a GraphQL query | documented `[odfs]`, since CaaS 16.12.0 `[core]` |

**Named REST aggregation (RESTHeart form).** The definition is a metadata
property of the collection, written with `PUT`/`PATCH` on the collection:

```json
{ "aggrs": [
  { "uri": "by_id",
    "type": "pipeline",
    "stages": [
      { "$match": { "_id": { "$var": "id" } } }
    ] }
] }
```

- `uri` is the name in the path: `GET /<db>/<collection>/_aggrs/by_id`.
- Variables are bound with **`$var`** in the stages and passed as
  **`?avars={"id":"<gid>.en_GB"}`** (JSON, URL-encoded). RESTHeart also
  accepts a default: `{ "$var": ["sort", { "_id": -1 }] }`; CaaS fixed
  default-variable resolution in 14.7.1 / 14.8.1 `[core]`, so defaults are
  supported. A call without a required variable answers **400** (since 14.9.1;
  was 500) `[core]`.
- **Pagination is not automatic.** RESTHeart exposes `@page`, `@pagesize`,
  `@skip`, `@limit` as predefined variables; a pipeline pages itself with
  `{ "$skip": { "$var": "@skip" } }, { "$limit": { "$var": "@limit" } }` and
  the caller sends `?page=&pagesize=`. The CaaS `pagesize` max of 100 applies
  to `@limit` **(UNVERIFIED)**.
- `type` is always `"pipeline"`: **mapReduce aggregations are disabled
  platform-wide** since CaaS 14.6.1 (they ran JavaScript the platform could not
  inspect) `[core]`. JavaScript operators (`$where`, `$function`,
  `$accumulator`) are blocked by RESTHeart as well.
- `$out` / `$merge` write the result into a collection; the HTTP response is
  then an **empty array** (corrected in 16.7.1) `[core]`. The simplified
  `{ "$merge": "<collection>" }` form is permission-checked, not rejected
  (17.2.1) `[core]`.
- Writing the metadata needs a key with `PUT`/`PATCH` on the collection; the
  read-only keys CaaS Connect generates cannot. Whether a CaaS Connect
  re-sync preserves custom metadata on a `<project>.release.content`
  collection is **UNVERIFIED** — put aggregations on a collection you own
  until that is settled.

**Security model (the CaaS-specific part).** Every aggregation is **inspected at
execution time** so that it touches only data the calling API key has permission
for `[core]`; this is why variables are **not permitted in authorization-relevant
attributes** of a stage, such as a database or collection name in `$lookup`,
`$merge` or `$out` — hard-code those `[odfs]`. Missing permissions produce a
descriptive error (improved in 17.8.0) `[core]`.

**Limits.** Aggregation execution is capped at **30 seconds** `[core]` (the
plain-query timeout is 408, see below); on the shared SaaS deployment a badly
written pipeline under load is a neighbour problem, so `$match` early, index the
matched fields (see *Indexes*), and avoid unbounded `$lookup`.

**Inside a GraphQL app** the same stages go into the query mapping; GraphQL
arguments are read with `$arg` instead of `$var` `[odfs]`:

```json
"Query": { "pageRefs": {
  "db": "<tenant>", "collection": "<project-GID>.release.content",
  "stages": [
    { "$match": { "fsType": "PageRef" } },
    { "$addFields": { "projectId": { "$arg": "projectId" } } }
  ] } }
```

The platform's own request collection uses the same shape for a count
(`$match` on `fsType`, then `$count`) `[core]`.

**When to use what.** Shape a single document → `keys`. Join referenced
documents → `resolveRef` (max depth 3, 100 refs). Group / count / compute /
join by arbitrary field → an aggregation. If a frontend uses the official
JavaScript Content API (`fsxa-api`), note that it ships no aggregation call; it
builds `filter`/`sort`/`keys` queries — the internal evaluation in 2022 chose
that route over shipping aggregations with a product `[observed]`.

---

## GraphQL

- **Auto-generated API** (schema derived from the FS data model, no config):
  ```
  POST https://REST-HOST:PORT/graphql/<app-uri>
  ```
- **Custom apps** (user schema + mappings). App-uri form is
  `<tenant>___<app-name>` (triple underscore). Managed via
  `PUT/DELETE /<tenant>/gql-apps/<tenant>___<app-name>` `[core]` and
  `POST /_logic/sync-gql-apps` (UNVERIFIED — not seen in the platform's own request
  collection). The apps CaaS Connect generates per project are named
  `<tenant>___<project-GID>-preview-documents` and `…-release-documents` `[core]`.
- App definition = **descriptor** (`{description, enabled, uri}`) + **schema**
  (GraphQL SDL) + **mappings** (field→path, field→query with `$fk` foreign keys,
  or Mongo aggregation `stages` — see *Aggregations* above; GraphQL
  aggregations since 16.12.0 `[core]`).
- **Default `pagesize` = 20.** Authorised by an API key with `GRAPHQL`-mode
  permission whose `url` = the app-uri (or a covering `PREFIX`/`REGEX` key).
- **`filter` and `sort` arguments take plain JSON** (Mongo-style objects; the argument type
  is `BsonDocument`), not a typed input `[observed]`.
- **A `GRAPHQL`-mode key is refused on REST (`403`)** `[observed]`; the scope limits the
  channel, not the fields: the GraphQL schema still serves whatever fields are in the
  documents, internal ones included. Keep fields you must not expose out of the stored
  JSON instead of relying on the key.

An experimental **CaaS MCP Server** (GraphQL/AI) is documented separately:
<https://caas-mcp.e-spirit.cloud/docs/en/documentation.html>.

---

## Change streams (real-time push) — WebSocket

Push is **WebSocket only** — there is **no SSE and no classic webhook**.
```
wss://<host>/<database>/<collection>/_streams/<stream-name>
```
- **Default stream name `crud`** is provided by CaaS Connect: it matches
  `insert`, `update`, `replace` and `delete` and projects the event down to
  `documentKey`, `operationType`, `operationResult` and the `_id` and `fsType` of the
  full document `[core]`.
- Auth via `?securetoken=<token>` query param or `securetoken` cookie.
- Events are Mongo change events:
  `{ "documentKey": {"_id": "..."}, "operationType": "insert|update|delete|replace" }`.
- Client guidance: periodic ping + automatic reconnection.

---

## Security — how a frontend authenticates

**Auth methods, in evaluation order:** (1) `?securetoken=<token>` query param,
(2) `Authorization: Bearer <key>` header, (3) `securetoken` cookie `[core]`. The two
token forms need the tenant to be derivable from the request path.

### Secure tokens (recommended for browsers)
Short-lived tokens minted from an API key — exposes read access to a public
frontend without shipping the raw key:
```bash
GET /_logic/securetoken?tenant=<db>&ttl=<seconds>       # returns {"securetoken": "..."}
GET /_logic/securetokencookie?tenant=<db>&ttl=<seconds> # sets the securetoken cookie
# minted with:  -H "Authorization: Bearer <api-key>"
```
`ttl` defaults to **300 s** and is capped at **86400 s** (one day); `tenant` is
mandatory (400 without it); only `GET` is allowed `[core]`.

### API keys
- **Global keys** live in `caas_admin/apikeys` (cross-database; permission `url`
  checked against the whole path). **Local keys** live in `<db>/apikeys`
  (single database; `url` checked against the path *after* the db segment).
- **Permission:** `{ "url": "<path>", "permissionMode": "PREFIX|REGEX|GRAPHQL",
  "methods": ["GET","POST",...] }`. `permissionMode` defaults to `PREFIX` (literal path
  prefix); `REGEX` matches the whole request path; `GRAPHQL` names an app, not a path
  `[core]`.
  - **Read-only vs read-write is the `methods` array** — the keys CaaS Connect generates
    use `GET`/`HEAD`/`OPTIONS` for read and add `PUT`/`POST`/`PATCH`/`DELETE` for
    read/write `[core]`. There is no distinct "read key / write key" *type*; the
    "read key/write key" wording (also used by CaaS Connect) is a convention over
    method scope.
- Managed via `GET/POST /<db>/apikeys`, `PUT/DELETE /<db>/apikeys/{id}`;
  validated against `/<db>/_schemas/apikeys` (400 on invalid, 500 if schema
  missing).

### CORS
Not covered in the developer pages — **(UNVERIFIED)**; configured at the
deployment/proxy layer. A Crownpeak quickstart reports it as an
admin-managed **allowed-origins** list (ask the FirstSpirit administrator to add
the frontend's domain) — plausible, confirm against the Operations Guide.

---

## Operational notes for consumers

- **Query timeout → HTTP 408.** Create indexes for frequently-filtered fields.
  Index endpoints: `GET/POST /<db>/<collection>/_indexes/`,
  `PUT/DELETE /<db>/<collection>/_indexes/<id>`. CaaS Connect creates predefined
  indexes automatically.
- **Rate limits / caching / CDN / API versioning:** not documented on the REST
  layer — **(UNVERIFIED)**. No `/vN/` path versioning observed (single-version
  product). A CDN is referenced in connection with the GraphQL API (see
  [caas-connect.md](caas-connect.md) media cache headers).
- **Broken references:** since **FirstSpirit 2026.5**, unresolved references
  carry `brokenReference: true` + a `url` for later retrieval.

## Official client libraries (and reference implementation)

Before hand-rolling `fetch` against these endpoints, consider e-Spirit's own
clients, which wrap CaaS **and** the Navigation Service (routing, reference
resolution, preview vs release, TPP wiring):

- **JavaScript Content API Library — `fsxa-api`** (Apache-2.0) —
  <https://github.com/e-Spirit/javascript-content-api-library>
- **Crownpeak PWA template** (example app) —
  <https://github.com/e-Spirit/crownpeak-pwa-template>

`fsxa-api` is also the **reference implementation** this skill's platform facts
are checked against (v11.2.2 at time of writing). Worth knowing even if you don't
adopt it:

- **Two classes: `FSXARemoteApi` (server) and `FSXAProxyApi` (frontend).** The
  remote API holds the CaaS API key and calls CaaS/Nav directly; the proxy API
  calls a small middleware that the remote API backs, so **secrets never reach the
  browser**. This is the recommended way to keep the key server-side (an
  alternative to the secure-token flow above).
- **Methods:** `fetchNavigation({ locale, initialPath })`,
  `fetchElement({ id, locale })`, `fetchByFilter({ filters, locale, page,
  pagesize, sort, additionalParams })`, `fetchProjectProperties({ locale })`
  (**needs CaaS Connect v3+**), plus `getAvailableLocales(...)`.
- **URL builders confirm the endpoint forms:** `buildCaaSUrl` →
  `${caasURL}/${tenantID}/${projectId}.${contentMode}.content`;
  `buildNavigationServiceUrl` → `${navigationServiceURL}/${contentMode}.${projectID}`
  (the configured `navigationServiceURL` ends in `/navigation`).
- **Auth header:** `{ authorization: 'Bearer <apikey>' }`.
- **`enableEventStream`** toggles consuming the CaaS change stream; **`remotes`**
  configures cross-project (remote) media.

For a Next.js frontend the the FirstSpirit PWA reference implementation (JavaScript Content API) skill is the build-side companion;
this skill stays the platform reference.

---

Installation, deployment (Helm/K8s/Docker), sizing, backup, on-prem-only knobs,
and SaaS-vs-on-prem restrictions are parked →
[for-later-configuration-and-install.md](for-later-configuration-and-install.md).
