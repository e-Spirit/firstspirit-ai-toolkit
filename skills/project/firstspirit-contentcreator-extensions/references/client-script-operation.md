# `ClientScriptOperation` — run JavaScript in the editor's browser from a server-side script

Interface: `de.espirit.firstspirit.webedit.server.ClientScriptOperation` [jar]
ODFS: JavaScript APIs › ContentCreator › Scripts [odfs]

| Member | Signature | Verified |
| --- | --- | --- |
| `TYPE` | `static final OperationType<ClientScriptOperation>` | [jar] FS 5.2.240208 |
| `perform` | `Serializable perform(String script, boolean asynchronous)` | [jar] — `@Nullable` return [javadoc] |

**ContentCreator only**, available since FirstSpirit 5.1.37 per the ODFS Javadoc page. [odfs]
`getOperation(ClientScriptOperation.TYPE)` in a SiteArchitect,
schedule or generation context has no browser to talk to — expect `null`; test for it. [odfs] [verify]

## Obtaining it

Through `OperationAgent`, like every operation (never as a specialist —
`firstspirit-operations` SKILL.md explains why): [odfs]

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.webedit.server.ClientScriptOperation;

opAg = context.requireSpecialist(OperationAgent.TYPE);
op   = opAg.getOperation(ClientScriptOperation.TYPE);
```

## Synchronous — `perform(script, false)`

The server **blocks** until the browser has evaluated the script; the evaluated value comes
back as the return value. Three accepted shapes: [javadoc]

| `script` contains | What is returned |
| --- | --- |
| a function definition `function f() { return 'x'; }` | the function is invoked; its return value |
| an expression `true ? 'x' : 'nothing'` | the expression's value |
| several statements | "depends on the order of the statements, and might differ in some browsers" — **avoid**; use a function or a single expression |

```
SCRIPT = "function executeScript() {"
       + "  var result = confirm('Press ok to start some useful operation!');"
       + "  return result;"
       + "}";
result = op.perform(SCRIPT, false);
if (result) { /* start some useful operation */ }
```
[odfs]

## Asynchronous — `perform(script, true)`

Use it when the JavaScript has to **wait** for something — user interaction in a dialog, a
fetch to an external resource. The script must be a **function taking one parameter, the
callback**; the server waits (in a parked thread) until that callback is invoked, and the
value passed to the callback becomes the return value of `perform`. [javadoc] [odfs]

```
SCRIPT = "function executeScript(callback) {"
       + "  var dialog = top.WE_API.Common.createDialog();"
       + "  dialog.setTitle('Confirm');"
       + "  var body = document.createElement('div'); body.textContent = 'Start the operation?';"
       + "  dialog.setContent(body);"
       + "  dialog.addButton('Yes',    function () { dialog.hide(); callback(true);  });"
       + "  dialog.addButton('Cancel', function () { dialog.hide(); callback(false); });"
       + "  dialog.show();"
       + "}";
result = op.perform(SCRIPT, true);
if (result != null && result) { /* start some useful operation */ }
```
Composite of the ODFS async example and the `Dialog` Javadoc; not an official example. [verify]

### The rule: the callback must always fire

> "The callback must always be notified about the completion of the execution! The server
> would otherwise wait forever on its completion." [javadoc]

The ODFS page adds the operational consequence: the waiting thread stays on the application
server **until the user logs out or closes the ContentCreator browser tab**. [odfs] Every
exit path of your JavaScript — every button, the dialog's close, a failed request — must call
`callback(...)`. A `try/catch` around your logic with `callback(null)` in the `catch` is the
minimum.

## Return value

`Serializable`, `null` "if there is no value to return". [javadoc] The field test recorded in
`firstspirit-operations` saw the async form return the callback's value — which is what the
Javadoc's async example shows too (`// returnValue => "methodReturnValue"`). [javadoc] [verify]
Types crossing the bridge are JavaScript primitives/strings; do not expect a structured object
to arrive as anything but a string unless you serialise it yourself. [verify]

## When to prefer something else

- Browser initiates, server answers → `top.WE_API.Common.execute(...)`
  (`references/we-api-common.md`): no parked thread, no string-embedded JavaScript.
- Just a question or message → `RequestOperation`, works in both clients:
  `firstspirit-operations/references/operations-catalogue.md`.
- Choose one of a few options → `SelectOptionOperation` (same package), listed in the same
  catalogue.
