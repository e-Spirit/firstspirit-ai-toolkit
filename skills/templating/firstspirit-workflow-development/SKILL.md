---
name: firstspirit-workflow-development
description: Building your own FirstSpirit workflows, the definitions and not only their scripts. Use it to model a workflow (states, activities, transitions, who may start and switch, error state, forms), to make it appear in SiteArchitect and ContentCreator, to build it in the Template Store UI or from a script, to release from a script (server-side release options, ReleaseOperation), and to find out why a workflow is not offered ("my workflow does not appear next to Release", "Hello World workflow", "workflow button missing in ContentCreator", "Runnable in ContentCreator", "Authorized checkbox", "Start transition", "missing rights error"). Also for reading the BasicWorkflows and ODFS sample workflows as models. Script contexts: firstspirit-scripting; installing BasicWorkflows: firstspirit-installation.
metadata:
  source-commit: "4a75bd0"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# Building FirstSpirit workflows

> **Beta.** Built from the product documentation, the Access API and one live run, checked where a tag says so: `[odfs]` product
> documentation, `[jar]` javap-verified against the FirstSpirit runtime jar (5.2.261011), `[observed]` seen in a live run (dated,
> versioned), `[verify]` not yet checked on a server. Treat a `[verify]` statement as a lead, not a fact.

A workflow is **a definition in the Template Store** (a state diagram plus settings) **and the scripts its activities call**.
Whether an editor sees it on a page is a third thing: **authorisation in the stores and rights on its Start transition**.
Most "my workflow does not show up" cases are that third thing, not the definition. A script can create and authorise a workflow; adding states or transitions from a script is not documented (`references/build-by-script.md`).

## Which part do you need

| You want to | Go to |
|---|---|
| Understand what a workflow consists of: states, activities, transitions, settings, the error state | `references/workflow-model.md` |
| Know why a workflow is not offered on an element | `references/not-offered.md` |
| Build one by hand in the Template Store (SiteArchitect, or the template-development view in ContentCreator), with a Hello World | `references/build-in-ui.md` |
| Build or change one from a script (Access API, runnable over REST) | `references/build-by-script.md` |
| Release from a script or module: default vs specific release, parent chain, recursive, dependent objects, `ReleaseOperation`, language-dependent release | `references/server-side-release.md` |
| Learn from the official ones (BasicWorkflows release, delete, release with AI review; the ODFS demos) | `references/official-examples.md` |

## Where the neighbours are

| Question | Goes to |
|---|---|
| Which `context` object a workflow script gets, `doTransition`, `showActionDialog`, session, forms, messages | `firstspirit-scripting` (`firstspirit-scripting/references/script-contexts.md`, `firstspirit-scripting/references/common-patterns.md`) |
| Which interface is a `Workflow`, how to reach `WorkflowAgent` | `firstspirit-api-reference` |
| Authorise a workflow in a store, group and role set-up, Git-sync of permissions | `firstspirit-configuration` (`firstspirit-configuration/references/workflows.md`, `firstspirit-configuration/references/permissions.md`) |
| Install BasicWorkflows, import its packages, element status provider, web component | `firstspirit-installation` (`firstspirit-installation/references/basicworkflows.md`) |
| Run a script on a server through REST | `firstspirit-rest-api` |
| Package workflows or scripts into a module | `firstspirit-module-development` |

## Rules of thumb

- **Two steps make it appear, and both are needed** (ContentCreator, administrator user, observed 2026-10-13 on FirstSpirit 2026.11 `[observed]`):
  1. *Authorise per store.* Not authorised: not listed. A workflow is offered only when it is *Authorized* in the store's Workflow permissions `[odfs]`.
  2. *Fixed rights on the Start transition.* Authorised with the default Start transition (fixed rights off): the user got a missing-rights error and a red status, **even as server and project administrator**, because the element's store permissions still apply. With *Fixed permissions* `Everyone` it was listed and ran. The BasicWorkflows packages are built this way `[verify]`, and so is the tutorial `[odfs]`.
- **An API check is not a UI check.** The same login passed `isWorkflowAllowed` and held every permission through REST while the UI refused it `[observed]`. Prove it in the client.
- **Red means "in workflow", not "stuck"** (ContentCreator status colours; blue never released, green released, orange modified, purple historic). A red element after a failed start has a running instance: resolve it in the client or, if that fails, abort it in SiteArchitect (`references/not-offered.md`).
- **ContentCreator is a setting, not a given.** The workflow must be *Runnable in ContentCreator* (`isWebedit()` `[jar]`, `webedit="1"` in the BasicWorkflows packages `[verify]`) and the element types it applies to must make sense in that client (display logic).
- **Edit in the UI, verify by reading back.** Reopen the workflow after saving; check the page's workflow list, not the absence of an error.
- **Test on a development or demo project.** Never on a production project.
- **Do not copy script facts here.** Point at `firstspirit-scripting`.

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
