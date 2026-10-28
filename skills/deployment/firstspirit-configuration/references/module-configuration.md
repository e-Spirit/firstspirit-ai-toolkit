# Module configuration in a project

Sources: each module's vendor documentation (`firstspirit-installation` names the pages and versions per module) `[odfs]`, read 2026-10-13. Not yet verified on a server.
Installation (module on the server, web components, restart) is `firstspirit-installation`; this page is what a project administrator **sets and keeps right afterwards**: the project component, its options, who may use it, and the schedules it adds.
Labels are the English ServerManager ones: Project properties, *Project components* (Add, Configure) and *Web components*; German names in `servermanager-labels.md`.

## Project components at a glance `[odfs]`

| Module | Project component | What you configure | Adds | Who may use it |
|---|---|---|---|---|
| BasicWorkflows | *BasicWorkflows Configuration* (1.6.0 and later, optional) | Import Workflows; show AI review report | the workflows and scripts | Authorise per store (`workflows.md`) |
| Development Tools (ContentCreator) | none (a MicroApp) | enable in the CXT-Platform *MicroApp Management* page | | **external** groups only, chosen there |
| CaaS Connect | *CaaS Connect project app* | URL factory (default *Advanced URLs*), remote datasets, `CaaS` tags on resolutions | collections, API keys, four sync schedules | API keys: preview and release, read-only and read/write, plus GraphQL |
| Navigation Service | *Navigation Project Configuration* | SEO route URL factory, languages, permissions input, *Ignore errors* (off) | two generation jobs | reads are public by default |
| OCM 3.0 | *CXT ContentCreator: Preview Configuration ProjectApp* (and *Feature Configuration ProjectApp*) | PreviewRenderingPlugin, extra preview applications per folder | | |
| Collaboration | *FirstSpirit Collaboration \| ProjectApp* | none | | project users |
| DQM Connect | *DQM Connect ProjectApp* | the endpoint (website ID) | | |
| SmartSearch Connect | *SmartSearch Connect ProjectApp* | data generator name, URL creator, inherit metadata, resolutions, media types, API version (V2 recommended) | job action *SmartSearch Connect push* | |
| VideoManagementPro | *VideoManagementPro Project Configuration* | technical user, use it in the preview, standard VideoManager | | editors with movingimage rights |
| Connect for Commerce | *FirstSpirit Connect for Commerce - Project Configuration* | bridge URL and login, reports, cache, form field names, ShareView secret | | |
| Multisite Management | *FirstSpirit MultisiteManagement \| Bundle management* (source), *Layer mapping* (target) | target projects, allowed groups, technical user | | listed groups, plus project administrators of a target |
| translationstudio (partner) | *translationstudio Project Preparations* | language mappings, workflow and scheduled-task permissions | scripts, folders, scheduled tasks | per workflow permission |
| AI Suite | *FirstSpirit AI Configuration ProjectApp* | shared and project prompts | | feature groups (`firstspirit-ai-suite`) |

## Settings that decide behaviour, by module `[odfs]`

- **CaaS Connect.** Tag only the image resolutions the front end needs with `CaaS`: with no tag every resolution of every image is sent and the first runs are very slow. After a change of URL factory, tags or media hosting, run **Total Sync**; the module does not repair old data itself. Edits to the shipped schedules are **reset** when the component is updated: edit a copy. With remote datasets the generated keys cannot read the other project: add a key by hand.
- **Navigation Service.** *Ignore errors* stays off, or errors become `null` values and the navigation can no longer be trusted. The component's presence is the switch: adding it creates the navigation, removing it deletes it. Exclude elements with the `md_navservice_exclude` toggle in the metadata.
- **OCM.** The preview URL with protocol is under *ContentCreator* settings; without a PreviewRenderingPlugin a CaaS project gets empty previews. Delete from a headless preview needs the delete workflow (`workflows.md`).
- **SmartSearch Connect.** Do not rename the project: the data generator and prepared search are named after it. Several projects need a data-generator pool at least as big as the project count on the server side.
- **DQM Connect.** Without a project endpoint the *Default Configuration* of the service is used.
- **Connect for Commerce.** The shop ID and page type field names default to `id` and `type`; changing them means changing templates, scripts and the Frontend API too. The ShareView secret must be identical in the project and the Frontend API server.
- **Multisite Management.** Every user needs rights in the source **and every target** project; the technical user needs rights in all targets (the *Test connection* button checks it). Layer mapping only when the database layers differ.
- **VideoManagementPro.** Five failed logins in an hour lock the technical user for an hour; with *Use this user in the preview* off, every editor is asked for their own login.

## Groups and permissions that come with modules

| Question | Where it is set |
|---|---|
| Who sees the Development Tools or another MicroApp | the CXT-Platform page, external groups only |
| Who may start a module's workflow | store workflow permissions and the Start transition (`workflows.md`, `firstspirit-workflow-development`) |
| Who may use Multisite Management | the group list in its project component, plus rights in the projects |
| Who may use an AI assistant | feature availability for users or groups (`firstspirit-ai-suite`) |
| Who may see the CaaS status report | project administrators (the web component of CaaS Connect) |
| Reference-project groups (*Editors*, *ChiefEditors*, *ProjectAdmins* in Connect for Commerce) | external groups: an LDAP connection is needed or they do nothing |

## Schedules that modules add `[odfs]`

CaaS Connect: *Smart Sync* and *Total Sync*, each for preview and release. Navigation Service: *Navigation Live Generation* and *Navigation Preview Generation*. SmartSearch: a job action, not a shipped schedule. translationstudio: scheduled tasks created by its install script. A shipped schedule is rewritten on update; keep changes in a copy.
