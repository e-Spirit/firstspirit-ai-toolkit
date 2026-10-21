# FirstSpirit — technical product overview

What FirstSpirit *is*, in technical terms — enough to reason about scope and
route to depth. For the headless platform read `firstspirit-headless`; for the
Access API model read `firstspirit-api-reference`; for templates read
`firstspirit-template-design` / `firstspirit-templating-reference`.

## In one paragraph

FirstSpirit is an **enterprise, hybrid-headless CMS**. It stores content once in
a server-side repository and delivers it
to any channel two ways: **classic** template-based delivery, where the server
*pre-generates* output (HTML or any text format) during a generation run, and
**headless** delivery via **Content as a Service (CaaS)**, where content is
serialised to standardised JSON and read over REST/GraphQL by a decoupled
frontend. Both can run against the same project (hybrid). Content authoring is
visual and in-context; the delivery tier is decoupled from authoring for
performance and failure isolation.

- **Category terms** used on firstspirit.com: "Enterprise CMS"; the AI Suite section
  speaks of "agentic content management".

## Naming & branding

- **Use product names.** **FirstSpirit** is the product name going forward; refer
  to modules and clients by their **product names** (ContentCreator, SiteArchitect,
  ServerManager, CaaS, DQM, …).
- **Default to the product name alone**; mention a company name only where
  necessary. FirstSpirit is published by Crownpeak Technology GmbH, a Rezolve Ai
  company (footer of `firstspirit.com/policies/legal`).
- **Literal doc/host URLs** (`docs.crownpeak.com`, `docs.e-spirit.com`,
  `*.e-spirit.cloud`, `*.e-spirit.hosting`) are technical identifiers and stay
  verbatim — the branding rule governs *prose*, not URLs.

## Version & release model

- **Current release: FirstSpirit 2026.8.** Naming is **calendar-based**
  (`YYYY.N`), shipped on a roughly 4-week cadence. Always confirm the live
  version before quoting version-specific behaviour.
- **History — why legacy names persist.** FirstSpirit used **major.minor**
  versioning until the **5.2** release (**2015**), then abandoned it for the
  time-based `YYYY.N` line. That cutover is *why* **relic naming survives** — in
  licence flags (`fs-license.conf`), class/API names (`WE_API`, `JC_API`,
  `TPP_SNAP`), and still-online docs written for the old line. It's noise
  (especially for Cloud, which is always-latest); see
  [naming-and-aliases.md](naming-and-aliases.md).
- **Support lifecycle differs by hosting.** Cloud is **always latest** on a fixed
  schedule; **self-hosted** has a maintenance window (current + last version
  line). See [hosting-and-deployment.md](hosting-and-deployment.md).
- **API stability:** the **Access API** is the primary Java interface and is
  built for enterprise stability — a deprecated element remains supported for
  **at least six additional releases** (releases, not months). `@Experimental`
  API is provisional. (This matches `firstspirit-api-reference`.)

## The server and the stores

A FirstSpirit **project** lives on a **FirstSpirit server** and is organised into
**stores**. The product's core organising principle is the **separation of
content, layout, and structure** — each store owns one concern (each is a tree of
typed elements, each element with a preview and a release version):

| Store | Holds | Notes |
| --- | --- | --- |
| **Page Store** | Page content (pages, sections, form data) | The editorial content |
| **Data Store** (Content Store / datasources) | Structured, schema-based data (datasets) | Database-backed structured content. The SiteArchitect manual names this the **Data Store**; older/API usage also "Content Store / datasources" |
| **Media Store** | Images, files, and their language/resolution variants | Referenced from pages/templates |
| **Site Store** (structure) | The navigation/URL structure (menu, page references) | Drives routing; source for the Navigation Service |
| **Template Store** | Page/section/format/link templates, GOM forms, rules, workflows | The developer-owned model |
| **Global settings** (Global Store) | Project settings, user settings, URL definitions | Cross-store, project-wide configuration |

> The store object model, interfaces, UID types and agents — and the **canonical
> store names** — are owned by **firstspirit-api-reference** (go there for "what
> interface is a section", "how do I get the PageStore"). This table is
> orientation only; align naming with that skill.

## Preview vs. release (core distinction)

Every element exists twice:

- **Preview** reflects *all* editorial changes immediately — what editors see.
- **Release** data changes *only* through an explicit FirstSpirit **release**
  action (or a schedule that synchronises it). Delivery to the public site/app
  is driven from release data.

This split runs through the whole product: separate CaaS collections
(`*.preview.*` / `*.release.*`), separate generation runs, a preview-only
on-page editing bridge. When advising, **always say which state you mean**.

## The generation / deployment model (classic delivery)

For classic (non-headless) delivery, FirstSpirit follows a **pre-generation**
principle: the server renders output during a **generation process** (a
scheduled or triggered job), producing static files, then **deploys** them out
(to S3/CDN, or via SFTP to a webserver). Rendering load stays on the CMS/staging
side, off the live system. See
[delivery-and-architectures.md](delivery-and-architectures.md).

## Core platform capabilities (feature scope)

Built into the product regardless of licensed modules — enough for scope
decisions; depth is owned by the reference skills, point there.

- **Multi-language.** FirstSpirit separates **editing languages** from **project
  languages**; content is maintained per language within one project. (Translation
  *workflow/automation* is the separate **TranslationStudio** module — see
  [extensions-and-modules.md](extensions-and-modules.md).) Modelling depth →
  `firstspirit-template-design` / `firstspirit-templating-reference`.
- **Multi-user / concurrent editing.** Elements are **locked** on edit so many
  editors work in parallel safely. Lock/save patterns →
  `firstspirit-scripting` / `firstspirit-api-reference`.
- **Versioning, historization & archiving.** Full **version history with
  restore**, historization of changes, and archiving — distinct from the
  preview/release split above.
- **Permissions & workflows.** Role/group-based permissions down to the **object
  level**, plus configurable editorial **workflows** (draft → review → release).
  Recent releases add **language-dependent release** (2026.4) and
  **language-dependent user permissions** (2026.7) — approve/publish and editing
  restrictions per project language.
  In-project permission/workflow depth → `firstspirit-scripting` (PermissionService,
  workflow contexts); Cloud group/identity setup →
  [hosting-and-deployment.md](hosting-and-deployment.md).

## The clients (editing & admin interfaces)

Three clients, plus a preview feature (MPP). **Who works in which is largely
configurable per project via permissions, not fixed** — the mappings below are
the typical defaults.

| Client | What it is | Typical users |
| --- | --- | --- |
| **ContentCreator** | Browser-based in-context client — it *surrounds a live preview* of the page (how it will be generated and deployed), rendered in an **iframe** | Editors / marketers; increasingly template developers |
| **SiteArchitect** | Java desktop "expert" client with full store access | Template developers; advanced / power editors |
| **ServerManager** | Desktop administration client | Project admins **and** server admins (see the split below) |

**ContentCreator — detail:**
- The editable surface is **driven by the template structure** — so *what an editor
  can touch* is a template-design decision (patterns live in
  `firstspirit-template-design`). Editing is bound via an **`editorId`** or an
  **`fs_button`**; where those aren't present, the editor still reaches the page
  and section forms through the **ContentCreator navigation**.
- **Development Tools** (v2026.8) run inside ContentCreator — a browser-based
  **subset** of SiteArchitect development that does not replace it: for quick
  edits (forms/GOM, rules, workflows, output channels, snippets, database
  schema/mappings, default values) plus media management, rendering/profiling log,
  version history, and a graphical workflow designer. **Advanced development still
  needs SiteArchitect.** **Code Assistant** and **DQM Connect** surface here too.
  Delivered as the **Template Development MicroApp** (`fs-sitedev-microapp`) in the
  ContentCreator Extensions (CXT) module list (release notes 2026.8). Needs the
  **CXT-Platform** and is disabled by default: admins enable it on the CXT-Platform
  MicroApp Management page and assign it to external user groups; on Cloud it is
  already set up (installation page). **Not the same as FSDevTools** (`fs-cli`, a
  command-line SDK, https://github.com/e-Spirit/FSDevTools): the Development Tools
  are a micro client inside ContentCreator. →
  `docs.crownpeak.com/template-development-content-creator/`
- **Reports** (right-hand panel) add functionality — **Collaboration** (now a
  released module as of 2026.5 → [extensions-and-modules.md](extensions-and-modules.md),
  depth in `firstspirit-collaboration`), the **Content Assistant** (AI Suite) and
  more; a **custom module** can contribute a report too.
- Full manual: `docs.e-spirit.com/contentcreator/`.

**SiteArchitect & template development:**
- Full template development is in **SiteArchitect**; **ContentCreator's Development
  Tools** cover **quick edits only** (a subset — see above). Working on templates
  via **external sync** (filesystem / Git) is possible, but the actual editing
  typically still happens inside a client.

**ServerManager — two audiences:**
- **Project admins** — project configuration, schedules, permissions, CaaS/OCM
  project setup.
- **Server admins** — server configuration, installing/updating modules,
  connecting external data sources, and more. **Not available to Cloud
  customers** — the managed-service provider owns server administration.
- **ServerMonitoring** — a separate web-based server-monitoring interface for
  admins (`fs5webmon`). Its landing view is the **Health Center** (FirstSpirit
  landscape, server load, active sessions, projects, Update-Checker). **Most
  relevant self-hosted**: on Cloud the managed service adds its own
  monitoring on top, so the built-in Health Center matters more when you run the
  server yourself.

**Multi Perspective Preview (MPP) — a preview feature, not a fourth client:**
- Available by default in ContentCreator. Gives a **time-slider** to view past
  revisions of a page (**classic projects only**) and a **mobile view**;
  behaviour is configurable. Editor docs also describe **device/viewport
  perspectives** (desktop/tablet/phone, rotate, zoom) and a **preview date** for
  seeing time-scheduled content. The MPP timeline has a **history side** (built from
  release revisions) and a **future side** (scheduled pages and sections);
  administrators can swap the timeline implementation (Timeline Markers
  documentation).
- **Personalisation preview is a per-project extension, not standard MPP.** MPP is
  **extensible** via the **`MPP_API`** (a small API for adding custom perspectives —
  toggling logged-in / logged-out views, or a personalisation-segment selector). A
  segment preview is wired per project through a **connector to a third-party
  personalisation engine** (e.g. Kameleoon) — it is *not* a bundled feature, which
  is why personalisation is classified as an **integration**, not an owned module
  (see [extensions-and-modules.md](extensions-and-modules.md#integrations-vs-modules--where-an-integration-lives)).

- **JavaScript client APIs** (in-product previews, *not* headless frontends):
  `top.WE_API` (ContentCreator), `top.JC_API` (SiteArchitect), `top.MPP_API`
  (MPP). They are
  documented at `docs.e-spirit.com/odfs/template-develo/javascript-apis/`. A
  headless frontend uses `TPP_SNAP` instead — see `firstspirit-headless`.
- **Showing an external site** in ContentCreator (e-commerce / PWA) and editing it
  via **OCM** is covered in
  [delivery-and-architectures.md](delivery-and-architectures.md#external-preview--on-page-editing-ocm).

## API & integration surfaces (at a glance)

Enough to route; depth is owned elsewhere.

| Surface | State | What it's for | Owner skill |
| --- | --- | --- | --- |
| **Access API** (Java) | GA, stable | The primary programmatic interface to the object model | `firstspirit-api-reference` |
| **REST API** (`/rest/v1/`) | **Open beta** (current version `0.0.25`, confirmed by the REST skill; docs at `docs.crownpeak.com/restapi/`), updated each release — **not GA**. Module `com.crownpeak.firstspirit.modules:fs-rest-service`. On-premise: request it via a support ticket, download from the Download Portal and install it yourself. SaaS: support ticket; **DEV and QA only, not PROD**, no client downtime | Read/write content in FirstSpirit over HTTP | `firstspirit-rest-api` |
| **CaaS REST + GraphQL** | GA (licensed) | Read delivered JSON from the headless repository (GraphQL is read-only) | `firstspirit-headless` |
| **Change Streams** | GA (licensed) | WebSocket push of content changes (Mongo change-event format) | `firstspirit-headless` |
| **Navigation Service** | GA (licensed) | Site structure as routing JSON | `firstspirit-headless` |
| **Module / FSM SPI** | GA | Package Java as a deployable module (Maven/Gradle, Cloud Artifactory) | `firstspirit-module-development` |

## Certifications & security posture

- **Point to the Governance Center, don't paraphrase.**
  Certifications, data protection, security posture, and compliance statements are
  published at the **Governance Center** (`firstspirit.com/policies/legal`). FirstSpirit is
  listed at the Governance Center with **ISO 27001:2022** and **TISAX** certification (relevant
  for regulated industries — automotive, pharma, financial services, public
  sector), but the **exact scope, version, and wording live at the Governance
  Center** — link it rather than quoting a figure or scope from here.
- **Identity:** Cloud uses **Keycloak** (one realm per customer); enterprise IDP
  integration (LDAP/AD, SAML, OAuth2/OIDC, SSO) is standard. Permissions in the
  Cloud are assigned via **groups**.

## What FirstSpirit is *not* (scope boundaries)

Useful for disqualifying the wrong fit early:

- **Not a commerce platform.** It orchestrates content *around* a shop (documented
  connectors include SAP Commerce Cloud and Salesforce) via **Connect for
  Commerce**; it does not run the shop or own the product catalogue.
- **Not a CRM/CDP.** Content that consumes customer/profile data reads it from the
  customer's own systems; FirstSpirit is not the system of record for that data.
- **Not a low-end / self-serve SaaS CMS.** It targets enterprise content
  complexity — many sites, brands, markets, and channels. A single small site with
  no multi-channel ambition is over-served by it.

---

*Sources: docs.crownpeak.com/firstspirit/first-steps; docs.e-spirit.com (API
overview, CaaS/CaaS Connect, release notes); firstspirit.com.*
