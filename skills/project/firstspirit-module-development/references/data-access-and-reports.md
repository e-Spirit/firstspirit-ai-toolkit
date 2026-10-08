# DataAccessPlugins (DAP) and Reports

A **DataAccessPlugin** integrates *foreign* objects (from any external system, or
elsewhere in the project) into FirstSpirit so editors can reference them in an
**`FS_INDEX`** and browse/search them in a **Report**. This is the durable way to
make non-FirstSpirit data first-class editorial content.

Package: `de.espirit.firstspirit.client.plugin.dataaccess` (+ `.aspects`,
`.aspects.transfer`) and `de.espirit.firstspirit.client.plugin.report`.

Grounded in a small **tagging** example module and cross-checked (2026-09-18) against three
official examples published with the ODFS: the *ContentCreator Examples* module's
text-blocks DAP (2019, compiles against FS 5.2.240208 `[jar]`) and the 2025 *DataAccessPlugin
OData / SOAP* samples (Gradle plugin 6.6.0, annotations 3.3.0, runtime 5.2.240809). The
skeleton below is a getting-started shape, not a production report.

---

## The core idea

- Each foreign object `D` is represented by a **String identifier**.
- `FS_INDEX` stores **only the identifier** per referenced object.
- The DAP converts **identifier ⇄ object** transparently — including at
  generation time, where `st_index.values()` yields the live `D` objects.
- Objects are displayed via **snippets** (icon, header, extract, thumbnail).
- Add the right **aspects** and the same DAP also powers a **Report** (a
  ContentCreator/SiteArchitect panel to search and drag objects in).

## The five interfaces (generic over your object type `D`)

| Interface | Role |
| --- | --- |
| `DataAccessPlugin<D>` | Entry point; the `<public>` component. Label, icon, creates session builders. |
| `DataAccessSessionBuilder<D>` | Configuration object for a session (aspects: GOM config, revision awareness). |
| `DataAccessSession<D>` | Translates identifier ⇄ `D`; supplies the `DataSnippetProvider<D>` and `DataStreamBuilder<D>`. |
| `DataStreamBuilder<D>` | Configures the stream of selectable objects (aspects: `Filterable`). |
| `DataStream<D>` | Yields the available `D` objects (used by `FS_INDEX` selection dialogs and Reports). |

Flow: `DataAccessPlugin` → `createSessionBuilder()` → `createSession(context)` →
the session builds a `DataStreamBuilder` → `createDataStream()` → paged objects.

Lifecycle notes `[observed]`: register aspects in the constructor or in `setUp(context)`
of the object that owns them (the aspect map is read right after construction — adding
later has no effect); `DataStream.close()` is where you release cursors, HTTP clients or
result sets, because streams are created per dialog and per report page and leak
otherwise.

## Registration (`module.xml`)

```xml
<public>
    <name>TagsDataAccess</name>
    <displayname>Find Tags</displayname>
    <class>de.espirit.ps.examples.tagging.v52.tags.TagDataAccess</class>
</public>
```

The `<name>` is what appears in `FS_INDEX` (`SOURCE`/use) with code completion. With the
Gradle plugin the same registration is `@PublicComponent(name = "ODataDataAccessPlugin",
displayName = "Data Access Plugin")` on the plug-in class (official OData sample). A DAP
needs nothing else: the OData sample's plug-in returns `null` from `getAspect` and `getIcon`
and still works — the aspects below are opt-in.

### Per-source configuration in the form — `GomConfigurable`

The 2025 samples show how one DAP serves several configured back ends. The session builder
implements `GomConfigurable` and registers *itself* as that aspect; `createConfiguration()`
returns your `GomElement` subclass, whose `@GomDoc` getters become child tags of the
`<SOURCE>` in the `FS_INDEX` form; FirstSpirit hands the parsed element back through
`setConfiguration(GomElement)` before `createSession(context)` `[jar]`:

```java
public class ODataSessionBuilder implements DataAccessSessionBuilder<ODataObject>, GomConfigurable {
    private final SessionBuilderAspectMap aspects = new SessionBuilderAspectMap();
    private ODataConfiguration gom;
    public ODataSessionBuilder() { aspects.put(GomConfigurable.TYPE, this); }
    public GomElement createConfiguration()             { return new ODataConfiguration(); }
    public void setConfiguration(GomElement configuration) { gom = (ODataConfiguration) configuration; }
    public <A> A getAspect(SessionBuilderAspectType<A> type) { return aspects.get(type); }
    public DataAccessSession<ODataObject> createSession(BaseContext ctx) {
        // look the named service up through ServicesBroker and open the session
    }
}
public class ODataConfiguration extends AbstractGomElement implements GomCheckable {
    protected String getDefaultTag() { return "ODATA_DATAACCESS_CONFIGURATION"; }
    @GomDoc(description = "Name of the service configuration to use.", since = "5.2")
    public String getServiceName() { … }   public void setServiceName(String s) { … }
    public void verify() throws IllegalStateException { /* required attributes present? */ }
    public void validate(Context ctx) throws GomValidationError { /* does the service exist? */ }
}
```

`GomCheckable.verify()` runs on parse, `validate(Context)` with a broker at template save
`[jar]`; throw `GomValidationError(message, element, null)` to reject the form.

## The aspect model — the key design point

DAP features are **not** declared with `implements`. Each object holds an
**aspect map** and answers `getAspect(SomeAspectType)`; return `null` when a
feature is off. Benefits: implement only what you use, decide per-runtime/context
whether a feature is active, and new aspects can be added by the API without
breaking existing plugins.

```java
public class TagDataAccess implements DataAccessPlugin<TagEntry> {
    private final DataAccessAspectMap aspects = new DataAccessAspectMap();
    private BaseContext context;

    public void setUp(@NotNull BaseContext context) {
        this.context = context;
        // Only offer the Report in ContentCreator:
        if (context.is(BaseContext.Env.WEBEDIT)) {
            aspects.put(Reporting.TYPE, getReportingAspect(context));
            aspects.put(ReportItemsProviding.TYPE, getItemsAspect(context));
        }
        aspects.put(StaticItemsProviding.TYPE, getStaticItemsAspect(context));
    }

    public <A> A getAspect(DataAccessAspectType<A> type) { return aspects.get(type); }

    public String    getLabel() { ... }
    public Image<?>  getIcon()  { ... }
    public DataAccessSessionBuilder<TagEntry> createSessionBuilder() { return new TagSessionBuilder(); }
    public void      tearDown() { }
}
```

Session — the identifier ⇄ object translation + snippets:

```java
public class TagSession implements DataAccessSession<TagEntry> {
    public TagEntry getData(String identifier) throws NoSuchElementException { ... }   // id -> object
    public List<TagEntry> getData(Collection<String> ids) { ... }
    public String getIdentifier(TagEntry entry) throws NoSuchElementException { ... }  // object -> id
    public DataSnippetProvider<TagEntry> createDataSnippetProvider() {
        return new DataSnippetProvider<TagEntry>() {
            public Image<?> getIcon(TagEntry e) { ... }
            public String   getHeader(TagEntry e, Language l) { ... }
            public String   getExtract(TagEntry e, Language l) { ... }
            public Image<?> getThumbnail(TagEntry e, Language l) { ... }
        };
    }
    public DataStreamBuilder<TagEntry> createDataStreamBuilder(...) { ... }
    public <A> A getAspect(SessionAspectType<A> type) { ... }
}
```

Stream builder — filtering via the `Filterable` aspect:

```java
static final ParameterText QUERYSTRING = Parameter.Factory.createText("querystring", "Search", "");

aspects.put(Filterable.TYPE, new Filterable() {
    public List<Parameter<?>> getDefinedParameters() { return List.of(QUERYSTRING); }
    public void setFilter(ParameterMap map) { this.parameterMap = map; }
});
```

`DataStream<D>` is a paging iterator: `getNext(int count)`, `hasNext()`,
`getTotal()`, `close()`.

Four aspect maps, one per level `[jar]`: `DataAccessAspectMap` (plug-in),
`SessionBuilderAspectMap`, `SessionAspectMap`, `StreamBuilderAspectMap`. The official
text-blocks example fills them all: plug-in `Reporting` + `ReportItemsProviding`; session
`Identifying`, `DataTemplating`, `ValueIndexing`, `TransferSupplying`, `TransferHandling`,
`JsonSupporting`; stream builder `Filterable` + `Updating`. Two of its conventions are worth
copying: `getData(Collection<String>)` returns a list with `null` at the position of every
unknown identifier instead of throwing, and icons are chosen by environment —
`ImageAgent.getImageFromUrl(webResourcePath)` when `context.is(Env.WEBEDIT | PREVIEW |
HEADLESS)`, `getImageFromIcon(new ImageIcon(classpathUrl))` in the SiteArchitect `[jar]`.

## Aspect catalogue

**DataAccessPlugin** (`DataAccessAspectType`):
| Aspect | Effect |
| --- | --- |
| `Reporting` | Turns the DAP into a Report |
| `ReportItemsProviding` | Buttons/actions on report result snippets |
| `StaticItemsProviding` | Global report actions (e.g. "create new object") |

**DataAccessSessionBuilder** (`SessionBuilderAspectType`): `GomConfigurable`
(further config via GOM), `RevisionConfigurable` (revision / release-state aware).

**DataAccessSession** (`SessionAspectType`): `DataTemplating` (HTML details
flyout, CC only), `Identifying`, `ModelReferencing` (references to templates),
`ValueReferencing` (references to datasets/pages), `ValueIndexing`,
`RequestMatching`, `TransferSupplying` (provide drop objects), `TransferHandling`
(accept drop objects; `.aspects.transfer` package).

**DataStreamBuilder** (`StreamBuilderAspectType`): `Filterable` (filter
parameters). Also `DataAssociating` in the Tagging example (associate results with
a `SiteStoreFolder`).

## Reports

A Report is "just" a DAP with the `Reporting` aspect — same object model, surfaced
as a search/browse panel. `ReportItemsProviding.getItems()` / `getClickItem()`
supply per-result actions (`ReportItem<D>`); `StaticItemsProviding` supplies
panel-level actions. `Filterable` on the stream builder gives the search box.
Report visibility is decided at runtime (register the aspect only when
`context.is(BaseContext.Env.WEBEDIT)`), replacing the older always-implement
`ReportPlugin.isVisible()` / `getParameter()` style.

The older `ReportPlugin<T>` `[jar]` (`de.espirit.firstspirit.client.plugin`) is still
shipped and still used by the official examples: `isVisible()`, `getTitle()`,
`getIcon(boolean selected)` → `Image.Factory.fromUrl(...)` / `fromIcon(...)`,
`getParameter()`, `createDataProvider()`, `createDataRenderer()`,
`createTransferHandler()`, `getDefaultItem()`, `getItems()`. Result actions implement
`JavaClientExecutableReportItem<T>` *and* `WebeditExecutableReportItem<T>` in one class
(Swing `getIcon` for the one, `getIconPath` for the other), or
`ClientScriptProvidingReportItem<T>` to run JavaScript in the browser; a
`RequestOperation` (`setKind(INFO)`, `setTitle`, `addAnswer`, `perform(text)`) is the
simplest server-side reaction `[jar]`.

## Version note

The aspect-based DAP/Report API is FirstSpirit **5.2+**. Earlier lines had a
narrower `ReportPlugin` model (5.0/5.1). Capabilities that arrived with 5.2
include: self-defined drop objects (`TransferHandling`), SiteArchitect
availability, result/global actions, and identifier↔object mapping usable outside
Reports (persistent references to foreign objects without project-specific drop
scripts). Confirm the exact API against the target FirstSpirit version.
