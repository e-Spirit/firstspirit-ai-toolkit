# `top.JC_API` — the SiteArchitect twin: reload the integrated preview, run a script

Java interface: `de.espirit.firstspirit.client.gui.JavaClientApi` [jar] FS 5.2.240208
ODFS: JavaScript APIs › SiteArchitect [odfs]

**Scope note:** this is **SiteArchitect**-side JavaScript — the integrated browser preview
(InlinePreview) and browser apps in the Java client. It is here because it is the exact twin of
two `WE_API` calls and a template author needs both sides of the `WEBEDIT` branch in one place.
Injected into the page as `window.JC_API` (so `top.JC_API` from the preview document). [javadoc]

## Members

| Member | Java signature [jar] | JavaScript call | Note |
| --- | --- | --- | --- |
| `reload` | `void reload()` | `top.JC_API.reload()` | reload the current preview URL of the integrated browser the script runs in [odfs] |
| `execute` | `Object execute(String identifier)` | `top.JC_API.execute("script:<uid>")` | **synchronous** — returns the script's / Executable's result [javadoc] |
| `execute` | `Object execute(String identifier, Map<String,Object> params)` | `top.JC_API.execute("script:<uid>", {…}, function (value) {…})` | **asynchronous** — the JavaScript proxy takes the callback as a trailing third argument; the result reaches the callback [javadoc] [odfs] |

The ODFS page writes the async form as `execute(String, Map, String callback)`; the Java
interface has only two parameters — the callback is consumed by the JavaScript proxy, not by
Java. Pass a function object or a function name. [jar] [javadoc] [odfs]

### `identifier` formats [javadoc]

| Form | Meaning |
| --- | --- |
| `script:<SCRIPT_UID>` | a script in the Template Store, by UID |
| `class:<FULLY_QUALIFIED_CLASSNAME>` | an `Executable` class from a module |
| `class:<NAME_OF_PUBLIC_EXECUTABLE>` | the name of a **public** `Executable` component — Javadoc only, not on the ODFS page |

```javascript
// synchronous — SiteArchitect only
var result = top.JC_API.execute("script:fsapiscript");

// asynchronous, with parameters
top.JC_API.execute("script:fsapiscript", {"param1": 42}, function (value) {
  alert(value);
  top.JC_API.reload();
});
```
[javadoc] [odfs]

## The twin table — write both branches

| Task | ContentCreator (`top.WE_API`) | SiteArchitect (`top.JC_API`) |
| --- | --- | --- |
| reload the whole preview | `WE_API.Preview.reload()` | `JC_API.reload()` |
| reload one element | `WE_API.Preview.reload(element)` | — (whole page only) |
| run a script / Executable, async with callback | `WE_API.Common.execute(id, params, cb)` | `JC_API.execute(id, params, cb)` |
| run a script synchronously | — | `JC_API.execute(id)` |
| messages, dialogs, jumpTo, reports, listeners, action hotspots | `WE_API.Common / Dialog / Report` | — |
| MPP parameters | `top.MPP_API` | `top.MPP_API` after injection — `references/mpp-api.md` |

```html
<script type="text/javascript">
  function runAndRefresh() {
$CMS_IF(#global.is("WEBEDIT"))$
    top.WE_API.Common.execute("script:editcontent", {}, function () { top.WE_API.Preview.reload(); });
$CMS_ELSE$
    top.JC_API.execute("script:editcontent", {}, function () { top.JC_API.reload(); });
$CMS_END_IF$
  }
</script>
```
Composite; not an official example. Whether `JC_API` is present at script-run time or, like
`MPP_API`, only after `window.onBrowserInjection` fires, is not stated on the ODFS page. [verify]

## Not covered here

SiteArchitect browser apps / InlinePreview configuration and the `de.espirit.firstspirit.client.gui`
package beyond `JavaClientApi`.
