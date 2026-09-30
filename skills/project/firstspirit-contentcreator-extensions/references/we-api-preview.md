# `top.WE_API.Preview` — reload, rescan, repaint, reload listeners

Java interface: `de.espirit.firstspirit.webedit.client.api.Preview` [javadoc]
ODFS: JavaScript APIs › ContentCreator › Preview; Content Highlighting › Dynamic content [odfs]

## Members

| Member | Signature | Note |
| --- | --- | --- |
| `reload` | `void reload()` | regenerate and reload the **entire** preview page [odfs] |
| `reload` | `void reload(Element element)` | partial reload — see the rule below [odfs] |
| `reload` | `void reload(String htmlId)` | reload the element with that HTML `id` — **Javadoc only**, not on the ODFS page [javadoc] |
| `addElementReloadListener` | `void addElementReloadListener(ElementReloadListener)` | callback `function(element)` — called with the DOM element ContentCreator just reloaded [odfs] |
| `rescan` | `void rescan(Element element)` | scan `element` and its children for editor identifiers and enable highlighting on them [odfs] |
| `repaint` | `void repaint()` | resize/reposition the currently visible highlight frames [odfs] |
| `getWindow` | `JavaScriptObject getWindow()` | the preview frame's `window`, or `null` [javadoc] |
| `highlight` | `void highlight(String text)` | **@Internal / hidden** — do not use [javadoc] |
| `isParameterized`, `getParameter`, `setParameter`, `getTimeParameter`, `setTimeParameter` | — | **Deprecated since 5.2** → `top.MPP_API`, same names: `references/mpp-api.md` [javadoc] [odfs] |

## The partial-reload rule (`reload(Element)`)

1. If the DOM element carries an **editor identifier** (rendered by `editorId(...)` in the
   template), that element is reloaded.
2. Otherwise the **nearest surrounding** element with an editor identifier is reloaded.
3. If there is none, the **whole** preview reloads. [odfs]

So to get a cheap partial reload, pass the container that carries the `editorId`, or a child
of it. `editorId(...)` syntax: `firstspirit-templating-reference/references/gom/references-links.md`.

```javascript
// After a server-side script changed content, reload only the affected container.
$CMS_IF(#global.is("WEBEDIT"))$
<script type="text/javascript">
  (function () {
    var button = document.getElementById("editPageButton");
    button.onclick = function () {
      top.WE_API.Common.execute("script:editContent", {id: 12345}, function (result) {
        if (result) {
          top.WE_API.Preview.reload(document.getElementById("pageContainer"));
        }
      });
    };
  }());
</script>
$CMS_END_IF$
```
[odfs — "Dynamic content" page]

## Reacting to partial reloads

ContentCreator itself reloads parts of the page (e.g. after drag-and-drop). Any JavaScript
that attached event handlers to the old DOM must re-initialise: [odfs]

```javascript
// The ODFS Preview page's example calls "registerElementReloadListener" — that method does
// not exist. The API is addElementReloadListener (Javadoc + the same page's definition).
top.WE_API.Preview.addElementReloadListener(function (element) {
  if (element.id == "galleryContainer" || element.querySelector("#galleryContainer")) {
    initGallery(document.getElementById("galleryContainer"));
  }
});
```
[odfs] [javadoc] — note the ODFS example calls `element.getElementById(...)`, which does not
exist on an `Element`; use `querySelector` or walk the tree. [verify]

## Dynamic content: `rescan` and `repaint`

- **`rescan(element)`** — after your JavaScript inserted new HTML that contains
  `editorId` markers (a lazily loaded gallery, a section rendered client-side), call
  `rescan` on the container so ContentCreator picks up the new editable elements. [odfs]
- **`repaint()`** — after a layout change while highlight frames are visible (typical in an
  `FS_BUTTON` callback after drag-and-drop), so the frames follow their elements. [odfs]

```javascript
galleryModel.addLoadListener(function () {
  top.WE_API.Preview.rescan(document.getElementById("galleryContainer"));
});
```
[odfs — "Dynamic content" page]
