---
name: firstspirit-contentcreator-extensions
description: >-
  Lookup reference for extending the FirstSpirit ContentCreator. Browser side: the WE_API JavaScript API (top.WE_API.Common / Dialog / Preview / Report, FSID, jumpTo, execute, showMessage, createDialog, preview reload / rescan / repaint, report shortcodes), the server→browser bridges ClientScriptOperation (sync vs async, callback-must-fire) and ClientResourceOperation, a "does not work in ContentCreator" list, MPP_API / JC_API (SiteArchitect). Java side: the ContentCreator plug-in interfaces a module implements (toolbar, inline edit, status notes, element status, timeline, translation) and the @WebAppComponent they need. Use whenever JavaScript in a ContentCreator preview or action must talk to the client, a BeanShell script or Executable must run JavaScript in the editor's browser, or a module adds ContentCreator UI — e.g. "reload only this section after my script ran", "open a report with a preset filter", "why does my ClientScriptOperation never return", "add a button to the ContentCreator toolbar".
metadata:
  source-commit: "889cb43"
  published: "2026-10-02"
  toolkit-version: "0.3.1"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# ContentCreator extensions (`WE_API` + `ClientScriptOperation`)

> **First pass (2026-09-14) — SME review pending.** Every `WE_API` member is tagged
> **[javadoc]** (FirstSpirit Access API Javadoc, package
> `de.espirit.firstspirit.webedit.client.api`) or **[odfs]** (the ODFS "JavaScript APIs ›
> ContentCreator" pages, FirstSpirit 2026.9). The `WE_API` interfaces are GWT client classes and
> are **not in `fs-isolated-runtime.jar`**, so they could not be `javap`-checked; only
> `ClientScriptOperation.perform(String, boolean)`, `MPPWebControl` (`top.MPP_API`) and
> `JavaClientApi` (`top.JC_API`) are **[jar]**-verified (FS 5.2.240208).
> **[observed]** = toolkit field test 2026-09-11 (one session, one project) — strong evidence,
> not yet reproduced. Other behaviour notes are **[verify]**.

ContentCreator exposes a JavaScript object, **`top.WE_API`**, that lets code running in the
browser drive parts of the editor UI and the preview: show a message or a custom HTML dialog,
navigate the preview to an element, reload part of the page after a change, open a report with
preset filters, register actions on `FS_INDEX` entries, and run a FirstSpirit script or
`Executable` on the server. The reverse direction — a server-side script pushing JavaScript
into the editor's browser — is the operation `ClientScriptOperation`. [odfs]

## Where the code runs — pick the direction first

| You are writing… | Use | Detail |
| --- | --- | --- |
| JavaScript in the **preview HTML** (template output), an **FS_BUTTON** callback, an **InlineEdit** button or a **report action** | `top.WE_API.*` | `references/we-api-common.md`, `references/we-api-preview.md`, `references/we-api-dialog.md`, `references/we-api-report.md` |
| Browser JavaScript that must run **server-side** code | `top.WE_API.Common.execute("script:<uid>" \| "class:<FQCN>", params, callback)` — asynchronous, result arrives in the callback | `references/we-api-common.md` |
| A **BeanShell script / Executable** that must run JavaScript **in the editor's browser** | `ClientScriptOperation` via `OperationAgent` — ContentCreator only | `references/client-script-operation.md` |
| Preview JavaScript that reads or sets **Multi Perspective Preview** parameters (timeline date, custom parameters such as a visitor role) | `top.MPP_API.*` — also available in the **SiteArchitect** preview, after injection | `references/mpp-api.md` |
| JavaScript in the **SiteArchitect** integrated preview that must reload the page or run a script | `top.JC_API.reload()` / `top.JC_API.execute(...)` — the SiteArchitect twin of the two `WE_API` calls; use the twin table to write both `WEBEDIT` branches | `references/jc-api.md` |
| **Java in a module** that adds a toolbar button, an inline-edit button, a status note, release-state detection, timeline markers, a translation provider or focus areas | the `Webedit…Plugin` interfaces (`[jar]`-verified signatures), each inside a `@WebAppComponent` | `references/java-plugins.md` |

The API is `top.WE_API`, not `window.WE_API`: the preview is an iframe, the API object lives
on the ContentCreator top window. [odfs]

## The three rules

1. **Guard the output.** `WE_API` exists only in a ContentCreator preview. Template output
   that uses it must be wrapped so SiteArchitect preview and generation never see it:
   `$CMS_IF(#global.is("WEBEDIT"))$ … $CMS_END_IF$` (the ODFS examples use exactly this). If
   the SiteArchitect preview needs the same behaviour, the `$CMS_ELSE$` branch calls
   `top.JC_API` (`references/jc-api.md`). In a script, the equivalent test is
   `context.is(Env.WEBEDIT)` — see `firstspirit-scripting/references/script-contexts.md`. [odfs]
2. **An asynchronous `ClientScriptOperation` must call its callback — always.** The
   application server parks a thread until the callback fires; if your JavaScript never calls
   it, that thread lives until the user logs out or closes the tab. Every code path, including
   "user cancelled", must call `callback(...)`. [javadoc] [odfs]
3. **`WE_API` identifies elements by numeric ID, never by UID.** `jumpTo({...})` and
   `setPreviewElement({...})` take `{"id": <id>, "store": "SITESTORE"}` or
   `{"contentId": <id>, "pageref" | "content2" | "template": <id>}` — exactly two keys, and the
   Javadoc says outright: "The UID is not supported at this point." [javadoc]

## Documentation traps (the ODFS examples are not all runnable)

| Where | The page shows | Reality |
| --- | --- | --- |
| ODFS Preview page, "Reacting to Preview Changes" example | `top.WE_API.Preview.registerElementReloadListener(...)` | The method is **`addElementReloadListener`** — the same page's own definition, the Javadoc and the ODFS "Dynamic content" page all say so. [javadoc] [odfs] |
| ODFS Common page, workflow-listener example | callback declared as `function(){ … workflowInfo… }` | The callback **receives** the info object as its parameter: `function(workflowInfo){ … }`. Declare it. [javadoc] |
| ODFS Common page | `PreviewElementListener` callback named `onChanged(FSID)` | Javadoc: `onChange(FSID)`. Irrelevant in JavaScript (you pass a function), but don't implement a Java-side listener from the ODFS name. [javadoc] |
| ODFS Reports page, shortcode table | seven built-in reports | Javadoc also has `REPORT_RECENTELEMENTS` = `"RecentElements"`; `Report.refresh(String)` is Javadoc-only too. [javadoc] |
| ODFS Common page, `addItemsPlugin` | only the `"index"` context type | Javadoc lists `"index"`, `"status"`, `"floating"` (`ClientItemConstants.TYPE_INDEX / TYPE_STATUS / TYPE_FLOATING`). [javadoc] |
| ODFS Preview page | MPP getters/setters on `top.WE_API.Preview` | **Deprecated since 5.2** — use `top.MPP_API`, same method names: `references/mpp-api.md`. [odfs] [javadoc] |
| ODFS MPP_API page | five functions | `MPPWebControl` also has `addParameterizedListener`, `addParameterListener`, `addTimeParameterListener` (ContentCreator only) — on the jar, not on the page. [jar] [javadoc] |
| ODFS JC_API page | `execute(String, Map, String callback)` | The Java interface has `execute(String)` (sync, returns the result) and `execute(String, Map)`; the callback is a trailing argument consumed by the JavaScript proxy. Also accepts `class:<name of a public Executable>`. [jar] [javadoc] |
| `firstspirit-operations` field-test note | async `perform(script, true)` "returns the callback value" | Consistent with the Javadoc: the async example returns `"methodReturnValue"` from `perform(script, true)`. The `@returns null` applies only when there is no value. [javadoc] [verify] |

## Does not work in ContentCreator — read before the first click

`references/does-not-work-in-contentcreator.md` — the calls that are **type-compatible but
semantically invalid** here: `jumpTo` to a medium, the ContentCreator URL builder on a medium,
`OpenElementDataFormOperation.perform(medium)`, HTML in a `RequestOperation`, `showForm()`
from an `FS_BUTTON`, and the one observation that `WE_API.Common.execute` **did not deliver
its parameters** to the script. No parser or `javap` catches these; only the list does. The
full SiteArchitect × ContentCreator matrix is
`firstspirit-operations/references/client-capability-matrix.md`.

## Test before you ask the editor to click

`references/testing-client-bound-scripts.md` — what can be checked headlessly (the REST
parse probe, `javap` on every `perform`, the does-not-work list) and the one-click manual loop
for what cannot. Loading larger JavaScript/CSS into the client once instead of embedding it in
a string: `references/client-resource-operation.md`.

## How the pieces fit — a typical round trip

Button in the preview → `WE_API.Common.execute("script:editcontent", {id: 12345}, cb)` →
BeanShell runs on the server, returns a value → `cb(result)` runs in the browser →
`WE_API.Preview.reload(containerElement)` re-renders just the section that carries an
`editorId`. That is the ODFS "Dynamic content" reload example, and it is the pattern to reach
for before writing a `ClientScriptOperation`. [odfs]

Use `ClientScriptOperation` only when the **server** side is the initiator (a toolbar
action, a workflow script) and needs the browser's answer before it can continue.

## What this skill does not own

- **How an operation is obtained, and the other client operations** (`RequestOperation`,
  `OpenElementDataFormOperation`, `SelectOptionOperation`, …):
  `firstspirit-operations/references/operations-catalogue.md`.
- **Which script context you are in** and `Env.WEBEDIT`:
  `firstspirit-scripting/references/script-contexts.md`.
- **`FS_BUTTON` / `fsbutton(...)` / `editorId(...)`** template syntax:
  `firstspirit-templating-reference/references/gom/references-links.md`.
- **Shipping JavaScript, an `Executable` or a plug-in class in a module** — `web-app`
  components, `fsWebCompile`, `cxt-cc-api` as `compileOnly`:
  the FirstSpirit module development documentation (ODFS: web-app components and `<public>` components) and
  the FirstSpirit module Gradle plugin documentation (`fsWebCompile` / `fsModuleCompile`). The plug-in *interfaces* are here
  (`references/java-plugins.md`); the packaging is not. Report plug-ins and their
  `Parameter` types: the FirstSpirit module development documentation (ODFS: DataAccessPlugin and reports).
- **Defining** the MPP parameterisation template, timeline and viewports (SiteArchitect
  documentation), and SiteArchitect browser-app configuration — not covered. The `MPP_API`
  and `JC_API` *calls* are: `references/mpp-api.md`, `references/jc-api.md`.

<!-- feedback-footer:v1 -->
## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
