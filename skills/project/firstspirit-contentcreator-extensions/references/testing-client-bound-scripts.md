# Testing client-bound scripts — what you can check headlessly, and the minimum manual loop

An `FS_BUTTON` script, a `ClientScriptOperation`, or preview JavaScript calling `WE_API` runs
**only when an editor clicks in ContentCreator**. Nothing in the REST API or the toolkit can
drive that click. The 2026-09-11 field test lost four round-trips to this; the point of this
page is to spend at most one.

## 1. Pre-check headlessly — the REST parse probe

`POST /rest/v1/projects/{id}/scripts/{name}/execute` runs a script in the REST server
context. A **BeanShell parse or compile error comes back in the response body**; a clean run
answers with an empty body. So it cheaply separates "my syntax is broken" from "my API call is
wrong". Its limit: the REST context is a project script context with **no `getElement()`**,
so any line that touches the current element fails there even when the script is correct in
ContentCreator. Details, the request shape and the `type: MENU` caveat when creating scripts
over REST: `firstspirit-rest-api` SKILL.md, section "Scripts". [odfs? no — `firstspirit-rest-api`, verified 0.0.23-beta]

Pattern: keep the element-dependent part behind a guard so the probe reaches the end of the file.

```
//!BeanShell
// parse-probe friendly: everything that needs the client is inside the if
el = null;
try { el = context.getElement(); } catch (Exception e) { /* REST probe context: no element */ }
if (el != null) {
    // real work here — operations, WE_API via ClientScriptOperation, …
}
```
Composite; not an official example. [verify]

## 2. Pre-check signatures — `javap`, not the Javadoc

Every `perform(...)` you call: read its parameter type from the jar before the click
(`firstspirit-operations` SKILL.md, "the one rule"). The two `ReflectError`s in the field test
were both signature mismatches a `javap` would have shown.

## 3. Pre-check the "does not work here" list

`references/does-not-work-in-contentcreator.md` — the calls that pass both checks above and
still do nothing.

## 4. The minimum manual loop

One click per iteration; make each click count:

1. Upload the script source (`PUT …/scripts/{name}/template-sets/{ts}`), then **read it back**
   and diff — a silent upload failure looks exactly like a script bug.
2. Have the editor reload the preview (`WE_API.Preview.reload()` from the console, or F5) so
   the `FS_BUTTON` picks up the new script.
3. Click once. Capture **both** sides: the server log for the BeanShell side
   (`context.logInfo`, `firstspirit-scripting/references/logging-and-debugging.md`) and the
   browser console for the JavaScript side (`console.log` in your `WE_API` code).
4. For async `ClientScriptOperation`: if the script "never returns", the callback did not fire
   — check every exit path before touching anything else (`references/client-script-operation.md`).

## 5. Build the dialog first, wire it second

The field test's task 6 needed four clicks because the dialog HTML, the click handler and the
server round trip were all changed at once. Sequence that costs one click each and fails
loudly: (a) static dialog with `WE_API.Common.createDialog()` from the browser console — no
script involved; (b) the script alone, returning a fixed value through `RequestOperation`;
(c) join them.

## Open

- Whether `POST …/execute` binds the JSON body as script **variables** (REST skill says so) —
  if yes, the probe can also unit-test parameter handling that `WE_API.Common.execute` did not
  deliver (`references/does-not-work-in-contentcreator.md`). [verify]
