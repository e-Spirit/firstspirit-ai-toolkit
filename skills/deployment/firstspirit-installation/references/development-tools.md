# Development Tools for ContentCreator

Source: *Installation and Configuration* of the Development Tools in ContentCreator documentation, 2026.11 `[odfs]`, read 2026-10-13.
What the tools do is not covered here.

## Cloud or on-prem

On **Cloud** everything is set up; only the configuration step below applies `[odfs]`. On a local server, only a server administrator can install modules `[odfs]`.

## Requirements `[odfs]`

- **CXT-Platform** (the Development Tools MicroApp does not work without it; installation below).
- Module file `fs-sitedev-microapp-*.fsm`.
- One external web server only. The embedded Tomcat and Jetty modules are not supported with CXT (`firstspirit-server.md`, *Requirements for 2026.11*) `[odfs]`.

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Install the CXT-Platform | section below | the platform answers at `https://<host>/cxt-platform/management` |
| 2 | Install the module; a global web app is created by the installation | ServerManager, Server, Properties, Modules | module listed |
| 3 | Web component *Development Tools*: added to the **global** ContentCreator web app by the installation. With a **project-local** ContentCreator web app, add it by hand | Project properties, Web components | component listed on the project's web app |
| 4 | Roll the ContentCreator web app out again (after 3) | Web applications | tool visible after a reload |
| 5 | **Enable the MicroApp.** It is disabled by default (all environments, Cloud included). Open the *MicroApp Management* page of the CXT-Platform as an administrator and activate it for chosen user groups; only **external** user groups can be used | `https://<host>/cxt-platform/management` | a member of the group sees the tool in ContentCreator |

Restart: not documented on the page; apply the general module rule in `SKILL.md` `[verify]`.

## When "the tool is missing"

Work down the table: module installed, web component on the web app the project really uses (global or project-local), web app rolled out, MicroApp enabled **for a group the user is in**, and the group is an external group `[odfs]`.
Who may use it after that is group membership; group set-up is in `firstspirit-configuration`.

## Installing the CXT-Platform `[odfs]`

Source: *Content Experience Tools* documentation, page *CXT-Platform* (German page, read 2026-10-13). The page says the module is needed for FragmentCreator 3.x; the Development Tools page names it as a requirement too.

Requirements: a **SOCKET** connection to the FirstSpirit server; the platform web app must be reachable on the **same external host** as the clients that use it (same origin). Module file `platform-<version>.fsm`.

| # | Step | Where | Check |
|---|---|---|---|
| 1 | Install the module | ServerManager, Server properties, Modules | module listed |
| 2 | Set the MicroApp URL in the service *CXT-Platform \| Configuration Service* (Configure): `https://<external host>/cxt-platform/microapps/api.js`, the value of `cxt.platform.external-url` plus the path | Server properties, Services | |
| 3 | Define a **global web app** with web context `/cxt-platform`, pick a web server, add the web component *CXT Platform* and deploy it | Web applications, global web apps | `/cxt-platform/status` answers for an administrator |
| 4 | Configure through `web.xml` or a properties file (below) | the web app | status page shows no configuration warning |
| 5 | Optional: add the *ApplicationPlugin: MicroApp Management* to the start page web app, deploy it, then add it under *Start page* in the server properties. It gives a button for the management page | Web applications; server properties | the icon appears on the start page |

Parameters (names from the page; the placeholder defaults do not suit every setup, check them):

| Parameter | What it does |
|---|---|
| `cxt.platform.firstspirit.hostname`, `.port`, `.connection-mode` (`SOCKET` default; single sign-on only with SOCKET), `.root-context` | how the platform reaches the server |
| `cxt.platform.internal-url`, `cxt.platform.external-url` | how the platform is reached internally and from a browser |
| `cxt.platform.cors-allowed-origins` | empty: none; `*`: all; comma-separated list: those origins |
| `cxt.platform.eureka.password`, `cxt.platform.microapp-registry.password` (from FirstSpirit 2026.2), `cxt.platform.oauth.client-secret` | fixed shared secrets; use the same value in each client or MicroApp |
| `cxt.platform.oauth.jwt-signing-key` | default `RANDOM_VALUE` changes on every start |
| `cxt.platform.oauth.access-token-validity-seconds` (3600), `...refresh-token-validity-seconds` (43200, keep above the access value), `cxt.platform.microapp-registry.lease-timeout` (90) | token and registry lifetimes |
| `cxt.platform.microapps.csp-origins` | extra origins allowed to embed MicroApps; default `'self'`. Wrong values show as a *frame-ancestors* error in the browser console and the MicroApp does not open |
| `cxt.platform.management.persistence.persistenceFile` | path of the file that stores the MicroApp management settings; **without it the settings are not saved** |
| `logging.file.name`, `logging.level.<package>` | log file and level; the status page shows log lines only when a file is set |

The status page tests each MicroApp with an empty context, which can log `UnsupportedContextException: Context is not supported`; that is expected. The management page is for server or project administrators.
