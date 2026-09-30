# `top.MPP_API` — Multi Perspective Preview parameters from preview JavaScript

Java interface: `de.espirit.firstspirit.client.mpp.MPPWebControl` [jar] FS 5.2.240208
ODFS: JavaScript APIs › Multi Perspective Preview [odfs]

**Scope note:** this is the one part of this skill that is **not** ContentCreator-only. MPP_API
is injected into the **SiteArchitect** preview as well; only the three listener methods are
restricted to ContentCreator ("WebEdit mode"). [odfs] [javadoc]

The MPP getters/setters that used to sit on `top.WE_API.Preview` are deprecated since 5.2 and
map 1:1 onto these (`references/we-api-preview.md`). [javadoc]

## Members

| Member | Signature | Verified | Note |
| --- | --- | --- | --- |
| `IDENTIFIER` | `static final String` | [jar] | the injection name, `"MPP_API"` [verify value] |
| `isParameterized` | `boolean isParameterized()` | [jar] | `true` when the MPP toolbar is shown / parameterisation active [odfs] |
| `getTimeParameter` | `Object getTimeParameter()` | [jar] | the date/time set in the MPP timeline; ODFS types it `JavaScriptObject` (a JS `Date`) [odfs] |
| `setTimeParameter` | `void setTimeParameter(Object date)` | [jar] | sets the timeline; pass a JS `Date` [odfs] |
| `getParameter` | `Object getParameter(String name)` | [jar] | value of the custom parameter whose **input-component `name`** in the MPP parameterisation page template matches [odfs] |
| `setParameter` | `void setParameter(String name, Object value)` | [jar] | value must be compatible with that input component's value type [odfs] |
| `addParameterizedListener` | `void addParameterizedListener(ParameterizedListener)` | [jar] | callback `function(parameterized)` — toolbar switched on/off. **ContentCreator only** [javadoc] |
| `addParameterListener` | `void addParameterListener(ParameterListener)` | [jar] | callback `function()` — "at least one custom parameter was changed"; **no argument** tells you which. **ContentCreator only** [javadoc] |
| `addTimeParameterListener` | `void addTimeParameterListener(TimeParameterListener)` | [jar] | callback `function(date)`. **ContentCreator only** [javadoc] |

The three listeners are **not on the ODFS page** — Javadoc and jar only. [javadoc]

The API gives **no information about the current viewport** setting. [odfs]

## Reading parameters

```javascript
if (top.MPP_API.isParameterized()) {
  var role = top.MPP_API.getParameter("visitorRole");   // name of the input component in the MPP template
  var when = top.MPP_API.getTimeParameter();            // JS Date from the timeline
  document.body.classList.toggle("logged-in", role == "member");
}
```
Composite of the ODFS descriptions and the Javadoc example (`getParameter("gender")`). [odfs] [javadoc]

## Writing parameters (keep the toolbar in sync with the preview)

```javascript
// Visitor logged in inside the preview → reflect it in the MPP toolbar
top.MPP_API.setParameter("visitorRole", "member");
top.MPP_API.setTimeParameter(new Date(2026, 11, 24));
```
[odfs]

## SiteArchitect: wait for the injection

In ContentCreator `top.MPP_API` is available when the preview script runs. In the SiteArchitect
preview the object is **injected later**; wait for `window.onBrowserInjection` with the name
`"MPP_API"`: [odfs]

```html
<script type="text/javascript">
  function anyFunction() {
    // PUT YOUR CODE HERE
  }
$CMS_IF(isWebEdit)$
  anyFunction();
$CMS_ELSE$
  window.onBrowserInjection = function (name, object) {
    if (name == "MPP_API") {
      anyFunction();
    }
  };
$CMS_END_IF$
</script>
```
Verbatim from the ODFS page, which uses the older `isWebEdit` variable; `#global.is("WEBEDIT")`
is the current form — `firstspirit-templating-reference` owns that syntax. [odfs] [verify]

## Not covered here

Defining the MPP parameterisation page template, the timeline and viewports — the FirstSpirit
SiteArchitect documentation ("Multi Perspective Preview"), not this skill.
