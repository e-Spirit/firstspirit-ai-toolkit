# Customising ContentCreator: Tailored UI, FS_BUTTON handler classes, LiveEdit

Three documented ways to shape the editor's ContentCreator without writing a module (plus the
"Configure actions" menu, which uses a plug-in). All **[odfs]** — *Template development ›
ContentCreator › Customization* (Standard functions, Functions in the preview, LiveEdit),
FirstSpirit 2026.5. Not re-tested live **[verify]**.

| You want to … | Use | Section |
| --- | --- | --- |
| Hide, disable, reorder or limit ContentCreator's own functions per group | Feature Configuration ("Tailored UI") | below |
| Put "add section / page / dataset / list entry / edit navigation" into the preview | `FS_BUTTON` + a handler class + `fsbutton(...)` | below |
| Let editors edit a generated page without starting ContentCreator | LiveEdit | below |
| A project-specific "Actions" menu | "Configure actions" | below |
| Your own toolbar item, inline-edit button, status note | plug-in interfaces | `java-plugins.md` |

## Tailored UI: the Feature Configuration

**Switch it on.** In project properties > project components add the project component
**"CXT ContentCreator: Feature Configuration ProjectApp"** and open its configuration. [odfs]

**What can be configured.** The list on the *Features* tab holds ContentCreator's standard
functions **and every `ItemsPlugin` FirstSpirit has recognised** [jar]. Three areas: menu
functions (top bar), functions in the preview (icon bars on sections, datasets), reports (right
bar). Some functions are not graphical (InEdit by Ctrl+click, moving folders in a tree,
uploading media by drag-and-drop); they can be switched off too. Default groups:
EntityManagement, MediaManagement, Navigation, Preview, Report, Status, Toolbar. [odfs]

**Availability per function** (the *Edit* dialog):

| Setting | Effect |
| --- | --- |
| Default availability | The built-in default applies. |
| Available for all users | Usable by everybody in the project. |
| Available for selected groups only | Usable only by the chosen groups. **If the option is on and no group is chosen, the function is available to nobody.** Groups are evaluated only while this option is on. |
| Unavailable | Graphical functions are hidden; a non-graphical function shows a "deactivated" message when used. |
| Disabled | Not supported by every function. Graphical functions stay visible but grey and unusable. It **overrides** the other options: a function that is available but Disabled cannot be used. |

**Customer-specific functions ("Add").** Currently only plug-ins that implement
`de.espirit.firstspirit.client.plugin.ItemsPlugin` [jar]. Fields: *Group* (leave empty; supported
only for the standard functions), *Identifier* (set through the optional `ItemIdentifiable`
interface [jar], otherwise the class name of the item implementation), *Plugin* (editable list of
recognised `ItemsPlugin`s), *Context* (the `BaseContext` passed to the plug-in; `Void` for other
functions; custom contexts can be typed). A setting on an **Item** beats a setting on its
`ItemsPlugin`; a setting on the plug-in is inherited by its items unless an item has its own.
Standard functions cannot be removed, only reset. [odfs]

**Order** (*Features: Order* tab): drag and drop within a group. The order is a guideline, not a
guarantee: nested icon bars in the preview are grouped automatically when there is a primary
action; the "My changes" report always sits in the lower area; "Search" and "Dashboard" cannot
move; right-aligned bars stay right-aligned. [odfs]

**Server level.** The Feature Configuration Service (server configuration > modules >
"FirstSpirit CXT ContentCreator") holds a server-wide configuration that applies to every
project. "From Service" copies the server configuration into the project and **overwrites the
project's earlier configuration without asking**; "From Project" does the reverse for the server.
[odfs]

**Export / import.** Copy puts the whole configuration on the clipboard as JSON
(`featureTypes[]` with `order`, `group`, `availability`, `disabled`, `contextType`, `plugin`,
`identifier`); Paste overwrites the current one without asking. Use it to move a configuration
to another server. [odfs]

**Rollout and limits.** Editors must **restart the project** (for example "Change project") to
see a change. The configuration works per project or server and per group only: to hide
something from particular users or in one subtree, use permissions instead. [odfs]

## FS_BUTTON handler classes (functions in the preview)

ContentCreator ships server-side handler classes for `FS_BUTTON` that implement content
functions. They work in `onClick` and in `onDrop` (drag-and-drop needs the template's **Drop
Editor** combo box set on its Properties tab). In the form, the abbreviation is enough:
`onClick="class:NewSection"` stands for
`class:de.espirit.firstspirit.webedit.server.executables.NewSectionExecutable`. The
`…server.executables` classes are **not on the Access API jar** (checked against 5.2.261011), so
the handler names and their parameters rest on the documentation alone. [odfs] [verify]
How the button is rendered into the preview: `fsbutton(...)`
(`firstspirit-templating-reference/references/gom/references-links.md`).

| Abbreviation | Click | Drop | Parameters (passed in `fsbutton(parameter:{...})`) |
| --- | --- | --- | --- |
| `NewSection` | Lists the section templates allowed in the context, then opens the edit dialog (straight to it when only one template fits). | Creates the section directly when exactly one template matches (allowed for the content area, compatible with the Drop Editor), no `scope="SAVE"` rule is violated and no mandatory field (`allowEmpty="no"`) is empty; otherwise falls back to the list or dialog. | `page` (ID, UID or `previewId` of the page; its template decides which section templates are offered), `body` (content-area display name), optional `store` (`pagestore`, the default, or `globalstore`), optional `reload` (ID of an HTML element to swap instead of reloading the whole page) |
| `NewPage` | Opens the "Create new page" dialog. | With a dropped page or page reference, opens the same dialog pre-set to a copy below the current page (names from the dropped page, a menu item under the current page, layout and content taken from it); the editor can change all of that. | none |
| `NewContent` | Opens the "New dataset" dialog on the data source's table template. | Creates the dataset when the table template has a compatible Drop Editor, no save rule is violated and no mandatory field is empty; otherwise the dialog. | `content2` (ID or UID of the data source) |
| `NewListEntry` | Lists the templates of the list input component, then opens the edit dialog. | As `NewSection`, for a list entry. | `editorId` (from `editorId(editorName:"…", json:true)`) **or** `previewId` (full OCM path of a nested component), `json`, optional `reload` |
| `EditMenu` | Opens the "Edit Navigation" dialog (move Site Store folders, change menu order, edit menu names). | — | optional `node` (ID, UID or `previewId` of a folder or page reference the tree opens up to) |

Notes on the table:

- `NewListEntry` works only for `FS_CATALOG` and `FS_INDEX`. It **overrides restrictions set by
  rules** (for example the `NEW` property of `FS_CATALOG`). It is meant for the preview, not for
  forms: hide the button in the form with `hidden="yes"`. `json:true` inside `editorId(...)` makes
  that call return a JSON object instead of an HTML fragment, so it may be used **only in
  JavaScript**, never in HTML output (invalid HTML). [odfs]
- Programmatic equivalent of `NewSection`: `de.espirit.firstspirit.webedit.server.NewSectionOperation`
  [jar], which carries `PARAM_PAGE`, `PARAM_BODY`, `PARAM_SECTION`, `PARAM_RELOAD`,
  `PARAM_DROPDATA` and `PARAM_STORE` constants and fluent `body(...)`, `section(...)`,
  `template(...)` setters. The documentation adds `preselectedLanguage` for the language the
  form opens in (default: the preview language; an unknown language gives an error). [jar] [odfs]
- Partial reload: `reload` takes the ID of a container, for example one declared as
  `<div id="container">`; see `we-api-preview.md` for the rule that decides what is swapped.

Form definition and rendering (both from the ODFS page):

```xml
<FS_BUTTON name="pt_createSection" hidden="yes" icon="fs:new"
           onClick="class:NewSection" onDrop="class:NewSection"
           style="firstspirit" useLanguages="no">
  <LANGINFOS><LANGINFO lang="*" label="Create section"/></LANGINFOS>
</FS_BUTTON>
```

```
<span$CMS_VALUE(fsbutton(editorName:"pt_createSection",
                         parameter:{"page":#global.page.id, "body":"Content center"}))$></span>
```

## LiveEdit

LiveEdit puts the edit icons on an **already generated** page (the page documentation names an
intranet page as example), without starting ContentCreator. Clicking an icon opens the form.
[odfs]

1. **Same markers as EasyEdit.** The icons are drawn from the same `editorId` calls
   (`editing-in-the-preview.md`).
2. **Script include** in the template-set tab of the page template(s):
   `<script src="http://[SERVER]:[PORT]/fs5webedit/live/api.jsp?project=[ID]" …></script>`, the
   project ID being `$CMS_VALUE(#global.project.id)$`. [odfs]
3. **`editorId`s in the generated state.** They are created in the preview by default; for
   generated output switch them on with `$CMS_SET(#global.forceEditorIds, true)$`. [odfs]
4. **Highlighting off:** `window.ContentCreator.setEnabled(false)`, called from
   `window.onContentCreatorLoad`. [odfs]
5. **Workflow on save.** The project needs a workflow (project properties > ContentCreator >
   *Standard workflow*), or the script URL carries `&workflow=<workflow ID>`. After "Save" a
   window starts that workflow so the change can be released and deployed. [odfs]

## "Configure actions" (project-specific Actions menu)

A project administrator opens "Configure actions" in the ContentCreator menu and picks, with
"Add action", the actions every editor of the project gets; the arrows reorder, the remove button
drops one. The selectable actions come from plug-in components implementing
`de.espirit.firstspirit.webedit.plugin.WebeditToolbarActionsItemsPlugin` [jar]; the items are
`ExecutableToolbarActionsItem` or `ClientScriptProvidingToolbarActionsItem` [jar], sized
**40×40 px**; without an icon the item's first letter is shown. [odfs]
Implementation: `java-plugins.md` (toolbar items).
