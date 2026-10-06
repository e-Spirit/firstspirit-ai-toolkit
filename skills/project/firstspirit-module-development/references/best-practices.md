# Module development — best practices

Distilled from a set of small example modules and their comments, and cross-checked
in 2026 against three Crownpeak connector modules that have been in production for years.
These are the judgement calls that keep a module maintainable and free of classloader grief.

---

## Scope discipline

(The authoritative classloading model — Isolated Mode, `scope` vs `mode`, and the
resource-compatibility algorithm — is in
[isolated-mode-and-packaging.md](isolated-mode-and-packaging.md). The practical
rules below follow from it.)

- **Default to `scope="module"`** for every jar — your impl and third-party libs.
  Module-local classes can't collide with other modules. In Isolated Mode a module
  must **bundle its own libraries** (the server's internal libs aren't visible), so
  declare every dependency.
- **`scope="server"` only when a class must be visible server-wide** — in
  practice, a **service interface** other modules/scripts call. Never the
  implementation.
- **Avoid `global` / `<library>`.** It dumps classes into the global scope
  (incl. BeanShell) and invites version clashes.
- Pin `name` (`groupId:artifactId`) and `version` (with `minVersion`/`maxVersion`
  where shared) so the server can reconcile duplicate libs. **A resource with no
  version in `module.xml` is treated as incompatible with every other resource of
  the same name** — always include version info (and put it in the jar filename
  too, to avoid overwriting).
- **File/web resources:** don't use generic folder names (`/files/`, `/resources/`);
  prefix with the module name so components don't overwrite each other in a shared
  web context.

## Bridging module code into scripts

Module-local classes are invisible to BeanShell. The **only** sanctioned bridge is
an **`Executable`** `<public>` component: keep it module-scoped, yet call it from a
script (`#!executable-class`) or an `FS_BUTTON` (`onClick="class:…"`). Prefer this
over pushing a library to global scope just so a script can see it.

## Service interface vs implementation

- Interface (`ZipcodeService`) → server scope, so callers can bind to it.
- Implementation (`ZipcodeServiceImpl`) → module scope.
- Give services a **public no-arg constructor**; do real setup in `init(...)`,
  not the constructor.
- `stop()` should release *activity*, but remember the service object itself may
  be retained — don't assume a fresh instance on restart.

## Broker idioms that hold across every component

Seen identically in three production connector modules; interfaces `[jar]`-verified.

- **Services via `ServicesBroker`.** `broker.requireSpecialist(ServicesBroker.TYPE).getService(MyService.class)`.
  Never `new MyServiceImpl()`, never a static singleton. The interface `Class` must come from
  the server-scope jar.
- **`requireSpecialist` when absence is a bug, `requestSpecialist` when it is an answer.**
  `requestSpecialist` returns null `[jar]`; that makes it the environment probe: no `UIAgent`
  and no `WebeditUiAgent` means generation, no `ProjectAgent` means a server context or a
  service that is still starting (`firstspirit-api-reference`, agents).
- **Server code reaches a project through `BrokerAgent.getBrokerByProjectId(id)`.** A service
  or server schedule has no project; do not cache a project broker across calls for a
  different project.
- **A per-project façade, built once.** Instead of resolving agents and services in every
  method, create one object from a broker that captures the project id, the services and the
  project-app configuration, then pass that around `[observed]`. It also gives the tests one
  seam to mock.
- **Guard on the project app, then adapt.** DAPs, plugins and executables check
  `ModuleAdminAgent.getProjectAppUsages(MODULE, APP)` (or a cached client service wrapping it)
  in `setUp` and register nothing when the app is absent, instead of failing later with a
  missing configuration.
- **Write path.** lock → mutate → save → unlock in a nested try; the outer catch handles
  `LockException | ElementDeletedException` (`firstspirit-api-reference`, object model).

## Non-public packages that look public

`checkCompliance` flags classes marked `@Internal`. These are the packages that end up in the
compliance baselines of long-lived modules and would break them on a package move. Treat each
as an anti-pattern, with the replacement:

| Seen in production | Why it is a risk | Use instead |
| --- | --- | --- |
| `de.espirit.common.StringUtil`, `de.espirit.firstspirit.common.StringUtil`, `de.espirit.common.tools.XmlDocuments`, `de.espirit.common.json.*` | Not in the Access API javadoc `[javadoc]` — no compatibility promise, even though official example modules use two of them | `String.isBlank()`, the JDK XML and a JSON library of your own |
| `de.espirit.firstspirit.client.access.editor.lists.Catalog` | The concrete `FS_CATALOG` value implementation | `FormField` / `FormData` and the documented `Catalog` access in `firstspirit-api-reference` |
| `de.espirit.firstspirit.web.ConnectionExtractor` | Web-internal; pulls the editor `Connection` out of an `HttpServletRequest` | The `SpecialistsBroker` the web-app component receives |
| `de.espirit.firstspirit.server.event.*` (`EventListener`, `StoreEvent`, `StoreEventFilter`), `agency.EventAgent` | Server-internal event bus | `StoreListener` on the store `[jar]`; or react in the component that caused the change |
| `de.espirit.firstspirit.access.AdminService` → `ProjectStorage` *just to test that a project exists* | Demands admin rights for a question the broker answers | `BrokerAgent.getBrokerByProjectId` and a null check. `AdminService.getScheduleStorage()` for listing or creating schedule entries is fine — `ScheduleStorage` `[jar]` is the intended API for that (confirmed internally at FirstSpirit, 2026-09-18) |
| `de.espirit.or.*` (`Session`, `Select`, `Equal`, `EntityList`) | Raw ORM layer | `QueryAgent` (`firstspirit-api-reference`, querying) |
| `de.espirit.firstspirit.agency.LegacyModuleAgent` | Legacy (confirmed internally, 2026-09-18) | `ModuleAdminAgent` `[jar]` for configuration and usages; `de.espirit.firstspirit.access.ModuleAgent` `[jar]` (`getComponents(Class)`, `getClassLoader()`) is *not* deprecated and is how the official examples discover other modules' components |
| `de.espirit.firstspirit.store.access.contentstore.ContentOptionFactory` (`getTable()`) *to find the table template behind a database-backed combobox / radiobutton / checkbox* | `@ApiStatus.Internal` `[jar]`; `checkCompliance` fails on it | `gomSelect.getEntries().getIncludeConfiguration()` → `GomIncludeOptions.getOptionFactory().getOptionModel(broker, language, release)` → `instanceof TableTemplateProvider` → `getTableTemplate()` — all Access API `[jar]`; worked example in `firstspirit-api-reference` (values and data). The `Entity` alone is not enough: several table templates can share one table (confirmed internally at FirstSpirit, 2026-09-30) |
| `com.espirit.moddev.fcaf.*`, `com.espirit.ps.psci.*` | Internal Crownpeak frameworks, not FirstSpirit API | Only if you own them |

Not in this table on purpose: **`de.espirit.common.base.Logging`** (`logInfo(String, Class)`,
`logWarning`, `logError`, …) *is* part of the documented Access API `[javadoc]` and the
supported logger for module code — an earlier version of this file listed it as internal,
which was wrong (corrected 2026-09-18 after internal confirmation). The same holds for
`de.espirit.common.tools.Strings`, `Streams`, `Objects`, `Windows` and
`de.espirit.common.util.Pair` / `Filter`: all in the Access API javadoc `[javadoc]` and used
throughout the official example modules. Earlier versions of this table listed them as
risky; the javadoc, not the package name, decides.

The last row is a reminder that "compiles against `fs-isolated-runtime`" is not the same as
"public API": the runtime jar contains the internal classes too. `checkCompliance` with an
empty, or shrinking, baseline is the only mechanical proof
([multi-project-layout.md](multi-project-layout.md)).

## Testing a module

- `fs-isolated-runtime` as `testImplementation`; mock `SpecialistsBroker`, agents and store
  elements with Mockito. Production modules run hundreds of such tests without a server
  `[observed]`.
- Add `--add-opens java.base/java.lang=ALL-UNNAMED` (and `java.util`, `java.time`) to the test
  JVM when FirstSpirit serialisation or reflection is exercised.
- Keep tests that hit the external system (`*IT`) out of the default `test` task.
- Assert the descriptor, not only the code: unzip the built `.fsm` in a test and check that
  the expected components and scopes are present. A wrong `fsWebCompile` line fails silently
  at build time and loudly in the customer's ContentCreator.

## Script vs module — choose deliberately

| Use a **script** when | Use a **module** when |
| --- | --- |
| Project-local, one-off, migration, glue | Long-term, load-bearing, reused across projects |
| Editors/developers tweak it in the client | Needs real packaging: services, plugins, web apps |
| No build/release process wanted | Versioned, tested, deployed as an FSM |

When in doubt for durable logic: **module**, exposed as an `Executable` so scripts
can still call it.

## Entry-point mindset

- The examples in this skill are **entry points**, deliberately simplified — real modules do
  more validation, error handling, and separation of concerns.
- Keep **connection/bootstrap code at the edge** (see
  [external-api-access.md](external-api-access.md)) so the core logic runs
  unchanged whether launched standalone or inside a module.
- Always follow the **lock → modify → save → unlock** discipline for writes (see
  `firstspirit-api-reference`), and log through the context, not `System.out`
  (see `firstspirit-scripting`).

## Public API only, and how stability is signalled

Use documented `de.espirit.firstspirit.*` types. Non-public / internal classes and
methods (and things like `ConnectionManager.setProxy`) carry no compatibility
guarantee and may change or disappear without notice.

FirstSpirit exposes one public **Access API** (Java); the historical "Access API
vs Developer API" split no longer applies (current material describes them as
consolidated). The stability policy (ODFS *Template development → FirstSpirit API →
API documentation*) is:

- Incompatibly-changing methods/classes are first marked **`@Deprecated`** (with
  timeframe + alternative in the docs) and listed in the **release notes**.
- They are removed or changed **no earlier than six additional releases** after
  that. (Note: *releases*, not months.)
- **`@ApiStatus.Experimental`** marks provisional additions — these are **not** in
  the release notes and may change as early as the next release after being
  deprecated.
- **Always check the release notes** when moving FirstSpirit versions.

Source: `https://docs.e-spirit.com/odfs/template-develo/firstspirit-api/api-documentati/`.
