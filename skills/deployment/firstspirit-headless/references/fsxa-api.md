# `fsxa-api` — the JavaScript Content API Library

The official client for reading FirstSpirit content from CaaS and the Navigation Service in any JavaScript
project. Apache-2.0, published by Crownpeak Technology GmbH:
<https://github.com/e-Spirit/javascript-content-api-library>. An example application that uses it is the
FirstSpirit PWA template (Nuxt), <https://github.com/e-Spirit/crownpeak-pwa-template>; the README tells customers to
validate the library against their own performance, compatibility and security needs.

Source: the library's README and `docs/` on the public repository, read 2026-10-19 (the page shows no release
number; the last version this skill was checked against in the code is 11.2.2, 2026-09-15). Names, parameters and
defaults below are the README's; the README does not cover installation, preview or TPP wiring, or the event
stream beyond the configuration flag, and neither does this file. Experimental features of the library may
change in a minor release (README).

## Two classes, one recommended setup

| Class | Runs | Does |
| --- | --- | --- |
| `FSXARemoteApi` | on a server | holds the CaaS API key and calls CaaS and the Navigation Service directly |
| `FSXAProxyApi` | in the frontend | calls a REST endpoint that a `FSXARemoteApi` backs, so no secret reaches the browser |

The recommended setup uses both: the remote API behind a small server route, the proxy API in the frontend. On
Node a `fetch` implementation is required (the README uses `cross-fetch/polyfill` for older versions). The
library ships an Express router for the server side:

```ts
const remoteApi = new FSXARemoteApi(config)
app.use('/api', getExpressRouter({ api: remoteApi }))      // getExpressRouter: fsxa-api/dist/lib/integrations/express
const proxyApi = new FSXAProxyApi('http://localhost:3002/api', LogLevel.INFO)
```

The endpoint integration is built from validation helpers (they check that required parameters are present, not
their values) and wrapper functions such as `fetchByFilter` and `fetchNavigation` that return a result, a status
code and an error message; `express.ts` shows how to turn that into an HTTP response, which other servers can copy.
The README names no routes or parameter names for it; read the source.

## Configuration of `FSXARemoteApi`

| Key | Meaning |
| --- | --- |
| `apikey` | CaaS API key (sent as `Authorization: Bearer <key>`, also available as `remoteApi.authorizationHeader`) |
| `caasURL` | CaaS base URL |
| `tenantID`, `projectID` | tenant and FirstSpirit project id |
| `contentMode` | `FSXAContentMode.PREVIEW` (`preview`) or `FSXAContentMode.RELEASE` (`release`): selects the preview or release collections and navigation |
| `navigationServiceURL` | Navigation Service URL; it ends in `/navigation` |
| `logLevel` | `LogLevel`: 0 info, 1 log, 2 warning, 3 error (default), 4 none |
| `enableEventStream` | boolean; the README says no more |
| `remotes` | other projects whose media and datasets are resolved (below) |

The URLs the library builds are `${caasURL}/${tenantID}/${projectId}.${contentMode}.content` for CaaS
(`buildCaasUrl`) and `${navigationServiceURL}/${contentMode}.${projectID}` for the Navigation Service. Both
modes are one configuration switch: a frontend that serves editors and visitors runs the same code with
`preview` or `release`.

## Methods

| Method | Parameters | Returns |
| --- | --- | --- |
| `fetchNavigation` | `locale`, `initialPath` | the navigation (`caas` format: `idMap`, `seoRouteMap`, `structure`; see [navigation-service.md](navigation-service.md)) |
| `fetchElement` | `id`, `locale`, optional `remoteProject` | one element by id |
| `fetchByFilter` | `filters` (required, all must match), `locale` (required), `page`, `pagesize`, `sort`, `additionalParams`, optional `remoteProject` | matching entries, mapped to a simpler frontend format |
| `fetchProjectProperties` | `locale` | project properties; needs CaaS Connect version 3 or later |
| `getAvailableLocales` | `projectId`, `navigationServiceURL`, `contentMode` | `Promise<string[]>`, for example `["en_GB", "de_DE"]` |

```ts
fsxaApi.fetchByFilter({
  filters: [{ field: 'fsType', operator: ComparisonQueryOperatorEnum.EQUALS, value: 'Example' }],
  locale: 'en', page: 2, pagesize: 50,
  additionalParams: { keys: { identifier: 0 } },          // omit the key `identifier`
  sort: [{ name: 'fsType', order: 'desc' }],
})
```

- The default sort is by id, descending; several sort entries are allowed and the first has priority. Sorting
  acts on the raw data.
- **Key names in `filters`, `sort` and `additionalParams` are the key names of the raw CaaS document.** Fetch the
  raw document once with the authorization header and `buildCaasUrl()` to read them
  ([caas-connect.md](caas-connect.md) describes the shape).
- Filters use MongoDB operators through enums: `LogicalQueryOperatorEnum` (`AND`, `NOT`, `NOR`, `OR`),
  `ComparisonQueryOperatorEnum` (`EQUALS`, `NOT_EQUALS`, `IN`, `NOT_IN`, `GREATER_THAN`, `GREATER_THAN_EQUALS`,
  `LESS_THAN`, `LESS_THAN_EQUALS`), `EvaluationQueryOperatorEnum.REGEX`, `ArrayQueryOperatorEnum.ALL`. The query
  language itself is in [caas-platform.md](caas-platform.md).

## What the mapper returns for each input component

The library maps the CaaS JSON of every input component to a value your frontend can use. The CaaS side of the
same table is in [caas-connect.md](caas-connect.md); this is the Content API value (README, *Type Mapping*):

| Input component | Content API value |
| --- | --- |
| `FS_CATALOG` | `Section[]` |
| `CMS_INPUT_CHECKBOX`, `CMS_INPUT_LIST` | `Option[]` |
| `CMS_INPUT_COMBOBOX`, `CMS_INPUT_RADIOBUTTON` | `Option` |
| `FS_DATASET` | `Dataset` |
| `FS_INDEX` | `DataEntries[]` |
| `CMS_INPUT_DATE` | JavaScript `Date` |
| `CMS_INPUT_DOM`, `CMS_INPUT_DOMTABLE` | `RichTextElement[]` (parsed from FS-XML) |
| `CMS_INPUT_IMAGEMAP` | `ImageMap` |
| `CMS_INPUT_LINK` | `Link` |
| `CMS_INPUT_NUMBER` | `number` |
| `CMS_INPUT_PERMISSION` | `Permission` |
| `CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA` | `string` |
| `CMS_INPUT_TOGGLE` | `boolean` |
| `FS_REFERENCE` | not specified in the README |

## References into other projects (`remotes`)

Media (`FS_REFERENCE`, `CMS_INPUT_IMAGEMAP`) and datasets (`FS_DATASET`, `FS_INDEX` with the dataset data access
plugin) can live in another project.

```ts
remotes: {
  media1:    { id: '<project-id>', locale: 'en_GB' },
  datasets2: { id: '<project-id>', useSourceLocale: true },
}
```

- The project is read from the reference URL and looked up in `remotes`; only the project id counts, the host,
  tenant and mode in the URL are ignored and requests are built from your own `caasURL`, `tenantID` and mode.
- **The locale is never read from the URL; the application sets it.** Own project, not in `remotes`: the locale
  of the requested element. A configured remote: its `locale`. A remote with `useSourceLocale: true`: the locale
  of the requested element, which stays the same through the whole resolution tree. Anything else: the
  reference stays unresolved and a warning with the project id is logged.
- Every entry needs an `id` and either a `locale` or `useSourceLocale: true`. Entries may share an `id`; the first
  match wins and a warning is logged. An entry may name your own project to force a locale for it. The entry's
  name is what you pass as `remoteProject`.
- **One API key is sent for every project**, so it needs read access to each project in `remotes`.
- One CaaS request per project and locale pair, more only above 30 references.
- Content projections: the datasets of a `Content2Section` are **not** loaded; the section carries only the
  projection's configuration. To load them, configure the project in `remotes` and call `fetchByFilter` with
  filters built from that configuration and the project id as `remoteProject`.

## Extending it: your own aggregation

On the server, `FSXARemoteApi` can call a CaaS aggregation the library has no method for:

```ts
const url = `${remoteApi.buildCaasUrl()}/_aggrs/example`
const response = await fetch(url, { headers: { ...remoteApi.authorizationHeader } })
```

How aggregations are defined and called is in [caas-platform.md](caas-platform.md). Do this on the server only;
`FSXAProxyApi` has no such method.

## Building the frontend around it

These rules hold for any framework. Where the library or the documented services decide the rule, it is said;
the rest is practice (`[verify]`). The official example shows one way to do it (next section); it is an example,
not a specification.

- **Keep the API key on the server.** Use `FSXARemoteApi` server-side and the proxy in the browser, or the secure
  token flow in [caas-platform.md](caas-platform.md).
- **Route by the Navigation Service.** `seoRouteMap[path]` gives the element id, `idMap[id]` the item with its
  `caasDocumentId`; an external link has none and cannot be rendered as a page. Try the path with and without a
  trailing slash `[verify]`. Menus come from `structure`, expanded through `idMap`. →
  [navigation-service.md](navigation-service.md)
- **Pick the component by the section's template.** A section carries its template (`template.uid`); a
  frontend maps that to a component, so the template uid is a contract between template development and the
  frontend `[verify]`. →
  [caas-connect.md](caas-connect.md)
- **Locale spelling differs by place.** The CaaS document has `locale: { identifier, language, country }`; the
  library takes `en_GB`-style strings. Build one from the other in one place `[verify]`.
- **Cache by mode.** Preview shows what editors save, so it should not be cached; release can be `[verify]`. The
  CaaS change stream ([caas-platform.md](caas-platform.md)) is the push channel for invalidation.
- **Preview editing** needs the element ids on the rendered nodes and the TPP script: →
  [preview-and-editing.md](preview-and-editing.md).

## What the official example does

The FirstSpirit PWA template is a Nuxt project (public, Apache-2.0); its `docs/pages` guides were read on
2026-10-19. It is a reference, not a standard: take the idea, check it against your project. Copy what the guides
say, not what you infer from the folder names.

- **Configuration by environment**: the mode (`preview` or `release`), project id, tenant id, CaaS host,
  Navigation Service host (with its `/navigation` endpoint) and API key are server-side settings; the key is a
  read-only key matching the mode (the keys CaaS Connect generates, [caas-connect.md](caas-connect.md)). Optional:
  log level (default 3), maximum depth of nested reference resolution (default 10), the event stream (handles
  `insert`, `replace` and `delete` events; used in preview mode) and a default locale for URLs that do not reveal
  the language (for example `/`).
- **Routing**: a link opens the route through the Navigation Service's `by-seo-route` endpoint; the locale is
  derived from the route. `seoRouteRegex` of the node decides whether the route stands for a content projection
  (filter the datasets whose route matches) or a page reference (`contentReference` is the direct CaaS URL of the
  page reference). A global middleware handles deep links and redirects the index route to the first page. See
  [navigation-service.md](navigation-service.md) for the node fields.
- **Internal links** are rendered from the navigation item, not from a hand-built path.
- **Preview editing**: the TPP script (`snap.js` from the FirstSpirit server, `https://<server>/fs5webedit/snap.js`;
  the guides advise against the CDN copy because the versions can differ) is loaded only in preview mode; the
  client plugin implements the minimum hooks `onRequestPreviewElement`, `onRerenderView` and `onNavigationChange`.
  Elements carry `data-preview-id="#<field>"`, items of a list `#<index>`, and `data-inedit` on editable nodes.
  The hooks and attributes are described in [preview-and-editing.md](preview-and-editing.md).
- **Not covered by the guides**: caching, and how a section is mapped to a component (by template uid or by type);
  those two rules above stay `[verify]`.
