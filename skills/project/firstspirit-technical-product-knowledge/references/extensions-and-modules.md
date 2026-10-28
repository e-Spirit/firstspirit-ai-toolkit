# Extensions & modules — decision catalogue

Decision 3 of the four: **which premium module or extension a requirement
needs.** Licensing is covered in
[editions-and-licensing.md](editions-and-licensing.md); the "Depends on" column
names the licence features and subscriptions the documentation states. This
catalogue is for *choosing*; the build depth lives in the owning skill/doc named
per row.

**How to use:** match the requirement to the "solves" column, check the
"depends on" column (some modules require others — CaaS underpins the headless
family), then route to the owner for the how.

## At a glance

| Module / extension | Solves | Depends on | Depth: skill / doc |
| --- | --- | --- | --- |
| **AI Suite** | GenAI help for editors inside ContentCreator | ContentCreator; an LLM (OpenAI / AzureAI / AWS Bedrock, or BYO); a valid AI Suite licence | ContentCreator AI-tools doc |
| **Collaboration** | Comment threads on editorial elements in ContentCreator (with optional AI-agent participants) | ContentCreator; AI-agent replies need a suitable licence (AI Suite customer) and FirstSpirit AI configured | `firstspirit-collaboration` |
| **CaaS Platform** | Headless content repository (JSON over REST/GraphQL) | — (the base of headless) | `firstspirit-headless` |
| **CaaS Connect** | Syncs FirstSpirit content → CaaS as JSON | CaaS Platform; needs a valid CaaS licence | `firstspirit-headless` |
| **Navigation Service** | Site structure as routing JSON for headless apps | CaaS licence | `firstspirit-headless` |
| **Omnichannel Manager (OCM/TPP)** | In-context WYSIWYG editing of an external/headless frontend | ContentCreator + the external app (2.x module: also CaaS) | `firstspirit-headless` |
| **SmartSearch** | Site search-as-a-service (facets, autocomplete, synonyms) | Own credentials/endpoints; valid licence | first-steps + SmartSearch doc |
| **DQM** + **DQM Connect** | Accessibility / SEO / content-quality / brand scanning (standalone product; **DQM Connect** integrates it into FirstSpirit, classic or headless) | DQM SaaS subscription (valid licence); DQM Connect module + endpoint (website ID + API key) | `dqm-connect/` doc |
| **TranslationStudio** | Translation/localisation workflows + TMS connectors | valid licence | first-steps + TranslationStudio doc |
| **Connect for Commerce** | Content around a commerce catalogue (Bridge API) | A commerce backend; valid licence | reference-architecture + connector repos |
| **Multisite Management** (ContentTransport + Corporate Content) | Move content/templates across projects — portable ZIP promotion (cross-server, DQP) or versioned package/subscription distribution (same-server, master→targets) | `license.PACKAGEPOOL=1` + PackageManager service | CorporateContent doc |
| **Formcentric Webforms** | Editorial form builder | valid licence | Formcentric doc |
| **VideoManagementPro** | Video content integration | — | VideoManagementPro doc |
| **External Synchronization** (`fs-cli` / FSDevTools) | Export templates + deps to filesystem for Git / IDE / CI (dev artefacts only — not mass data, not editorial content) | API-Access license; Git | `firstspirit-external-sync-export`, `firstspirit-cloud` |
| **Data Access Plug-Ins** | Java extensions (`DataAccessPlugin<D>`) that connect external data to FirstSpirit's data access functionality; optional aspects make them usable as a **report** in SiteArchitect and ContentCreator (item actions, access control, reference reporting) | Plug-in development (Java) | [Data Access Plug-Ins](https://docs.e-spirit.com/odfs/plug-developmen/universal-exten/data-access/data-access-plu/index.html), [javadoc `client.plugin.dataaccess`](https://docs.e-spirit.com/odfs/access/de/espirit/firstspirit/client/plugin/dataaccess/package-summary.html); `firstspirit-module-development` |
| **BasicWorkflows** | Ready-made dependency-aware **release** & **delete** workflows | `license.WORKFLOW=1` (BasicWorkflows documentation); Cloud pre-installed | GitHub + `basicworkflows/` doc |

> Spelling note: the live firstspirit.com site uses **"Multisite Management"**
> (one word) and **"AI Suite"** (also seen as "AI Assistant Suite"; prefer
> "AI Suite").

## Cloud vs. self-hosted availability

**Most extensions are available in both** — the usual difference is *provisioning*,
not availability: **Cloud** = no module installation by the customer, Crownpeak provisions the environment and manages the server properties (Cloud vs. Self-Hosted page); **self-hosted** = you install
the module and it's gated by an `fs-license.conf` flag (see
[editions-and-licensing.md](editions-and-licensing.md)). `✓` cells for the services the Cloud first-steps page lists as licensed come from that page; cells marked **(verify)** are not documented there, so check the current
Cloud service catalogue.

| Extension | Cloud | Self-hosted | Note |
| --- | --- | --- | --- |
| Core CMS (ContentCreator, SiteArchitect, delivery) | ✓ | ✓ | Base |
| AI Suite | ✓ | ✓ | licensed service (Cloud first-steps) |
| Collaboration | ✓ (preconfigured; activate per project) | ✓ | released with 2026.5; AI-agent replies need a suitable licence and FirstSpirit AI |
| CaaS Platform + CaaS Connect | ✓ | ✓ | licensed service (Cloud first-steps) |
| Navigation Service | ✓ | Cloud service; use with a self-hosted FirstSpirit is arranged with Sales or the CSM | needs CaaS |
| OCM / TPP | ✓ | ✓ | headless stack |
| SmartSearch | ✓ | ✓ | own credentials |
| DQM + DQM Connect | ✓ | ✓ | DQM SaaS behind both; on Cloud, Crownpeak support installs DQM Connect on request |
| TranslationStudio | ✓ | ✓ | licensed service (Cloud first-steps) |
| Formcentric Webforms | ✓ | ✓ | licensed service (Cloud first-steps) |
| Connect for Commerce | ✓ | ✓ | licensed service (Cloud first-steps) |
| Development Tools (ContentCreator) | ✓ (pre-configured) | ✓ (install `.fsm`) | needs CXT-Platform |
| BasicWorkflows | ✓ (pre-installed; activate per project) | ✓ (install `.fsm`) | open source |
| Multisite Management (ContentTransport / Corporate Content) | (verify) | ✓ | `license.PACKAGEPOOL` |
| External Synchronization (`fs-cli`) | (verify) | ✓ | Cloud development uses Git-based template transport; how External Synchronization maps to it is not documented in the first-steps doc |
| Custom modules (FSM) | (verify — via provider pipeline) | ✓ | Cloud deploy via the Cloud Artifactory/CI |
| **Server administration** (install modules, connect datasources, licence file) | ✗ provider only | ✓ | **the key structural difference** |

**Not module-by-module:**
- **Server administration** — installing/updating modules, connecting external
  data sources, editing the licence file — is **self-hosted only**; in Cloud the
  provider does it.
- **Licence provisioning** differs (Cloud packaged; self-hosted `fs-license.conf`)
  — see [editions-and-licensing.md](editions-and-licensing.md).
- **Services the Cloud first-steps page lists as licensed:** AI Suite,
  CaaS Connect, Navigation Service, SmartSearch, DQM, TranslationStudio,
  Formcentric, Connect for Commerce.

## The entries

### AI Suite
GenAI assistants embedded in **ContentCreator**, built on large language models.
Assistants (docs, v2026.8): **Content Assistant** (draft/edit/optimise
copy, delegate repetitive tasks), **Analyze Assistant** (analyse a whole page and
apply suggested fixes in bulk), **Image Assistant** (object detection, smart
crop, tagging, alt-text), **Code Assistant** (in ContentCreator's Development
Tools: inline autocompletion + Emmet for HTML/CSS, plus a **prompt-configurable**
AI analysis of HTML/JS/CSS surfaced as a report — improvement dimensions are set
by an **editable prompt**, not fixed). firstspirit.com also names **Prompt
Management** (govern/reuse prompts per user/group/project) and an **Assistant
API** for calling a custom model from templates; the ContentCreator AI-tools
doc does not describe them, so check the AI Suite documentation. The suite is licensed as a whole: every assistant and the API are included, with later enhancements. Assistants differ in how they are installed, configured and enabled; follow the AI Suite documentation per assistant. Native LLM integrations: **OpenAI, AzureAI, AWS Bedrock**, or BYO-LLM.
- **Why it matters:** productivity with governance — curated prompts, transparent
  output, nothing goes live without editor approval, and the LLM can be the
  customer's own contracted model.
- **Depth:** setup, prompt configuration, the AI API (scripting, function
  calling) and plugins: `firstspirit-ai-suite`. Docs:
  [AI Suite documentation](https://docs.crownpeak.com/ai-suite/firstspirit-ai-suite/) (current) and
  `docs.e-spirit.com/contentcreator/ai-powered-tool/` (older).
- **MCP:** the **Analyze Assistant** supports **MCP function servers** (2026.5), so
  the assistants can call external tools and data via MCP. Verify specifics in the
  AI Suite documentation when scoping.

### Collaboration
Comment threads on editorial elements (pages, sections, datasets, specific
editors) **inside ContentCreator**. Shipped as the `fs-collaboration` module;
**released 2026.5** (no longer beta; beta from 2025.13). A **Collaboration API** lets
developers create/read/update/archive threads from code, and threads can include
**AI-agent participants** (function-calling) — the AI-agent path needs FirstSpirit
AI configured.
- **Why it matters:** in-context editorial review/approval discussion without
  leaving the editor, and a way to deliver analysis results to editors.
- **Depth:** `firstspirit-collaboration` (the Java API + DTOs). Surfaces in the
  ContentCreator **Reports** panel (see [product-overview.md](product-overview.md)).

### CaaS Platform + CaaS Connect (the headless base)
**CaaS Platform** is the MongoDB-backed content repository exposing **REST +
GraphQL** (GraphQL read-only). **CaaS Connect** (successor to the deprecated
legacy CaaS module v2) serialises FirstSpirit content to **standardised JSON**
via `toJson` and syncs it in near-real-time (Smart Sync / Total Sync / manual);
JSON output is fixed — **customisation is prohibited** (you change the *model*,
not an output channel). Auto-generates read-only and read-write API keys.
- **Hosting:** the CaaS Platform is a hosted service; customers with an on-premise
  FirstSpirit can use it too. Running it yourself is possible (Operations Guide:
  Kubernetes, Helm) but is the exception.
- **Depends on:** each other; CaaS is the base the rest of the headless family
  needs. **CaaS is not covered by the FirstSpirit backup**: in the SaaS environment it is backed up periodically (confirm scope with the CSM); a self-operated CaaS needs its own backup.
- **Depth:** `firstspirit-headless`.

### Navigation Service
Transfers the **Site Store** structure into JSON exposed over REST, so a headless
frontend can resolve routes (`idMap` / `seoRouteMap`). Server component
(Navigation Client Service) + project component (Navigation Project
Configuration). **Requires a CaaS licence.** It is offered as a Cloud service; for a
self-hosted FirstSpirit, ask Sales or the CSM whether and how it can be used.
- **Depth:** `firstspirit-headless`.

### Omnichannel Manager (OCM) / ThirdPartyPreview (TPP)
Brings an external application's frontend **into ContentCreator** for in-context WYSIWYG
editing (partial/dynamic reload, parallel editing of content areas). This is how headless
projects keep editor in-context editing.
- **Version:** **OCM 3.0** is part of ContentCreator: **no module to install** and no
  dependency on CaaS (the preview is rendered by the templates unless a
  PreviewRenderingPlugin is configured) `[odfs]`. The **2.x module** `fs-tpp-<version>.fsm`
  (with its ThirdPartyPreview web component and a CaaS dependency) is deprecated but may
  still run in older projects. New installs: OCM 3.0 (`firstspirit-installation`,
  `firstspirit-installation/references/ocm.md`).
- **Depends on:** FirstSpirit (ContentCreator) + the external app; CaaS is the usual content source.
- **Depth:** `firstspirit-headless` (OCM/TPP/SNAP, `data-preview-id`).

### SmartSearch
Search-as-a-service (Launch-Pad, Cockpit UI, API-GW endpoints; `SmartSearch.js`
+ a SmartSearch REST API). Autocomplete, search-as-you-type, facets,
did-you-mean, multi-language; editors own weighting/synonyms/boosting via UI.
Crawls sources inside and outside the CMS. **Separate credentials.**
- **Depth:** building, indexing, querying and running it (server, smartsearch.js,
  SmartSearch Connect): `firstspirit-smartsearch`.

### Digital Quality Management (DQM) & DQM Connect
**DQM is a standalone SaaS product** — a **CMS-agnostic** quality platform that
crawls any reachable website and analyses its content and code. It is not a
FirstSpirit sub-feature.
- **What it checks — "checkpoint" categories:** Accessibility, Branding, Editorial
  (content), Legal, SEO, Site integrity (e.g. broken links), Spell checking,
  Usability. A Checkpoint Library plus custom checkpoints; any can be a **priority
  checkpoint**. Automated scanning covers HTML/JS pages and assets (images, PDFs).
- **Tools:** **Dashboards** (a grouping of pages), **Page Checker** (browser bookmarklet;
  on-demand, works pre-publish, no login), **Contrast Checker** (WCAG 2 **AA**
  default / **AAA** optional). Group- and website-level reporting, CSV export.
- **Accessibility standards:** the product docs name **WCAG** (WCAG 2 AA/AAA in the
  Contrast Checker); they do not name ADA, Section 508 or EAA. **Core Web Vitals:**
  only **LCP** is addressed (image-size checkpoints); FID and CLS are not covered.
- **Users:** Managers (group analytics/benchmarking), Admins (users/groups/
  checkpoint config), editors (resolve issues).

**DQM Connect** is the **FirstSpirit integration module** (documented v2026.8) —
it runs DQM checks against the page an editor is on and guides the fixes.
- **Where it surfaces:** a **Report panel / DQM dashboard in ContentCreator** (+ a
  Report button in SiteArchitect; the standalone dashboard view is
  ContentCreator-only). Issues highlighted in page view and source view. In
  **ContentCreator's Development Tools** it ties findings to the **template
  source** (reference name + line, click-to-navigate, hover explanation) — **not**
  available for media, database schemas/queries, table-format templates, or
  scripts; the template analysis is DQM-Connect-license-gated.
- **Setup:** self-hosted admins install the `.fsm` from customer support; on Cloud,
  Crownpeak support installs and configures it. Either way Support provides the DQM
  Website ID and API key, entered as an endpoint in the DQM Connector service; the
  DQM Integration web app and the per-project DQM Connect ProjectApp must be added
  (DQM Connect administration and configuration docs).
- **Two integration paths:** *classic* — the server renders the page and checks it
  automatically (no frontend code); *headless / CaaS* — a **JS "DQM Headless
  Connector"** (script tag or NPM) in the frontend pushes rendered content back;
  call `refreshDqmReport()` on load. **The headless connector is preview/dev
  only.**
- **For developers:** a **`DQMConnectorVerificationService`** lets scripts and
  **workflows enforce quality gates** (e.g. halt a release when a category fails).
  **Only Page / PageRef elements.** Depth → `firstspirit-scripting` /
  `firstspirit-module-development`.
- **Setup / license:** `.fsm` installed in ServerManager (service + autostart);
  **endpoints = website ID + API key from support**; ContentCreator web app + a
  per-project **ProjectApp**. Requires a
  **DQM (SaaS) subscription** behind the API keys.
- **Why it matters:** makes accessibility/SEO/quality compliance part of the
  editorial process (and a release gate).
- **Docs:** `docs.crownpeak.com/dqm-connect/` (Connect); the DQM product support
  articles (Product Overview, Page Checker, Contrast Checker, Dashboards).

### TranslationStudio
Translation-management module. Translate a section, page, or
many pages via AI/ML, via a **TMS** (connectors
named on firstspirit.com include Across, Trados, XTM), or via manual workflows;
synchronous and asynchronous integrations.

### Connect for Commerce
Shop-agnostic connector integrating a commerce backend with FirstSpirit via a
**Bridge API** (Frontend API + Bridge API). Makes products/categories/catalogue
data visible in ContentCreator so editors build teasers/campaigns against the
real catalogue — **content-led commerce without a parallel product database**.
Documented connectors: SAP Commerce Cloud, SAP Commerce Cloud (Headless),
Salesforce; reference connectors on GitHub (`e-Spirit/fcecom-*`).
- **Depth:** module, Bridge, Frontend API and the reference implementations →
  the Connect for Commerce documentation.

### Multisite Management — ContentTransport & Corporate Content
Cross-project content movement. Per the CorporateContent developer doc,
**Multisite Management** is the umbrella for **two mechanisms** that share the
same underlying tech (assemble content from **"start nodes"** with automatic
dependency-graph resolution) but are **used differently**. Per that doc, both are
gated by `license.PACKAGEPOOL=1` and need the **PackageManager
service** running.

- **ContentTransport** — assembles chosen content **+ templates + project
  properties** into a **"Feature"**, saved as a portable **ZIP archive** and
  imported into other projects — **across server boundaries**, from a **fixed
  project revision** (point-in-time snapshot). Repeatable/automatable (schedule +
  API). Classic use: **DEV → QA → PROD promotion** ("DQP"). No subscriptions.
- **Corporate Content** (package/subscription distribution; successor to
  "package management") — distributes templates/content between projects **on the
  same server** via living, **versioned packages** that target projects
  **subscribe** to. **Master → target**; **push** (master admin publishes to all
  subscribers) or **pull** (target admin updates on demand); **publishing groups**
  (e.g. Dev/Test/Prod) stage rollout. Target content can be **read-only or
  editable** (master vs. local), with conflict handling (overwrite / copy).
  Package **events** can trigger a **workflow/script** on import (release,
  conflict resolution, reporting). Content packages (Content/Site/Media) vs.
  template packages (Template store) — each object in **one** package only.
- **They complement each other:** template packages move **templates**; to also
  move editorially-maintained **content / metadata / project settings**, use
  **ContentTransport**.
- **Restrictions (orientation):** **permissions and workflow states are not
  transported**; objects locked for editing can't be imported; **don't delete a
  package master project** (subscriptions are lost). Full matrix in the doc.
- **Why it matters:** eliminates redundant editorial work across a multi-brand /
  multi-market portfolio while keeping brand consistency.
- **Distinct from** External Synchronization (dev artefacts + VCS) and **remote
  projects** (referencing another project's content). Workflow/script depth →
  `firstspirit-scripting`. The CorporateContent doc is **V5.2**; the current
  module naming is in the installation guide below.
- **Bundles API:** a **Bundles API** (`BundleAgent`) was added in 2026.6, with
  **asynchronous bundle rollout** (`deployBundle` / `getDeployment`) in 2026.8.

- **2026.11 installation guide (verified 2026-10-13):** the current module is a **microapp** with its
  own **PostgreSQL** database, needing **FirstSpirit 2026.6 or higher**, Tomcat 10.1.11+ and a
  configured CXT-Platform; it works with **bundles** from a source project with chosen target
  projects (project component *Bundle management*). That guide does not mention
  `license.PACKAGEPOOL` or the PackageManager service, so how the older package-based Corporate
  Content above relates to it, and which licence flag applies, is `[verify]`. Install:
  `firstspirit-installation` (`firstspirit-installation/references/multisite-management.md`).

### Formcentric Webforms, VideoManagementPro
- **Formcentric Webforms** — editorial form builder (formerly "Monday").
- **VideoManagementPro** — integrates **VideoManager Pro from movingimage**: the videos stay
  there and are referenced from a report in both clients and embedded via embed codes. Needs a
  licence with the **AppCenter** on (`license.APPTAB_SLOTS`), a technical movingimage user, and
  **does not work with the external preview** (so not with OCM or headless previews) `[odfs]`.
  Install: `firstspirit-installation` (`firstspirit-installation/references/videomanagementpro.md`).

### External Synchronization (FSDevTools / `fs-cli`)
Exports a project's **templates and their dependent elements** to a **filesystem**
representation (readable XML/JSP) for **version control**, external/IDE editing,
and CI; re-importing brings changes back. Tool: **FSDevTools**, run as **`fs-cli`**
(export/import, automatable for CI; open source). Requires the **API-Access
license feature**.
- **Two scenarios:** *external editing* — develop templates/assets in an **IDE**,
  export/import via `fs-cli`; *distributed editing* — multiple developers each on
  a **local FirstSpirit server**, sharing changes through **Git** as the hub.
- **Restrictions (decide with these in mind):** **development artefacts only** —
  **not** mass data (datasets / DB content); **not** for editorial content
  distribution (that is **ContentTransport**); **Git is the recommended VCS**
  (others untested); **all environments must share identical project structure /
  settings** (e.g. language counts) or imports conflict; there is **no built-in
  merge / concurrency** — conflict handling is the VCS's job.
- **Role & routing:** it's the mechanism behind **Cloud Git-based template
  development** (see [hosting-and-deployment.md](hosting-and-deployment.md));
  running the export and import → `firstspirit-external-sync-export`; Cloud
  specifics → `firstspirit-cloud`. **Remote projects** (distinct feature) let one
  project reference another's content.
- Doc: `docs.e-spirit.com/odfs/edocs/sync/`.

### BasicWorkflows
A **maintained, open-source** module providing ready-made standard
editorial workflows, so projects don't reimplement them (public GitHub repository, https://github.com/e-Spirit/basicworkflows, Apache-2.0).
- **What it provides:** a **Release** workflow and a **Delete** workflow, both
  **dependency-aware** (release/delete an element together with what it needs, to
  avoid generation errors / broken references). Work across **SiteArchitect and
  ContentCreator** over media, datasets, pages, page references, document groups,
  folders, and global pages/settings (scope varies by client). Version 1.5.4
  (2025-12); FirstSpirit **2022.3+**, Java 17.
- **Cloud:** the module is **pre-installed on all Cloud servers**; the customer
  **activates it per project** (import the workflows, set permissions). The licence-flag
  restriction below does not apply in Cloud.
- **Self-hosted:** install the `.fsm` (ServerManager → Modules), then activate per
  project. The general workflow feature must be enabled — see the licence note.
- **Licence note:** the **`license.WORKFLOW`** flag gates the **general
  custom-workflow feature** (self-hosted; with 0 only the "Assign task" and "Request
  release" workflows exist, licence-configuration page); the BasicWorkflows
  documentation states that creating and running workflows needs `license.WORKFLOW=1`.
  See [editions-and-licensing.md](editions-and-licensing.md).
- **Depth:** workflow scripting → `firstspirit-scripting`. Doc:
  `docs.e-spirit.com/module/basicworkflows/`; source on **public GitHub**.

## Integrations vs. modules — where an integration lives

Not every "extension" in this catalogue is a licensed module you install. An
**integration** is any point where FirstSpirit reaches an outside system, and the
classification rule is ownership: **own the product behind it → catalogue the
product** (DQM, SmartSearch, CaaS — the "Connect" is plumbing); **don't own it →
it's an integration** (see [naming-and-aliases.md](naming-and-aliases.md), "own it
→ product; don't → integration"). **Personalisation is the textbook integration**
— delivered via a **per-project connector to a third-party engine** (e.g.
Kameleoon), *not* a bundled FirstSpirit module (see the MPP note in
[product-overview.md](product-overview.md)).

Integrations surface at **six touchpoints** an editor meets (orientation only — the
extension points behind each are **`firstspirit-module-development`** territory,
route there for the how):

| Touchpoint | What it does | Editor sees |
| --- | --- | --- |
| **Report sidebar** | Streams repository or external data into a searchable panel | An icon in the ContentCreator report rail (e.g. a YouTube/video report) |
| **Form field** | Search-and-pick a record from an external system, or a button that runs an action | A pick list or button inside an editing form |
| **Workflow step** | Calls an external system as content moves through review/release | A workflow action button |
| **Asset / upload** | A DAM/asset connector, or logic on upload | An external-media picker; automatic handling on upload |
| **AI function** | The AI Suite calls registered functions against external systems mid-generation | Generate/translate/summarise reaching live project data |
| **Background task/service** | Scheduled sync or always-on service, no editor present | Only the *result* — fresh datasets, imported media |

> The extension-point names behind each touchpoint are not listed here; see
> `firstspirit-module-development`.

## Deciding — worked pattern

> "We're building a React storefront with editor-managed campaign content."
>
> Headless delivery (decision 2) → needs **CaaS Platform + CaaS Connect** and the
> **Navigation Service** (routing), **OCM/TPP** so editors keep in-context
> editing, and **Connect for Commerce** for the catalogue. Route the build to `firstspirit-headless` (`fsxa-api` is covered there too) and the Connect-for-Commerce reference architecture.

---

*Sources: docs.crownpeak.com/firstspirit/first-steps; docs.crownpeak.com/overview
(FirstSpirit doc index); docs.e-spirit.com (CaaS, CaaS Connect, Navigation
Service, TPP, ContentCreator AI tools); firstspirit.com (product names/offerings).*
