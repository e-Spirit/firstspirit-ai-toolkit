# Script types and their `context` object

A FirstSpirit script always has a variable named **`context`** bound at runtime.
Its concrete Java interface — and therefore which methods you may call — depends
entirely on **where the script runs**. Pick the row that matches your script type
before writing any code.

> All context interfaces below extend `ScriptContext` (base: logging, properties,
> connection), and through `BaseContext` **every one of them is a `SpecialistsBroker`**
> `[jar]` — `context.requireSpecialist(...)` works directly on `context`, in schedule and
> generation scripts too. Client-side ones also extend `ProjectScriptContext` (project +
> `UserService`).

> **Visual:** [assets/firstspirit-context-hierarchy.md](../assets/firstspirit-context-hierarchy.md)
> is a Mermaid class diagram of this whole hierarchy (plus a plain-text tree) — handy for
> seeing at a glance which interface inherits which methods, and editable as text.

---

## Overview table

| Script type | Where it runs | `context` interface | Extends |
| --- | --- | --- | --- |
| **Menu script** | SiteArchitect *Extras → Execute Script* | `GuiScriptContext` | `ClientScriptContext`, `ProjectScriptContext` |
| **Context-menu script** | Right-click a store node / path in SiteArchitect | `GuiScriptContext` | same as above |
| **Workflow script** | On a transition/activity in a workflow | `WorkflowScriptContext` | `GuiScriptContext` |
| **Content2 (dataset) script** | On a Content2 node (table) **or** a dataset in the Content Store `[core]` | `Content2ScriptContext` | `GuiScriptContext` |
| **FS_BUTTON script** | `onClick` / `onDrop` of an `FS_BUTTON` | `ClientScriptContext` in a SiteArchitect form `[core]`; only a `BaseContext` in the SiteArchitect preview `[core]`; `GuiScriptContext` in ContentCreator `[verify]` | `ProjectScriptContext` |
| **PermissionEditor script** | Button inside a `PERMISSION` input component | `PermissionEditorScriptContext` | `GuiScriptContext` |
| **Template / generation script** | `$CMS_RENDER(script:…)$` during (preview) generation | `GenerationContext` (extends `GenerationScriptContext`), bound as **`gc`** *and* as `context` `[core]` | `ProjectScriptContext` |
| **Schedule script** | Schedule action (server/project), manual or interval | `ScheduleContext` | `ScriptContext` |
| **PermissionService script** | PermissionService, at fixed intervals on the server | `PermissionServiceScriptContext` | `ScriptContext` |

Two broad families:

- **Client context** — menu, context-menu, workflow, Content2, FS_BUTTON,
  PermissionEditor. Runs in SiteArchitect/ContentCreator with an editing user and
  a context element. Use for automating editorial steps, dialogs, transitions.
- **Server context** — generation, schedule, PermissionService. Runs in the
  server (generation, deployment, interval tasks). Use for string/number work,
  modifying the generation context, backups, sub-site deployments.

---

## `ScriptContext` — base (available everywhere)

```
context.getConnection();                 // Connection

context.logDebug(msg);
context.logInfo(msg);
context.logWarning(msg);
context.logError(msg);
context.logError(msg, throwable);

context.getProperty(name);               // per-execution property (Object)
context.setProperty(name, value);
context.removeProperty(name);
context.getProperties();                 // String[]

context.is(Env.WEBEDIT);                 // true in ContentCreator
```

The method is `BaseContext.is(Env)` — **not** `isEnv(...)`, which does not exist
in the API. `Env` is `de.espirit.firstspirit.access.BaseContext.Env`. The full enum,
from the FS 5.2 source (`BaseContext.java`, confirmed 2026-09-03), has **11 values**:

| `Env` value | True when the script runs… |
| --- | --- |
| `WEBEDIT` | in **ContentCreator** |
| `PREVIEW` | in **preview** |
| `GENERATION` | during **generation** |
| `ARCHITECT` | in SiteArchitect **report / homepage** contexts only `[core]` — **not** set for menu, context-menu, workflow or Content2 scripts, whose context starts with an empty `Env` set, so `context.is(Env.ARCHITECT)` is `false` there |
| `WEB` | in a generic **web environment** on an application server `[javadoc]` (ContentCreator sets it together with `WEBEDIT` `[verify]`) |
| `MANAGER` | in **ServerManager** |
| `FS_BUTTON` | triggered by an **FS_BUTTON** in a template |
| `DROP` | during a **drag-and-drop** operation |
| `HEADLESS` | in **headless** mode |
| `FORM` | in a **form** context |
| `REPORT` | in a **report** context |

> **Correction (2026-09-03).** An earlier version of this table listed `AUTH_CLIENT` and
> `WEBSTART_CONFIG_CLIENT` — **neither exists** in `BaseContext.Env`. They came from the
> AI-sibling doc's Env list, "salvaged" as verified; that was wrong. The extracted `fs-api/`
> list and the FS 5.2.261001 `api-methods.txt` dump do **not** capture enum constants, so
> neither could confirm or deny them — the set must be read from `BaseContext.java` source
> (thanks to the PS source-checkout validation). `ARCHITECT` and `WEB` are now source-checked
> (above); the glosses for `MANAGER`/`FORM`/`REPORT` are still name-inferred — confirm the exact
> trigger against source if you branch on them.

> `context.is(Env.WEBEDIT)` replaces the deprecated `isWebClient` property.
>
> ⚠️ **Known doc trap — ignore it.** The official `ScriptContext` Javadoc
> (`docs.e-spirit.com/odfs/access/de/espirit/firstspirit/access/ScriptContext.html`), in its
> **"Common properties"** note, states: *"isWebClient … has been deprecated with 5.0.12, use
> `#isEnv(Env.WEBEDIT)` instead."* **That method name is wrong** — the real inherited method is
> `is(BaseContext.Env)`; there is no `isEnv`. This stale comment is the likely origin of the
> `isEnv` error (ours and the AI-sibling doc's). Do **not** copy the method name from that comment;
> the method-summary/inherited-methods section of the same page correctly shows `is(BaseContext.Env)`.
>
> To branch between the clients test **`context.is(Env.WEBEDIT)`** (`true` = ContentCreator,
> `false` = SiteArchitect). `PREVIEW` is **not** the SiteArchitect flag: it only says the script
> runs in a preview context and can be set in either client — the SiteArchitect preview's
> FS_BUTTON context carries `PREVIEW` + `FS_BUTTON` `[core]`, and ContentCreator can carry
> `WEBEDIT` and `PREVIEW` at the same time `[verify]`.

## `ProjectScriptContext` — adds project access

```
context.getProject();                    // Project
context.getUserService();                // UserService
```

Because every context is a `SpecialistsBroker` (via `BaseContext` `[jar]`):

```
context.requireSpecialist(SomeAgent.TYPE);
context.requestSpecialist(SomeService.TYPE);
```

## `ClientScriptContext` — the editing user + context element

```
context.getUser();                       // User
context.getUserGroups();                 // Group[]
context.getElement();                    // IDProvider — the element the script runs on
```

- `getElement()` returns the current store element as an `IDProvider` `[jar]` — it can be
  `null` (menu script without a selection) and is not necessarily a `DataProvider`; for
  Content2 scripts it is the `Content2` or the `Dataset` the script was started on `[core]`.
- Bound in **FS_BUTTON** scripts in a SiteArchitect form `[core]` (other clients: see the
  FS_BUTTON section), and inherited by all GUI script types below.

## `GuiScriptContext` — GUI host + form dialogs (menu / context-menu)

```
context.getGuiHost();                    // Host (UserService, Project, Connection, GUI language, ResourceBundle)
context.getScript();                     // Script — the executing script element
context.isOnHomePage();                  // boolean

// Open the script's own form as a dialog and read back what the editor entered:
FormData data = context.showForm();                       // no language tabs
FormData data = context.showForm(true);                   // with language tabs
FormData data = context.showForm(true, "subFormName");    // a named sub-part
// returns null if the user cancels
```

`showForm(...)` is the standard way to prompt an editor for input from a menu /
context-menu script — define the inputs on the script's **Form** tab, then read
the returned `FormData`.

## `WorkflowScriptContext` — drive a workflow (extends `GuiScriptContext`)

```
context.getElement();                    // the element under workflow (via ClientScriptContext)
context.getWorkflowable();               // Workflowable
context.getFormData();                   // FormData defined within the current Task
context.getTransitions();                // Transition[] allowed for the current user
context.getCallMode();                   // TaskState.Mode

context.doTransition("nextTransition");  // by reference name  (throws IllegalAccessException)
context.doTransition(transition);        // by Transition object
Transition t = context.showActionDialog();   // show dialog, auto-applies selected transition

context.getSession();                    // Map — persists across the whole workflow process
context.getWorkflowContext();            // WorkflowContext — the running process
context.getErrorInfo();                  // TaskErrorInfo — only if gotoErrorState was called in THIS execution, else null [javadoc]
context.sendEMail(receivers, subject, message);   // comma-separated receivers
context.gotoErrorState(comment, throwable);       // jump to the workflow's error state

// Constants: WorkflowScriptContext.MANUAL, WorkflowScriptContext.AUTOMATIC
```

Use `getSession()` (persistent Map) to carry values between workflow steps.
`getFormData()` reads the task's form; `showActionDialog()` handles the standard
"choose next transition" dialog for you — no explicit `doTransition` needed after.

## `Content2ScriptContext` — dataset scripts (extends `GuiScriptContext`)

Bound as `context` when a script runs on a Content2 node (table) **or** on a dataset in the
Content Store `[core]` — the same context class serves both, so do not assume a `Dataset`.

```
context.getEntityType();                 // EntityType
context.getData();                       // List of entities (master language, respects filter/order)
context.getData(language);               // same, for a specific Language
context.getSelectedRow();                // Entity — the selected row, or null
context.getElement();                    // the Content2 or the Dataset the script was started on (via ClientScriptContext)
```

## FS_BUTTON scripts — extra bound variables

An `FS_BUTTON` (`onClick="script:UID"` / `onDrop="script:UID"`) runs with these variables
`[core]` (SiteArchitect form gadget and SiteArchitect preview bind the same keys):

| Variable | Meaning |
| --- | --- |
| `context` | SiteArchitect form: `ClientScriptContext` with `Env.FS_BUTTON` (+ `DROP` on a drop) `[core]`; SiteArchitect preview: a plain `BaseContext` with `PREVIEW` + `FS_BUTTON` `[core]`; ContentCreator: `GuiScriptContext` with `WEBEDIT` + `WEB` `[verify]` |
| `element` | the element the form belongs to (only bound when there is one) |
| `language` | the current editing `Language` (preview: the master language when none is set) |
| `properties` | `Map<String,String>` — the button's own value; changes made by the script are kept |
| `drop` | `true` when triggered by drag-and-drop (`onDrop`), `false` on click |
| `dropdata` | the dropped `CommodityContainer` (empty container on a click) |
| *PARAM name* | every `<PARAM name="x">` of the FS_BUTTON as variable `x`; a value `#field.NAME` yields the `FormField` of input component NAME |

There is **no** `values`, `$field$` or `isDrop` variable — scripts using them fail with
"variable not found" or always take the `false` branch. (An earlier version of this table
listed them; they were taken from a third-party summary, not from the source.)

If you reference a **class** instead of a script (`onClick="class:…"`), it must
implement `de.espirit.firstspirit.access.script.Executable`; the same variables
arrive via the `Map` passed to `execute(...)` (keys `context`, `element`, `language`,
`properties`, `drop`, `dropdata`, plus the PARAMs).

## `GenerationScriptContext` / `GenerationContext` — template / generation scripts

Called from a template via `$CMS_RENDER(script:"IDENTIFIER", param:value)$`.
The runtime object is a **`GenerationContext`** (which extends `GenerationScriptContext`,
`Evaluator` and `Closeable` `[jar]`), bound as **`gc`** and, identically, as **`context`**
`[core]`. The script's **return value** is what is rendered into the template; the `result`
object is a legacy wrapper that is consulted only when the script returns nothing `[core]`:

```
//!BeanShell
// gc == context : the GenerationContext
return gc.getVariableValue("variable");          // preferred
// result.setValue(gc.getVariableValue("variable"));   // legacy equivalent
```

Key methods (on `GenerationScriptContext` unless marked):

```
gc.getGenerationContext();               // GenerationContext
gc.getLanguage();                        // Language currently generated
gc.getTemplateSet();                     // TemplateSet currently generated
gc.isRelease();                          // release vs current
gc.isPreview();                          // preview vs file generation
gc.toString(object);                     // same as $CMS_VALUE(object)$
gc.getVariableValue("name");             // read a $CMS_RENDER$ user parameter — an Evaluator method [jar]; works because gc is a GenerationContext
```

(In a Java `Executable` typed against `GenerationScriptContext` the `getVariableValue` call does
not compile — type it as `GenerationContext`.) The `$CMS_RENDER$` parameters are also bound
directly as script variables `[core]`.

Use these for conditional output (e.g. behave differently in preview vs release)
and to pull extra content (e.g. from the Content Store) into a page at generation.

`gc.getGenerationContext()` returns the `GenerationContext`, which exposes the
element and settings currently being generated:

```
genCtx.getPage();                        // Page currently generated
genCtx.getNode();                        // ContentProducer — the generating node
genCtx.getDataset();                     // Dataset (when generating dataset output)
genCtx.getPageParams();                  // PageParams
genCtx.getPageContext();                 // Context of the current page
genCtx.getNavigationContext();           // IDProvider — navigation position
genCtx.getScheduleContext();             // ScheduleContext (the running generation schedule)
genCtx.getUrlCreator();                  // UrlCreator
genCtx.getUrlCreatorProvider();          // UrlCreatorProvider
genCtx.mediaReferenced(media, language, resolution);   // register a media dependency
genCtx.getBasePath();                    // String
genCtx.getEncoding();                    // String
genCtx.getStartTime();                   // Date
genCtx.getEvaluator();                   // Evaluator
genCtx.getCharacterReplacer(boolean);    // CharacterReplacer
genCtx.getDebugMode();  genCtx.setDebugMode(boolean);
genCtx.getDeleteDirectory();             // boolean
genCtx.setUseMasterLanguageForData(boolean);
```

## `ScheduleContext` — schedule scripts (server)

```
context.getExecutionId();                // long
context.getProject();                    // Project (null if server-level entry)
context.getUserService();                // UserService (throws if not project-dependent)
context.getTask();                       // ScheduleTask (null if none running)
context.getTaskIndex();                  // int, or -1
context.getTasks();                      // List of tasks in this entry
context.getPath();                       // output/working path for this entry
context.getStartTime();                  // Date — reference time of this execution, not necessarily the real start (see setStartTime) [javadoc]
context.setStartTime(date);

// Report the outcome of a script-driven schedule step:
context.getErrorCount();                 // int
context.setStateToSuccess();
context.setStateToFailed();

// Variables persist BEYOND a single execution (unlike setProperty, which is per-run):
context.setVariable(name, serializableValue);
context.getVariable(name);
context.getVariableNames();              // Set
context.removeVariable(name);
```

Call `setStateToFailed()` (or `setStateToSuccess()`) so following schedule actions
and the schedule log reflect the script's result.

Use `setVariable/getVariable` to carry state between scheduled runs (e.g. a
timestamp of the last successful run); use `setProperty` only for the current run.

## `PermissionServiceScriptContext` / `PermissionEditorScriptContext`

- **PermissionService script** — generates user-group files from a database
  structure for the `PERMISSION` input component; run by the server at intervals.
  `context` is `PermissionServiceScriptContext` (extends `ScriptContext`).
- **PermissionEditor script** — each script named in a `PERMISSION` component
  renders as a button under it. `context` is `PermissionEditorScriptContext`
  (extends `GuiScriptContext`).
