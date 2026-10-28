# Multisite Management (bundles)

Source: *Installation guide*, Multisite Management 2026.11 `[odfs]`, read 2026-10-13.
Decision-level facts (what it is, ContentTransport against Corporate Content): `firstspirit-technical-product-knowledge`, `firstspirit-technical-product-knowledge/references/extensions-and-modules.md`. The older package-based Corporate Content is **not** what this page describes.

## Cloud or on-prem

Server configuration and installation are for a **local** server only; on Cloud the base is set up. Project configuration is needed everywhere `[odfs]`.

## Requirements `[odfs]`

FirstSpirit **2026.6 or higher**; Tomcat 10.1.11 or higher; a fully configured **CXT-Platform** (with `cxt-platform.properties` and `cxt-microapps-common.properties`); **PostgreSQL 12.0 or higher**; a FirstSpirit module that provides the **JDBC driver**; one external web server only; module `fs-multisite-[version].fsm`. A downgrade is generally not guaranteed. The licence flag the older packages needed (`license.PACKAGEPOOL`) is **not mentioned** on this page `[verify]`.

## Steps, in order `[odfs]`

The preparations come **before the first installation**; their order does not matter. It is the same pattern as Collaboration (`collaboration.md`).

| # | Step | Where | Check |
|---|---|---|---|
| 1 | Create `[FirstSpirit]/conf/modules/fs-multisite.fs-multisite-service/fs-multisite-service.properties` with `fs.microapp.multisite.database.` keys `driver.module`, `driver` (`org.postgresql.Driver`), `url`, `user`, `password` | server file system | |
| 2 | Copy the PostgreSQL driver jar into `[Tomcat]/lib/` and create `[Tomcat]/lib/config/fs-multisite-microapp.properties` with `driver`, `url`, `user`, `password`. **The database values must be identical on the server and in Tomcat** | Tomcat host | |
| 3 | Create the schema (`fs.microapp.multisite.database.schema`, default `public`); full read and write for the user | PostgreSQL | |
| 4 | Install the module in the ServerManager. It creates the global web app *FirstSpirit MultisiteManagement \| MicroApp* (id `fs-multisite-microapp`, context `/fs-multisite-microapp`), adds the *Multisite Management* web component to the ContentCreator web app and adds its service to the autostart list. The service creates the tables at start | ServerManager, Server, Properties, Modules | service running |
| 5 | **Restart FirstSpirit and Tomcat**; **deploy the ContentCreator web app by hand**. Project-local ContentCreator instances need *Multisite Management* and *CXT-Platform \| CC Integration* added | Web applications | |
| 6 | **Source project:** add the project component *FirstSpirit MultisiteManagement \| Bundle management*. The application then appears in the ContentCreator toolbar for project administrators | Project components | |
| 7 | In that component: pick the **target projects** (none picked = no targets), the **user groups** allowed to use it (server and project administrators of a target project may by default; every user needs rights in the source **and every target** project), and optionally a **technical user** (tab *Post-Processing*; *Test connection*) with rights in all targets, for scripts and workflows that run after a bundle is deployed | same | |
| 8 | **Target project, only if the database layers differ:** add *Layer mapping* with lines `<source layer>=<target layer>` (`*` for all others). With the DBA layer in the cloud it is generally not needed | Project components | |

## Decisions to make before the first bundle `[odfs]`

*Multisite Management* user documentation 2026.11, pages *Bundling strategies*, *Back transport*, *MSM API Guide*, *Best practice* and *FAQ*, read 2026-10-13.

- **Bundling strategy** (chosen per bundle): *None* (only the element); *Include content references* (page, medium, dataset and what they reference, recursively by element type, **never templates**; the recommended default); *Include outgoing references* (everything referenced, **templates included**, recursive: only for self-contained parts such as a campaign); or a **project-specific strategy** written against the MSM API. Templates are therefore distributed only by adding them by hand under *content references*. With datasets only the table template follows automatically, never the schema.
- **Release or current state** is chosen on each bundle; the module cannot be limited to release only. A rollout **overwrites** local edits to distributed content, deletes in the target what was deleted in the source, and cannot be decoupled locally (a local copy of the section marked untranslated is the workaround).
- **Languages:** either translate in the target project (recommended for a language used by one target) or translate in the source project and keep **localised language versions** in the targets (for a language shared by several). Editors must see only the matching language. Both setups use project-specific workflows or scripts so a rollout does not overwrite local work.
- **Back transport** (target to source) is **not ready-made in the target project**: each target project needs its own ContentCreator script or workflow that checks whether an element changed and creates a *change request* through the MSM API; it is revision-based and covers pages, paragraphs and datasets, one element at a time. The source project's user interface (tab *Pull*) lists, edits, accepts or rejects them and flags conflicts on language-independent fields. The MSM API Guide has a sample script and the other API functions (bundles, subscriptions, deployments).
- **Media master (remote project):** bundles with references work when the media master has the same remote name in the target; remote media are not part of the bundle.
- **After a rollout**, post-processing workflows run in the **target** project, with the transported objects in the context.

Who may use it afterwards is group membership: `firstspirit-configuration`.
