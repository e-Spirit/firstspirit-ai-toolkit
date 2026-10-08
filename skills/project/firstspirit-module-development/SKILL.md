---
name: firstspirit-module-development
description: >-
  Concrete lookup reference for building FirstSpirit modules (FSM): the module
  descriptor (module.xml, resource scopes, the @…Component annotations), the Gradle
  layout (fsServerCompile / fsModuleCompile / fsWebCompile, checkCompliance, the 7.x
  plugin split, the Cloud build pipeline), the component types (Executable, Service and
  ServiceProxy, ValueService, ProjectApp with Configurable, client plugins, schedule
  tasks, web-app components, DataAccessPlugin, Report, UrlFactory, UploadHook,
  IDProviderEventAgent, GadgetSpecification), broker idioms, non-public packages to
  avoid, and Access API use from a standalone app. Use it whenever you package Java
  against FirstSpirit as a module or need a component skeleton: "write a server
  service", "module.xml for an executable", "which jar goes in fsWebCompile",
  "ValueService for a rule", "reject an upload", "run code when a page is saved",
  "connect from my IDE". Object model: firstspirit-api-reference.
metadata:
  source-commit: "9c191a5"
  published: "2026-10-08"
  toolkit-version: "0.4.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit module development

Fast, factual lookup for building **FirstSpirit modules (FSM)** — the durable way
to add Java functionality. It is a reference with small getting-started examples, not a
substitute for the FirstSpirit developer courses or for the ODFS.
Where `firstspirit-scripting` covers lightweight BeanShell glue and
`firstspirit-api-reference` covers the object model you manipulate, this skill
covers **packaging and component types**: the `module.xml` descriptor, the
component skeletons, resource scopes, and connecting from a standalone app.

## Script or module?

- **Script** (BeanShell) — quick, project-local automation, migrations, glue.
  Editable in the client, no build. → `firstspirit-scripting`.
- **Module** (FSM) — behaviour that is long-term, load-bearing, reused across
  projects, or needs real Java packaging (services, plugins, web components). More
  stable and maintainable. **This skill.**

A useful hybrid: implement logic as an **`Executable`** (a `<public>` component)
and call it from a script (`#!executable-class` / `onClick="class:…"`) — module-
grade code, script-level convenience.

## How to use this skill

- **Look up, don't lecture.** Give the descriptor snippet, the interface to
  implement, or the scope rule — then stop. Point into `references/`.
- **Pick the component type first**, then wire it in `module.xml`. See
  [references/component-types.md](references/component-types.md) and
  [references/module-descriptor.md](references/module-descriptor.md).
- **Get resource scope right early** — it's the most common source of
  classloading pain. See the scope rules in
  [references/module-descriptor.md](references/module-descriptor.md).
- **Public API only.** Use documented `de.espirit.firstspirit.*` types; internal
  ones may change without notice. Access + Developer API are one consolidated
  public API since 2024 — see the stability signals in
  [references/best-practices.md](references/best-practices.md).
- **Defer.** The object model / agents a component calls → `firstspirit-api-reference`.
  BeanShell scripts → `firstspirit-scripting`. Deep plugin docs → the FirstSpirit ODFS documentation.

## Quick answers

- **Executable:** implement `de.espirit.firstspirit.access.script.Executable`
  (`execute(Map)` + `execute(Map, Writer, Writer)`); the script/button context
  arrives as `map.get("context")`.
- **Server service:** implement `de.espirit.firstspirit.module.Service<T>`
  (`start`/`stop`/`isRunning`/`init`/`getServiceInterface`/`getProxyClass`). Callers get it
  via `ServicesBroker.getService(T.class)`; a `ServiceProxy<T>` runs client-side and can fill
  defaults before the remote call.
- **Several jars, three scopes:** an assembly project wires `fsServerCompile` (interfaces),
  `fsModuleCompile` (implementations), `fsWebCompile` (what the web app needs); the
  `@…Component` annotations generate the descriptor; `checkCompliance` fails on `@Internal`
  usage. See [references/multi-project-layout.md](references/multi-project-layout.md).
- **Schedule task:** `@ScheduleTaskComponent` on a `ScheduleTaskApplication<D>` plus form
  factory, form, executor and data class.
- **Is the project app installed here?** `ModuleAdminAgent.getProjectAppUsages(module, app)`.
- **Server code needs a project:** `BrokerAgent.getBrokerByProjectId(id)`; probe optional
  agents with `requestSpecialist` (null), demand them with `requireSpecialist` (throws).
- **Rule value provider:** implement
  `de.espirit.firstspirit.service.value.ValueService` (`getValue(broker, params)`);
  reference it in a `<RULE>` by its `<public>` name.
- **Connect from an IDE/app:** `ConnectionManager.getConnection(host, port, mode,
  login, pw)` → `connect()` → get a **project** broker via `BrokerAgent`.
- **Foreign data in `FS_INDEX` / a Report:** implement `DataAccessPlugin<D>` (+
  session/stream + aspects) — see [references/data-access-and-reports.md](references/data-access-and-reports.md).
- **Custom generation URLs:** implement `UrlFactory` (module scope); register with the
  `@UrlFactoryComponent` annotation — the plugin generates the `<public>` descriptor
  (`<class>…generate.UrlCreatorSpecification</class>` `[odfs]` — a type key the server
  matches, not a class it instantiates — plus `<configuration>`).
- **Veto or scan a media upload:** implement `UploadHook` (`<public>`); throw
  `UploadRejectedException` from `preProcess` — the message reaches the editor.
- **React to element saves:** `IDProviderEventAgent.addListener(filter, consumer)` from a
  **project** broker; keep a strong reference to the consumer (the agent holds it weakly).
- **Custom input component:** `<public>` with `<class>GadgetSpecification</class>` and
  `<gom>`/`<factory>`/`<value>`/`<scope>` — or `@GadgetComponent`; ContentCreator numbers
  arrive as `Double`.
- **ContentCreator toolbar / inline-edit / status-note / timeline plug-ins:** the Java
  interfaces live in `firstspirit-contentcreator-extensions/references/java-plugins.md`;
  this skill covers the `@WebAppComponent` packaging they need.
- **A config dialog:** a `<configurable>` class (`Configuration<E>`); in practice
  extend `GenericConfigPanel<E>` — one `builder()` line per value.
- **Build for the Cloud pipeline:** Kotlin-DSL Gradle build driven by `gradle.properties`, the
  FSM plugin plus `maven-publish` and the release plugin, credentials only in the user-level
  `~/.gradle/gradle.properties`, at least one passing unit test. Gradle 9 needs FSM plugin 7 or
  newer; a Java 21 runtime jar needs a JDK 21 to compile. See
  [references/cloud-fsm-build.md](references/cloud-fsm-build.md); the repository, branches and PROD
  ticket are `firstspirit-cloud`'s.
- **Change what the SiteArchitect preview sends** (a template set's output downloads instead of
  rendering): the preview type follows the template set's extension, and the first ID after the state
  in the preview URL is the template set ID. A `web-app` filter is the module route; the servlet
  API is not in `fs-isolated-runtime`. See
  [references/preview-web-app-filter.md](references/preview-web-app-filter.md).
- **Register everything** in `module.xml` under `<components>`; ship jars under
  `<resources>` with the right `scope`.
- **Always build Isolated Mode** — the default since 2019-02 and the only supported
  model (legacy gone by 2025); the Gradle plugin builds isolated and emits
  `module-isolated.xml` automatically, so there is no mode to choose. Isolation means:
  bundle every library yourself (the server's internal libs aren't visible), version
  your resources, and build with the **FirstSpirit Module Gradle Plugin**
  (`assembleFSM`). See [references/isolated-mode-and-packaging.md](references/isolated-mode-and-packaging.md).

## References

| File | Covers | Read when |
| --- | --- | --- |
| [references/module-descriptor.md](references/module-descriptor.md) | `module.xml`: `<module>`, `<components>`, `<resources>` and the module/server/global **scope** rules, versioning, common pitfalls | You need to declare a component or decide a jar's scope |
| [references/component-types.md](references/component-types.md) | Skeletons for each component: `Executable`, `Service` + **ServiceProxy**, `ValueService`, `ProjectApp` (config file, `updated()` migration, install guard), permanent plugin for **both clients**, **schedule task**, `GomIncludeValueProvider`, ContentCreator/web-app, DAP/Report, **UrlFactory**, **UploadHook**, **IDProviderEventAgent** listener, **custom input component** (`GadgetSpecification`), **Configurable (GenericConfiguration)** | You need the interface to implement and a minimal working shape |
| [references/multi-project-layout.md](references/multi-project-layout.md) | Gradle subprojects → `fsServerCompile` / `fsModuleCompile` / `fsWebCompile`; assembly project; the 7.x plugin split and `maxBytecodeVersion`; annotation → descriptor table; `checkCompliance` and its baseline; testing across the split | Your module exposes a Java API, has a web-app component, or you must decide which jar goes where |
| [references/data-access-and-reports.md](references/data-access-and-reports.md) | DataAccessPlugin/Report in depth: the five interfaces, the aspect model + catalogue, `FS_INDEX` integration, and a small tagging example as a skeleton | You are building a DAP or Report, or need the aspect list |
| [references/external-api-access.md](references/external-api-access.md) | Standalone/IDE access: `ConnectionManager`, connect/disconnect, `BrokerAgent` project broker, create-with-lock example | You run Java against a FirstSpirit server from outside a running module/script |
| [references/cloud-fsm-build.md](references/cloud-fsm-build.md) | The build files of a Cloud module: `build.gradle.kts`, `gradle.properties` keys, `ci.properties`, credentials, the Gradle / FSM plugin / JDK / runtime-jar compatibility table, what a local `assembleFSM` proves | You set up or review the build of a module the Cloud pipeline builds |
| [references/preview-web-app-filter.md](references/preview-web-app-filter.md) | What decides the SiteArchitect preview response (template set extension, template set ID in the URL), what does not (`mime.types.additional`, `UrlFactory`), and the `web-app` filter module shape | A template set previews as a download, or you change the preview response from a module |
| [references/best-practices.md](references/best-practices.md) | Dos & don'ts: scope discipline, Executable-from-script, service interface vs impl scopes, entry-point mindset | You are structuring or reviewing a module |
| [references/isolated-mode-and-packaging.md](references/isolated-mode-and-packaging.md) | **Isolated Mode** (the modern default): classloading, `scope` vs `mode`, resource naming/version compatibility rules, `module-isolated.xml`, the Gradle plugin build, module/component naming, isolated-server markers | You need the authoritative classloading/packaging model, or are deciding a resource's scope/version |

---

*Sources: a set of small example modules (module.xml and Java component sources),
three production connector modules, and the FirstSpirit Access/Developer API
(the FirstSpirit ODFS documentation).*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
