# ContentCreator Java plug-ins — the server-side extension points

The browser-side `WE_API` (the other references here) is how *JavaScript* talks to the
ContentCreator. This file is the *Java* side: the plug-in interfaces a module implements to
add toolbar buttons, inline-edit buttons, status notes, release-state detection, timeline
markers, translation providers and focus areas. Every signature marked **[jar]** was read
with `javap` from `fs-isolated-runtime.jar` FS 5.2.240208, or from FS 5.2.261011 where the
text says so; **[odfs]** is the ODFS chapter
"Plug-In Development › ContentCreator Extensions" (FirstSpirit 2026.5, read in an offline
HTML export, not the live site); behaviour marked **[observed]** comes from Professional
Services example modules and has not been reproduced here. The ODFS calls the complete,
compilable versions of every example below the *ContentCreator Examples* module source;
its own listings are deliberately not compilable **[odfs]**. That module source (the
official `fs5_webclient_examples` download, last built 2019, Ant-based) was **compiled here
against FS 5.2.240208 with zero FirstSpirit API errors** — the only failures are two
third-party libraries the archive does not ship. Old, but not wrong: every interface it
uses is still on the jar, and it is the source of the idioms marked *(examples module)*
below.

**Packaging is not this file's job.** All of these ship as `<public>` components inside a
`@WebAppComponent` — see the last section and
the FirstSpirit module development documentation (ODFS: web-app components and `<public>` components) for the module side.

## Which plug-in for which spot

| You want… | Implement | Package |
| --- | --- | --- |
| A button in the ContentCreator **toolbar** | `WebeditToolbarActionsItemsPlugin` → items `ExecutableToolbarActionsItem` | `de.espirit.firstspirit.webedit.plugin`, `…webedit.plugin.toolbar` |
| A button in the **inline-edit** bar of a section, page or dataset | `WebeditInlineEditItemsPlugin` → items `ExecutableInlineEditItem` | `…webedit.plugin.inlineedit` |
| A **note** in the status/notification area (e.g. "3 broken links") | `WebeditStatusNotePlugin` | `…webedit.plugin.status` |
| Your own **release state / workflow** detection for the status display | `WebeditElementStatusProviderPlugin` | `de.espirit.firstspirit.workflow` |
| Markers on the **timeline** (past or future) | `HistoryTimelineProvider` / `FutureTimelineProvider` | `de.espirit.firstspirit.client.plugin.timeline` |
| A machine **translation** provider in the translation dialog | `TranslationPlugin` | `…webedit.plugin.translation` |
| Suggested **crop / focus areas** for a picture | `FocusAreaProviderPlugin` | `…webedit.plugin.focus` |
| Items in the **entity management** (dataset) views | `EntityManagementItemsPlugin` | `de.espirit.cxt.cc.plugin.entity` — separate API jar, see below |
| A button in the **media management** view | `MediaManagementItemsPlugin` → `ClientScriptProvidingMediaManagementItem` / executable item, context `MediaManagementContext` (`getElement`, `getRemoteName`, `getLanguage`, `show(MediaFolder)`, `refresh()`) | `…webedit.plugin.media` **[jar]** |
| A **report** (search panel with drag-and-drop results) | `DataAccessPlugin` with the `Reporting` aspect, or the older `ReportPlugin<T>` | `de.espirit.firstspirit.client.plugin.dataaccess` — owned by the FirstSpirit module development documentation (ODFS: DataAccessPlugin and reports) |
| JavaScript/CSS loaded into **every** ContentCreator session | `ClientResourcePlugin` (`getScriptUrls()`, `getStylesheetUrls()`) | `…webedit.plugin` **[jar]** — the one-off variant is the operation in `client-resource-operation.md` |
| Where a **new page** lands in the Page Store | `WebeditStoreMappingPlugin` (`PageFolder requestMappedFolder(SiteStoreFolder)` / `requireMappedFolder(SiteStoreFolder)`) | `de.espirit.firstspirit.store` **[jar]** **[javadoc]** — see "Store mapping" below |
| An **external preview** entry in the SiteArchitect (device labs, staging hosts) | `ExternalPreviewItemsPlugin` → `ExternalPreviewItem` (`getLabel`, `getIcon` (Swing `Icon`), `getBrowserType()` → `EngineType`, `getUrl(ExternalPreviewContext)`) | `de.espirit.firstspirit.client.plugin` **[jar]** — SiteArchitect only; the official *BrowserStack* example builds the URL with `GenerateElementOperation.perform(PageRef, Language)` **[jar]** |

Every plug-in interface extends `de.espirit.firstspirit.client.plugin.Plugin` **[jar]**
(`setUp(BaseContext)`, `tearDown()`), which extends `Public`; the class is therefore a
`<public>` component **[odfs]**. `setUp` runs before the ContentCreator polls the plug-in
for items **[odfs]** and is where you keep the context and the broker; do not open
connections in the constructor. The item plug-ins (toolbar, inline edit, status note) all
offer **two item flavours** **[jar]** **[odfs]**: an *executable* item (`execute(ctx)` runs
Java on the server) and a *client-script* item (`ClientScriptProvidingItem<C>`:
`getLabel`, `getIconPath`, `getScript(ctx)` returns JavaScript that the ContentCreator runs
in the browser, where `WE_API` is available).

## Toolbar actions

```java
// [jar]
public interface WebeditToolbarActionsItemsPlugin extends WebeditItemsPlugin<WebeditToolbarItem> {
    Collection<? extends WebeditToolbarItem> getItems();      // inherited from ItemsPlugin
}
public interface ExecutableToolbarActionsItem
        extends WebeditToolbarItem, WebeditExecutablePluginItem<ToolbarContext> {
    String getLabel(ToolbarContext ctx);
    String getIconPath(ToolbarContext ctx);
    void   execute(ToolbarContext ctx);
    boolean isVisible(ToolbarContext ctx);                    // from Item<C>
    boolean isEnabled(ToolbarContext ctx);
}
```

`ToolbarContext` is **`de.espirit.firstspirit.client.plugin.toolbar.ToolbarContext`** **[jar]**
(there is no `webedit.plugin.toolbar.ToolbarContext`): it extends `BaseContext` and adds
`getStoreType()`, `getElement()` and `getSymbolicProjectName()`.

- **`getItems()` is polled after `setUp`** **[odfs]** and, in the field, **on every toolbar
  render** **[observed]** — every page load, every element switch. Anything that queries
  the server there (schedules, users, remote APIs) runs that often; build the item list
  once in `setUp` and return it. The ContentCreator then calls `isVisible`/`isEnabled` per
  item itself **[odfs]**.
- The context element is the **page reference shown in the preview** **[odfs]**; the same
  menu also lists Template Store scripts of type *Menu* and context-free workflows.
- **Toolbar icons are not rendered** — `getIconPath` on toolbar items is "reserved for
  future use" and may return `null` **[odfs]**.
- The client-script flavour is `ClientScriptProvidingToolbarActionsItem` **[jar]**
  (`getScript(ToolbarContext)`). The examples module returns
  a `top.WE_API.Common` `showMessage` call from it; the 2026.5 ODFS listing uses the newer
  `top.fs.API.getInstance().getCommon()` object for the same call **[odfs]** — both names reach the
  same API object (`we-api-common.md`).
- Idioms from the examples module *(examples module, compiled against 5.2.240208)*: build a
  dialog form on the fly with `FormsAgent.getForm(String xml)` and show it with
  `ShowFormDialogOperation` (`setTitle`, `setContextElement`, `setFormData`,
  `setMultiLanguage(false)`, `perform(form, languages)`); build client URLs for an element
  with `ClientUrlAgent.getBuilder(ClientType.WEBEDIT | JAVACLIENT)` →
  `.element(el).project(p).language(l).locale(loc).createUrl()` **[jar]**.
- **`execute` runs on the server, but the editor waits for it.** A blocking call
  (`awaitTermination`, a slow HTTP request) freezes the ContentCreator UI **[observed]**.
  Kick long work off asynchronously and report back with a status note or a dialog.
- To open UI from `execute`, use the operations (`RequestOperation`,
  `ClientScriptOperation`) via `OperationAgent`; guard with
  `ctx.is(BaseContext.Env.WEBEDIT)` when the same item class also serves SiteArchitect.
- `getIconPath` returns a path **relative to the web app**, resolved against a
  `@WebResource` of the `@WebAppComponent` (last section).

## Inline-edit items

```java
// [jar]
public interface WebeditInlineEditItemsPlugin extends WebeditItemsPlugin<InlineEditItem> { }
public interface ExecutableInlineEditItem extends InlineEditItem, WebeditExecutablePluginItem<InlineEditContext> {
    String getLabel(InlineEditContext ctx);
    String getIconPath(InlineEditContext ctx);
    void   execute(InlineEditContext ctx);
}
public interface InlineEditContext extends BaseContext {
    IDProvider getElement();     // the section / page / dataset the bar belongs to
    EditorNode getEditorNode();  // de.espirit.firstspirit.client.EditorNode — the input the bar sits on
    boolean    isEditMode();
    Language   getLanguage();
    boolean    isMeta();         // true when the bar is on the metadata form
    String     getTag();         // the editor's tag name, e.g. "CMS_INPUT_TEXT"
}
```

Return the item only when it applies (`isVisible` on `getElement()`'s type and `getTag()`);
the bar is rebuilt on every hover, so keep both predicates cheap. The ODFS example
discriminates `Section` from `Content2Section`/`SectionReference` in `isVisible` and checks
`getPermission().canChange()` in `isEnabled` **[odfs]**. Icons: **19×19 px PNG with alpha,
white tones** — the bar has a dark grey background — at a path relative to the
project-specific ContentCreator web-app root **[odfs]**. The client-script flavour is
`ClientScriptProvidingInlineEditItem` **[jar]**.

Idioms from the examples module *(examples module)*:

- **"Is this the section's own bar or an input's bar?"** — the section-level bar has
  `getTag()` equal to `"CMS_MODULE"` and `getEditorNode()` either `null` or without an
  item node; an input's bar carries that input's tag. Combine with `!isMeta()` and, for
  writing items, `isEditMode()`.
- **Write through the page, not the section.** To change a section, lock the *page*
  (`page.setLock(true, true)`), edit, `page.save(comment)`, unlock in `finally`; then
  refresh the preview with `DisplayElementOperation` on `WebeditUiAgent.getPreviewElement()`
  **[jar]**.
- **Start a workflow from a button**: `WorkflowAgent.startWorkflow(workflow, element)`
  returns a `WorkflowProcessContext`; if `!isActivityProcessed()` call `showActionDialog()`
  and `doTransition(transition)` **[jar]**. Guard with `element.isWorkflowAllowed(workflow,
  user)` and `!element.hasTask()`.
- `ShowFormDialogOperation` also takes `setRuleset(String xml)` and `setDefaults(FormData)`,
  so a dialog can carry its own rules **[jar]**.
- A **built-in icon** may be reused by path, e.g. `media/view/translation/compare.png`
  for the translation item; that path is not a public contract.

## Status notes

```java
// [jar]
public interface WebeditStatusNotePlugin extends Plugin {
    List<WebeditStatusNote> getStatusNotes(WebeditStatusNoteContext ctx);
}
public interface WebeditStatusNoteContext extends BaseContext {
    IDProvider getElement();
    Language   getLanguage();
    WebeditStatusNoteBuilder createNote();
}
// WebeditStatusNoteBuilder: color(WebeditColor) icon(Image<?>) title(String) text(String)
//   visibleOnLoad(boolean) addItem(WebeditStatusNoteItem) setItems(Collection<? extends WebeditStatusNoteItem>) create()
```

`WebeditColor` (`de.espirit.firstspirit.webedit.WebeditColor`) **[jar]** is an enum of fifteen named colours: `BLUEBERRY`, `BUBBLEGUM`,
`PEPPERMINT`, `ARUGULA`, `BASIL`, `KIWI`, `VANILLA`, `CARAMEL`, `MILKCHOCOLATE`,
`DARKCHOCOLATE`, `CHERRY`, `STRAWBERRY`, `LAVENDER`, `PLUM`, `SHARK`. Notes appear in the
flyout of the page-status display; `visibleOnLoad(true)` additionally shows the note below
the status display right after navigating to the page (default `false`) **[odfs]**. The
icon is an `Image<?>` from `ImageAgent` **[odfs]**. A note carries `WebeditStatusNoteItem`s
(`isVisible`/`isEnabled(WebeditStatusNoteContext)`) **[jar]**; an action item must *also*
implement `WebeditExecutablePluginItem` (server-side Java) or `ClientScriptProvidingItem`
(browser JavaScript) **[odfs]**. "Page" here means whatever `IDProvider` the preview shows,
datasets included **[odfs]**. `getStatusNotes` is called when the status area opens and
whenever the current element changes **[observed]**; the same render-frequency caveat as
the toolbar applies. The examples module's note reads `element.getTask()`, compares
`task.getEditors()` with the current user and sets `visibleOnLoad(personalTask)` — a
personal task pops up, a foreign one waits in the flyout *(examples module)*.

## Release state and workflow groups

```java
// [jar]  package de.espirit.firstspirit.workflow
public interface WebeditElementStatusProviderPlugin extends Plugin {
    List<WorkflowGroup> getWorkflowGroups(IDProvider element);
    State getReleaseState(IDProvider element);
    default boolean isSupported(IDProvider element) { … }
    // language-aware overloads: on 5.2.261011, absent on 5.2.240208 [jar]
    default List<WorkflowGroup> getWorkflowGroups(IDProvider element, Language language) { … }
    default State getReleaseState(IDProvider element, Language language) { … }

    // nested helper, on both jars [jar]
    class Factory {
        static WorkflowGroup create(String displayName, List<IDProvider> elements);
        static WorkflowGroup create(String displayName, List<IDProvider> elements,
                                    boolean releaseStateDetection);
    }
}
enum State { RELEASED, CHANGED, IN_WORKFLOW }
public interface WorkflowGroup {
    String getDisplayName();
    List<IDProvider> getElements();
    default boolean hasReleaseStateDetection() { … }
}
```

The Element Status Provider (ESP) replaces the built-in release detection with yours. The
ContentCreator hands `getReleaseState` the **page reference shown in the preview** on every
navigation or reload and colours the status display from the result; `getWorkflowGroups`
returns the sets of elements a workflow transition should act on together — the flyout
offers only transitions available on *all* elements of a group, and one element may sit in
several groups **[odfs]**. The **active ESP is a project setting** (ServerManager →
project → ContentCreator settings), and FirstSpirit ships two: *page-based* (the Page or
Dataset) and *page-reference-based* (the PageRef; pair it with recursive release)
**[odfs]**. Recommended: keep state and groups consistent — if you report
`IN_WORKFLOW`, at least one group should offer the transition that resolves it **[odfs]**.

The ODFS example and the examples module build groups with the unqualified
`Factory.create(displayName, elements)` from inside the plug-in class — that is the nested
`WebeditElementStatusProviderPlugin.Factory` above, not a factory on `WorkflowGroup`
**[jar]**. The factory is on both jars; only the `Language` overloads are newer (on
5.2.261011, absent on 5.2.240208 **[jar]**; the Professional Services collection dates them
to 5.2.250602 **[observed]**). The examples module's *ContentProjectionElementStatusProvider*
shows the intended shape: for a content-projection PageRef, collect the projected datasets
(`pageRef.getContent2Params().getData(language)` → `tableTemplate.getDataset(entity)`),
bucket everything by `getReleaseStatus()`/`hasTask()`, one group per bucket named after the
workflow or a fixed label, and derive `getReleaseState` from the groups so the two never
disagree *(examples module)*.

## Timeline markers

```java
// [jar]  package de.espirit.firstspirit.client.plugin.timeline
public interface TimelineEntryProvider {
    long getRange();                                              // NOTE: long, not int
    Collection<TimelineEntry> getEntries(IDProvider element, Language language);
}
public interface HistoryTimelineProvider extends TimelineEntryProvider, Plugin { }
public interface FutureTimelineProvider  extends TimelineEntryProvider, Plugin { }
public interface TimelineEntry extends Comparable<TimelineEntry> {
    Date     getTimestamp();     // java.util.Date
    Revision getRevision();      // de.espirit.firstspirit.storage.Revision
}
// TimelineEntry.Factory: builder(), create(Date), create(Revision), timestamp(...), revision(...), create()
```

`getRange()` is the timeline scale in **milliseconds from "now"** (the moment the MPP
timeline was last drawn): a history provider's range extends into the past, a future
provider's into the future. **`0` means auto-fit** — the entry farthest from now becomes the
end of the timeline; entries outside a non-zero range may not be shown. Entries closer
together than a marker's width collapse into one marker with a flyout **[odfs]**.
`getEntries` is polled as the editor drags the slider **[observed]**, so it must be fast and
side-effect free. `Revision`-based entries make no sense in a future provider **[odfs]**.
The providers are **selected per project** in ServerManager → ContentCreator settings, and
the web-app component that contains them must be added to the project's ContentCreator web
application with its web server active **[odfs]**; the same providers also serve the
SiteArchitect's MPP timeline **[odfs]**. A PS example declares `int getRange()` — it does not
compile against the jar; the return type is `long` **[jar]**.

## Translation providers

```java
// [jar]  package de.espirit.firstspirit.webedit.plugin.translation
public interface TranslationPlugin extends Plugin {
    void register(TranslationHost host);
}
public interface TranslationHost {
    <T> void register(TranslationType<T> type, TranslationHost.Translator<T> translator);
    interface Translator<T> { T translate(TranslationContext ctx, T value); }
}
public class TranslationType<T> {              // TEXT and XML (both TranslationType<String>)
    public static final TranslationType<String> TEXT, XML;
}
public interface TranslationContext {
    SpecialistsBroker getBroker();
    Language getSourceLanguage();
    Language getTargetLanguage();
    GomFormElement getGomElement();               // decide per input component
}
```

Register one translator per type in `register(host)`; **`T` is `String` for both types**
**[odfs]**: `TEXT` receives plain strings, `XML` receives the serialised DOM of rich-text
inputs — translate the text nodes, keep the markup and the identifying attributes so the
result can be matched back **[odfs]**. The translation dialog itself is *not* wired into
the ContentCreator by default; a project opens it from an inline-edit item, an `FS_BUTTON`
or a report action via the operation below **[odfs]**. To trigger a translation from your
own code, the operation
`de.espirit.firstspirit.webedit.server.TranslationOperation` **[jar]** exists
(`setElement(DataProvider)`, `setSourceLanguage`, `setTargetLanguage`,
`setTranslationPlugin(String name, boolean)`, `perform()`); obtain it through
`OperationAgent` like every other operation (`firstspirit-operations`). The examples module
discovers an installed provider at `setUp` with
`ModuleAgent.getComponents(TranslationPlugin.class)` (`de.espirit.firstspirit.access.ModuleAgent`
**[jar]**, not deprecated) and passes the class name to `setTranslationPlugin` *(examples
module)*.

## Store mapping — where a new page lands

```java
// [jar]  package de.espirit.firstspirit.store
public interface WebeditStoreMappingPlugin extends Plugin {
    PageFolder requestMappedFolder(SiteStoreFolder folder);   // null when no folder exists yet
    PageFolder requireMappedFolder(SiteStoreFolder folder);   // create it if needed, never null
}
```

When an editor creates a page in the ContentCreator, the plug-in decides which Page Store
folder receives it for the Site Store folder the editor is in. The examples module maps
every first-level Site Store folder to a same-named folder below the project's ContentCreator
system folder (`Project.getWebeditSystemFolder()` **[jar]**, falling back to the Page Store
root), creating it in `requireMappedFolder` with `createPageFolder(uid, displayNames, true)`
and copying the Site Store folder's permissions *(examples module)*. Register it like every
other plug-in; one per project.

## Focus areas for pictures

```java
// [jar]  package de.espirit.firstspirit.webedit.plugin.focus
public interface FocusAreaProviderPlugin extends Plugin {
    List<FocusArea> getFocusAreas(FocusAreaProviderContext ctx);
}
public interface FocusAreaProviderContext { Media getMedia(); Language getLanguage(); }
// FocusAreaBuilder: title(String) bounds(Rectangle) orientationFromDegree(double)
//   orientationFromEulerAngles(double,double,double) orientationFromRatio(Point2D.Double)
//   orientationFromPoint(Point) create()
```

Return the regions (faces, products, logos) the crop dialog should offer as presets. The
provider runs when the crop dialog opens for a picture; an image-analysis call belongs in a
cache keyed by media id and revision, not in the provider itself.

## Entity management items and `CropOperation` — the separate API jar

`EntityManagementItemsPlugin`, `EntityManagementItem`, `ExecutableEntityManagementItem`,
`EntityManagementContext` (package `de.espirit.cxt.cc.plugin.entity`) and `CropOperation`
are **not in `fs-isolated-runtime.jar`**. They come from the ContentCreator's own API
artifact, `de.espirit.cxt.cc:cxt-cc-api`, which a module declares `compileOnly` (the web
app provides it at runtime; bundling it breaks the module). Their signatures could not be
`javap`-checked here — **[verify]** against the `cxt-cc-api` version that matches your
ContentCreator before relying on a method name. The artifact is **not generally published**:
it is available for FirstSpirit Cloud projects, and its documentation was still pending at
the time of writing (confirmed internally at FirstSpirit, 2026-09-29) — ask your FirstSpirit
contact for the jar and the matching ContentCreator version before planning on it.

## What every one of these needs: a `@WebAppComponent`

A ContentCreator plug-in is a `<public>` component **[odfs]** shipped **inside a web app**
that is deployed to the ContentCreator web application (confirmed internally at FirstSpirit,
2026-09-29: the web-app component is what gets your jars into the ContentCreator; every
plug-in type needs one, but **one web-app component per module** is enough — not one per
plug-in). Without the web app the class is deployed but the ContentCreator never asks for it:

```java
@WebAppComponent(
    name = "MyCcPlugins",
    displayName = "My ContentCreator plug-ins",
    webXml = "webedit/web.xml",                       // relative to src/main/fsm-resources
    xmlSchemaVersion = "6.0",
    webResources = { @WebResource(path = "icons", name = "my-cc-icons", version = "1.0.0") })
public class MyCcWebApp extends AbstractWebApp implements WebApp { }
```

- `webXml` and every `@WebResource.path` are relative to `src/main/fsm-resources`; a minimal
  `web.xml` with just the `<web-app>` root is enough for a plug-in-only web app.
- `getIconPath(...)` values resolve against the `@WebResource` — the same `path` prefix
  rule as for gadget scripts. Bumping `@WebResource.version` is the icon cache-buster.
- **Scope: global is the normal choice.** A globally deployed ContentCreator web app
  usually serves the plug-ins for every project, and FirstSpirit Cloud does not want
  project-specific web-app components at all; declaring both scopes
  (`scopes="PROJECT,GLOBAL"`, as the official 2024 example does) keeps local testing easy
  (confirmed internally at FirstSpirit, 2026-09-29). The ODFS states the project deployment
  for timeline providers **[odfs]**; an earlier field observation that a global deployment
  was "not enough" is superseded. Deploy in ServerManager (global: server properties → web
  applications; project: project component → web components). Icon and resource URLs resolve
  against the ContentCreator web-app root the plug-in was deployed to **[odfs]**.
- The plug-in jar goes in `fsWebCompile`; anything the `execute` methods call on the
  server side that is not in the web scope must also be in `fsModuleCompile`:
  the FirstSpirit module Gradle plugin documentation (`fsWebCompile` / `fsModuleCompile`). The two official
  example descriptors do it differently: they list the same jar as a **server-scope**
  `<resource>` and again inside `<web-resources>` (2019 `module.xml`; 2024
  `module-isolated.xml` with `mode="isolated"`, `<web-app scopes="PROJECT,GLOBAL"
  xml-schema-version="6.0">` and a Jakarta `web-app_6_0` `web.xml`). Server scope works
  because a `<public>` class must be loadable by the server; module scope is the narrower
  choice and what the Gradle plugin produces.
