# Multi-project layout: one Gradle build, several jars, three scopes

The single-project build in [isolated-mode-and-packaging.md](isolated-mode-and-packaging.md)
is right for a module with a handful of components. Split into **subprojects** when the
module exposes a **Java API other modules or scripts call** (a service interface), when it has
a **web-app component** that must not drag the server-side implementation into the web
container, or when third-party libraries should reach only one classloader. Every Crownpeak
e-commerce connector module is built this way; the shape below is what they share.

---

## The shape

```
my-module/                       root: no FirstSpirit plugin, shared subprojects { } config
├── settings.gradle.kts          include(...) the four projects
├── gradle.properties            fsRuntimeVersion, fsModuleName, fsDisplayName, fsVendor, ...
├── my-module-module/            ASSEMBLY: applies de.espirit.firstspirit-module, no Java source
├── my-module-api/               server scope: service interfaces + DTOs, nothing else
├── my-module-scope-module/      module scope: components that also run in the web app
└── my-module-server-only/       module scope: service impls, ProjectApp, heavy libraries
```

Only the assembly project applies the FSM plugin. The code projects apply the companion
**`de.espirit.firstspirit-module-annotations`** plugin (same version), which supplies the
`@…Component` annotations without pulling the FSM build machinery into every jar. Since
plugin **7.0.0** there are three ids: `de.espirit.firstspirit-module` (assembly),
`-annotations` (code projects) and `-configurations` (adds only the `fs…Compile`
configurations, for a subproject that declares scope but neither assembles nor
annotates). Older examples with a single plugin id are 6.x `[observed]`.

### Root `build.gradle.kts` — the shared block

```kotlin
subprojects {
    apply(plugin = "java-library")

    tasks.withType<JavaCompile> {
        options.encoding = "UTF-8"
        options.release.set(17)                       // the FirstSpirit JDK, not "latest"
    }

    dependencies {
        // NEVER implementation(): the server provides the runtime; bundling it breaks isolation.
        compileOnly("de.espirit.firstspirit:fs-isolated-runtime:$fsRuntimeVersion")
        testImplementation("de.espirit.firstspirit:fs-isolated-runtime:$fsRuntimeVersion")
    }
}
```

`fs-isolated-runtime` is **`compileOnly`** in every subproject. Its only other appearance is
`testImplementation`, so unit tests can mock `SpecialistsBroker`, agents and store elements.
The same rule applies to **`de.espirit.cxt.cc:cxt-cc-api`**, the ContentCreator plug-in API
(entity management items, crop operation, …): `compileOnly`, never bundled — the ContentCreator
web app provides it. Plug-in types are catalogued in
`firstspirit-contentcreator-extensions/references/java-plugins.md`.

### Assembly `build.gradle.kts` — where scope is decided

```kotlin
plugins {
    id("de.espirit.firstspirit-module") version "8.0.2"   // pin; see isolated-mode-and-packaging.md
}

dependencies {
    fsServerCompile(project(":my-module-api"))            // server scope

    fsModuleCompile(project(":my-module-scope-module"))   // module scope
    fsModuleCompile(project(":my-module-server-only"))

    fsWebCompile(project(":my-module-api"))               // web-app scope: API + client-side code,
    fsWebCompile(project(":my-module-scope-module"))      // never the server-only jar

    // A library that BOTH the ProjectApp (server) and the web-app config panel use
    // must appear in both lists; each scope is packaged separately.
    fsModuleCompile("com.example:shared-lib:1.2.3")
    fsWebCompile("com.example:shared-lib:1.2.3")
}

firstSpiritModule {
    moduleName        = fsModuleName
    displayName       = fsDisplayName
    vendor            = fsVendor
    description       = fsDescription
    firstSpiritVersion = fsRuntimeVersion
    // Plugin 7.0+: fail the build if any packaged class targets a newer JVM than the
    // server runs. 61 = Java 17, 65 = Java 21. Catches a mis-configured toolchain in a
    // transitive dependency before the server refuses the module. [observed]
    // Pick the value from the server: the 5.2.240208 runtime jar is Java 17 bytecode (61),
    // the 5.2.261011 jar is Java 21 bytecode (65) [jar] — compiling against the latter
    // needs a JDK 21 toolchain even if your own classes stay at release 17.
    maxBytecodeVersion = 61
}

// The hosted "FSM Dependency Checker" service is gone; run the check locally on every build.
tasks.check { dependsOn(tasks.checkCompliance) }
```

The three configurations **are** the resource scopes of `module-descriptor.md`:

| Gradle configuration | Descriptor result | Put here |
| --- | --- | --- |
| `fsServerCompile` | `<resource scope="server">` | Service **interfaces** and the DTOs they pass. One classloader server-wide, so proxies in module/web scope and the implementation agree on the same `Class` objects. |
| `fsModuleCompile` | `<resource scope="module">` | Everything that runs on the server or in SiteArchitect: service implementations, ProjectApp + Configurable, DAPs, executables, third-party HTTP/JSON libraries. |
| `fsWebCompile` | `<web-resources>` of every `@WebAppComponent` | What the ContentCreator/preview web app needs: the API jar, client-side components, service **proxies**. Leaving the server-only jar out keeps ten HTTP libraries out of the web container. |

A jar may appear in more than one configuration (the API jar is in `fsServerCompile` and
`fsWebCompile` in every real module). Transitive `implementation` dependencies of a subproject
travel with it into the same scope.

### Why the API jar is server scope, and small

Callers reach a service through `ServicesBroker.getService(MyService.class)` `[jar]`. The
`Class` they pass must be the very same one the implementation returned from
`getServiceInterface()`, which only holds if both were loaded by the server classloader. Hence:
interfaces and their argument/return types in the server-scope jar, nothing else. Every class
you add there is loaded once for the whole server and cannot be versioned per module, so the
jar stays a contract, not a toolbox.

---

## Descriptor from annotations

None of the surveyed production modules has a hand-written `module.xml`. The annotations are
tied to the Gradle plugin: they exist so that the plugin can generate the descriptor and the
build needs no hand-maintained XML. Without the plugin (a Maven or plain-jar build) they do
nothing, and a hand-written `module.xml` is then the normal form, not a smell (confirmed internally, 2026-09-18). The assembly project
writes the `<module>` header from `firstSpiritModule { }`, and the plugin scans the compiled
jars for these annotations (`com.espirit.moddev.components:annotations`, attributes checked
against 3.3.0 `[jar]` and the annotation sources `[core]`):

| Annotation | Descriptor element | Attributes |
| --- | --- | --- |
| `@ModuleComponent` | `<module>` header, `<configurable>` | `configurable` only — put it on the class that implements `Module` when the module has a server-level configuration panel; everything else in the header comes from `firstSpiritModule { }` |
| `@PublicComponent` | `<public>` | `name`, `displayName`, `description`, `hidden`, `configurable` |
| `@ServiceComponent` | `<service>` | `name`, `displayName`, `description`, `hidden`, `configurable` |
| `@ProjectAppComponent` | `<project-app>` | as above plus `resources` (`@Resource[]` with `path`, `name`, `version`, `minVersion`, `maxVersion`, `scope` = `MODULE` (default) or `SERVER`) |
| `@WebAppComponent` | `<web-app>` | as above plus `webXml`, `xmlSchemaVersion`, `scope` (`WebAppScope[]`, default `PROJECT` and `GLOBAL`), `webResources` (`@WebResource[]` with `path`, `name`, `version`, `minVersion`, `maxVersion`, `targetPath`) |
| `@WebServerComponent` | `<web-server>` | `name`, `displayName`, `description`, `hidden`, `configurable` — for a `WebServer` implementation (external web server integration); rare |
| `@ScheduleTaskComponent` | schedule task `<public>` | `taskName`, `displayName`, `description`, `formClass` (a `ScheduleTaskFormFactory`), `configurable` |
| `@GadgetComponent` | gadget `<public>` | `name`, `description`, `scopes` (`DATA`, `CONTENT`, `LINK`, `STYLE`, `UNRESTRICTED`), `factories` (`GadgetFactory[]`), `valueEngineerFactory`, `configurable` — custom input components; the four classes and the hand-written descriptor shape are in [component-types.md](component-types.md), section "Custom input component" |
| `@UrlFactoryComponent` | `<public>` with `<configuration>` | `name`, `displayName`, `description`, `useRegistry`, `filenameFactory`, `parameters`; see [component-types.md](component-types.md) |

`@PublicComponent` covers every `Public` hotspot: `Executable`, `ValueService`,
`GomIncludeValueProvider`, client plugins, DAPs, report items, drop handlers. Only the
interface the class implements decides what FirstSpirit does with it.

```java
@ServiceComponent(name = "MyCatalogService", displayName = "My Catalog Service")
public class MyCatalogServiceImpl implements Service<MyCatalogService>, MyCatalogService { … }

@ProjectAppComponent(name = ProjectAppHelper.PROJECT_APP_NAME,
                     displayName = "My Module Project Configuration",
                     configurable = MyProjectConfiguration.class)
public class MyProjectApp implements ProjectApp { … }

@WebAppComponent(name = "MyModule_WebApp", webXml = "web.xml", xmlSchemaVersion = "6.0")
public class MyWebApp extends AbstractWebApp { }        // the shell; behaviour is in web.xml + plugins
```

`web.xml` and other packaged files live in `src/main/fsm-resources/` of the assembly project.
Keep the `xmlSchemaVersion` you declare and the `version` inside `web.xml` in step; one
surveyed module declares 6.0 and ships a 3.1 descriptor, which works only by accident.

---

## Compliance check and the tech-debt baseline

`checkCompliance` (FSM plugin) fails the build when module code depends on FirstSpirit classes
marked `@Internal`. Wire it into `check` so it runs on every CI build. When a legacy module
cannot pass yet, the plugin accepts a **baseline file** of regexes matched against the ArchUnit
violation text. The one convention worth copying, from a module that has carried such a file
for years:

```
# Treat every entry as tech debt. When fixing a violation, delete its pattern.
# Line numbers are matched as \d+ so unrelated line shifts do not cause false positives.
```

A baseline that can only shrink makes non-public API usage visible; a baseline that grows is
the module quietly becoming unupgradeable. The packages that end up in these files are listed
in [best-practices.md](best-practices.md#non-public-packages-that-look-public).

---

## Testing across the split

- JUnit 5 + Mockito against `fs-isolated-runtime` as `testImplementation`; every FirstSpirit
  object (`SpecialistsBroker`, agents, `Page`, `FormData`) is a mock. No FirstSpirit server is
  started `[observed]` in all three surveyed modules.
- Tests that touch FirstSpirit serialisation or reflection need the same JVM opens the server
  itself runs with; one module sets them for every test task `[observed]`:
  ```kotlin
  tasks.withType<Test>().all {
      jvmArgs("--add-opens", "java.base/java.lang=ALL-UNNAMED",
              "--add-opens", "java.base/java.util=ALL-UNNAMED",
              "--add-opens", "java.base/java.time=ALL-UNNAMED")
  }
  ```
- Live integration tests against the external system belong in their own source set or task,
  not in `src/test`, or every CI run needs credentials.

---

## When not to split

One jar in `fsModuleCompile` is the right answer for a module that exposes no Java API, has no
web-app component and bundles few libraries. The split costs a Gradle project per scope and a
discipline about what may import what. Add the API jar the day another module or a script
needs to call your service, not before.

> Sources: three Crownpeak e-commerce connector modules in production (Connect for Commerce,
> ContentConnect for SAP Commerce Cloud, ContentConnect for Salesforce Commerce Cloud), read
> 2026-09-17. Gradle wiring and annotation usage are `[observed]` in their build files; FirstSpirit
> interfaces are `[jar]`-verified against the runtime; annotation attributes against the FSM
> annotations jar 3.3.0.
