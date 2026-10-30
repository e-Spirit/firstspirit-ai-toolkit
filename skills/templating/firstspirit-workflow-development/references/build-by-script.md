# Build and change a workflow from a script

The Access API has the whole workflow model: `Workflows.createWorkflow`, `Workflow.setWebedit/setContextFree/setViewScript`, `getWorkflowModel()`
(a `ModifiableWorkflow` when read from a workflow `[jar]`) and `WorkflowPermission`. So a definition is **not** out of reach of a script, and not of REST:
a script runs in a project through `POST /projects/{id}/scripts/{name}/execute` (`firstspirit-rest-api`; the permissions scripts in `firstspirit-configuration` do it).
What works and what does not was observed 2026-10-13 on FirstSpirit 2026.11, on a development project `[observed]`.

## What worked `[observed]`

- **Read** all workflows: `ts = storeAgent.getStore(Store.Type.TEMPLATESTORE); ts.getWorkflows().getChildren(Workflow.class, true).toList()`; `getWorkflowByName(name)`.
  Flags per workflow: `isWebedit()`, `isContextFree()`, `isAlwaysActive()`, `getViewScript()`. Transitions: `m.transitions()` (an iterator); `getSource()`, `getTarget()`, `useFixedRights()`, `getAllowedGroups()`.
  (`getSourceTransitions()` on the Start state returned nothing; iterate `transitions()` and compare `getSource()` with `getStartState()`.)
- **Create:** `wf = ts.getWorkflows().createWorkflow("zz_hello_world", "Hello World")` returned a workflow with an id. The new element is not locked.
- **Change and save:** `wf.setLock(true, false)`, `wf.setWebedit(true)`, `m = wf.getWorkflowModel()`, `m.setProperty(element, Activity.PROPERTY_SCRIPT, "script_name")`, `wf.setWorkflowModel(m)`, `wf.save("comment")`, `wf.setLock(false, false)`.
  Without `setLock(true, false)` the save throws `IllegalStateException ... not locked`. A script that throws midway leaves the lock behind; the next run of the same user can lock again.
- **Authorise in a store and test it:** `site.setLock(true,false); wp = site.getCreateWorkflowPermission(wf); wp.setAllowedGroups(new Group[]{g}); site.setWorkflowPermission(wp); site.save(); site.setLock(false,false)`,
  with `g = ProjectMembersAgent.getGroupByName("Everyone")`. `el.isWorkflowAllowed(wf, user)` on a page reference then went `false` → `true`; after `site.removeWorkflowPermission(wf)` it went back to `false`. This is the check to script: it needs no client.
- **Set the Start transition's rights:** `m.setProperty(start, Transition.PROPERTY_FIXED_RIGHTS, Boolean.TRUE)` and `m.setProperty(start, Transition.PROPERTY_GROUPS, list)` with `list = ["Everyone"]` (group names as strings), then `wf.setWorkflowModel(m); wf.save(...)`. Read back with `t.useFixedRights()` and `t.getAllowedGroups()`: `fixed=true groups=[Everyone]` `[observed]`. The workflow then listed and ran in ContentCreator `[observed]`.
- **Read back the activity:** `getScript()` and `isAutomatic()` returned what `m.setProperty(act, Activity.PROPERTY_SCRIPT / PROPERTY_AUTOMATIC, ...)` set `[observed]`.
- **Delete:** `wf.setLock(true, false); wf.delete()`; the delete worked after the authorisation was removed.
- **A new workflow made by script has `contextfree` on** (`isContextFree()` true) and `alwaysActive` on; the BasicWorkflows packages have `contextfree` off `[verify]`. Set `wf.setContextFree(false)` before relying on it `[observed]`; whether a UI-created workflow has the same defaults is `[verify]`.

## What did not work

- **Adding a state or a transition.** `insertTransition` needs a new transition object, and creating one is not documented in the Access API; the classes behind the model interfaces are not API and must not be used. No supported way to add states or transitions from a script was found in the test `[observed]`.
  Ways round it: draw them in the UI; import a ContentTransport package that contains the model; or start from `release`/`delete` and change properties of the existing elements.
- A default new workflow has Start → one manual activity and **no transition to End** `[jar]` `[observed]`; adding it from a script is not documented. A Hello World built only by script therefore cannot finish.

## Not tried

- Display names per language on a new workflow (`createWorkflow(String, String)` takes one string; the Map variant `createWorkflow(String, Map<Language,String>, boolean)` is in `WorkflowContainer` `[jar]` `[verify]`).
- Setting the display logic with `setViewScript`.
- The effect of the Start transition's rights for a user who is **not** an administrator (the administrator test already failed on the default, see `not-offered.md`).
- Removing a running instance by script (`removeTask`) `[verify]`.
- Importing a package from a script: `StoreElement.importStoreElement(ZipFile, ImportHandler)` and `UserService.importStoreElements` exist `[jar]`; the BasicWorkflows project app does it for its three packages (`firstspirit-installation`).

## Sketch (each call ran in the test above; this exact combination was not run as one script)

```
import de.espirit.firstspirit.agency.StoreAgent;
import de.espirit.firstspirit.agency.ProjectMembersAgent;
import de.espirit.firstspirit.access.store.Store;
storeAgent = context.requireSpecialist(StoreAgent.TYPE);
ts = storeAgent.getStore(Store.Type.TEMPLATESTORE);
wf = ts.getWorkflowByName("my_workflow");
if (wf == null) wf = ts.getWorkflows().createWorkflow("my_workflow", "My workflow");
wf.setLock(true, false);
wf.setWebedit(true);
wf.save("create");
wf.setLock(false, false);
```

Authorisation and the check are the block above. Run a scripted create only on an internal or demo project and delete what you made.
