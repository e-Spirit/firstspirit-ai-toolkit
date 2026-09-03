# Script types and their `context` object

A FirstSpirit script always has a variable named **`context`** bound at runtime.
Its concrete Java interface — and therefore which methods you may call — depends
entirely on **where the script runs**. Pick the row that matches your script type
before writing any code.

> All context interfaces below extend `ScriptContext` (base: logging, properties,
> connection). Client-side ones also extend `ProjectScriptContext` (project +
> `UserService`) and `SpecialistsBroker` (so `context.requireSpecialist(...)`
> works directly on `context`).

> **Visual:** [assets/firstspirit-context-hierarchy.png](../assets/firstspirit-context-hierarchy.png)
> is the DTA "FirstSpirit Contexts" UML poster of this whole hierarchy — handy for
> seeing at a glance which interface inherits which methods.

---

## Overview table

| Script type | Where it runs | `context` interface | Extends |
| --- | --- | --- | --- |
| **Menu script** | SiteArchitect *Extras → Execute Script* | `GuiScriptContext` | `ClientScriptContext`, `ProjectScriptContext` |
| **Context-menu script** | Right-click a store node / path in SiteArchitect | `GuiScriptContext` | same as above |
| **Workflow script** | On a transition/activity in a workflow | `WorkflowScriptContext` | `GuiScriptContext` |
| **Content2 (dataset) script** | On a dataset row in the Content Store | `Content2ScriptContext` | `GuiScriptContext` |
| **FS_BUTTON script** | `onClick` / `onDrop` of an `FS_BUTTON` | `ClientScriptContext` | `ProjectScriptContext` |
| **PermissionEditor script** | Button inside a `PERMISSION` input component | `PermissionEditorScriptContext` | `GuiScriptContext` |
| **Template / generation script** | `$CMS_RENDER(script:…)$` during (preview) generation | `GenerationScriptContext` (bound as **`gc`**) | `ProjectScriptContext` |
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
in the API. `Env` is `de.espirit.firstspirit.access.BaseContext.Env`. Method and
values verified against `fs-api/`, the ODFS `execution-envir` page
(`context.is(BaseContext.Env.WEBEDIT)`), and the FS 5.2.261001 API dump:

| `Env` value | True when the script runs… |
| --- | --- |
| `WEBEDIT` | in **ContentCreator** |
| `PREVIEW` | in the **SiteArchitect** Java client / preview |
| `GENERATION` | during **generation** |
| `AUTH_CLIENT`, `WEBSTART_CONFIG_CLIENT` | in the auth / web-start config clients |

> `context.is(Env.WEBEDIT)` replaces the deprecated `isWebClient` property.
> Use `WEBEDIT` vs `PREVIEW` to branch between ContentCreator and SiteArchitect
> behaviour.

## `ProjectScriptContext` — adds project access

```
context.getProject();                    // Project
context.getUserService();                // UserService
```

Because client contexts also implement `SpecialistsBroker`:

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

- `getElement()` returns the current store element; for dataset scripts it returns
  a `Dataset` (not the raw `Content2`).
- Bound in **FS_BUTTON** scripts, and inherited by all GUI script types below.

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
context.getErrorInfo();                  // TaskErrorInfo — details after a failure
context.sendEMail(receivers, subject, message);   // comma-separated receivers
context.gotoErrorState(comment, throwable);       // jump to the workflow's error state

// Constants: WorkflowScriptContext.MANUAL, WorkflowScriptContext.AUTOMATIC
```

Use `getSession()` (persistent Map) to carry values between workflow steps.
`getFormData()` reads the task's form; `showActionDialog()` handles the standard
"choose next transition" dialog for you — no explicit `doTransition` needed after.

## `Content2ScriptContext` — dataset scripts (extends `GuiScriptContext`)

Bound as `context` when a script runs on a dataset row in the Content Store.

```
context.getEntityType();                 // EntityType
context.getData();                       // List of entities (master language, respects filter/order)
context.getData(language);               // same, for a specific Language
context.getSelectedRow();                // Entity — the selected row, or null
context.getElement();                    // the Dataset (via ClientScriptContext)
```

## FS_BUTTON scripts — extra bound variables

An `FS_BUTTON` (`onClick="script:UID"` / `onDrop="script:UID"`) runs with
`context` typed as `ClientScriptContext`, **plus** these variables:

| Variable | Meaning |
| --- | --- |
| `context` | the `ClientScriptContext` |
| `values` | `Map` of values set by a previous script/executable |
| `$field$` / `#field` | the tree node info (section/page/dataset); use the `#field` system object for individual input components |
| `isDrop` | `true` if triggered by drag-and-drop (`onDrop`), `false` on click (`onClick`) |

If you reference a **class** instead of a script (`onClick="class:…"`), it must
implement `de.espirit.firstspirit.access.script.Executable`; the same variables
arrive via the `Map` passed to `execute(...)` (keys `context`, `values`, …).

## `GenerationScriptContext` — template / generation scripts

Called from a template via `$CMS_RENDER(script:"IDENTIFIER", param:value)$`.
Inside the script the generation context is bound as **`gc`** and the output is
returned through **`result`**:

```
//!BeanShell
// gc  : GenerationScriptContext
// result : holds the value rendered back into the template
result.setValue(gc.getVariableValue("variable"));
```

Key `GenerationScriptContext` methods:

```
gc.getGenerationContext();               // GenerationContext
gc.getLanguage();                        // Language currently generated
gc.getTemplateSet();                     // TemplateSet currently generated
gc.isRelease();                          // release vs current
gc.isPreview();                          // preview vs file generation
gc.toString(object);                     // same as $CMS_VALUE(object)$
gc.getVariableValue("name");             // read a $CMS_RENDER$ user parameter
```

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
context.getStartTime();                  // Date — when the entry started
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
