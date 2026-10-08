# For later — configuration, installation, and admin

> **Parked, on purpose.** Configuration / installation / admin is a **separate
> audience and a separate documentation source** from developer-facing usage. The
> portfolio has deliberately not built a config/install skill yet (see
> the portfolio's skills index → "Configuration / installation / admin"). This file
> is a **holding pen**: the setup material that surfaced while distilling the
> headless docs, kept out of the usage references so they stay developer-facing,
> and ready to lift into a config/install skill when one is built.
>
> Nothing here is a validated install procedure. Treat every item as a pointer to
> the authoritative admin doc, not as steps to follow. Versions and paths change.

---

## CaaS Platform (deployment / admin)

**Home for all of this:** the
[Operations Guide](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Operations_Guide_EN.html)
(not fetched in depth — retrieve it when building the config skill).

- **Components to deploy:** `caas-rest-api` (RESTHeart-based REST interface) +
  `caas-mongo` (MongoDB). Needs an HTTP/HTTPS endpoint, WebSocket support (change
  streams), and the MongoDB backend.
- **On-prem-only knobs** (not available in SaaS): `pagesize` default/max;
  reference-resolution max depth, per-request reference limit, and enable/disable;
  disabling the automatic `np` parameter; database/collection management
  (create/delete via `PUT`/`DELETE`).
- **SaaS vs on-prem:** database management (create/delete DBs) is not permitted in
  SaaS; binary content is not stored in CaaS buckets in SaaS (served elsewhere via
  the URL factory).
- Helm/Kubernetes/Docker, sizing, backup: expected in the Operations Guide —
  **(UNVERIFIED, not fetched)**.

---

## CaaS Connect (module setup)

Source:
[Server Administrator](https://docs.e-spirit.com/module/caas-connect/CaaS_Connect_ServerAdministrator_EN.html).

- **Requirements:** FirstSpirit ≥ 5.2.260507; network access to the CaaS platform
  (mandatory); optional S3-compatible storage.
- **Install:** install the module on the FirstSpirit server, restart the service;
  optionally install the WebApp component via ServerManager.
- **Service config (`CaaS Connect Service`):** CaaS platform URL, **Master API
  key** (read+write to all CaaS projects), Tenant ID (≤63 chars,
  case-insensitive). File: `./conf/modules/CaasConnect.CaasConnectService/caasConnect.json`
  ```json
  { "baseUrl": "http://localhost:8080",
    "apiKey": "ef27ef88-11c1-4ba0-946c-5c82d2880a18",
    "tenantId": "defaultTenant" }
  ```
  Full config adds `mediaConnectorConfig.S3` (credentials, bucket, CloudFront
  distribution, region).
- **Project activation:** projects must be explicitly marked as CaaS projects —
  nothing syncs automatically after install.
- **Consumer API keys:** read-only and read/write REST keys per state
  (preview/release) and a GraphQL key per state are issued/configured here.
- **Runtime:** connection validated at startup; failures logged without blocking
  editors.
- **Migration (v2 → Connect):** run both modules simultaneously; migrate
  iteratively per project/consumer. Deprecated v2 docs:
  <https://docs.e-spirit.com/module/caas-module/>.

---

## Navigation Service (setup)

- **FirstSpirit side:** install the Navigation FS module; add the **Navigation
  Project Configuration** project component to enable navigation creation
  (removing it deletes the project's navigations).
- **Auth:** Keycloak-based OAuth (Client Credentials Grant) issues write tokens;
  read protection is configured via `authenticationRequirements` with `url`
  path-prefix matching (e.g. protect ids/paths beginning `preview`).
- **Hosting:** the Navigation Service is a hosted cloud service
  (`navigationservice.e-spirit.cloud`); OpenAPI at `/docs/api/swagger.yml`.

---

## OCM / preview (project configuration)

Source: <https://docs.crownpeak.com/firstspirit/ocm/> → "Configuration in
FirstSpirit".

- **Preview URL setup:** ServerManager → project properties → ContentCreator
  settings → point the preview at the external frontend.
- **PreviewRenderingPlugin** selection (e.g. "CaaS Connect Preview Rendering
  Plugin") to generate preview content.
- **Project component:** "CXT ContentCreator: Preview Configuration ProjectApp".
- iFrame / protocol (http vs https) requirements between ContentCreator and the
  preview app; preview configuration for sub-areas.
- **Version requirements** for `TPP_SNAP.enableCaasMode`: CaaS Platform v3.0.3+,
  CaaS Connect v3.4.0+.
- **Migration** from OCM 2.x.

---

## ODFS JavaScript APIs (config)

`WE_API` / `JC_API` are injected by FirstSpirit into its own previews — no
frontend install. `MPP_API` / MPP parameterisation requires an MPP
parameterisation template configured in the project (project config).

---

*Compiled 2026-07-31 from the same doc pass as the usage references. When a
configuration/installation skill is created, this file is its seed — re-verify
every item against the live admin docs first.*
