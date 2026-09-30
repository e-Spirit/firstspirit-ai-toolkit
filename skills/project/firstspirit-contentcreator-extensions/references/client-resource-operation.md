# `ClientResourceOperation` — load a script or stylesheet into the ContentCreator page

Interface: `de.espirit.firstspirit.webedit.server.ClientResourceOperation` [jar] FS 5.2.240208
Javadoc: "Operation providing means to load resources on the client-side." [javadoc]
Not on the six ODFS "JavaScript APIs" pages — Javadoc + jar only.

| Member | Signature | Verified | Note |
| --- | --- | --- | --- |
| `TYPE` | `static final OperationType<ClientResourceOperation>` | [jar] | |
| `addScriptUrl` | `void addScriptUrl(String url)` | [jar] | JavaScript to load; relative URLs resolve against the **ContentCreator web-app context path** (e.g. `/fs5webedit/`) [javadoc] |
| `addStylesheetUrl` | `void addStylesheetUrl(String url)` | [jar] | CSS to load; same base URL rule [javadoc] |
| `perform` | `void perform(boolean waitForResources)` | [jar] | `true` → block until loading has completed; `false` → return immediately, loading continues [javadoc] |

**ContentCreator only** — it lives in `webedit.server` and loads into the ContentCreator
window, not the preview iframe. [javadoc] [verify]

## Why it exists

`ClientScriptOperation` sends a JavaScript **string**. Anything larger than a few lines — a
dialog library, a shared helper — belongs in a file served by a module's `web-app` component,
loaded once with `ClientResourceOperation`, then *called* with `ClientScriptOperation`:

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.webedit.server.ClientResourceOperation;
import de.espirit.firstspirit.webedit.server.ClientScriptOperation;

ops = context.requireSpecialist(OperationAgent.TYPE);

res = ops.getOperation(ClientResourceOperation.TYPE);
res.addStylesheetUrl("mymodule/dialog.css");         // relative → /fs5webedit/mymodule/dialog.css
res.addScriptUrl("mymodule/dialog.js");
res.perform(true);                                   // wait, so the functions exist before we call them

run = ops.getOperation(ClientScriptOperation.TYPE);
result = run.perform("function f(callback) { MyModule.openDialog(callback); }", true);
```
Composite of the Javadoc members; not an official example. Where the files are served from
(the module's `web-app` component, its resource path) is the FirstSpirit module development documentation (ODFS: web-app components and `<public>` components). [verify]

## Open

- Whether resources loaded this way survive a preview navigation (they are in the top window,
  so they should) and whether loading the same URL twice is deduplicated. [verify]
- `waitForResources=true` presumably parks a server thread like the async
  `ClientScriptOperation`; a URL that never loads may hang it. Prefer `false` plus a readiness
  check in the script you run next unless you need the guarantee. [verify]
