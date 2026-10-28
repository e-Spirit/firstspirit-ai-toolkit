# Why a workflow is not offered on a page

The symptom: the workflow exists in the Template Store, saves fine, and never appears next to Release, Delete, Translate this page.
Work through the list top to bottom; each item says where the evidence comes from. **Items 1 and 2 were observed in ContentCreator (2026-10-13, FirstSpirit 2026.11, an administrator user)**; items 3 to 9 rest on the documentation or are marked `[verify]`.

## Where to look

- **ContentCreator:** the workflows are listed in the element status panel (the status button, orange on a changed page), not in the user menu and not in the tasks panel `[observed]`.
- **SiteArchitect:** the *Workflow* entry of the element's context menu `[odfs]`.

## Checklist

1. **Authorised in the store?** On the store root: context menu › Extras › Change permissions › tab *Workflow permissions*, tick *Authorized* for the workflow, OK `[odfs]`.
   **Verified in ContentCreator:** a new, unauthorised workflow was **not listed** on the page `[observed]`.
   **Verified by API:** on a development project a freshly created workflow reported `isWorkflowAllowed(workflow, user) = false` on a page reference; after authorising it on the Site Store root it reported `true`; after removing the authorisation `false` again (an administrator user, 2026-10-13) `[observed]`. `release` stayed `true` throughout.
   Each store has its own list (Site Store, Page Store, Media Store, ...). A new workflow is not authorised anywhere. The entry may be visible to project administrators only `[odfs]`.
   Scripted: `firstspirit-configuration/references/permissions.md` (`WorkflowPermission`) `[jar]`.
2. **Rights on the Start transition.** Open the diagram, select the transition leaving Start, enable *Fixed permissions* and add the group `Everyone` (or the groups that should start it) `[odfs]`.
   The default new transition has fixed rights off and no group `[jar]`; the BasicWorkflows packages have `Everyone` `[verify]`.
   **Verified in ContentCreator:** with the workflow authorised and the default Start transition (fixed rights off, store-element rights 4 = `CAN_CHANGE`), the user got an error that the necessary rights were missing and the status provider turned red, **although the user is a server administrator and a project administrator**. The store permissions of the element still apply to them. After the Start transition was set to *Fixed permissions* with `Everyone`, the workflow was listed and the popup showed `[observed]` (one reload between the two states; the rights change is the only change to the definition).
   The REST/API user (same login) did **not** hit this: `isWorkflowAllowed` was `true` and the user held every permission on the page ref. Do not use an API check to prove what the UI will allow `[observed]`.
   A transition without fixed rights takes its rights from the target element's permissions `[odfs]`, so the default is not always fatal; what decides it is the rights of the person on the element. Fixed rights `Everyone` take that out of the equation.
3. **Workflow available in ContentCreator** ticked on the *Properties* tab (`webedit`), if the editor works in ContentCreator `[odfs]` `[jar]`.
4. **Display logic** (`Use display logic`): the script must return `true` for the element in question, **and** the user must be allowed to take the Start transition; both are checked `[odfs]`. *Display always* skips the script. A script copied from `release` excludes content-store folders and is right for pages;
   one that returns `false` or throws hides the workflow without a message `[verify]` (what the client does on an exception is not checked).
   The `delete` workflow's logic excludes content folders, project properties and datasources `[verify]`.
5. **ContentCreator needs more for BasicWorkflows only.** The *BasicWorkflows Status Provider* and the web component are for the module's own workflows `[odfs]`; a home-made workflow should not need them, `[verify]` on a server.
6. **Element type.** The workflow dialog is offered for elements the client supports; BasicWorkflows lists the types per client `[odfs]` (release in ContentCreator: page references, datasets, document groups).
7. **Reload.** After changing authorisation or settings, reload the client; whether a new login is needed as well is `[verify]`.
8. **Per-node special permissions** override the transition's rights on that node; an empty workflow list in ContentCreator means no workflow is authorised or none is allowed for the user on that element `[odfs]`.
9. **The delete workflow** is a separate setting (ServerManager › Project properties › Options › *Workflow to delete elements*) and replaces native delete `[odfs]`. Do not use it for experiments. ContentCreator shows *Delete* only if it is set; the *Release function* option of the same page must be on, as ContentCreator does not support projects without it `[odfs]`.

## Stuck instances and the status colours

The status shown in ContentCreator is worked out by a status provider. The ContentCreator documentation (Element status) names four states: *Never released*, *Released*, *Modified* (changed, not released in the selected language) and *In workflow* (a workflow has started; a lock icon means the element is write-protected and only the next workflow action can be done) `[odfs]`.
It marks a page that is in a workflow with a **red dot on the globe icon**, and a page not released in another language with a brown dot; an exclamation mark means validation issues `[odfs]`.
The page names the default status determination and the `WebeditElementStatusProviderPlugin`, says other providers may exist, and says a provider may show a never-released element as *Modified* `[odfs]`. BasicWorkflows ships its own *BasicWorkflows Status Provider*, which must be selected per project `[odfs]`.
Also on that page: a workflow always runs for an element in all languages; a second workflow cannot be started on an element that is already in one; while a parent is write-protected by a workflow its children cannot be started or switched `[odfs]`.
The text of the page names no colours; its screenshots show them (read 2026-10-13) `[odfs]`:

| Colour | Status |
|---|---|
| blue | never released |
| green | released |
| orange | modified, validation issues, or a section to restore |
| red | **in workflow** |
| purple | a historic version, or the release state of it |

**Red means "in workflow", not "stuck".** An element with a running instance is red whether the instance is healthy, waiting for the next action or in the error state; what the colour cannot tell is which. That explains the red status after the failed start above: the instance existed until it was resolved `[observed]`.
Release is the main use of a workflow in ContentCreator, so release states and workflow states share one colour scheme. A workflow that does something else (a deployment, a task) does not map onto it cleanly: the element is red while it runs and then goes back to whatever its release state is.
The BasicWorkflows documentation describes no colours of its own; its Status Provider decides which release and workflow state is shown `[odfs]`. Whether a provider could add colours at all is `[verify]`.
**Empty or grey status:** in an OCM, external-preview or e-commerce (headless) integration the status provider can be empty or grey. That is expected when the preview shows a page with no FirstSpirit object connected. An object is tied to a shop page by creating a section in the preview; after that the status, and with it the workflow list, works as usual `[verify]`.
Resolving: an instance that cannot be resolved inside the workflow is aborted in SiteArchitect, in the overview of open workflows at the *Workflows* root node, where tasks can be closed `[odfs]`; in ContentCreator the workflow window shows only the steps of the workflow that was started, with *Cancel* to leave it `[odfs]`; whether ContentCreator can resolve every case is `[verify]`; in the test above it was resolved by clicking once the Start rights were right `[observed]`.
By script: `Workflowable.hasTask()`, `getTask()`, `removeTask()` and `UserService.closeTask(Task)` exist `[jar]` `[verify]` on a server.

## Not the cause (so far)

- **The Start transition's name.** Naming it did not make the workflow appear (2026-10-12 `[verify]`); in the BasicWorkflows `release` package it has no name `[verify]`, and that workflow is offered.
- **The script type** (for example a menu script). The BasicWorkflows scripts are mostly type 0 (`Script.TEMPLATE` `[jar]`) `[verify]`, but a script is called by name from an activity; `[verify]` that the type does not matter.

## Proof

A workflow is verified when it appears in the status panel, runs to the End state and the popup (or the effect) is seen. Record the client and the server version with the result.
