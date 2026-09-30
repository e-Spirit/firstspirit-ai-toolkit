# `top.WE_API.Dialog` — a ContentCreator-styled dialog with your own DOM content

Java interface: `de.espirit.firstspirit.webedit.client.api.Dialog` (+ `Dialog.Button`) [javadoc]
ODFS: JavaScript APIs › ContentCreator › Dialogs — the page is a stub ("provides functionality to
configure a dialog with custom DOM content") and defers to the Javadoc. [odfs]

You do not construct a dialog; `top.WE_API.Common.createDialog()` returns one, **hidden**. [javadoc]

## Members

| Member | Signature | Note |
| --- | --- | --- |
| `setTitle` | `void setTitle(String title)` | |
| `setContent` | `void setContent(Element element)` | a **DOM element**, not an HTML string — build it with `document.createElement` or pass an existing node |
| `addButton` | `Dialog.Button addButton(String text, JavaScriptObject clickHandler)` | returns the button so you can enable/disable it |
| `setSize` | `void setSize(int width, int height)` | total width/height of the dialog |
| `show` | `void show()` | **"The caller is responsible to hide the dialog"** — nothing closes it for you |
| `hide` | `void hide()` | |
| `Dialog.Button.setEnabled` | `void setEnabled(boolean enabled)` | |

All [javadoc].

## Pattern

```javascript
var dialog = top.WE_API.Common.createDialog();
dialog.setTitle("Choose a variant");

var content = document.createElement("div");
content.innerHTML = "<p>Which variant should be applied?</p>";
dialog.setContent(content);
dialog.setSize(480, 240);

var ok = dialog.addButton("Apply", function () {
  ok.setEnabled(false);
  top.WE_API.Common.execute("script:applyvariant", {variant: "b"}, function (result) {
    dialog.hide();                 // you must hide it yourself
    top.WE_API.Preview.reload();
  });
});
dialog.addButton("Cancel", function () { dialog.hide(); });

dialog.show();
```
Composite of the Javadoc members; not an official example. [javadoc] [verify]

## Notes

- The dialog is drawn by the ContentCreator top window; the `Element` you pass is adopted
  into it. Whether an element created in the **preview iframe's** document is accepted, or
  must be created with `top.document.createElement`, is not documented — test. [verify]
- A dialog opened **from a server-side script** goes through `ClientScriptOperation` in
  asynchronous mode, with the dialog's button handlers calling the operation's callback:
  `references/client-script-operation.md`.
- For a plain question/message from a script, `RequestOperation` is simpler and works in both
  clients: `firstspirit-operations/references/operations-catalogue.md`.
