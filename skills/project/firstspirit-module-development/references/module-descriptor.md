# The module descriptor (module.xml)

A FirstSpirit module is packaged as an **FSM** (a zip). Its manifest,
`module.xml`, declares the module's **components** and the **resources** (jars,
files) they need — each resource pinned to a **scope**.

---

## Skeleton

```xml
<module>
    <name>@MODULE_NAME@</name>
    <version>@VERSION@</version>
    <description>...</description>
    <vendor>...</vendor>

    <components>
        <!-- one entry per component (see component-types.md) -->
    </components>

    <resources>
        <!-- jars/files, each with a scope -->
    </resources>
</module>
```

Placeholders like `@MODULE_NAME@` / `@VERSION@` are filled by the build. The
**recommended toolchain is the FirstSpirit Module Gradle Plugin** (annotations +
`build.gradle`, `assembleFSM` task), which also generates the descriptor for you —
see [isolated-mode-and-packaging.md](isolated-mode-and-packaging.md).

> **You will rarely write this file.** Production modules surveyed in 2026 carry no
> `module.xml` at all: the `<module>` header comes from the `firstSpiritModule { }` block,
> each `<components>` entry from a `@PublicComponent` / `@ServiceComponent` /
> `@ProjectAppComponent` / `@WebAppComponent` / `@ScheduleTaskComponent` /
> `@UrlFactoryComponent` annotation on the class, and each `<resources>` entry with its
> `scope` from the Gradle configuration the jar is wired into (`fsServerCompile`,
> `fsModuleCompile`, `fsWebCompile`). The annotation → element table and the configuration →
> scope table are in [multi-project-layout.md](multi-project-layout.md). Read this page to
> understand **what the plugin generates** and what each scope means; hand-write it only when
> you maintain the descriptor yourself.

> **Always build Isolated Mode** — it is the default since 2019-02 and the only
> supported model (legacy binaries gone 2022-03; customer-module legacy support ends
> 2025). Don't choose a mode: the **FirstSpirit Module Gradle Plugin builds isolated
> and generates the descriptor as `module-isolated.xml`** for you — the `module.xml`
> name used on this page is the generic term for that descriptor, not a legacy build.
> Isolated classloading means a module must **bundle its own libraries** — the
> descriptor's `<resources>` and their `scope` are how. Read
> [isolated-mode-and-packaging.md](isolated-mode-and-packaging.md) alongside this page.

## Component elements

Declared inside `<components>`. Each names a class implementing the matching
interface (see [component-types.md](component-types.md)):

| Element | Component |
| --- | --- |
| `<public>` | A public hotspot class — `Executable`, `ValueService`, a plugin, etc. Referenced by name from scripts/rules/buttons. |
| `<service>` | A server service (`Service<T>`). |
| `<project-app>` | A project application; optional `<configurable>` for its config UI. |
| `<web-app scopes="global,project">` | A web component (servlets/resources) with `<web-resources>` and `<web-xml>`. |
| `<library>` | (Legacy) puts jars in the global scope — avoid; prefer module-scope resources. |

Some `<public>` components take a nested **`<configuration>`** block whose child
tags become an init settings map — used by hotspot components such as the
UrlFactory (whose `<class>` is `UrlCreatorSpecification`; the block names the
implementation class + options). Tag names arrive lower-cased in the settings map.
See the UrlFactory section in [component-types.md](component-types.md).

Note: `<configuration>` (init settings on a public component) is distinct from
`<configurable>` (a ServerManager config-dialog class on a ProjectApp/Service/
WebApp — see the Configurable section in [component-types.md](component-types.md)).

Examples:

```xml
<public>
    <name>Documentimporter Executable</name>
    <class>com.example.docimporter.DocumentImporterExecutable</class>
</public>

<service>
    <name>ZipcodeService</name>
    <description>...</description>
    <class>com.example.serverservice.ZipcodeServiceImpl</class>
</service>

<project-app>
    <name>DocumentImporter ProjectApp</name>
    <displayname>Document Importer Project App</displayname>
    <class>com.example.docimporter.DocumentImporterProjectApp</class>
    <configurable>com.example.docimporter.DocumentImporterConfigurable</configurable>
</project-app>

<public>                                <!-- a Rule value provider -->
    <name>ZipcodeValidation</name>
    <class>com.example.valueservice.ZipcodeValidationValueService</class>
</public>

<web-app scopes="global,project">
    <name>Example WebApp</name>
    <web-resources>
        <resource scope="module" name="com.example:module" version="@VERSION@">lib/@COMPONENT_JAR@_module.jar</resource>
        <resource target="/">web/resources/</resource>
    </web-resources>
    <web-xml>web/web.xml</web-xml>
</web-app>
```

> The `<public>` **name** is the identifier you reference elsewhere — e.g. a
> `ValueService` named `ZipcodeValidation` is used in a rule as
> `service="ZipcodeValidation"`, and an `Executable` is callable from an
> `FS_BUTTON` as `onClick="class:..."` or a script header `#!executable-class`.

## Resources and scopes

`<resources>` lists the jars/files the module ships. **Scope decides the
classloader** that can see the resource:

| Scope | Visible to | Use for |
| --- | --- | --- |
| `module` | only this module's components | **Default — use almost always.** Your implementation jars and third-party libs. |
| `server` | the whole server (global) | Only when unavoidable — e.g. a **service interface** other modules/scripts must see. **Not** the implementation. |
| `global` (via `<library>`) | everything, incl. BeanShell scripts | Avoid; leaks classes server-wide. |

```xml
<resources>
    <resource scope="module" name="com.thoughtworks.xstream:xstream" version="1.4.20">lib/xstream-1.4.20.jar</resource>
    <resource scope="module" name="com.example:module"  version="@VERSION@">lib/@COMPONENT_JAR@_module.jar</resource>
    <resource scope="server" name="com.example:global"  version="@VERSION@">lib/@COMPONENT_JAR@_global.jar</resource>
</resources>
```

- `name` is a Maven-style `groupId:artifactId`; `version` (and optional
  `minVersion`/`maxVersion`) let the server reconcile duplicate libs across
  modules. **Unversioned resources are treated as incompatible** — always version.
- A second attribute, **`mode`** (`isolated` / `legacy`), sets the classloading
  model per resource. Modern modules are all `isolated`; from FirstSpirit 2025.9
  the attribute is effectively ignored (everything is isolated). Full model +
  compatibility rules: [isolated-mode-and-packaging.md](isolated-mode-and-packaging.md).
- **Module-local classes are invisible to the global scope** (e.g. BeanShell). The
  one sanctioned bridge: expose logic as an **`Executable`** `<public>` component —
  it can stay module-local yet be called from scripts. See
  [best-practices.md](best-practices.md).

## Common pitfalls

- Putting implementation jars in `server`/`global` scope "to make scripts see
  them" → classloader conflicts. Use module scope + an `Executable` instead.
- Splitting into `_global.jar` + `_module.jar` only when you genuinely need a
  server-visible interface; otherwise one module jar is simpler. When you do need it,
  the Gradle subproject layout in [multi-project-layout.md](multi-project-layout.md)
  makes the split mechanical.
- Web components (ContentCreator, servlets) need their jar as a **`<web-resource>`**
  in the `web-app`, not only under top-level `<resources>`.
