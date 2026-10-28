# Documentation map — topic → doc + owning skill

The pointer index. Given a topic, this gives the **official documentation URL**
and the **owning portfolio skill** (which distils that doc for a specific
audience). Send people to the doc for authoritative depth; use the skill when the
task is one that skill is built for.

**Rule:** point, don't paraphrase. If a portfolio skill owns a topic, route to
it rather than restating its content here.

## Start here

| Doc | Covers |
| --- | --- |
| [FirstSpirit doc index](https://docs.crownpeak.com/overview/?locale=en&main=firstspirit&sub=all) | The full FirstSpirit documentation index — every area (editing, admin, templating, cloud, modules, commerce, search, headless). The master fallback. |
| [Cloud first-steps](https://docs.crownpeak.com/firstspirit/first-steps/) | Cloud onboarding hub: stages, hosting URLs, patch cadence, roles, and the link list to every module doc. |
| [Governance Center](https://www.firstspirit.com/policies/legal/) | Home for governance: licensing terms, SLAs, product addenda, certifications (ISO 27001, TISAX), data protection/compliance. Governance, legal, certification and licensing topics route here — **link it, don't restate it.** |

## By topic

| Topic | Official doc | Owning skill |
| --- | --- | --- |
| **FirstSpirit concept / architecture intro** (stores, separation of content/layout/structure, languages, multi-user, versioning) | [The FirstSpirit concept (SiteArchitect manual)](https://docs.e-spirit.com/odfs/edocs/fsar/introduction/firstspirit-co/index.html) | this skill → `firstspirit-api-reference` |
| **Product overview / API stability** | [FirstSpirit API overview](https://docs.e-spirit.com/odfs/template-develo/firstspirit-api/api-documentati/index.html) | this skill → `firstspirit-api-reference` |
| **Release notes** (per-version: naming, deprecations, new features, requirement changes) | [Release Notes (HTML index)](https://docs.crownpeak.com/firstspirit/releasenotes/) — per-version pages under `…/5.2/<version>/index-2.html`; also [Release Notes (PDF)](https://docs.e-spirit.com/odfs/releasenotes/FirstSpirit_Releasenotes_EN.pdf) | this skill |
| **Feature/area name index** (naming oracle — ~99 current category labels) | [Release-notes Categories](https://docs.crownpeak.com/firstspirit/releasenotes/5.2/release-notes-kategorien/index-2.html) | this skill (naming-and-aliases) |
| **Governance: certifications (ISO 27001, TISAX), licensing terms, SLAs, data protection** | [Governance Center](https://www.firstspirit.com/policies/legal/) — **link, don't restate** | this skill (editions-and-licensing) |
| **License configuration (self-hosted `fs-license.conf` feature flags)** | [License configuration](https://docs.e-spirit.com/odfs/edocs/admi/firstspirit-ser/configuration-f/licence-configu/index.html) | this skill (editions-and-licensing) → config / `firstspirit-cloud` |
| **Hosting / Cloud stages / operations** | [Cloud Development Handover](https://docs.e-spirit.com/cloud/developer-cloud-documentation/Cloud_Development_Handover_EN.html) | this skill (hosting-and-deployment) |
| **Technical requirements & compatible components (self-hosted version matrix)** | [Technical requirements](https://docs.e-spirit.com/odfs/edocs/admi/technical-requi/index.html) · [Compatible components](https://docs.e-spirit.com/odfs/edocs/admi/technical-requi/compatible-comp/index.html) | this skill (decision input) → config / `firstspirit-cloud` |
| **User management / Keycloak / groups** | [Cloud user management](https://docs.crownpeak.com/firstspirit/user-management/) | this skill |
| **Support, tickets, knowledge articles** | [Support portal: FirstSpirit CMS](https://support.rezolve.com/hc/de/categories/24654166553501-FirstSpirit-CMS) | this skill |
| **Reference architectures (index)** | [FirstSpirit reference architectures](https://docs.crownpeak.com/reference-architectures/firstspirit/) | this skill (delivery-and-architectures) |
| **Static delivery architecture** | [Static deployment reference architecture](https://docs.crownpeak.com/reference-architectures/firstspirit/static-deployment/) | this skill (delivery-and-architectures) |
| **rsync deployment** (static output → remote server over SSH; Cloud + self-hosted) | [rsync deployment](https://docs.crownpeak.com/firstspirit/rsync-deployment/) | this skill (hosting-and-deployment) |
| **Headless delivery architecture** | [Headless reference architecture](https://docs.crownpeak.com/reference-architectures/firstspirit/headless/index.html) | this skill → `firstspirit-headless` |
| **Commerce architecture** | [Connect for Commerce reference architecture](https://docs.crownpeak.com/reference-architectures/firstspirit/connect-for-commerce/) | this skill → `firstspirit-headless` |
| **CaaS Platform (REST/GraphQL, change streams, keys)** | [CaaS Platform doc](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Documentation_EN.html) | `firstspirit-headless` |
| **CaaS Connect (sync, `toJson`, preview/release)** | [CaaS Connect doc](https://docs.e-spirit.com/module/caas-connect/CaaS_Connect_FSM_Documentation_EN.html) | `firstspirit-headless` |
| **CaaS product/versions** | [CaaS product doc](https://docs.e-spirit.com/module/caas/CaaS_Product_Documentation_EN.html) | `firstspirit-headless` |
| **Navigation Service** | [Navigation Service module](https://docs.e-spirit.com/module/navigation-service-fsm/Navigation_Service_FSM_Documentation_EN.html) · [REST endpoints](https://navigationservice.e-spirit.cloud/docs/user/en/documentation.html) | `firstspirit-headless` |
| **OCM 3.0 (headless in-context editing; part of ContentCreator, no module)** | [OCM 3.0 doc](https://docs.crownpeak.com/firstspirit/ocm/); the older module, deprecated and kept for existing installs: [OCM / TPP 2.x](https://docs.e-spirit.com/tpp/index.html.en) | `firstspirit-headless`; install: `firstspirit-installation` |
| **ContentCreator (editing client)** | [ContentCreator manual](https://docs.e-spirit.com/contentcreator/index.en.html) | this skill |
| **Editor how-to** (day-to-day ContentCreator tasks: asset management, navigation/search, data-source editing, report integrations, MPP) | ContentCreator manual (above) | not covered by a skill here |
| **Development Tools in ContentCreator** (quick-edit template dev subset; Code Assistant; DQM Connect; install/config) | [Development Tools in ContentCreator](https://docs.crownpeak.com/template-development-content-creator/) | this skill → `firstspirit-template-design` |
| **AI Suite (ContentCreator assistants)** | [AI Suite documentation](https://docs.crownpeak.com/ai-suite/firstspirit-ai-suite/) (older: [AI-powered tools](https://docs.e-spirit.com/contentcreator/ai-powered-tool/index.html)) | this skill (extensions) |
| **DQM Connect (quality checks in FirstSpirit; headless support; verification service)** | [DQM Connect docs](https://docs.crownpeak.com/dqm-connect/) | this skill → `firstspirit-scripting` (quality-gate service) |
| **DQM (standalone product — checkpoints, dashboards, Page/Contrast Checker)** | DQM support articles (Product Overview, Page Checker, Contrast Checker, Dashboards) at `support.rezolve.com` | this skill |
| **Module / FSM development** | [Module Development in the Cloud (PDF)](https://docs.e-spirit.com/cloud/module-development/Module_Development_FirstSpirit_Guide_EN.pdf) | `firstspirit-module-development` |
| **External Synchronization** (`fs-cli` / FSDevTools; Git dev workflow, CI) | [External Synchronization docs](https://docs.e-spirit.com/odfs/edocs/sync/index.en.html) | this skill → `firstspirit-external-sync-export` |
| **BasicWorkflows** (free release/delete workflows; open source) | [BasicWorkflows docs](https://docs.e-spirit.com/module/basicworkflows/BasicWorkflows_Documentation_EN.html) | this skill → `firstspirit-scripting` |
| **Multisite Management / CorporateContent** (ContentTransport + package distribution) | [CorporateContent doc (PDF, V5.2, DE)](https://docs.e-spirit.com/odfs/dokumentation/module/entwickler/CONT_DE_FirstSpirit_CorporateContent.pdf) | this skill → `firstspirit-scripting` (package-event workflows) |
| **Multisite Management, current (bundles; installation guide)** | [Installation guide](https://docs.crownpeak.com/multisite-management/installation-guide/) | `firstspirit-installation` |
| **CaaS Platform operations (Kubernetes, Helm)** | [Operations Guide](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Operations_Guide_EN.html) · [Product documentation](https://docs.e-spirit.com/module/caas-platform/CaaS_Platform_Product_Documentation_EN.html) | `firstspirit-installation` |
| **CaaS Connect, server administrator** | [Server Administrator](https://docs.e-spirit.com/module/caas-connect/CaaS_Connect_ServerAdministrator_EN.html) | `firstspirit-installation` |
| **Collaboration installation** | [Installation guide](https://docs.crownpeak.com/firstspirit/collaboration/installation-guide/) | `firstspirit-installation` |
| **AI Suite: connecting a model** | [Connecting a model and vendor](https://docs.crownpeak.com/ai-suite/configuring-the-ai-suite/connecting-a-model-and-vendor/) | `firstspirit-ai-suite` |
| **SmartSearch (server, Connect, smartsearch.js)** | [SmartSearch documentation](https://docs.e-spirit.com/delivery_modules/smart_search/SmartSearch_Documentation_EN.html) · [Admin Manual](https://docs.e-spirit.com/delivery_modules/smart_search/SmartSearch_Admin-Manual_EN.html) · [Connect](https://docs.e-spirit.com/module/smartsearch-connect/SmartSearch_Connect_Documentation_EN.html) | `firstspirit-smartsearch` |
| **DQM Connect administration** | [Administration and configuration](https://docs.crownpeak.com/dqm-connect/administration-and-configuration/) | `firstspirit-installation` |
| **VideoManagementPro** | [Documentation](https://docs.e-spirit.com/module/videomanagementpro/VideoManagementPro_Documentation_EN.html) · [Server administrator](https://docs.e-spirit.com/module/videomanagementpro/VideoManagementPro_ServerAdministrator_EN.html) | `firstspirit-installation` |
| **Connect for Commerce (getting started, administrator, troubleshooting)** | [Getting Started](https://docs.e-spirit.com/ecom/fsconnect-com/FirstSpirit_Connect_for_Commerce_Getting_Started_EN.html) · [Server admin](https://docs.e-spirit.com/ecom/fsconnect-com/FirstSpirit_Connect_for_Commerce_ServeradminManual_EN.html) · [Troubleshooting](https://docs.e-spirit.com/ecom/fsconnect-com/FirstSpirit_Connect_for_Commerce_Troubleshooting_EN.html) | the Connect for Commerce documentation |
| **Partner modules (not ours)** translationstudio, Formcentric | [translationstudio](https://documentation.translationstudio.tech/firstspirit/) · [Formcentric](https://help.formcentric.com/en/firstspirit/) | the partner's own manual; `firstspirit-installation` has an overview |
| **Template development (design/judgement)** | ODFS templating docs (via the doc index) | `firstspirit-template-design` |
| **Template language & GOM syntax** | ODFS templating docs (via the doc index) | `firstspirit-templating-reference` |
| **BeanShell scripting / workflows** | ODFS scripting docs (via the doc index) | `firstspirit-scripting` |
| **Java Access API object model** | [FirstSpirit API overview](https://docs.e-spirit.com/odfs/template-develo/firstspirit-api/api-documentati/index.html) | `firstspirit-api-reference` |
| **JavaScript client APIs** (`WE_API` / `JC_API` / `MPP_API`) | [JavaScript APIs](https://docs.e-spirit.com/odfs/template-develo/javascript-apis/index.html) | this skill / `firstspirit-scripting` |
| **FirstSpirit REST API** (beta) | [REST API documentation](https://docs.crownpeak.com/restapi/) | `firstspirit-rest-api` |
| **Collaboration comments** | Collaboration API docs | `firstspirit-collaboration` |

## Notes on the doc estate

- **Two hostnames.** Docs live under both **`docs.crownpeak.com`** (newer Cloud /
  reference-architecture / first-steps content) and **`docs.e-spirit.com`**
  (module docs, ODFS templating/API, TPP, release notes). `crownpeak.com/firstspirit`
  marketing URLs 301-redirect to `firstspirit.com`.
- **ODFS** = the Online Documentation FirstSpirit (the templating/developer
  manual). Much template/scripting/API detail lives there.
- **Version drift.** Module docs cite component versions (e.g. CaaS Platform
  v16.18.2, CaaS Connect v3.32.3) and FirstSpirit 2026.8 — always confirm against
  the live version before quoting version-specific behaviour.

---

*Sources: the URLs listed above, gathered 2026-07-31.*
