# `top.WE_API.Common` — messages, dialogs, navigation, listeners, execute, action hotspots

Java interface: `de.espirit.firstspirit.webedit.client.api.Common` [javadoc]
ODFS: JavaScript APIs › ContentCreator › Common Functionality [odfs]

Tags: **[javadoc]** = Access API Javadoc of the package · **[odfs]** = ODFS page · **[verify]**
= not confirmed. None of these interfaces are on `fs-isolated-runtime.jar` (GWT client side).

## Members

| Member | Signature | Note |
| --- | --- | --- |
| `showMessage` | `void showMessage(String text)` | Information pop-up, one OK button; buttons not configurable [odfs] |
| `showMessage` | `void showMessage(String title, String text)` | same, with title [odfs] |
| `createDialog` | `Dialog createDialog()` | returns an **invisible** empty dialog — configure, then `show()`; see `we-api-dialog.md` [javadoc] |
| `getPreviewElement` | `FSID getPreviewElement()` | element behind the current preview — usually a `PageRef` or a `Dataset` [odfs] |
| `setPreviewElement` | `void setPreviewElement(JavaScriptObject fsid)` / `void setPreviewElement(FSID fsid)` | **App Mode only** [javadoc] [verify] |
| `addPreviewElementListener` | `void addPreviewElementListener(PreviewElementListener)` | callback `function(fsid)`; fires on page navigation; receives the PageRef's FSID, or the content projection's FSID for dataset pages [odfs] |
| `addPreviewRequestHandler` | `void addPreviewRequestHandler(PreviewRequestHandler)` | callback `function(fsid)`; a new element is *requested* (e.g. report click). **App Mode only** [javadoc] |
| `addNavigationChangeListener` | `void addNavigationChangeListener(NavigationChangeListener)` | callback `function(fsid)`; fires on "Edit navigation" moves (moved `PageRefFolder`'s FSID) and on new-page creation (new PageRef's FSID); **not** on deletion; fsid may be `null` [odfs] [javadoc] |
| `addWorkflowTransitionListener` | `void addWorkflowTransitionListener(WorkflowTransitionListener)` | callback `function(workflowTransitionInfo)` — see below [javadoc] |
| `getLocale` | `String getLocale()` | UI locale of the ContentCreator session [odfs] |
| `getDisplayLanguage` | `String getDisplayLanguage()` | abbreviation of the display language (labels, display names) [odfs] |
| `jumpTo` | `void jumpTo(FSID fsid)` | navigate the preview to the element [odfs] |
| `jumpTo` | `void jumpTo(JavaScriptObject fsid)` | JSON form, see below [odfs] |
| `jumpTo` | `void jumpTo(JavaScriptObject fsid, String language)` | `language` = project-language abbreviation, or `null` for current [javadoc] |
| `execute` | `void execute(String executable, JavaScriptObject parameters, JavaScriptObject callback)` | run a script/Executable on the server, **asynchronously**; see below [odfs] |
| `addItemsPlugin` | `void addItemsPlugin(String type, ClientItemsPlugin provider)` | register context actions; `type` ∈ `"index"`, `"status"`, `"floating"` [javadoc] |

## Message box

```javascript
top.WE_API.Common.showMessage("I am a sample message box.");
top.WE_API.Common.showMessage("Important message:", "I am a sample message box.");
```
[odfs]

## Navigating the preview — `jumpTo`

The JSON object always has **exactly two keys**, all values numeric element IDs (not UIDs): [odfs] [javadoc]

| Target | Keys | Meaning |
| --- | --- | --- |
| store element | `id`, `store` | `store` in capitals, one of `Store.Type`. **`MEDIASTORE` is accepted but does not resolve** — the preview is page-centric; jump to the PageRef instead (`references/does-not-work-in-contentcreator.md`) [observed] |
| dataset via a page reference | `contentId`, `pageref` | display the dataset through that PageRef |
| dataset via its data source | `contentId`, `content2` | the Content2 node's preview page reference is used |
| dataset via its table template | `contentId`, `template` | the table template's preview page reference is used |

```javascript
top.WE_API.Common.jumpTo({"id": 47, "store": "SITESTORE"});
top.WE_API.Common.jumpTo({"contentId": 128, "pageref": 47});
top.WE_API.Common.jumpTo({"contentId": 128, "content2": 243});
top.WE_API.Common.jumpTo({"contentId": 128, "template": 17});
top.WE_API.Common.jumpTo({"id": 47, "store": "SITESTORE"}, "de");   // in a given language
```
[odfs]

## Reacting to events

```javascript
// Page navigation — which element is the preview showing now?
top.WE_API.Common.addPreviewElementListener(function (fsid) {
  if (fsid.getContentId() != -1) {
    console.log("dataset page: contentId=" + fsid.getContentId() + " content2=" + fsid.getContent2());
  } else {
    console.log("pageref id=" + fsid.getPageref());
  }
});

// Site structure changed (folder moved / new page created)
top.WE_API.Common.addNavigationChangeListener(function (fsid) {
  console.log("navigationChanged: " + (fsid ? fsid.getStoreType() + ":" + fsid.getId() : "all"));
});

// Workflow step executed in this session — NOTE the parameter, which the ODFS example omits
top.WE_API.Common.addWorkflowTransitionListener(function (workflowInfo) {
  console.log("target: "     + (workflowInfo.getWorkflowTarget() ? workflowInfo.getWorkflowTarget().getId() : "-")
            + " deleted: "   + workflowInfo.isDeleted()
            + " released: "  + workflowInfo.isReleased()
            + " first: "     + workflowInfo.isFirstTransition()
            + " transition: "+ workflowInfo.getTransitionId()
            + " workflow: "  + workflowInfo.getWorkflowId()
            + " endState: "  + workflowInfo.isEndState());
});
```
[odfs] [javadoc]

### `WorkflowTransitionInfo` (`Common.WorkflowTransitionInfo`) [javadoc]

| Member | Returns |
| --- | --- |
| `getWorkflowTarget()` | `FSID` of the element the workflow runs on |
| `isDeleted()` | `true` if the element was deleted in this transition |
| `isReleased()` | `true` if it was released in this transition |
| `isFirstTransition()` | `true` if the workflow just started |
| `getTransitionId()` | `long` |
| `getWorkflowId()` | `long` — ID of the workflow's store element |
| `isEndState()` | `true` if the workflow is now in an end state |

## Running server-side code — `execute`

```javascript
top.WE_API.Common.execute(
  "script:myexample",                 // a script in the Template Store, by UID
  {"param1": 42, "param2": "test"},   // parameters handed to the script / Executable
  function (result) {                 // called when the server has finished
    alert("script result: " + result);
  }
);
top.WE_API.Common.execute("class:com.example.MyExecutable", {}, function (result) { /* … */ });
```
[odfs] [javadoc]

- `executable`: `script:<SCRIPT_UID>` or `class:<FULLY_QUALIFIED_CLASS_NAME>` of an
  `Executable` from a module. [odfs]
- Execution is **asynchronous**; the return value is delivered only through the callback.
  `callback` may be a function object or the *name* of a function. [odfs]
- **The parameters may not arrive.** The ODFS page does not say *how* they surface, and in
  the 2026-09-11 field test they did **not** surface at all — neither in
  `context.getProperties()` nor as script variables. Single observation; details and the
  workaround in `references/does-not-work-in-contentcreator.md`. Treat the result direction
  (callback) as reliable and the parameter direction as unproven. [observed] [verify]
- Shipping the `Executable` class: the FirstSpirit module development documentation (ODFS: web-app components and `<public>` components).
- SiteArchitect twin: `top.JC_API.execute(...)` — same identifier formats, plus a synchronous
  one-argument form: `references/jc-api.md`.

## Action hotspots — `addItemsPlugin`

Register a provider that returns actions for a context. Package
`de.espirit.firstspirit.webedit.client.api`: `ClientItemsPlugin`, `ClientItemContext`,
`ClientItem`, `ClientItemPerformable`, `ClientItemConstants`. [odfs] [javadoc]

```javascript
top.WE_API.Common.addItemsPlugin("index", function clientItemsPlugin(context, receiver) {
  var items = [];
  var fsid = context.getProperty("fsid");          // the FS_INDEX entry's element
  if (fsid) {
    items.push(context.createItem("ICON_URL", "TITLE", function clientItemPerformable() {
      console.log("action for element " + fsid.getId());
      context.refresh();                          // optional: reload the contextual view
    }));
  }
  receiver(items);                                // hand the actions back — always call it
});
```
[javadoc] [odfs]

| Context type (`ClientItemConstants`) | String | Properties available via `context.getProperty(name)` |
| --- | --- | --- |
| `TYPE_INDEX` | `"index"` | `"fsid"` (`FSID`), `"language"` (abbreviation), `"plugin"` (DAP name), `"objectId"` (String) |
| `TYPE_STATUS` | `"status"` | `"fsid"` |
| `TYPE_FLOATING` | `"floating"` | none listed |

The property-name constants are `PROPERTY_FSID`, `PROPERTY_LANGUAGE`, `PROPERTY_PLUGIN`,
`PROPERTY_OBJECT_ID`. [javadoc]

`ClientItemContext`: `createItem(String iconUrl, String title, ClientItemPerformable handler)`
(`iconUrl` may be `null`), `getProperty(String)` (returns `null` if absent), `refresh()`.
`ClientItem`: `getTitle()`, `getIcon()`, `perform()`. [javadoc]

## `FSID` — the element identifier (`de.espirit.firstspirit.webedit.client.api.FSID`) [javadoc]

| Member | Returns |
| --- | --- |
| `getId()` | `int` — store-element ID |
| `getStoreType()` | `String` — e.g. `"SITESTORE"` |
| `getElementType()` | `String` or `null` |
| `getContentId()` | `int`, `-1` if not a dataset |
| `getPageref()` / `getContent2()` / `getTemplate()` | `int`, `-1` if not set — which route displays the dataset |
| `getLanguage()` | `String` abbreviation or `null` |
| `toJson()` | plain JSON object — usable as the `jumpTo` argument |

Constants for the JSON keys: `PARAM_ID` `"id"`, `PARAM_STORE` `"store"`, `PARAM_CONTENT_ID`
`"contentId"`, `PARAM_PAGEREF` `"pageref"`, `PARAM_CONTENT2` `"content2"`, `PARAM_TEMPLATE`
`"template"`, `PARAM_LANGUAGE` `"language"`. [javadoc]
