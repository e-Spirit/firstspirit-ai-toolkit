# Workflows: permissions, models and where the rest lives

Source: ODFS tutorial "Workflows" (index and all subpages: Modeling workflow, Error, Delete, RecursiveLock, RecursiveRelease, Examples for scripts,
Form support, Messages, Persistent content) and BasicWorkflows documentation 2.5, `[odfs]`, read 2026-10-09 (FirstSpirit 2026.11 documentation).
Jar claims checked with `javap` against 5.2.261011 `[jar]`. The full reference is the SiteArchitect handbook and the developers' documentation.

## Authorising a workflow (the permission part)

- A workflow is available on elements only if it is **authorised per store**: on the store root, context menu, Extras, Change permissions,
  tab *Workflow permissions*, tick *Authorized*. OK applies it to every element in the store.
- The release workflows also need *Use release permission* (BasicWorkflows 2.5).
- The tutorial page covers only these ticks. Inheritance, who may start a workflow and transition permissions are not on it
  (it points to the SiteArchitect handbook); use the Access API facts in `permissions.md` `[jar]`.
- The Change permissions entry may be visible only to project administrators.
- Store-level workflow permissions do not appear in a Git export in any mode (`permissions.md`, `[observed]`).

## Model facts an administrator needs `[odfs]`

- A workflow is created under *Workflows* in the Template Store (New, Create new workflow): a reference name and a display name per editorial language.
  Editors see the display names on buttons and titles. New workflows open in edit mode; the graphical editor is the *State diagram* tab; the *Form* tab holds input forms.
- Who may start the workflow and who may switch a step is set on the elements. Start status type *Start (Set editor(s) automatically based on permissions)*
  takes the editors from the store permissions; a transition with *Fixed permissions* names users or groups itself (the tutorial uses *Everyone*).
  Per step you can also choose write protection and a notification.
- **Error status:** a status of type *Error* (red border) has only outgoing transitions. Any exception in the workflow, handled or not, puts the
  instance there; the model decides how to go on.
- **Delete workflow:** one per project, chosen in ServerManager, Project, Options, *Workflow to delete elements*; it replaces all delete controls in
  SiteArchitect and ContentCreator. The workflow must be authorised in the stores and must itself delete the element (see `firstspirit-installation` for BasicWorkflows).
- Workflows and their scripts travel as a zip or a ContentTransport package (the tutorial offers sample files for import into the *Workflows* node).

## Where the tutorial's other parts belong

| Tutorial part | Fits best | Why |
|---|---|---|
| Authorising, delete workflow setting, error status, who may start | this page | project administration |
| Installing and importing workflow sets | `firstspirit-installation` | steps on server and project |
| Script facts: `context` methods, session, messages, forms, server-side release | `firstspirit-scripting` (workflow facts below) | the script context and patterns are its subject |
| Workflow modeling as development (state diagram, loops, review chains), why a workflow is not offered | `firstspirit-workflow-development` | developer work |

### Workflow script facts

The script contexts and general patterns are in `firstspirit-scripting`; these are the workflow-specific facts.

- `[jar]` `WorkflowScriptContext` has `showActionDialog()` (returns a `Transition`), `doTransition(String | Transition)`, `getTransitions()`,
  `getTransitionParameters()`, `getFormData()`, `getSession()` (a Map, state kept between transitions), `gotoErrorState(String, Throwable)`,
  `getErrorInfo()`, `getTask()`, `getStoreElement()`, `sendEMail(...)`. `getElement()` comes from `ClientScriptContext`. `Transition.getAllowedUsers()` returns a list of names.
- `[odfs]` An unhandled exception puts the instance into the error status; `gotoErrorState` does it on purpose. An error dialog can read `getErrorInfo()` and
  then `doTransition` back to a normal state.
- `[odfs]` Messages use `RequestOperation` from `OperationAgent` with kinds WARN, INFO, QUESTION, ERROR; ContentCreator shows WARN and INFO alike.
- `[odfs]` Server-side release: `AccessUtil.release(IDProvider, checkOnly, releaseParentPath, recursive, DependentReleaseType)` `[jar]` (the 5-argument form exists),
  returns a `ServerActionHandle`; `getProgress(true)` then `getMissingPermissionElements()` and `getLockFailedElements()` `[jar]`. The workflow's own
  write protection must be removed first (`setLock(false, false)`), because the release sets its own. Lock failures are reported in test mode (`checkOnly`) only.
- `[odfs]` Counter and state between runs through `context.getSession()`.
- In the tutorial's error example the script throws `IllegalArgumentException` (the surrounding text names `IllegalStateException`).
