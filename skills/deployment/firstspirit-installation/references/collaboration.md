# Collaboration

Source: *FirstSpirit Collaboration: Installation Guide*, 2026.11 `[odfs]`, read 2026-10-13.
What the module does and its API: `firstspirit-collaboration` (`firstspirit-collaboration/references/concepts-and-setup.md` has a shorter version of these steps).

## Cloud or on-prem

Configuration and installation are only for a **local** server; on Cloud the base is set up. **Activation per project is needed everywhere** `[odfs]`.

## Requirements `[odfs]`

FirstSpirit 2025.5 or higher; Tomcat 10.1.11 or higher; a fully configured **CXT-Platform** including its Tomcat properties files; **PostgreSQL 12.0 or higher**; one external web server only. A downgrade is generally not guaranteed. Module file `fs-collaboration-[version].fsm`.

## Steps, in order `[odfs]`

The three preparations must be done **before the first installation**; their order does not matter.

| # | Step | Where | Check |
|---|---|---|---|
| 1 | **FirstSpirit service config:** create `[FirstSpirit]/conf/modules/fs-collaboration.fs-collaboration-service/` with `fs-collaboration-service.properties` holding `fs.microapp.collaboration.database.` keys: `schema`, `password`, `driver.module`, `driver` (`org.postgresql.Driver`), `url` (JDBC), `user`. Without it the installation errors; the fix is to fill the service's configuration afterwards (ServerManager, Server Properties, Modules, FirstSpirit Collaboration, Service) and **restart the service by hand** | server file system | |
| 2 | **Tomcat:** copy the PostgreSQL driver jar matching the database version into `[Tomcat]/lib/`; create `[Tomcat]/lib/config/fs-collaboration-microapp.properties` with `driver`, `url`, `user`, `password`, `schema` (default `public`) | Tomcat host | |
| 3 | **Database:** create the schema named in the properties; give the user full read and write permission on it | PostgreSQL | |
| 4 | Install the module in the ServerManager as usual. It creates and deploys the global web app *FirstSpirit Collaboration \| MicroApp* (id `fs-multisite-microapp`, web context `/fs-collaboration-microapp`, on the same web server as the root web app) and adds the web component *FirstSpirit Collaboration \| ContentCreator Integration* to the ContentCreator web app | ServerManager, Server, Properties, Modules | module and web app listed |
| 5 | **Restart FirstSpirit and Tomcat** after the installation | | |
| 6 | **Deploy the ContentCreator web app by hand.** It is not deployed automatically. With a project-local ContentCreator web app, add the components *FirstSpirit Collaboration* and *CXT-Platform \| CC Integration* there; the vendor recommends avoiding project-local web apps in production | Web applications | |
| 7 | **Per project:** add the project component *FirstSpirit Collaboration \| ProjectApp* | Project properties, Project components | Collaboration is active in the project |

Whether the AI agents that can join threads need more (FirstSpirit AI configured): `ai-suite.md`.
Why a missing module and a missing ProjectApp look the same (no conversations, API finds nothing): `firstspirit-collaboration`.
