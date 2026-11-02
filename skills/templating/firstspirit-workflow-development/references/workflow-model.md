# What a workflow consists of

Sources: ODFS tutorial "Workflows" › "Modeling workflow" (Create workflow, Mapping the structure, Configuring workflow steps, Workflow permissions) `[odfs]`;
Access API checked with `javap` against 5.2.261011 `[jar]`; the three BasicWorkflows export packages (`WORKFLOW` and `ExternalAttributes.xml` read as files, then read back through the Access API on a project that has them imported; observed 2026-10-30 on FirstSpirit 2026.11 (5.2.261119), a development project) `[observed]`.

## The parts

| Part | What it is | Where |
|---|---|---|
| **Workflow** | One element under *Workflows* in the Template Store: reference name, display name per editorial language `[odfs]` | `Workflow` interface `[jar]` |
| **State** | A node of the diagram: Start, intermediate, End, Error. Holds who is responsible, write protection, release flag, duration | `State` `[jar]` |
| **Activity** | A step that runs a script, automatic or manual. A step with no script is allowed `[observed]` | `Activity.getScript()`, `isAutomatic()` `[jar]` |
| **Transition** | An arrow between states and activities; named; carries the rights ("who may take it") and optional e-mail | `Transition` `[jar]` |
| **Form** | The *Form* tab: input components shown in the workflow dialog `[odfs]` | `firstspirit-scripting` for reading values |
| **Settings** | Runnable in ContentCreator, runnable without context, display logic (a BeanShell) | `Workflow.isWebedit()`, `isContextFree()`, `getViewScript()` `[jar]` |
| **Rules / Snippets** | Tabs on the workflow, as on other templates | not covered here |

The editor tabs are *Properties*, *State diagram*, *Form*, *Rules* and *Snippet* `[odfs]` (ODFS *Workflows* landing page, 2026.5; *Settings* is the older wording of *Properties*). The *Snippet* tab decides how the workflow shows in overview lists; it is evaluated in the ContentCreator action windows for workflows `[odfs]`.

## A new workflow

A new workflow contains a Start state with a transition to the first activity, and an End state `[odfs]`. The default model in the runtime jar
has exactly that: Start (type 1), one manual activity, one End state, one transition from Start with
`useFixedRights=false`, `storeElementRights=4` and no groups `[jar]`. The official workflows change this transition (fixed rights, `Everyone`); the authorisation in the stores is the larger step (`not-offered.md`).

## Who may start, who may switch a step `[odfs]` `[jar]`

- The **Start state** type *Start (Set editor(s) automatically based on permissions)* takes the editors from the store permissions.
- A **transition** is allowed for the users named on it when *Fixed permissions* is on (`useFixedRights()` `[jar]`). The tutorial gives every transition *Fixed permissions: Enable, User: Everyone*.
- Without fixed rights a transition falls back to the store element's rights (`useStoreElementRights()`, `getUsedStoreElementRights()`) or to the task's rights (`useTaskRights()`) `[jar]`. What the integer
  `storeElementRights` means is not documented: the Javadoc calls it the transition's *store element rights code* (`Transition.getUsedStoreElementRights()` `[javadoc]`). The values seen all equal single `Permission` flags: 4 = `CAN_CHANGE`
  (the default of a new transition `[jar]`), 64 = `CAN_DELETE_LEAF` and 32 = `CAN_DELETE_FOLDER` (the BasicWorkflows delete workflow's non-fixed transitions, element and folder variants `[observed]`), 256 = `CAN_RELEASE` (the integrated `request_release`, read 2026-10-13, and the non-fixed `release` transitions, read 2026-10-30 `[observed]`).
  Reading the code as a `Permission` flag is a working assumption that fits these values and the refusal in `not-offered.md` `[verify]`.
  The `Permission` flags are public compile-time constants, **not ids**: identical in the 5.2.240208 and 5.2.261011 jars (`CAN_SEE` 1, `CAN_READ` 2, `CAN_CHANGE` 4, `CAN_APPEND_FOLDER` 8, `CAN_APPEND_LEAF` 16, `CAN_DELETE_FOLDER` 32, `CAN_DELETE_LEAF` 64, `CAN_CHANGE_PERMISSION` 128, `CAN_RELEASE` 256, `CAN_META_SEE` 512, `CAN_META_CHANGE` 1024, `PROJECT_ADMIN_PERMISSIONS` 135) `[jar]`, so they do not differ between servers or projects.
  Write the code as a constant (`Permission.CAN_RELEASE`), not as a number. What *does* differ per project and server: element ids, `workflowid` (12, 13 and 8 in the three packages), group ids and group names.
  A transition set to *From the target element's permissions* asks for a permission **on the element** `[odfs]`; read as flags, the default Start transition asks for `CAN_CHANGE` and `request_release` for `CAN_RELEASE` `[verify]`.
- A server or project administrator is **not** exempt: store permissions still apply in the UI `[observed]` (`not-offered.md`).
- All three BasicWorkflows packages set the Start transition to *Fixed permissions* with the group `Everyone` `[observed]`. In all three its reference name is `start`; in `release` and `release_with_ai_review` its **display name is empty**, in `delete` it is `Start` `[observed]`.
  So the transition name is not what makes a workflow appear on a page.
- Per state you can also choose write protection (`getStoreElementLock()`), a release of the element (`releaseStoreElement()`) and a duration `[jar]`.

## Modeling rules and properties `[odfs]`

- Exactly one Start state, with exactly one outgoing transition; a transition runs only between a state and an activity, never state to state or activity to activity.
- State types: Start, Normal, End, End and release element, Error. An activity is automatic (script runs at once) or manual (a user triggers it).
- An unnamed transition is addressed by `"->Target"` in `doTransition`.
- The *Permissions* tab of a transition offers three sources: *Fixed permissions*, *From the target element's permissions*, *From the active workflow task*. A node's *Special permissions* override a transition's rights on that node.
- A running instance write-protects the element where the state asks for it; a workflow cannot be edited while instances are running (write protection by running instances).
- Two integrated workflows ship with the server: *Release request* (`request_release`, bound to an element) and *Task* (`assign_task`, without context).
- The overview of open workflows sits at the *Workflows* root node in SiteArchitect; tasks can be closed there, which is the way to resolve a stuck instance.

## Project settings that workflows depend on `[odfs]`

ServerManager › Project properties › Options (read 2026-10-13):
- **Delete workflow:** must be set for deleting in ContentCreator. ContentCreator's *Delete* menu entry is only shown if a delete workflow is set.
- **Release function:** the type of release (including language-dependent release) is chosen here. ContentCreator does not support projects without the release function.

## Error state

A state of type *Error* (red border) has only outgoing transitions; any exception in the running workflow puts the instance there
(`Workflow.getErrorState()`, `WorkflowScriptContext.gotoErrorState` `[jar]`); see `firstspirit-configuration/references/workflows.md` and `firstspirit-scripting/references/script-contexts.md`.
All three BasicWorkflows packages define one (`errorState` in the model); its outgoing transition is unnamed `[observed]`.

## Settings that decide where it runs

| UI label (Properties tab) | API | Export attribute | Meaning |
|---|---|---|---|
| Workflow available in ContentCreator | `isWebedit()` / `setWebedit` `[jar]` | `webedit="1"`; `isWebedit()` true on all three `[observed]` | the workflow can be used in ContentCreator `[odfs]` |
| Workflow executable without context | `isContextFree()` / `setContextFree` `[jar]` | `contextfree="0"`; `isContextFree()` false on all three `[observed]` | the workflow may start without an element (the open-workflows overview); all official ones: off `[odfs]`. A context-free workflow (the integrated *Task*) can also run on an element when it is allowed in that store's Workflow permissions `[odfs]` |
| Display always | `isAlwaysActive()` `[jar]` | `alwaysActive="0"` on workflows (`isAlwaysActive()` false on all three `[observed]`), `"1"` on their scripts and on the 2012 samples `[verify]` | the workflow is offered regardless of the display logic `[odfs]` |
| Use display logic | `getViewScript()` / `setViewScript` `[jar]` | `viewScript` in `ExternalAttributes.xml` `[verify]`; `getViewScript()` set on all three `[observed]` | a BeanShell returning `true` when the workflow applies to `context.getElement()`; see `official-examples.md` |

The labels and the mapping to the three flags are from the Templates Basics page *Properties tab* of the workflow `[odfs]` (read 2026-10-13); the labels *Runnable in ContentCreator* and *Runnable without context* are the same checkboxes in an older wording. The display logic **and** the start permission are both evaluated: a workflow is offered only if the script allows it and the user may take the Start transition `[odfs]`.

The 2012 sample packages have no `webedit` attribute: they are SiteArchitect-era `[verify]`. Importing them does not make them ContentCreator workflows.

## Scripts and activities, from the documentation `[odfs]`

ODFS *Workflows* › *Using scripts* (2026.5):

- A script is attached to an **activity**, nothing else; `WorkflowScriptContext` is its context (`firstspirit-scripting`).
- **Editorial permissions are not evaluated automatically** when a script does the work (a release in a script, for example): the transition permissions have to carry them. The BasicWorkflows `release` transitions an administrator takes do that with store-element rights 256 (`CAN_RELEASE`) `[observed]`.
- An **automatic** activity runs as soon as the state before it is reached; at most **16 automatic activities in succession**, and a loop of automatic actions is detected, the instance terminated with an error message.
- `doTransition(String)` with the transition's name, or the generated `"->" + target state name` for an unnamed one; `getTransitions()`, `showActionDialog()`, `getFormData()`, `getSession()` are the other entry points named there.

Whether a workflow releases at all depends on the project: with *Use release function* off (ServerManager › Project properties › Options) the project is an **auto-release project** and every change is released at once; with it on, a change needs a release, and that is what the release workflows are for `[odfs]` (ODFS *Release workflow*).

## Reading a workflow from a package

A ContentTransport package stores a workflow as two files: `StoreElement.xml` (the `WORKFLOW` element with the attributes above and the display names)
and `ExternalAttributes.xml` (a serialised object graph: the `workflowModel`, plus `viewScript`, `rulesetXml`, `guiXml`) `[verify]`.
The serialised classes are not API: to *read or build* a model use the interfaces in `de.espirit.firstspirit.workflow.model` `[jar]`, not the XML.
