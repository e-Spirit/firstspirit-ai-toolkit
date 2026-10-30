# The official workflows as models

Two sets, both free to read and import. The BasicWorkflows source is public (Apache licence) at the e-Spirit GitHub organisation, repository `basicworkflows`; the packages are the
ContentTransport exports the module's project app imports `[odfs]`. The ODFS tutorial ships its demos as `DEVB_workflows.zip` on the Workflows tutorial page `[odfs]`.
What follows was read from the package files (`StoreElement.xml`, `ExternalAttributes.xml`) `[verify]`.

## BasicWorkflows (module 1.6.2) `[verify]`

| Package | Workflow uid | Scripts | Start transition | Display logic excludes |
|---|---|---|---|---|
| `basicworkflows-export-basic-delete` | `delete` | nine `wf_delete_*` scripts in a folder `delete_workflow_scripts` | named `Start`, fixed rights, `Everyone` | content-store folders, project properties, datasources |
| `basicworkflows-export-basic-release` | `release` | `wf_release`, `wf_release_find_releated_objects`, `wf_release_show_not_released`, `wf_release_show_warning`, `wf_release_test` | no name, fixed rights, `Everyone` | content-store folders |
| `basicworkflows-export-basic-release-with-ai-review` | `release_with_ai_review` | `wf_ai_review`, `wf_ai_review_configuration`, `wf_show_ai_review_results` | no name, fixed rights, `Everyone` | content-store folders |

Common to all three: `webedit="1"`, `contextfree="0"`, `alwaysActive="0"` on the workflow, an error state, German and English display names, scripts with `alwaysActive="1"`.
The delete workflow models `Check`, `Check references`, `Show faulty objects`, `Delete decision`, an error-handling state and a final `End delete`; most transitions are fixed to `Everyone`, one (`Trigger check`) is not fixed and lists `Administrators` with store-element rights 64 (meaning of the number: `workflow-model.md`) `[verify]`.
Installing, importing, authorising and the one-delete-workflow rule: `firstspirit-installation/references/basicworkflows.md`, `firstspirit-configuration/references/workflows.md`.

Use them as models for: a Start transition with rights, a display-logic script, scripts split per step and called by name from activities, an error state, forms (`release` has a form with the language and media options `[odfs]`),
and server-side release in a script.

## ODFS demos (sample package from the tutorial) `[verify]`

| Demo workflow | Scripts | Teaches | Tutorial page |
|---|---|---|---|
| `countertest` | `counter` | state between runs through `context.getSession()` | Persistent content |
| `errortest` | `errortest1`, `errortest2`, `errorshow` | the Error state, an unhandled exception, `gotoErrorState`, reading the error info | Workflow "Error" |
| `guidemo` | `guitest` | the *Form* tab, `showActionDialog()`, `getFormData()` | Form support |
| `message` | `transitionmessage` | `RequestOperation` dialogs before and after a transition | Messages |
| `deletedemo` | `serverdelete`, `clientdelete` | deleting via a workflow, server-side and client-side | Workflow "Delete" |
| `recursivelock` | `lockrecursive` | write protection set by the workflow, then recursive lock by the script | Workflow "RecursiveLock" |
| `recursicereleasedemo` | `serverrelease` | server-side release with `AccessUtil.release` (deprecated, use `ReleaseOperation`: `server-side-release.md`; the uid is spelled so in the package) | Workflow "RecursiveRelease" |

**Age:** the demo package was exported in 2012 `[verify]`. The workflows carry no `webedit` attribute, so they are SiteArchitect workflows; importing them does not make them appear in ContentCreator `[verify]`.
The code on the tutorial pages is current (FirstSpirit 2026.11 documentation `[odfs]`); script facts belong to `firstspirit-scripting`. Which tutorial part belongs where, and the corrections to the tutorial's example code, are in `firstspirit-configuration/references/workflows.md`.

## What to copy and what not

- Copy the **structure**: Start transition with fixed rights, one script per step, display names in both languages, an error state.
- Do not copy uids, `workflowid` or element ids; they belong to the source project.
- Do not edit the imported BasicWorkflows packages in place if you want module updates; copy the workflow and change the copy (`firstspirit-installation`: updates re-import is `[verify]`).
