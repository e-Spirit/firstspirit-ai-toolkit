# Navigation Service

Sources `[odfs]`, read 2026-10-13: *Navigation Service: Module Documentation* (5.2.21, 14.07.2026); *Navigation Service documentation* of the endpoint (1.18.13, 15.09.2026; introduction, restrictions, authentication, module chapter).
Using the endpoint from a front end: `firstspirit-headless`.

## Cloud or on-prem

The Navigation Service itself is **SaaS only**; self-hosted instances are not supported `[odfs]`. Installing the module on a self-hosted FirstSpirit server is on-prem work, and so are the technical users below.
The module's **Navigation Client Service** transmits to the endpoint over HTTPS `[odfs]`.

## Requirements `[odfs]`

- The Navigation FirstSpirit module on the server; a licence is an add-on that depends on CaaS (`firstspirit-technical-product-knowledge`).
- A tenant at the endpoint and the endpoint URLs for preview and release (provided by the vendor).
- For on-prem: a technical user per environment (dev, QA, prod) requested from the vendor; access tokens are fetched with OAuth (Client Credentials). The module does this itself once configured.

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Install the module and restart. This adds the service *Navigation Client Service* (started on install) and the project component *Navigation Project Configuration* | ServerManager, Server, Properties, Modules | service running: with it stopped, nothing is transmitted |
| 2 | Add the project component. **Adding it triggers the first creation of the navigation; removing it deletes the project's navigations at the endpoint** | Project properties, Project components | navigation present at the endpoint |
| 3 | Configure it: *SEO Route Url Factory* (default *get from CaaS Connect*, recommended), navigation URLs for release and preview, languages, *Ignore errors* (leave off), *Permissions* (input name and activity) | the component's dialog | |
| 4 | Optional: script `navigation_service_custom_data` (extra fields), toggle `md_navservice_exclude` in the metadata to leave elements out | SiteArchitect | |

The *Content Reference Url Factory* can no longer be set: CaaS Connect's factory is always used `[odfs]`.

## Schedules and updates `[odfs]`

Installing the project component adds the jobs *Navigation Live Generation* and *Navigation Preview Generation* (all active languages; they also delete navigations of languages no longer in the project). Language counts as active when *Generate language* is on. Updates are also triggered by changes to page references, structure folders, the root node, pages that a page reference uses, and the global URL settings; a failed update is retried for more than a day.

## Limits and security `[odfs]`

- A navigation is at most **10 MB** (about 40 000 nodes without permissions and custom data).
- **GET requests are not protected by default**, so preview navigations are public as soon as the component is on. Anything sensitive must stay out of the navigation. Blocking reads (preview or all) is a request to the vendor or the endpoint's `authenticationRequirements` (path prefix such as `/navigation/preview`).
- Writes always need a token; the module handles it.

## Changing who may read or write `[odfs]`

Endpoint documentation 1.18.13, 15.09.2026, chapter *Configuration*.

1. Ask the vendor for a **technical user** per environment (dev, QA, prod). The credentials are an OIDC client (realm, client id `navigation-service-<ENV>-external`, secret). Keep them in the application, never in a browser.
2. Fetch an access token with the **client credentials grant** from the vendor's identity service. Reuse the token until it expires; fetching one per request can get the access blocked.
3. Use the token on the endpoint's authentication configuration (see the OpenAPI) to set `authenticationRequirements`: a list of `url` path prefixes with the HTTP `methods` that need a token.

Default: `/` with POST, PUT, DELETE, and `/config` with all four methods. To protect the preview navigations on read, **add** `/navigation/preview` with GET, POST, PUT, DELETE to the list. Do not replace the list: deleting the default entries switches write protection off.
