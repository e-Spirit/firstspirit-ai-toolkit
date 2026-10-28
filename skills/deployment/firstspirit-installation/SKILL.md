---
name: firstspirit-installation
description: Installing FirstSpirit itself (on-premises only) and installing, updating and activating modules and project components on a server and in a project: BasicWorkflows, Development Tools, CaaS Connect, Navigation Service, OCM, AI Suite, Collaboration, SmartSearch, DQM Connect, Multisite Management, VideoManagementPro, Connect for Commerce. Also licence files, ports, Java wrapper, updates and uninstall. Use it for "how do I install the BasicWorkflows module", "release / delete workflow is missing", "which ServerManager step comes first", "Development Tools missing in ContentCreator", "install CaaS Connect", "Navigation Service project component", "OCM 3.0 or the TPP module", "Collaboration needs PostgreSQL", "DQM Connect endpoint", "Multisite Management bundles", "VideoManagementPro setup", "preview is empty in the headless project", "a module left from an older server breaks the client". Covers the order of steps (server, project, permissions), what each step needs and what to check afterwards.
metadata:
  source-commit: "8a9c029"
  published: "2026-10-28"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# Installing modules and activating them in a project

> **Beta.** Built from the product documentation, checked where a tag says so: `[odfs]` product documentation, `[observed]` seen in a
> live run (dated, versioned), `[verify]` not yet checked on a server. Treat a `[verify]` statement as a lead, not a fact.

Installing a module is three separate things, and each can be forgotten:
**server** (the module is installed and the server restarted), **project** (components activated, content imported),
**permissions** (who may use it). This skill gives the order and the check after each step.
Setting up *who may do what* afterwards belongs to `firstspirit-configuration`; menu labels in German and English
are in its `firstspirit-configuration/references/servermanager-labels.md`.

## What is covered

| Topic | Reference |
|---|---|
| FirstSpirit server: install, first login, update, uninstall (on-prem only) | `references/firstspirit-server.md` |
| Licence file and flags (on-prem) | `references/licence.md` |
| BasicWorkflows (release, delete, release with AI review) | `references/basicworkflows.md` |
| Development Tools for ContentCreator (CXT-Platform, MicroApp) | `references/development-tools.md` |
| CaaS Platform: Kubernetes, Helm, scaling, update (on-prem) | `references/caas-platform.md` |
| CaaS Connect (service, project app, media, schedules) | `references/caas-connect.md` |
| Navigation Service (module, project component, security) | `references/navigation-service.md` |
| Omnichannel Manager: OCM 3.0 (no module) and the deprecated TPP module | `references/ocm.md` |
| AI Suite: connecting a model | `references/ai-suite.md` |
| Collaboration (PostgreSQL, Tomcat, web apps, project app) | `references/collaboration.md` |
| SmartSearch server and SmartSearch Connect | `references/smartsearch.md` |
| DQM Connect | `references/dqm-connect.md` |
| Multisite Management (bundles; PostgreSQL, Tomcat, project component) | `references/multisite-management.md` |
| VideoManagementPro | `references/videomanagementpro.md` |
| Connect for Commerce (order; detail in its own skill) | `references/connect-for-commerce.md` |
| External Synchronization (`fs-cli` prerequisites; procedure in `firstspirit-external-sync-export`) | `references/external-synchronization.md` |

**On-prem or Cloud.** Server installation, update and licence are on-prem work. On Cloud the platform service does them and
module install is a Support request; the project-level steps (components, import, permissions) are the customer's on both.

## Where things live

| Question | Goes to |
|---|---|
| Is X licensed, which edition includes it | `firstspirit-technical-product-knowledge` (`firstspirit-technical-product-knowledge/references/editions-and-licensing.md`) |
| Licence flag a module needs, and what to do on-prem | the module's own reference here, and `references/licence.md` |
| Group and permission set-up after install | `firstspirit-configuration` |
| Build your own workflow; a workflow is not offered | `firstspirit-workflow-development` |
| Cloud: server-level install and uninstall | a Support ticket; see `firstspirit-cloud` |

## Rules of thumb

- Installing or updating a module needs a **server restart** `[odfs]`.
- Module install is server-wide; activation and import are per project. A project that "has the module" may still lack all of it.
- Never edit `fs-license.conf`; it invalidates the licence. Changes go through Technical Support `[odfs]`.
- Verify by reading back (the element appears in the list, the workflow shows up in the Template Store), not by the absence of an error.
- A server update does not remove modules of discontinued products, and they may not work with the clients of the new version: the FragmentCreator set (Fragment DAP, Tagging Editor, Markdown Editor; discontinued with 2025.12) is not built for the 2026 releases, and at least one of its modules breaks a client there. With the Markdown Editor still installed, the SiteArchitect GOM form view failed on 5.2.261119 until the module was deactivated `[observed]` (2026-10-26); deactivating took effect without a restart. Deactivate or uninstall such modules after the update. Which products are discontinued: `firstspirit-technical-product-knowledge` (`firstspirit-technical-product-knowledge/references/naming-and-aliases.md`); why a module stops linking: `firstspirit-module-development` (`firstspirit-module-development/references/isolated-mode-and-packaging.md`).

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
