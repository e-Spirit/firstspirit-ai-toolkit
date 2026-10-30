# Connect for Commerce

Sources `[odfs]`, read 2026-10-13: *Guide for server administrators* 26.4.0 (20.08.2026); *Installation guide* (project setup) 26.4.0; the *Troubleshooting* page.
The Connect for Commerce module documentation has the same installation in detail, with its own troubleshooting page. This page is the order and the points that cross other modules.

## Requirements and modules `[odfs]`

Always: `connect-for-commerce-module-<VERSION>.fsm` **and CaaS Connect** (`caas-connect.md`; so a CaaS platform too). With the reference project: BasicWorkflows. Interactive Video: YouTube-DAP-Integration and Interactive-Video. Optional: Navigation Service (`navigation-service.md`). Only the C4C module is in the delivery; the others come from Technical Support. Give every module **All rights**; restart once after installing all of them (and after each update). A **bridge** to the shop system and, unless you build your own front end, the **Frontend API** are separate pieces, not FirstSpirit modules.

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Install the modules above | ServerManager, Server Properties, Modules | folders listed with All rights |
| 2 | Web components on the **ContentCreator** tab: *CaaS Connect Web App*, *FirstSpirit Connect for Commerce - Web Application Component*, and as needed *BasicWorkflows_ContentCreator_Library*, *YouTube DAP Integration - Web App*, *Interactive-Video for ContentCreator*; pick the active web server, Install | Server Properties, Web applications | |
| 3 | The **project**: import the reference project (`fs-connect-reference-project-<VERSION>.tar.gz`, Project, Import) or create your own with Technical Support. The reference project brings the external groups *Editors*, *ChiefEditors*, *ProjectAdmins*, which **work only with an LDAP connection** | ServerManager | |
| 4 | **External preview URL** of the storefront (OCM): `ocm.md`. With OCM 3.0 the project components *CXT ContentCreator: Feature Configuration ProjectApp* and *Preview Configuration ProjectApp* are also needed; the reference project has them preset, change only after talking to Technical Support | Project properties, ContentCreator | |
| 5 | Project component *FirstSpirit Connect for Commerce - Project Configuration*: tabs **General** (ContentCreator extension file only if the Frontend API is not used), **Bridge** (URL, login, *Test bridge connection*), **Reports** (category levels, default 3), **Cache**, **Form Fields**, **ShareView** (JWT secret, the same as in the Frontend API server; close all ContentCreator tabs after changing it) | Project components | the connection test log shows success |
| 6 | Own project only: page templates with UIDs `product` and `category` (others are content pages), hidden text fields `id` and `type` (`type` with a preset), `FS_INDEX` fields on the three Data Access Plugins (Products, Categories, ContentPages) | SiteArchitect | |
| 7 | BasicWorkflows if used: status provider, import of the templates, authorise the workflows per store: `basicworkflows.md` | | |

Saving the **Form Fields** tab creates a CaaS index, even when the names are unchanged; large projects take a while. Renaming the fields means changing the templates, the scripts and the Frontend API configuration too `[odfs]`.
