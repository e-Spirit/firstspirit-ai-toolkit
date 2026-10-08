# Isolated Mode, classloading, and packaging

**Isolated Mode is how FirstSpirit modules work today** — the default for new
servers since FirstSpirit **2019-02**, and effectively the *only* mode now: legacy
binaries stopped shipping in **2022-03**, and from **FirstSpirit 2025.9** all module
resources are treated as isolated regardless of any `mode` attribute. Write modules
as isolated; treat "legacy mode" below as background for old modules only.

Source: ODFS *Documentation for Module Developers → Module Development*
(`edocs/modd/`): the root page, *Classloading – Visibility of Resources*,
*Ensuring Compatibility*, *Changing modules to Isolated Mode*, *FirstSpirit Module
Gradle Plugin*, *Server Installation*.

---

## Why Isolated Mode exists

In legacy mode the whole `fs-server.jar` (FirstSpirit APIs **plus** internal `Impl`
classes and bundled third-party libs like Log4j/Apache Commons) was on the module
classpath. Convenient, but it caused:

- **Library version conflicts** — a module couldn't use its own version of a lib
  the server also bundled; server up/downgrades could change that version under you.
- **Uncontrolled use of internal `Impl` classes** — not covered by API stability,
  could change at any time.

**Isolated Mode** ships the API in `fs-isolated-server.jar`: only the **Runtime
API interfaces** (+ a minimal connection infrastructure) are visible to the module
classloader. Internal `Impl` classes and the server's bundled libraries are moved
to a hidden area of the jar and are **no longer visible**. Result: a module must
**bring its own libraries**, and version conflicts with the server go away.

Consequence you must design for: **you can no longer rely on any library being
"just there" from the server** — declare every dependency as a module resource.

## Resource visibility: `scope` and `mode`

Two independent `<resource>` attributes control visibility.

**`scope`** — *where* a resource is visible:

| `scope` | Visible to | Notes |
| --- | --- | --- |
| `module` | only this module (+ it can see all global resources) | **Default choice.** Different modules may bundle different versions of the same class without clashing. Globally-defined jars **cannot** see module-local classes; module-local **can** see global. |
| `server` | this module + all other modules on the server | One namespace → a class can exist only **once**; different versions can't coexist. Use only for something genuinely shared, e.g. a **service interface**. |

**`mode`** — *which classloading model* the resource uses:

| `mode` | Sees |
| --- | --- |
| `isolated` | FirstSpirit **Runtime API** interfaces, this module's own resources, and other modules' global resources — **not** internal FS `Impl` classes/libs. |
| `legacy` | the above **plus** internal FS implementation classes/libraries (the old behavior). Historical — removed for customer modules as of 2025.9. |

`mode` is set per `<resource>`, not on the surrounding `<resources>`. If it was
omitted, legacy used to apply — now everything is isolated regardless.

```xml
<resources>
    <resource name="org.apache.httpcomponents:httpclient" version="4.4"
              scope="module" mode="isolated">lib/httpclient-4.4.jar</resource>
</resources>
```

## Resource naming and version compatibility

The server reconciles duplicate libraries across modules by **name + version**, so
naming matters:

- **`name`** = Maven-style `groupId:artifactId` (e.g.
  `org.apache.httpcomponents:httpclient`). Consistent names let the server detect
  that two modules' jars are the same library.
- **`version`**, plus optional **`minVersion`** / **`maxVersion`** describe the
  compatible range. `maxVersion="4.9.9"` is allowed even if that version doesn't
  exist yet (means "stable within the range").

Rules the server applies when names match:

- **No `version` on either resource → treated as incompatible.** Always version
  your resources.
- With overlapping `[minVersion, maxVersion]` ranges, the **newest resource
  compatible with all requesting modules** is used. Missing `minVersion` = no lower
  bound; missing `maxVersion` = no upper bound.
- If no single version satisfies every module's range → **conflict** (for web
  apps, this aborts the rollout with an error).

Worked example (from the ODFS docs):

| | version | minVersion | maxVersion | |
| --- | :-: | :-: | :-: | --- |
| Module A | 1.0 | 1.0 | – | |
| Module B | 1.5 | 1.5 | 1.999 | |
| Module C | 2.0 | – | 2.999 | |
| → | | | | **v1.5 chosen** — compatible with A, B and C |

Change one bound (A `maxVersion=1.999`, B `minVersion=1.5` open top, C
`minVersion=2.0`) and there is **no** version compatible with all three → conflict.

## Descriptors: `module.xml` and `module-isolated.xml`

- **`module.xml`** — the module descriptor (`<module>` → `<components>` +
  `<resources>`); see [module-descriptor.md](module-descriptor.md).
- **`module-isolated.xml`** — historically, a module shipped *both* so it could run
  on legacy **and** isolated servers: an isolated server used `module-isolated.xml`,
  a legacy server used `module.xml`, and if `module-isolated.xml` was absent the
  isolated server fell back to `module.xml`. With legacy gone, a single descriptor
  suffices; the Gradle plugin generates the right one for you.

## Build: FirstSpirit Module Gradle Plugin (recommended)

Crownpeak supports and updates the **FirstSpirit Module Gradle Plugin**. A few
annotations in the Java sources plus a little `build.gradle` config generate a
compliant FSM; run the **`assembleFSM`** Gradle task. This is the current
recommended toolchain — prefer it over hand-maintaining the descriptor or older
Ant/Maven setups. (For migrating an existing module, the **FSM Dependency Checker**
lists internal/external dependencies and flags non-isolated / deprecated / internal
API usage.)

- **Latest published plugin: 9.0.2** (needs Gradle ≥ 8.11, JDK ≥ 11). But **pin the
  version your target expects** — the Cloud module archetype (below) currently ships
  **6.5.2**, and the CI pipeline resolves against a fixed Artifactory, so bumping the
  plugin means confirming the new version is available there.
- **A JDK rollout drives the whole toolchain.** The constraint also runs backwards: an
  older plugin cannot run on a newer Gradle at all (plugin 6.5.2 failed on Gradle 9
  `[observed]`; the exact plugin version where Gradle 9 support starts is `[verify]`). Each
  JDK has a minimum Gradle (JDK 25 needs Gradle ≥ 9.1), and the plugin major must support
  that Gradle major, so raising the JDK usually forces Gradle and the plugin up together.
  A Gradle major bump also drops implicits: Gradle 9 no longer puts the JUnit Platform
  launcher on the test classpath, so add
  `testRuntimeOnly("org.junit.platform:junit-platform-launcher")` or the mandatory test
  no longer runs.
- **Build JDK ≠ language level.** `options.release` (the bytecode you deliver) is
  independent of the JDK the build runs on. A module can target 21 and still fail a build on
  JDK 25 because its Gradle/plugin toolchain cannot run there. Keep `languageLevel`
  matched to the server (see the archetype notes) and treat the build JDK as a separate
  upgrade, driven by the Cloud's Compatibility plans
  ([firstspirit-cloud → operations-and-maintenance.md]).
- The plugin auto-applies the **component annotations**
  (`com.espirit.moddev.components.annotations.*`, e.g. `@UrlFactoryComponent`) and
  generates the descriptor as `module-isolated.xml`. Newer annotation attributes
  (e.g. `@UrlFactoryComponent`'s `useRegistry` / `parameters`) require a plugin new
  enough to carry them — a mismatch surfaces as a compile error on the attribute.

### The FirstSpirit Cloud module archetype

On **FirstSpirit Cloud** a custom module is a **Bitbucket repo** built by the Cloud
CI (Bamboo → Artifactory), not an FSM you install — see
[firstspirit-cloud → environments-and-workflow.md]. The Cloud team hands you a
**project archetype** with a specific, load-bearing shape; keep it and just fill it in:

- **Kotlin DSL** — `build.gradle.kts` + `settings.gradle.kts` (not Groovy).
- Plugins: `java-library`, `maven-publish`, `de.espirit.firstspirit-module`,
  `net.researchgate.release`. Release publishes to Artifactory
  `es-snapshot-local` / `es-release-local` (SNAPSHOT vs release), `requireBranch = main|master`.
- **`ci.properties`** — read by the pipeline; `fsm.project.path` locates the FSM
  subproject (empty = built by the root project).
- **All config lives in `gradle.properties`** — `rootProjectName`, `groupId`,
  `java.languageLevel`, `firstSpirit.version`, the four `firstSpiritModule.*` values,
  and the publishing repos. The build fails fast if the required ones are blank.
  - **Match `firstSpirit.version` and `java.languageLevel` to the target server.** Find
    the current values two ways, cross-checking: the server's **About page**
    (`https://<server>/about.jsp` — a placeholder for the actual stage server; needs a
    FirstSpirit login), and the ODFS **Technical Requirements** data sheet
    ([`docs.e-spirit.com/odfs/edocs/admi/technical-requi/`](https://docs.e-spirit.com/odfs/edocs/admi/technical-requi/index.html)),
    where the required Java level is listed. Compiling with `options.release` at that
    level needs a matching **local JDK**.
- **At least one unit test is mandatory** — the shipped `ExampleTest` deliberately
  *fails* ("otherwise the build pipeline will fail"); replace it with real tests.
- Credentials come from the developer's **`~/.gradle/gradle.properties`**
  (`artifactory_hosting_username` / `artifactory_hosting_password`) — never committed.

## Naming scheme (modules and components)

- **Names** (technical, must be unique per server; the server makes directories
  from them): lowercase, no spaces, hyphen-separated, product-family prefix, and
  the **module name as the prefix for its component names** — e.g. module
  `mpl-example-login` → components `mpl-example-login-service`,
  `mpl-example-login-webapp`.
- **Display names**: CamelCase with spaces, and (for older/dual-mode modules) a
  server-mode suffix — `(I)` isolated-only, `(L)` legacy-only, `(I, L)` both. Keep
  the `<name>` stable across versions (changing it installs a *second* module
  instead of updating).

## Web-app components in Isolated Mode

Web apps get no access to the server's shaded internal libraries, so a web
component must **supply its own libraries as `<web-resources>`**. (A transitional
`fs-web-compatibility.fsm` re-exposed the old libs; it stopped shipping in
**2023.4**.) On deployment, web resources are reconciled by name across components
and duplicates filtered — an unresolved conflict aborts the rollout.

## Recognising an isolated server (brief)

Mostly admin territory, but useful to know: an isolated server runs
`fs-isolated-server.jar` from `server/lib-isolated`, uses `fs-wrapper.isolated.conf`,
and its version string carries a **`(I)`** tag. Full install/migration steps are in
the ODFS *Server Installation* page and the Administrator documentation.
