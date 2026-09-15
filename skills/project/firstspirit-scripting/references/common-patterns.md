# Common scripting patterns

Working, copy-paste BeanShell/Access-API patterns. Adapt names to your project.
All assume the standard `//!BeanShell` header and imports (see
[conventions.md](conventions.md)).

---

## Lock / modify / save / unlock

The **only** safe way to change a store element. Always release the lock in a
`finally`; wrap the whole thing so a failed *acquire* is handled too.

```
//!BeanShell
import de.espirit.firstspirit.access.store.LockException;

try {
    elm.setLock(true, false);            // acquire exclusive lock
    try {
        // ... modify elm ...
        elm.save("changed by script", false);
    } catch (Exception e) {
        context.logError("Modify failed", e);
    } finally {
        elm.setLock(false, false);       // always release
    }
} catch (LockException e) {
    context.logError("Element already locked", e);
}
```

Notes: store elements are **local copies** — nothing persists until `save(...)`.
**Don't pre-check the lock** (it's a server-side state that can change under you) —
just attempt `setLock(true, …)` and handle `LockException`. **Pages are typically
locked and saved recursively** (`setLock(true, true)` / `save(comment, true)`),
most other elements non-recursively (`false`) — the second boolean is the
recursive flag.

## Safe iteration over children

Child lists (especially recursive ones) can be huge — iterate, never materialise a
full list/array. Filter by type with `getChildren(Class, recursive)`:

```
//!BeanShell
import de.espirit.firstspirit.access.store.pagestore.Page;

for (elem : folder.getChildren(Page.class, true).iterator()) {
    context.logDebug(elem.getUid());
}
```

## Navigate the store via `SpecialistsBroker`

Client contexts *are* a `SpecialistsBroker`, so call `requireSpecialist` on
`context` directly:

```
//!BeanShell
import de.espirit.firstspirit.agency.StoreAgent;
import de.espirit.firstspirit.access.store.Store;

storeAgent = context.requireSpecialist(StoreAgent.TYPE);
pageStore  = storeAgent.getStore(Store.Type.PAGESTORE);
```

## Navigate the store via `UserService` (also works server-side)

```
//!BeanShell
import de.espirit.firstspirit.access.store.Store;

store = context.getUserService().getStore(Store.Type.PAGESTORE, false);   // false = current, true = release
```

## Look up an element by UID

```
//!BeanShell
import de.espirit.firstspirit.access.store.IDProvider;
import de.espirit.firstspirit.access.store.pagestore.Page;

element = pageStore.getStoreElement("my-uid", IDProvider.UidType.PAGESTORE);
if (element instanceof Page) {
    page = (Page) element;
    // ...
}
```

## Read a form field (language-aware)

```
//!BeanShell
project = context.getProject();
lang    = project.getMasterLanguage();

formData = context.getElement().getFormData();
value    = formData.get(lang, "st_headline").get();     // FormField -> value
```

## Prompt the editor with a dialog (menu / context-menu script)

Define inputs on the script's **Form** tab, then read what the editor enters:

```
//!BeanShell
import de.espirit.firstspirit.forms.FormData;

FormData input = context.showForm(true);     // true = show language tabs
if (input == null) {
    return;                                   // user cancelled
}
name = input.get(context.getProject().getMasterLanguage(), "pt_name").get();
```

`showForm` is a **`GuiScriptContext`** method — menu and context-menu scripts only. It does
**not** exist in an FS_BUTTON script (`ClientScriptContext`), a workflow script, or on the
server. For a dialog that works from **any** client context, use `RequestOperation` below.

## Ask a question or show a message from any client context (`RequestOperation`)

`RequestOperation` is the one dialog operation in the API (there is no `QuestionOperation`,
`InputOperation` or `SelectOperation`). Obtain it through **`OperationAgent`** — not via
`requireSpecialist(<Operation>.TYPE)`; operations are not specialists — and it works wherever
an `OperationAgent` is available, FS_BUTTON scripts included:

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.ui.operations.RequestOperation;

ops = context.requireSpecialist(OperationAgent.TYPE);
req = ops.getOperation(RequestOperation.TYPE);          // null if there is no UI in this context
req.setKind(RequestOperation.Kind.QUESTION);            // INFO (default) · WARN · ERROR · QUESTION
yes = req.addYes();                                     // also addNo() · addOk() · addCancel() · addAnswer("label")
req.addNo();
answer = req.perform("Release the current page now?");  // the chosen Answer, or null
if (answer != null && answer.equals(yes)) {
    // ...
}
```

### Opening an element's form — check the `perform` parameter type first

"Open the element's form" is **two** operations with different `perform` parameter types.
BeanShell resolves the overload at run time, so the wrong one is not a compile error but a
`bsh.ReflectError: Method perform(…MediaImpl) not found` when the editor clicks. Verified on
the API jar (FS 5.2.240208):

| Operation (`de.espirit.firstspirit.ui.operations`) | `perform` takes | Accepts a `Media`? | Has `setLanguage`? |
| --- | --- | --- | --- |
| `OpenElementDataFormOperation` | `pagestore.DataProvider` (pages, sections, datasets) | **no** | yes |
| `OpenElementMetaFormOperation` | `store.IDProvider` (any element with meta data) | **yes** | **no** |

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.ui.operations.OpenElementMetaFormOperation;

ops = context.requireSpecialist(OperationAgent.TYPE);
open = ops.getOperation(OpenElementMetaFormOperation.TYPE);   // a medium has no data form
open.perform(medium);                                          // IDProvider — no setLanguage on this one
```

Full signatures and setters for these and the other client operations (`PreviewOperation`,
`ShowFormDialogOperation`, the ContentCreator-only `ClientScriptOperation`,
`SelectOptionOperation`, …): the FirstSpirit Access API Javadoc for `de.espirit.firstspirit.ui.operations` and `de.espirit.firstspirit.webedit.server`.

## Drive a workflow (workflow script)

```
//!BeanShell
// context is a WorkflowScriptContext here
data = context.getFormData();                 // the task's form
context.getSession().put("approvedBy", context.getUser().getLoginName());  // persists across steps
context.doTransition("release");              // by reference name

// on failure:
// context.gotoErrorState("could not release", someThrowable);
```

> **Language-dependent release & permissions (recent — verify).** As of FirstSpirit
> **2026.4** release is language-aware — an element can be approved/published for
> **specific project languages**, not only all-or-nothing — and **2026.7** adds
> **language-dependent user permissions** (editing gated per project language). So a
> release transition or a permission check may now carry a `Language` dimension;
> don't assume a single global release/permission state. The API entry points
> (e.g. `LanguageDataProvider#getFormData`, language-specific release info on
> `IDProviderEventAgent`) are release-notes-sourced — confirm against the Javadoc
> (see `firstspirit-api-reference`) before scripting against them.

## Call a script from a template (`$CMS_RENDER$`)

Template side (page/section/link template or format template):

```
$CMS_RENDER(script:"ScriptOutput", variable:"VALUE")$
```

Script side — generation context is `gc`, output goes through `result`:

```
//!BeanShell
result.setValue(gc.getVariableValue("variable"));
```

Branch on generation mode inside the script:

```
//!BeanShell
if (gc.isPreview()) {
    result.setValue("preview only");
} else {
    result.setValue(gc.toString(someObject));   // same as $CMS_VALUE(someObject)$
}
```

## Persist state between scheduled runs (schedule script)

`setProperty` lasts one execution; `setVariable` survives beyond it:

```
//!BeanShell
last = context.getVariable("lastRun");        // read previous run's value (or null)
// ... do work ...
context.setVariable("lastRun", new java.util.Date());   // value must be Serializable
```

## Send an email (workflow script)

```
//!BeanShell
context.sendEMail("editor@example.com,lead@example.com", "Page released", "The page is live.");
```

## Alternative to a script: an `Executable` class

FS_BUTTON and template calls can reference a **class** instead of a script. It
must implement `de.espirit.firstspirit.access.script.Executable`; the script
variables arrive in the `Map`:

```java
public class MyButtonAction implements Executable {
    public Object execute(Map context) {
        BaseContext ctx = (BaseContext) context.get("context");
        // context.get("values"), context.get("isDrop"), ...
        return null;
    }
    public Object execute(Map context, Writer out, Writer err) {
        return execute(context);
    }
}
```

Reference it with `onClick="class:FQN_OR_HOTSPOT"`. For long-term behaviour this
is preferable to a script (see the script-vs-module note in
[conventions.md](conventions.md)).

## Do NOT reach for these — they don't exist

These are the API calls that AI-generated FirstSpirit scripts most often invent.
Each has been verified against the `fs-api/` Javadoc (and the FS 5.2.261001 API
dump); the right-hand column is the real approach.

| Invented / wrong | Reality |
| --- | --- |
| `context.requireSpecialist(TransactionAgent.TYPE)`, `beginTransaction()`/`commit`/`rollback` | **No transaction API and no `TransactionAgent`.** Save per element with `save()`; coordinate with locks. |
| `context.requireSpecialist(LockService.TYPE)` | **No `LockService`.** Locking is element-level: `elm.setLock(true, false)` / `setLock(false)`. |
| `context.requireSpecialist(ReleaseAgent.TYPE).releaseStoreElement(...)` | **No `ReleaseAgent`.** Release runs through the workflow model, not an agent. |
| `connection.getService(GenerationService.class)` | **No `GenerationService`.** Generation is a scheduled task / `GenerationAgent` in `de.espirit.firstspirit.scheduling.agency`, not a directly-callable script service. |
| `QuestionOperation` / `InputOperation` / `SelectOperation` | Only **`RequestOperation`** exists for dialogs — see [the RequestOperation pattern](#ask-a-question-or-show-a-message-from-any-client-context-requestoperation), which works from any client context (the `showForm()` pattern is `GuiScriptContext`-only). Custom input UIs need a plugin. |
| `store.getStoreRoot()` | The store **is** the root — iterate it directly (`store.getChildren(...)`). |
| `folder.getChildByName("x")` | No such method — look up by UID (`getStoreElement(uid, UidType)`) or iterate `getChildren`. |
| `context.isEnv(Env.X)` | The method is **`context.is(Env.X)`** (`BaseContext.is`); `isEnv` does not exist. See [script-contexts.md](script-contexts.md). |
| `import de.espirit.firstspirit.access.Group` | Wrong package — `Group` lives in **`de.espirit.firstspirit.access.project`**. |
| `project.getClassLoader()` / `project.getVersion()` | Neither method exists on `Project`. |
| `context.requireSpecialist(OpenElementDataFormDialogOperation.TYPE)` — as written on the ODFS "Working With Store Elements" page | **Wrong class and wrong acquisition.** The class is `OpenElementDataFormOperation` (no "Dialog"), and operations are not specialists — get them via `OperationAgent`: `context.requireSpecialist(OperationAgent.TYPE).getOperation(OpenElementDataFormOperation.TYPE)`. Verified on the API jar. And check the `perform` parameter type — see [Opening an element's form](#opening-an-elements-form--check-the-perform-parameter-type-first). |
| `picture.getThumbnail()` | Does not exist — **`getPreviewImage()`** (`getPreview()` is deprecated since 5.0). And `Picture` has no `getResolution()`: `getPictureResolution(Resolution)` → `PictureResolution`. |

> Note: a clean `bsh-validator --check-api` run does **not** guarantee these are
> caught — its method check verifies the name only (not arity or argument types)
> and skips untyped variables. The **import** check is reliable; wrong-package and
> non-existent types (e.g. `TransactionAgent`, the `access.Group` import) are its
> strongest catches.
