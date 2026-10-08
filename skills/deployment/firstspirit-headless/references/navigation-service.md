# Navigation Service — site structure as JSON

Transfers the FirstSpirit **SiteStore** structure into **JSON** for headless
frontends, and provides the dynamic mapping between a **route** and its
**content**. A frontend uses it to answer "what page is at this URL?" and then
fetches that page's content from [CaaS](caas-platform.md).

Sources:
[FSM docs](https://docs.e-spirit.com/module/navigation-service-fsm/Navigation_Service_FSM_Documentation_EN.html) ·
[User docs](https://navigationservice.e-spirit.cloud/docs/user/en/documentation.html) ·
OpenAPI: `https://navigationservice.e-spirit.cloud/docs/api/swagger.yml`
(also `/docs/swagger-ui`, `/docs/redoc`, `/docs/rapidoc`).

> **Separate endpoint, separate credentials from CaaS.** The Navigation Service
> and CaaS are distinct services. Navigation Service reads are unauthenticated by
> default (see Security); CaaS wants a Bearer/secure token.

---

## Two components

- **Navigation Client Service** — runs on the FirstSpirit server; pushes
  navigation changes to the Navigation Service over HTTPS. Navigations maintained
  in FirstSpirit are made available automatically.
- **Navigation Project Configuration** — the FirstSpirit project component that
  controls whether navigations are created for a project. Removing it deletes the
  project's navigations.

Clients read on a **pull** basis over REST.

---

## REST API

Endpoints are rooted at `/navigation`. A **`navigationId`** identifies a specific
navigation (project + preview/release variant; language is a query param, not
part of the id). The id form is **`{preview|release}.{PROJECT_ID}`** — e.g.
`release.12345678-90ab-cdef-1234-567890abcdef` — which matches the `preview`
path-prefix the auth examples protect. This is **confirmed by the official
`fsxa-api`** (`buildNavigationServiceUrl` →
`${navigationServiceURL}/${contentMode}.${projectID}`, where the configured
`navigationServiceURL` ends in `/navigation`). On Cloud the service is
tenant-hosted:

```
GET https://{TENANT_ID}-navigationservice.e-spirit.cloud/navigation/{preview|release}.{PROJECT_ID}?language={locale}
```

The `fsxa-api` reaches it with `fetchNavigation({ locale, initialPath })` and
offers `getAvailableLocales({ projectId, navigationServiceURL, contentMode })`.

| Verb | Path | Purpose |
| --- | --- | --- |
| GET | `/navigation/{navigationId}` | full navigation tree |
| GET | `/navigation` | list navigation ids (paginated) |
| GET | `/navigation/{navigationId}/node/{elementId}` | subtree by element id |
| GET | `/navigation/{navigationId}/by-seo-route/{seoRoute}` | **route resolution** — subtree from the first element whose `seoRoute` matches |
| GET | `/navigation/{navigationId}/node/{elementId}/path` | breadcrumb — flat array root → element |
| POST/PUT/DELETE | `/navigation[/{navigationId}[/node/{elementId}]]` | create/update/delete (write side) |

**Read query params:** `language`, `Accept-Language`, `depth` (default `10`),
`format` (default `default`; also `noLinks`, `caas`), `If-None-Match` (ETag derived from
the navigation's last update). `by-seo-route` also takes `all` and defaults the route to
`/`. List uses `from`/`after`/`before`/`until`/`limit` (default `50`). All of this is
confirmed in the service source `[core]`. The service itself only requires a
`navigationId` to match `[0-9a-zA-Z\-_.]{1,80}` — the `{preview|release}.{PROJECT_ID}`
form is the convention CaaS Connect and the `fsxa-api` follow, not a server rule `[core]`.

**Response schemas:** `NavElementV1Response` (default),
`NavElementNoLinksResponse` (`noLinks`), `NavElementCaasResponse` (`caas`),
`NavElementPathResponseV1[]` (breadcrumb), `NavSearchResult` (list).

---

## Default element shape

Node fields: `id`, `label`, `seoRoute`, `seoRouteRegex`, `contentReference`,
`customData`, `visible`, `permissions`, `_links`, `hasChildren`, `children`.

```json
{ "id": "815c307c-2ca6-4f02-9653-fa3454988fc2",
  "label": "products", "seoRoute": "/products", "seoRouteRegex": null,
  "contentReference": "/Products/Sales/index.html",
  "visible": true, "permissions": null,
  "customData": { "pageDescription": "Our product range" },
  "children": [ /* nested elements */ ] }
```
- `contentReference` — handle to the content the app must fetch; in a headless
  project this is typically the **CaaS URL** for the page.
- `seoRoute` — the SEO/human route; `seoRouteRegex` handles variable routes.

---

## CAAS format (`format=caas`) — what headless frontends consume

`NavElementCaasResponse` top-level: `idMap`, `seoRouteMap`, `structure`, `pages`,
`meta`.

- **`idMap`** — map of `elementId → NavMappedElement`. Each element:
  `id`, `parentIds[]`, `label`, `contentReference`, **`caasDocumentId`**,
  `seoRoute`, `seoRouteRegex`, `customData`, `permissions`.
- **`seoRouteMap`** — map of `seoRoute → elementId` (one-to-one; first match wins
  on duplicates).
- **`structure`** — array of `StructureNode` `{ id, children[] }` (recursive).
  Only elements that are **visible and have a non-null `contentReference`** are
  included.
- **`pages`** — object (includes an `index` seoRoute + more).
- **`meta`** — `identifier` with `tenantId`, `navigationId`, `languageId`.

`caasDocumentId` links a navigation node directly to its CaaS content document.

### Resolving a URL to a page (caas format)
1. `elementId = seoRouteMap[path]` (fall back to `seoRouteRegex` for variable
   routes).
2. `node = idMap[elementId]` → read `contentReference` / `caasDocumentId`.
3. Fetch the content from CaaS.

Or resolve server-side: `GET /navigation/{navigationId}/by-seo-route/{seoRoute}`.

> note from the FirstSpirit PWA reference implementation that catches people out: a TPP `previewId` is
> `{uuid}.{locale}` but `caasDocumentId` is just the UUID — split on `.` and take
> index 0 when matching. That consumer detail lives in the FirstSpirit PWA reference implementation (JavaScript Content API).

---

## Integration and customData

- **Feed:** the Client Service persists/updates navigations automatically as the
  SiteStore changes (HTTPS, pull for reads). Scheduled-task / resilience
  specifics not detailed in the fetched docs — **(UNVERIFIED)**.
- **`customData`** — arbitrary key/value on nodes for app-specific needs.
  **Limits: max 5 entries per node; key ≤200 chars; value ≤500 chars; values
  must be `null`, number, boolean, or string** (no objects/arrays) — enforced by the
  service on write `[core]`. *The FirstSpirit-side
  mechanism that populates it (which template/field) was not specified in the
  fetched docs — **(UNVERIFIED)**.*
- **Filtering:** `visible` controls display; `permissions` lists allowed/forbidden
  roles; in `caas` `structure`, non-visible or null-`contentReference` nodes are
  excluded. No draft-vs-published filtering endpoint is described.

---

## Security

- **Reads are unauthenticated by default:** "In the default setting, read
  requests are not protected, so all information known to the Navigation Service
  is freely available on the Internet."
- **Writes (POST/PUT/DELETE)** require an **OAuth Bearer JWT** (Client
  Credentials Grant via Keycloak). The OpenAPI spec defines **only** a Bearer/JWT
  scheme — no `apikey` header.
- **Preview vs release protection** is configured by **path prefix** in
  `authenticationRequirements` (e.g. require auth for ids/paths beginning
  `preview`).

Module install, the Navigation Project Configuration component, Keycloak/OAuth
setup, and `authenticationRequirements` are parked →
[for-later-configuration-and-install.md](for-later-configuration-and-install.md).
