# CaaS Platform — the headless content repository

**CaaS = Content as a Service.** The MongoDB-backed content store that fronts
FirstSpirit's headless delivery: JSON documents in, REST + GraphQL out, secured
with API keys. FirstSpirit content is written into it by the **CaaS Connect**
module ([caas-connect.md](caas-connect.md)); frontends read it directly.

> **Boundary.** This file is the *platform* — how content is stored and read.
> How FirstSpirit content becomes those JSON documents is
> [caas-connect.md](caas-connect.md). How to *shape/name/nest*
> templates for headless JSON is `firstspirit-template-design` (not here).

> **Engine.** The REST interface (`caas-rest-api`) is **RESTHeart** over
> **MongoDB** (`caas-mongo`). Much of the query/write/index/change-stream
> behaviour is standard RESTHeart that the CaaS docs reference rather than
> restate. Where a feature is RESTHeart's, it is flagged as such.

Sources:
[Product](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Product_Documentation_EN.html) ·
[Technical](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Documentation_EN.html) ·
[Operations (admin)](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Operations_Guide_EN.html) ·
RESTHeart: <https://restheart.org/docs/>. Documentation version: **21.1.4**.

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
- `?filter={<mongo query>}`. Example — all English docs in `products`:
  ```
  GET https://REST-HOST:PORT/<db>/products?filter={fs_language:"EN"}
  ```
- Operators are delegated to MongoDB: `$gt`,`$lt`,`$gte`,`$lte`,`$and`,`$or`,
  `$in`,`$regex`,`$exists`,`$text`. Multiple `filter` params AND together
  (RESTHeart behaviour).
- **`np` is auto-appended** by CaaS to filter queries, so collection metadata is
  omitted from the response by default (disable on-prem).
- **An empty filter `{}` answers `400`** `[observed]`. Leave `filter` out when there is
  nothing to filter on.

### Sort / projection / count — RESTHeart params
CaaS docs document only `filter`, `page`, `pagesize`, `np`. The official
`fsxa-api` client also sends **`sort`** and **`keys`** (projection) to CaaS via
its `fetchByFilter` (`additionalParams: { keys: { identifier: 0 } }`,
`sort: [{ name, order }]`):
- `sort=<field>` / `-<field>` / `{"a":1,"b":-1}` (1 asc, -1 desc) — the client
  defaults to `_id` descending
- `keys={"item":1}` (include) / `{"item":0}` (exclude); dot notation for nested
- RESTHeart also defines `count` / `count=estimated` and `hint=...`; CaaS does not
  document them

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
inside `filter` (needs a text index).

### Aggregations (named server-side pipelines)

When `filter` + `sort` + `keys` + `resolveRef` are not enough — grouping, counting,
computed fields, joins across collections — CaaS runs **MongoDB aggregation
pipelines** server-side. The platform documentation names "custom aggregations"
as a feature of the REST interface `[odfs]` but documents them only inside
GraphQL apps (next section) and points to the RESTHeart documentation for the
rest. The REST form below is RESTHeart's.

**Two ways to run a pipeline:**

| Form | Where the pipeline lives | Called as | Documented in |
| --- | --- | --- | --- |
| **Named REST aggregation** | collection metadata, property `aggrs` | `GET /<db>/<collection>/_aggrs/<uri>?avars={…}` | RESTHeart docs |
| **GraphQL app mapping** | the app's `mappings`, a query field with `db`, `collection`, `stages` | `POST /graphql/<app-uri>` with a GraphQL query | documented `[odfs]` |

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
  accepts a default: `{ "$var": ["sort", { "_id": -1 }] }` (RESTHeart
  documentation). A call without a required variable answers **400** `[core]`.
- **Pagination is not automatic.** RESTHeart exposes `@page`, `@pagesize`,
  `@skip`, `@limit` as predefined variables; a pipeline pages itself with
  `{ "$skip": { "$var": "@skip" } }, { "$limit": { "$var": "@limit" } }` and
  the caller sends `?page=&pagesize=`.
- mapReduce is not available (disabled in CaaS 14.6.1 for security reasons, release notes); `type` is always `"pipeline"` `[odfs]`.
  JavaScript operators (`$where`, `$function`, `$accumulator`) are blocked by
  RESTHeart as well.
- `$out` / `$merge` write the result into a collection the key must be allowed
  to write; the HTTP response is then an **empty array** `[core]`.
- Writing the metadata needs a key with `PUT`/`PATCH` on the collection; the
  read-only keys CaaS Connect generates cannot. Put aggregations on a collection
  you own, not on one CaaS Connect manages.

**Security model (the CaaS-specific part).** Variables are **not permitted in
authorization-relevant attributes** of a stage, such as a database or collection
name in `$lookup`, `$merge` or `$out` — hard-code those `[odfs]`.

**Limits.** Keep pipelines short (the plain-query timeout is 408, see below):
put `$match` first, index the matched fields (see *Indexes*), avoid unbounded
`$lookup`.

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

A count uses the same shape (`$match` on `fsType`, then `$count`).

**When to use what.** Shape a single document → `keys`. Join referenced
documents → `resolveRef` (max depth 3, 100 refs). Group / count / compute /
join by arbitrary field → an aggregation. If a frontend uses the official
JavaScript Content API (`fsxa-api`), note that it ships no aggregation call; it
builds `filter`/`sort`/`keys` queries.

---

## GraphQL

- **Auto-generated API** (schema derived from the FS data model, no config):
  ```
  POST https://REST-HOST:PORT/graphql/<app-uri>
  ```
- **Custom apps** (user schema + mappings). App-uri form is
  `<tenant>___<app-name>` (triple underscore). `POST /_logic/sync-gql-apps`
  resynchronises the GraphQL apps of all tenants `[odfs]`.
- App definition = **descriptor** (`{description, enabled, uri}`) + **schema**
  (GraphQL SDL) + **mappings** (field→path, field→query with `$fk` foreign keys,
  or Mongo aggregation `stages` — see *Aggregations* above).
- **Default `pagesize` = 20.** Authorised by an API key with `GRAPHQL`-mode
  permission whose `url` = the app-uri (or a covering `PREFIX`/`REGEX` key).
- **`filter` and `sort` arguments take plain JSON** (Mongo-style objects; the argument type
  is `BsonDocument`), not a typed input `[observed]`.
- **A `GRAPHQL`-mode key is refused on REST (`403`)** `[observed]`. Do not store fields
  in a document that must not be delivered; a key scope selects collections, not fields.

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

**Three accepted forms:** `?securetoken=<token>` query param,
`Authorization: Bearer <key>` header, `securetoken` cookie `[core]`. The two
token forms need the tenant to be derivable from the request path.

### Secure tokens (recommended for browsers)
Short-lived tokens minted from an API key — exposes read access to a public
frontend without shipping the raw key:
```bash
GET /_logic/securetoken?tenant=<db>&ttl=<seconds>       # returns {"securetoken": "..."}
GET /_logic/securetokencookie?tenant=<db>&ttl=<seconds> # sets the securetoken cookie
# minted with:  -H "Authorization: Bearer <api-key>"
```
`ttl` defaults to **300 s** and long values are capped by the server; `tenant` is
mandatory (400 without it); only `GET` is allowed `[core]`.

### API keys
- **Global keys** live in `caas_admin/apikeys` (cross-database; permission `url`
  checked against the whole path). **Local keys** live in `<db>/apikeys`
  (single database; `url` checked against the path *after* the db segment).
- **Permission:** `{ "url": "<path>", "permissionMode": "PREFIX|REGEX|GRAPHQL",
  "methods": ["GET","POST",...] }`.
  - **Read-only vs read-write is the `methods` array.** There is no distinct
    "read key / write key" *type*; the "read key/write key" wording (also used by
    CaaS Connect) is a convention over method scope.
- Managed via `GET/POST /<db>/apikeys`, `PUT/DELETE /<db>/apikeys/{id}`;
  validated against `/<db>/_schemas/apikeys` (400 on invalid, 500 if schema
  missing).

### CORS
The developer documentation does not cover CORS; see the Operations Guide.

---

## Operational notes for consumers

- **Query timeout → HTTP 408.** Create indexes for frequently-filtered fields.
  Index endpoints: `GET/POST /<db>/<collection>/_indexes/`,
  `PUT/DELETE /<db>/<collection>/_indexes/<id>`. CaaS Connect creates predefined
  indexes automatically.
- **Rate limits / caching / CDN / API versioning:** not documented for the REST
  layer; there is no `/vN/` path versioning. A CDN is referenced in connection
  with the GraphQL API (see [caas-connect.md](caas-connect.md) media cache headers).
- **Broken references:** since **FirstSpirit 2026.5**, unresolved references
  carry `brokenReference: true` + a `url` for later retrieval.

## Official client libraries

Before hand-rolling `fetch` against these endpoints, consider e-Spirit's own
clients, which wrap CaaS **and** the Navigation Service (routing, reference
resolution, preview vs release, TPP wiring):

- **JavaScript Content API Library — `fsxa-api`** (Apache-2.0) —
  <https://github.com/e-Spirit/javascript-content-api-library>
- **FirstSpirit PWA template** (example app) —
  <https://github.com/e-Spirit/crownpeak-pwa-template>

The classes, configuration, methods and remote-project rules of `fsxa-api` are in
[fsxa-api.md](fsxa-api.md).

---

Installation, deployment, on-prem-only settings and SaaS-vs-on-prem restrictions:
[configuration-and-install.md](configuration-and-install.md).
