# Component types

The interface to implement for each component, with a minimal working skeleton.
Register every one with its `@…Component` annotation or in `module.xml` (see
[module-descriptor.md](module-descriptor.md)). The objects these components call
(brokers, agents, stores) are documented in `firstspirit-api-reference`.

Two rules that hold for every component below:

- **Obtain a service through `ServicesBroker.getService(Interface.class)`**, never by
  instantiating the implementation; obtain agents through `requireSpecialist` when their
  absence is a bug, `requestSpecialist` when it is a legitimate "not in this client"
  `[jar]`. The broker comes from `ServerEnvironment.getBroker()` (services, project apps),
  or **is** the `BaseContext` handed to plugins, DAPs and executables.
- **A server component has no project.** It reaches one through
  `BrokerAgent.getBrokerByProjectId(long)` `[jar]`.

---

## Executable — the workhorse `<public>` component

`de.espirit.firstspirit.access.script.Executable`. Callable from scripts
(`#!executable-class`), `FS_BUTTON` (`onClick="class:…"`), and directly. The
calling context and parameters arrive in the `Map`.

```java
public class DocumentImporterExecutable implements Executable {

    public Object execute(Map<String, Object> params, Writer out, Writer err) throws ExecutionException {
        return execute(params);
    }

    public Object execute(Map<String, Object> params) throws ExecutionException {
        Object context = params.get("context");                 // the script/button context
        if (!(context instanceof GuiScriptContext)) {
            throw new IllegalArgumentException("expected GuiScriptContext, got " + context);
        }
        GuiScriptContext ctx = (GuiScriptContext) context;
        // ... do work; user params are other map keys ...
        return null;                                            // return value flows back to caller
    }
}
```

- Always implement **both** `execute` overloads (delegate the 3-arg to the 1-arg).
- `params.get("context")` is a `ScriptContext`/`SpecialistsBroker` subtype — cast
  to what the calling site provides (`GuiScriptContext` in a client, plain
  `SpecialistsBroker` in a web/ContentCreator context).

## Server Service — `<service>`

`de.espirit.firstspirit.module.Service<T>`. A long-lived server object with a
lifecycle; exposes an interface `T` others can call.

```java
public interface ZipcodeService {                 // the public interface (server-scope jar)
    String getCity(String zipcode);
}

public class ZipcodeServiceImpl implements ZipcodeService, Service<ZipcodeService> {
    private boolean running;
    private ZipCodeLookup lookup;

    public ZipcodeServiceImpl() { }                // needs a public no-arg constructor

    public String getCity(String zip) { return lookup.getCity(zip); }

    public void start()  { running = true; }
    public void stop()   { running = false; }      // note: underlying objects not discarded
    public boolean isRunning() { return running; }

    public void init(ServiceDescriptor descriptor, ServerEnvironment env) {
        lookup = new ZipCodeLookup();              // read config, allocate resources
    }
    public void installed()  { }
    public void uninstalling() { }
    public void updated(String from) { }

    public Class<? extends ZipcodeService> getServiceInterface() { return ZipcodeService.class; }
    public Class<? extends ServiceProxy<ZipcodeService>> getProxyClass() { return null; }
}
```

- Put the **interface** in a server-scope jar; keep the **impl** module-scope
  (the multi-jar build that makes this mechanical:
  [multi-project-layout.md](multi-project-layout.md)).
- `getProxyClass()` returns `null` unless you need a client-side proxy (next section).
- `init(ServiceDescriptor, ServerEnvironment)` `[jar]` is where the broker is captured:
  `broker = env.getBroker()`. A service has **no project context**; to touch a project's
  stores it asks `BrokerAgent.getBrokerByProjectId(id)` for a project broker `[jar]` (see
  `firstspirit-api-reference`, agents).
- Production services keep `start()`/`stop()` to flipping a flag and starting/stopping
  executors; `updated(String oldVersion)` `[jar]` on a service is normally a log line plus a
  cache reset.
- Do not use the JDK's **common fork-join pool** (parallel streams, `CompletableFuture`
  defaults) inside a service: FirstSpirit installs a `SecurityManager`, and the common
  pool's default thread factory throws an `AccessControlException` under it. Build your own
  pool with an explicit worker-thread factory `[observed]`.

### Calling a service — always through the `ServicesBroker`

```java
ServicesBroker services = broker.requireSpecialist(ServicesBroker.TYPE);      // [jar]
ZipcodeService zip = services.getService(ZipcodeService.class);               // throws ServiceNotFoundException
```

Never instantiate or cache the implementation class; the `Class` you pass must be the one
loaded from the server-scope jar, which is why the interface lives there.

### ServiceProxy — run part of the call on the caller's side

`de.espirit.firstspirit.module.ServiceProxy<T>` `[jar]` has one method,
`init(T remoteService, Connection connection)`. Return a proxy class from `getProxyClass()`
and FirstSpirit instantiates it **in the client or web app**, hands it the remote stub, and
gives callers the proxy instead. The proxy implements **both** the service interface and
`ServiceProxy<T>`:

```java
public class ConfiguredPreviewService
        implements PreviewService, ServiceProxy<PreviewService> {

    private PreviewService remote;

    public void init(PreviewService remote, Connection connection) { this.remote = remote; }

    public Ticket generateTicket(Ticket requested, ProjectConfig cfg) {
        Ticket effective = withDefaultsFrom(requested == null ? new Ticket() : requested, cfg);
        return remote.generateTicket(effective, cfg);   // one round trip, fully populated
    }
}
```

Use it to fill configuration defaults, validate arguments or cache client-side, so the server
implementation stays free of per-project lookups and each call crosses the wire once. The proxy
jar must be in **module and web scope** (it runs wherever callers run), never server scope.
`[observed]` in four production services of one connector module.

## ValueService — provide values to Rules `<public>`

`de.espirit.firstspirit.service.value.ValueService`. Computes a value for a
`<RULE>` (validation, prefill, lookup). **Technically unrelated to a server
`Service`.**

```java
public class ZipcodeValidationValueService implements ValueService {
    public Object getValue(SpecialistsBroker broker, Map<String, ?> params) {
        String zipcode = (String) params.get("zipcode");
        Object mandatory = params.get("mandatory");            // optional rule param
        boolean req = (mandatory instanceof String)  ? Boolean.valueOf((String) mandatory)
                    : (mandatory instanceof Boolean) ? (Boolean) mandatory : false;
        if (Strings.isEmpty(zipcode) && !req) return true;
        return new ZipCodeLookup().getCity(zipcode) != null;   // Boolean, String, ... per rule use
    }
}
```

Reference it in the form's rules by the component's `<public>` **name**, passing
params from form fields — e.g. `service="ZipcodeValidation"`. (Rule syntax:
`firstspirit-templating-reference`.)

## ProjectApp (+ Configurable) — `<project-app>`

A per-project application, typically carrying configuration other components read.

```java
public class DocumentImporterProjectApp implements ProjectApp {
    public void init(ProjectAppDescriptor descriptor, ServerEnvironment env) { }
    public void installed()   { }
    public void uninstalling(){ }
    public void updated(String from) { }
}
```

Its `<configurable>` class supplies the ServerManager config dialog (often built
with the GenericConfiguration helper). Components read whether the app is
installed/active via a settings helper and adapt (e.g. a toolbar button only
appears when the ProjectApp is present).

`ProjectApp extends Component<ProjectAppDescriptor, ProjectEnvironment>` `[jar]`, so
`init` receives a `ProjectEnvironment` with `getProjectId()`, `getProject()`,
`getBroker()`, `getConfDir()` and `getInstalledVersion()` `[jar]`. Three lifecycle idioms
from production modules:

**Create the config file on first install.** In `init`, obtain the file through the
environment, not through `java.io.File`:
```java
FileHandle cfg = env.getConfDir().obtain("configuration.properties");   // [jar] FileSystem.obtain
if (!cfg.exists()) { cfg.save(new ByteArrayInputStream(new byte[0])); }
```
The same `getConfDir()` exists on `ServerEnvironment`, so a **service-level**
`Configuration<ServerEnvironment>` persists its values the same way, without a database.

**Migrate configuration in `updated(String oldVersion)`.** The argument is the previously
installed module version. Compare it with the version whose release changed the config
format, read the old file, write the new shape, log what happened `[observed]`:
```java
public void updated(String oldVersion) {
    if (isConfigMigrationNeeded(oldVersion, CONFIG_BREAKING_VERSION)) {
        Properties old = loadOldConfiguration();
        store(convert(old));
    }
}
```
Without this, every module update that renames a property silently resets customer
configuration.

**"Is my project app installed here?"** The public answer is the `ModuleAdminAgent` `[jar]`:
```java
ModuleAdminAgent admin = broker.requireSpecialist(ModuleAdminAgent.TYPE);
boolean installed = admin.getProjectAppUsages(MODULE_NAME, PROJECT_APP_NAME)   // Collection<Project>
                         .stream().anyMatch(p -> p.getId() == projectId);
```
Put this helper in the jar every component can see (the API jar), so DAPs, plugins and
executables can guard their `setUp` on it without depending on the project-app jar. Two
cautions `[observed]`: the call is a server round trip, cache the result in a client plugin;
and during server start a service's `start()` may run before the ServiceManager is complete,
so a service that needs another service must probe `requestSpecialist(ProjectAgent.TYPE) != null`
first or catch `ServiceNotFoundException` `[jar]` rather than crash the boot.

## SiteArchitect toolbar plugin — `<public>`

`JavaClientEditorialToolbarItemsPlugin` (a `JavaClientToolbarItemsPlugin`).
Supplies buttons to the SiteArchitect toolbar.

```java
public class DocumentImporterExecutableToolbarItemsPlugin
        implements JavaClientEditorialToolbarItemsPlugin {

    private boolean isActive;
    public void setUp(BaseContext ctx) { isActive = DocumentImporterSettings.isActive(ctx); }
    public void tearDown() { }

    public Collection<? extends JavaClientToolbarItem> getItems() {
        return isActive ? Collections.singletonList(new MyItem()) : Collections.emptyList();
    }

    private static class MyItem implements ExecutableToolbarItem {
        public void execute(ToolbarContext ctx) { /* ... */ }
    }
}
```

Related client plugins in the examples: a **ClientService toolbar plugin** and a
**PermanentPlugin** (long-lived client-side component). Same registration pattern
(`<public>` + a `client.plugin` interface).

## PermanentPlugin for both clients — `<public>`

`JavaClientPermanentPlugin` and `WebeditPermanentPlugin` are both marker interfaces
extending `Plugin` (`setUp(BaseContext)`, `tearDown()`) `[jar]`, so **one class can serve
SiteArchitect and ContentCreator**. The production use is registering **client services**
that other components in the same client look up:

```java
@PublicComponent(name = "MyModule_ClientPermanentPlugin")
public class MyPermanentPlugin implements JavaClientPermanentPlugin, WebeditPermanentPlugin {
    private BaseContext context;
    private ProductManager manager;

    public void setUp(BaseContext context) {
        this.context = context;
        ClientServiceRegistryAgent registry = context.requireSpecialist(ClientServiceRegistryAgent.TYPE); // [jar]
        if (isProjectAppInstalled(context)) {                  // your helper: see ProjectApp above
            manager = new ProductManager(context);
            registry.registerClientService(ProductManager.class, manager);
        }
    }

    public void tearDown() {
        if (manager != null) {
            context.requireSpecialist(ClientServiceRegistryAgent.TYPE).unregisterClientService(manager);
        }
    }
}
```

Everything registered in `setUp` is unregistered in `tearDown`; the plugin outlives editor
sessions, not the client process. `BaseContext.is(BaseContext.Env.WEBEDIT)` tells the two
clients apart when the UI differs `[observed]`.

## Schedule task — `@ScheduleTaskComponent`

A custom entry in a project or server schedule (ServerManager → Schedule management). Four
classes and one data holder, all `[jar]`-verified:

| Piece | Contract | Role |
| --- | --- | --- |
| Application | `ScheduleTaskApplication<D extends ScheduleTaskData>`: `getName(Locale)`, `getDescription(Locale)`, `isApplicable(ScheduleTaskDefinitionContext)`, `getExecutor()`, `createData()`, `getAspect(ApplicationAspectType)` | The registered component |
| Data | your `D implements ScheduleTaskData` | Serialised task parameters; put it in the **server-scope** jar so client and server share it |
| Form factory | `ScheduleTaskFormFactory<D>`: `createForm(SpecialistsBroker)` | Named in the annotation's `formClass` |
| Form | `ScheduleTaskForm<D>`: `load(cfg)`, `store(cfg)`, `openAndWait(Window, String)` | The Swing dialog in ServerManager |
| Executor | `ScheduleTaskExecutor<D>`: `execute(control, data, ctx)`, `validate(control, data, ctx)` | Runs on the server |

```java
@ScheduleTaskComponent(taskName = "MyImportTask", description = "Starts an import",
                       formClass = MyImportTaskFormFactory.class)
public class MyImportTaskApplication implements ScheduleTaskApplication<MyImportTaskData> {
    private final ApplicationAspectMap aspects = new ApplicationAspectMap();
    { aspects.put(IconProviding.TYPE, () -> new ImageIcon(getClass().getResource("task_icon.png"))); }

    public <A> A getAspect(ApplicationAspectType<A> type) { return aspects.get(type); }
    public String getName(Locale l)        { return "My importer"; }
    public String getDescription(Locale l) { return "Starts an import job"; }
    public boolean isApplicable(ScheduleTaskDefinitionContext ctx) { return ctx.hasProject(); } // project schedules only
    public ScheduleTaskExecutor<MyImportTaskData> getExecutor() { return new MyImportTaskExecutor(); }
    public MyImportTaskData createData() { return new MyImportTaskData(); }
}
```

`ScheduleTaskDefinitionContext` is itself a `SpecialistsBroker` `[jar]`, so `isApplicable`
can inspect the project. Inside `execute`, the context is a broker too; the three agents
that only exist in a running schedule live in
**`de.espirit.firstspirit.scheduling.agency`** (not `agency`) `[jar]`:

| Agent | Members | Use |
| --- | --- | --- |
| `JobAgent` | `getStartingTime()`, `getVariable(String)`, `setVariable(String, Object)`, `getFolder()`, `getFolderPath()`, `abort()` | Hand data from one task to the next in the same run (string keys, `Object` values — cast yourself); abort the whole job |
| `GenerationAgent` | `createDeltaGeneration()`, `getGeneratedFiles()`, `getOutput()` | Delta generation: compute the change set in a task placed *before* the generate task and configure it; a missing generate task fails the run `[observed]` |
| `ScheduleTaskControlsAgent` | `getControlsOfPrecedentTasks()`, `getControlsOfSubsequentTasks()` | Inspect or steer neighbouring tasks | For a task that is just "run this class with these parameters", a
script task calling an `Executable` is far less code; reach for a ScheduleTaskApplication
when editors must configure the task through a dialog.

## GomIncludeValueProvider — dynamic option lists for forms

`de.espirit.firstspirit.access.store.templatestore.gom.GomIncludeValueProvider<T>` `[jar]`:
`getType()`, `getValues(SpecialistsBroker)`, `getKey(T)`. Registered as a plain
`@PublicComponent`; a `CMS_INCLUDE_OPTIONS type="public"` in a form names it and the
combo box fills from `getValues`. Production tip `[observed]`: `getValues` runs in editors
**and** at generation; detect the environment by probing
`broker.requestSpecialist(UIAgent.TYPE) == null && broker.requestSpecialist(WebeditUiAgent.TYPE) == null`
and choose a long-lived cache for generation, a short one for editors.

## ContentCreator / web components — `<web-app>`

To run code in a web context (preview / ContentCreator), ship the class in a
**`web-app`** component and target the web context in ServerManager. A
ContentCreator action is often just an `Executable` that shows UI via the
`OperationAgent`:

```java
public class ShowPopupExecutable implements Executable {
    public Object execute(Map<String, Object> map, Writer o, Writer e) { return execute(map); }
    public Object execute(Map<String, Object> map) {
        SpecialistsBroker broker = (SpecialistsBroker) map.get("context");
        RequestOperation op = broker.requireSpecialist(OperationAgent.TYPE)
                                    .getOperation(RequestOperation.TYPE);
        op.perform("A popup from an Executable\n\nmyParam=" + map.get("myParam"));
        return "return value";
    }
}
```

## DataAccessPlugin (DAP) and Report — `<public>`

Integrate *foreign* objects (external systems, or other project data) so editors
can reference them in an **`FS_INDEX`** and browse/search them in a **Report**. The
`FS_INDEX` stores only a String **identifier** per object; the DAP translates
identifier ⇄ object transparently (including at generation via `st_index.values()`)
and renders objects as snippets.

```xml
<public>
    <name>TagsDataAccess</name>
    <class>de.espirit.ps.examples.tagging.v52.tags.TagDataAccess</class>
</public>
```

Implement `DataAccessPlugin<D>` and its session/stream chain, adding **aspects**
(not `implements`) for features like `Reporting`, `Filterable`, `TransferHandling`.
A DAP with the `Reporting` aspect *is* a Report.

**Full detail — interfaces, the aspect model, catalogue, and a real skeleton from
a small tagging example — in [data-access-and-reports.md](data-access-and-reports.md).**
Aspect-based DAP/Report API is FirstSpirit 5.2+.

## UrlFactory — generation URL/path hotspot — `<public>`

Customise how FirstSpirit builds **URLs/paths** for pages and media during
generation (e.g. SEO-friendly paths). A generation-time hotspot registered as a
`<public>` component whose `<configuration>` block names your `UrlFactory`
implementation.

**Recommended: the `@UrlFactoryComponent` annotation** — the Gradle plugin scans it
and generates the descriptor; no hand-written XML. Attributes: `name` (required),
`displayName`, `description`, `useRegistry` (boolean → `<UseRegistry>`; whether
generated URLs are persisted in the project URL registry — set **`false`** for a
deterministic factory that builds paths itself, so it never reuses stale stored URLs),
optional `filenameFactory` (a `FilenameFactory` class), and repeatable `parameters`
(`@UrlFactoryComponent.Parameter(name, value)` → extra `<configuration>` children that
arrive in `init`'s settings map).

```java
@UrlFactoryComponent(name = "SeoUrlFactory", displayName = "SEO URLs", useRegistry = false)
public class SeoUrlFactory implements UrlFactory { … }
```

The plugin then emits the descriptor below — hand-write it only if you maintain the
descriptor yourself. The documented `<class>` is the *interface*
**`de.espirit.firstspirit.generate.UrlCreatorSpecification`** `[odfs]` (Advanced URLs →
Configuration, FirstSpirit 2026.5). That works because the server never instantiates this
`<class>`: it is a type key. The module manager matches every `<public>` whose class *is or
implements* `UrlCreatorSpecification`, then builds its own internal specification object
from the `<configuration>` block `[core]`. Consequently the internal implementation class
`UrlCreatorSpecificationImpl` (seen in one field module) matches too, but it is
`@ApiStatus.Internal` `[core]` — use the interface name the documentation gives.

```xml
<public>
    <name>SeoUrlFactory</name>
    <displayname>SEO URLs</displayname>
    <class>de.espirit.firstspirit.generate.UrlCreatorSpecification</class>
    <configuration>
        <UrlFactory>com.example.urls.SeoUrlFactory</UrlFactory>
        <UseRegistry>false</UseRegistry>
    </configuration>
</public>
```

**The one case that needs hand-written XML even with the Gradle plugin: re-configuring the
built-in `AdvancedUrlFactory`.** Its parameters (`useWelcomeFilenames`, `useLowercase`,
`useRegistry`, `removeDeleted`, `useIRIs`, `selfLink`, …) are normally set per generation
schedule (`context.setProperty("#urlCreatorSettings", map)` in a schedule script). That
does not work for headless/CaaS projects, which have no generation schedule, and it repeats
the same map in every schedule of a hybrid project. The documented alternative `[odfs]`
(Advanced URLs → Configuration, FirstSpirit 2026.10) is a second `<public>` entry whose
`<UrlFactory>` names the built-in class and whose remaining `<configuration>` children are the
parameters — no Java class of your own:

```xml
<public>
    <name>ConfiguredAdvancedUrlCreator</name>
    <class>de.espirit.firstspirit.generate.UrlCreatorSpecification</class>
    <configuration>
        <UrlFactory>de.espirit.firstspirit.generate.AdvancedUrlFactory</UrlFactory>
        <useLowercase>true</useLowercase>
        <useWelcomeFilenames>true</useWelcomeFilenames>
    </configuration>
</public>
```

Because there is no class, there is nowhere to put `@UrlFactoryComponent`; with the Gradle
plugin you provide a `module-isolated.xml` **template** in the module directory
(`moduleDirName`) that keeps the generated parts as placeholders (`$components`, `$resources`,
`$name`, `$version`, …) and adds this block by hand (plugin README, section
*module-isolated.xml*). Do **not** subclass or instantiate `AdvancedUrlFactory` in Java to
achieve the same: the class is not part of the Access API, and a delegating wrapper can only
set the parameters the factory reads itself, not those evaluated by the surrounding URL
mechanism (`useRegistry` and friends). The descriptor route is the sanctioned one precisely
because the class name appears only as configuration, not in code (confirmed internally at
FirstSpirit, 2026-09-25). Put the entry in a module that carries general project
infrastructure, not in a single-purpose module (a DAP, say) where it would be forgotten.

Implement `de.espirit.firstspirit.generate.UrlFactory`:

```java
public class SeoUrlFactory implements UrlFactory {
    private PathLookup pathLookup;

    // Newer entry point: gives the context (broker/agents + getParameters()/
    // getPathLookup()). Keep the context (for logging), then DELEGATE to init so
    // both entry points share one code path -- don't duplicate the wiring here.
    public void setUp(UrlFactoryContext context) {
        this.context = context;
        init(context.getParameters(), context.getPathLookup());
    }

    // Older entry point -- some FirstSpirit versions still call init directly, so it
    // must stand on its own ("do what it can" without a context). settings =
    // <configuration> children (tag name lower-cased -> text) + @UrlFactoryComponent params.
    public void init(Map<String,String> settings, PathLookup pathLookup) {
        this.pathLookup = pathLookup;
    }

    // URL for a page / content-producing element (ContentProducer)
    public String getUrl(ContentProducer cp, TemplateSet ts, Language lang, PageParams pageParams) { ... }

    // URL for a media node (Picture/File), resolution may be null
    public String getUrl(Media node, @Nullable Language lang, @Nullable Resolution resolution) { ... }
}
```

Notes: FirstSpirit creates a **new `UrlFactory` instance per generation run** and calls
`setUp`/`init` on it, so caching the broker, the `PathLookup` or per-run lookups in
instance fields is safe; there is no cross-run state to worry about `[observed]`. The
implementation jar goes in **`module` scope** — the plugin default
(`projectJarScope="module"`). This is correct even though generation runs
server-side; **`server` scope is not required** and on **FirstSpirit Cloud**'s shared
managed server it is to be avoided. Use `PathLookup.lookupPath(element, language,
templateSet)` to honour editor-defined paths, but mind its contract:
- **Pass the language you're actually generating**, not the project's master language —
  a folder can carry a language-specific configured path, and a master-language lookup
  would silently use the wrong one.
- It **throws `NullPointerException`** if `element` or `language` is null, **or if a
  Site Store folder is passed without a `TemplateSet`**. So Site Store folders need the
  page's template set; Media Store folders take `null`; and a language-independent media
  URL can arrive with a **null language** — guard it (skip the lookup) rather than crash.
- **The Site Store root can hold an API-set path too.** The GUI can't assign a SEO URL to
  the store root (CORE-3344, won't-fix), but the API can, and generation honours it. If
  you walk the folder tree yourself, run the `lookupPath` on the root *before* you skip
  emitting its uid — otherwise a root path is silently ignored.

`PageParams`/`ContentPageParams` signal content projection (single-dataset pages). **Produce URL-safe paths yourself** — reserved/unsafe characters are not
encoded downstream, and Cloud (S3 + CloudFront) delivery breaks on them. Reference
names (uids) are already ASCII-safe; file/display names are not. If you lower-case a
segment (e.g. the language folder), use `toLowerCase(Locale.ROOT)` — the default-locale
overload can corrupt casing (Turkish `I`), and Cloud paths are case-sensitive.
**Don't reach for the channel's conversion table to do this:**
`TemplateSet.getConversionTable()` is the **content-quoting** table applied to generated
output *text* (e.g. the HTML channel escaping `<` → `&lt;`), **not** a file-name rule.
Running names through it injects entities into paths and makes channels diverge — normalize
file/folder names in the factory yourself.

## UploadHook — intercept media uploads — `<public>`

Implement `de.espirit.firstspirit.service.mediamanagement.UploadHook` (extends `Public`)
`[jar]` and register it as a `<public>` component (`@PublicComponent`). The server calls
it **synchronously** inside the upload, for every client (SiteArchitect, ContentCreator,
API):

| Method `[jar]` | When | Reject with |
| --- | --- | --- |
| `preProcess(BaseContext, Media, File, InputStream, long size)` | before a *file* is stored | throw `UploadRejectedException` |
| `preProcess(BaseContext, Media, Picture, Resolution, InputStream, long size)` | before a *picture resolution* is stored | throw `UploadRejectedException` |
| `postProcess(BaseContext, Media, File, long size)` / `postProcess(BaseContext, Media, Picture, long size)` | after the content is stored | — |
| `uploadAborted(BaseContext, Media, MediaElement)` | the upload was rejected — by **this or any other** hook | — |

`UploadRejectedException extends RuntimeException` `[jar]` (constructors `(String)` and
`(String, Throwable)`, plus `getStoreElement()`/`setStoreElement()`); both `preProcess`
overloads also declare `IOException`. The interface contract `[javadoc]`:

- **Synchronous by contract.** If the hook does anything concurrent, it must block until
  that work is finished; the server does not wait for you otherwise. A slow scan therefore
  blocks the editor's upload dialog — time-box external calls and fail open or closed
  deliberately.
- **Privileged.** Every hook method runs with *all* permissions, not the uploading user's.
  If the decision depends on the user, get them via `UserAgent` from the `BaseContext` and
  check `media.getPermission(user)` yourself.
- The hook is only called while the `Media` **holds a lock**; `postProcess` runs after the
  server has stored the content, and no explicit save is needed.

What triggers it (confirmed internally at FirstSpirit, 2026-09-29): technically **every
`File.setFile(...)` / `Picture.setPicture(...)` call**, i.e. whenever the binary content
changes — regardless of whether the client was SiteArchitect, ContentCreator, the REST API,
an External Sync import or a script. For pictures the hook runs **once per resolution**.
*Defining* a crop alone does **not** trigger it (no binary changes); rename, metadata edits,
move and copy do not either.

Field observations from a Professional Services upload-hook module `[observed]`, check
against your server version:

- The exception **message is shown to the editor** — write it for them, not for the log.
- The `InputStream` can be read once by your hook; the server keeps its own copy, so a
  virus scan or a header check consuming the stream does not break the upload.

## Reacting to element changes — `IDProviderEventAgent`

For "do something when an element is saved" the supported hook is the event agent, not
the server-internal event bus (see `best-practices.md`). `de.espirit.firstspirit.agency.IDProviderEventAgent` `[jar]`:

```java
boolean addListener(Predicate<EventInfo> filter, Consumer<RevisionEvent> listener);
boolean removeListener(Consumer<RevisionEvent> listener);
```

`RevisionEvent` `[jar]` gives `getRevision()`, `getUserService()` and
`getChanges()` (a collection of `IDProviderChange` — `getEventInfo()` + `getElement()`);
`EventInfo` `[jar]` extends `BasicElementInfo` and adds `getEventType()`, `isRelease()`,
`getParentId()`, `getOldParentId()`, `getGid()` and `getRevision()`.

The contract `[javadoc]` (agent available since 5.2.210505):

- **Keep a strong reference to the listener.** The agent holds it *weakly*; a lambda
  stored only in a local variable is collected and silently de-registered. Put it in a
  field or a map keyed by project id, and call `removeListener` in `stop()`/`tearDown()`.
- **Filter in the predicate**, e.g. on `eventInfo.getStoreType()`. It must return fast: it
  runs on the lightweight `EventInfo` before the heavyweight `RevisionEvent` is built, and
  it may be called once per change operation in the same revision — one accepted call
  delivers the whole event.
- **The listener runs in its own worker thread** and does not block other listeners.
  `addListener` returns `false` when the same filter/listener pair is already registered.
- A filter or listener that implements `Closeable` is closed when the underlying
  `Connection` closes; a closed connection delivers no more events.

Field observations from Professional Services modules `[observed]`:

- **Project-scoped broker.** Get the agent from `BrokerAgent.getBrokerByProjectId(id)`;
  a server-scoped broker did not deliver element events. A `ProjectApp` receives a
  project broker anyway.
- **The element may still be locked** when the listener runs. If you must write, retry
  with a short back-off on your own `ScheduledExecutorService`; do not block the event
  thread, and do not pull in a retry library for three lines of code.

## Custom input component — `GadgetSpecification` — `<public>`

A custom form component (a "gadget") is a `<public>` component whose `<class>` is
`de.espirit.firstspirit.module.GadgetSpecification` `[odfs]` (FirstSpirit 2026.5) and whose
`<configuration>` names your classes. Like the UrlFactory `<class>`, this is a type key the
module manager matches, not a class you implement: it is on the 5.2.240208 runtime jar but
no longer on 5.2.261011, while the documentation keeps the name `[jar]`. Four parts, all in
the Access API `[jar]`:

| Part | Interface | Runs in |
| --- | --- | --- |
| GOM element | your subclass of `GomFormElement`/`AbstractGomFormElement` — the `<FS_…>` tag and its attributes | server + both clients |
| SiteArchitect editor | `de.espirit.firstspirit.ui.gadgets.swing.SwingGadgetFactory<E>` → `SwingGadget` (`AbstractValueHoldingSwingGadget` as base) | SiteArchitect |
| ContentCreator editor | `de.espirit.firstspirit.webedit.server.gadgets.WebPluginGadgetFactory<G, C>` → `WebPluginGadget<C>`; `getControllerName()`, `getScriptUrls()`, `getStylesheetUrls()` | web app |
| Value engineer | `de.espirit.firstspirit.client.access.editor.ValueEngineerFactory<T, F>` → `ValueEngineer<T>` (`write`/`read` node lists, `getEmpty`, `isEmpty`, `copy`) | wherever the value is (de)serialised |

Descriptor shape (`@GadgetComponent` on the GOM class generates it — see
`multi-project-layout.md`; the official example collection still hand-writes it, as noted in the skill's review log):

```xml
<public>
    <name>MyGadget</name>
    <class>de.espirit.firstspirit.module.GadgetSpecification</class>
    <configuration>
        <gom>com.example.gadget.GomMyInput</gom>            <!-- exactly one -->
        <factory>com.example.gadget.MySwingFactory</factory> <!-- one per client -->
        <factory>com.example.gadget.MyWebFactory</factory>
        <value>com.example.gadget.MyValueEngineerFactory</value>  <!-- 0..1 -->
        <scope data="yes" content="yes" link="no" unrestricted="no"/>  <!-- mandatory -->
    </configuration>
</public>
```

The official *ContentCreator Examples* module (the `EXAMPLE_PHONENUMBER` gadget the ODFS
chapter "Universal Extensions › Input components" describes) uses exactly this descriptor
with `<scope unrestricted="yes"/>`, one `<gom>`, two `<factory>` entries and one `<value>`;
its sources compile against FS 5.2.240208 `[jar]`. The class shapes it shows:
`GomPhoneNumber extends AbstractGomFormElement` with `@GomDoc(description, since)` /
`@Default("no")` / `@InheritAnnotations` on the getters and a `GomList` for repeated child
tags; `SwingGadgetFactory<G>.create(SwingGadgetContext<G>)`;
`WebPluginGadgetFactory<G, C extends Serializable>` with `create(GadgetContext<G>)`,
`getControllerName()`, `getScriptUrls()`, `getStylesheetUrls()`; the web gadget implements
`WebPluginGadget<C>` plus the `SerializingValueHolder<T, C>` aspect (`getSerializedValue` /
`setSerializedValue` carry the value to the browser); `ValueEngineerFactory<T, F>` with
`getType()` and `create(ValueEngineerContext<F>)`; `ValueEngineer<T>` with `write(T) →
List<Node>`, `read(List<Node>)`, `getEmpty()`, `isEmpty(T)`, `copy(T)`, `getAspect(...)`,
optionally the `DifferenceComputing` and `ReferenceAwareValueIndexSupporting` aspects.
`GadgetContext<G>` hands the gadget `getGom()`, `getBroker()`, `getElement()`,
`getPersistencyLanguage()`, `getDisplayLanguage()`, `isRelease()`, `getFormUid()` `[jar]`.

Pitfalls from the PS universal-input-component example `[observed]`:

- **`<scope>` is mandatory**; without it the component is not offered in any form.
- **Numbers arrive as `Double`** in the ContentCreator gadget: the JSON bridge has no
  integer type, so `(Integer) value` throws — read `Number` and convert.
- The prefix returned by `getScriptUrls()` / `getStylesheetUrls()` must equal the
  `<web-resources>` `target` (or `@WebResource.targetPath`) — otherwise the browser
  fetches 404s and the form shows an empty box.
- The gadget jar goes in **both** `<resources>` (module scope) and `<web-resources>`; the
  Swing factory needs the former, the web factory the latter.
- `IntegrityValidating.validateIntegrity()` `[jar]` returns a `Set<? extends Problem>`;
  return `Collections.emptySet()`, never `null`.
- For a value that ContentCreator must round-trip, implement
  `SerializingValueHolder<T, S extends Serializable>` `[jar]`
  (`getSerializedValue`/`setSerializedValue`) next to `getValue`/`setValue`.

## Configurable — the ServerManager config dialog — `<configurable>`

A component's `<configurable>` class provides the dialog behind the *configure*
button in ServerManager (for ProjectApps, Services, WebApps). The raw contract is
`Configuration<E extends ServerEnvironment>` — but that means hand-writing Swing,
file read/write, and listeners.

In practice many modules use the **GenericConfiguration** helper
(`com.espirit.ps.psci.module:generic-configuration`): extend
`GenericConfigPanel<E>` and declare one line per value.

```java
public class DemoProjectConfig extends GenericConfigPanel<ProjectEnvironment> {
    @Override protected void configure() {
        builder()
            .title("Dialog title")
            .text("Label 1", "propName1", "default value")
            .text("Label X", "propNameX", "", "Some tooltip")
            .checkbox("Check me", "boolProp", false)
            .password("Secret key", "passProp", "")
            .button("Test", "testBtn", testAction, "Test connection");   // ExecuteAction
    }
}
```

```xml
<project-app>
    <name>...</name>
    <class>com.example.DemoProjectApp</class>
    <configurable>com.example.DemoProjectConfig</configurable>
</project-app>
```

- Choose the type param by target: `GenericConfigPanel<ServerEnvironment>`
  (Service), `<ProjectEnvironment>` (ProjectApp), `<WebEnvironment>` (WebApp).
- Values persist to a properties file (default `configuration.properties`), keyed
  by the property name.
- **Read values back** (ProjectApp, v1.2.0+):
  `DemoProjectConfig.values(broker, DemoProjectApp.class).getString("propNameX")` —
  do this once in an init method (it's a server call), not in a hot path. Older
  path: `LegacyModuleAgent.getProjectAppConfigProperties(...)` — still on the jar, but
  `ModuleAdminAgent.getProjectAppConfig(module, app, project)` `[jar]` is the favoured API
  (confirmed internally at FirstSpirit, 2026-09-18).
- Also offers hidden values, "secret" values (revealed by a key sequence — for
  PreSales feature switches), before/after-save listeners, and `setFormValue(...)`.
- **Scope discipline (critical):** ship GenericConfig **module-scope only** — a
  server-scope copy from any module forces its version on all others. It depends
  on `designgridlayout` (add it too if not using Maven). After first install,
  restart ServerManager and open the dialog once so defaults are written.
