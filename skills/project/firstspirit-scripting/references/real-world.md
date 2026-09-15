# Real-world scripting patterns

End-to-end examples, grounded in the **DTA (Developer Training Advanced)** training
examples and the analysed SE/Core project scripts. Where
[common-patterns.md](common-patterns.md) gives the atomic snippets (lock/save,
iteration, store navigation), this file shows fuller, task-shaped scenarios.

> The DTA examples are written as standalone launcher classes with a
> `start(broker)` method and a `context` field, so they can be run from an IDE.
> **In an actual FirstSpirit script you already have `context`** — drop the class
> wrapper and use `context` (and `broker`/agents from it) directly. See the
> "IDE-to-script workflow" below.
>
> Provenance/verification: distilled from DTA training sources; the same
> expert-verification caveat as the rest of this skill applies. The advanced SE/Core
> patterns (script-as-library, JS bridge, AI Suite) are catalogued in the skill's
> development notes and are not yet distilled into this reference.

---

## IDE-to-script workflow (develop with type-safety, ship as a script)

A practical DTA technique: prototype in a real IDE against the Access API (so you
get completion and type checks), then paste into a BeanShell script.

1. Write a class with a `start(SpecialistsBroker broker)` method; declare the
   values the script context provides (e.g. `context`) as **fields**.
2. Implement and compile against `fs-api.jar` in the IDE.
3. Copy into the script in order: **imports first** (or you get
   `ClassNotFoundException`), then the methods — **not** the fields that the
   context provides automatically.
4. End the script with `start(context);`.

Mind BeanShell's limits while coding (e.g. no real generics — see
[beanshell-language.md](beanshell-language.md)).

## Change a field value on a page (canonical write)

The full lock → read `FormData` → set → write back → save → unlock, language-aware
(DTA Example 2):

```java
//!BeanShell
import de.espirit.firstspirit.access.store.pagestore.Page;
import de.espirit.firstspirit.access.store.LockException;
import de.espirit.firstspirit.access.store.ElementDeletedException;
import de.espirit.firstspirit.agency.StoreElementAgent;
import de.espirit.firstspirit.agency.LanguageAgent;

page = context.requireSpecialist(StoreElementAgent.TYPE)
              .loadStoreElement("mithras_home_1", Page.UID_TYPE, false);
try {
    page.setLock(true);                                   // recursive lock
    lang = context.requireSpecialist(LanguageAgent.TYPE).getMasterLanguage();
    fd = page.getFormData();
    fd.get(lang, "pt_headline").set("New title");
    page.setFormData(fd);
    page.save();
} catch (ElementDeletedException | LockException e) {
    context.logError("Rename failed", e);
} finally {
    try { page.setLock(false); } catch (Exception e) { context.logError("Unlock failed", e); }
}
```

## Create a page and a section (DTA Example 3)

```java
//!BeanShell
import de.espirit.firstspirit.access.store.pagestore.PageFolder;
import de.espirit.firstspirit.access.store.pagestore.Page;
import de.espirit.firstspirit.access.store.templatestore.PageTemplate;
import de.espirit.firstspirit.access.store.templatestore.SectionTemplate;

sea = context.requireSpecialist(StoreElementAgent.TYPE);
folder   = (PageFolder)   sea.loadStoreElement("root",        PageFolder.UID_TYPE,   false);
pageTpl  = sea.loadStoreElement("standard",    PageTemplate.UID_TYPE, false);
secTpl   = (SectionTemplate) sea.loadStoreElement("textpicture", SectionTemplate.UID_TYPE, false);

page = folder.createPage("new_page_uid", pageTpl, true);          // lock folder as needed
page.getBodyByName("Content center").createSection("My section", secTpl);
// then lock/save the page (see the write pattern above)
```

## Show a dynamic form dialog from a script (DTA Example 5)

Build a form at runtime with `FormsAgent` and show it with
`ShowFormDialogOperation` — for wizards or when the inputs depend on runtime state.
(For a static form, prefer the script's own **Form** tab + `context.showForm(...)`,
see [script-contexts.md](script-contexts.md).)

```java
//!BeanShell
import de.espirit.firstspirit.agency.FormsAgent;
import de.espirit.firstspirit.agency.LanguageAgent;
import de.espirit.firstspirit.forms.Form;
import de.espirit.firstspirit.forms.FormData;
import de.espirit.firstspirit.ui.operations.ShowFormDialogOperation;
import java.util.Collections;

lang = context.requireSpecialist(LanguageAgent.TYPE).getMasterLanguage();

formXml =
  "<CMS_MODULE>" +
  "  <CMS_INPUT_TEXT name=\"sc_name\" singleLine=\"no\">" +
  "    <LANGINFOS><LANGINFO lang=\"*\" label=\"Name\"/></LANGINFOS>" +
  "  </CMS_INPUT_TEXT>" +
  "</CMS_MODULE>";

form = context.requireSpecialist(FormsAgent.TYPE).getForm(formXml);
op   = context.requireSpecialist(OperationAgent.TYPE).getOperation(ShowFormDialogOperation.TYPE);

// Optional: prepopulate
prefill = form.createFormData();
prefill.get(lang, "sc_name").set("I have been here before!");
op.setFormData(prefill);
// op.setModified(true);   // enable OK even with no edits

result = op.perform(form, Collections.singletonList(lang));       // null if cancelled
if (result != null) {
    name = result.get(lang, "sc_name").get();
    context.logInfo("Entered: " + name);
}
```

(Pre-5.2 the `perform(...)` could throw `InvalidRulesetException` — catch it.)

## Read a data source — two ways (DTA Example 6)

Iterate the datasets, or run a real query against the schema session.

```java
//!BeanShell
import de.espirit.firstspirit.access.store.contentstore.Content2;
import de.espirit.firstspirit.access.store.contentstore.Dataset;

content2 = context.requireSpecialist(StoreElementAgent.TYPE)
                  .loadStoreElement("contacts", Content2.UID_TYPE, false);
lang = context.requireSpecialist(LanguageAgent.TYPE).getMasterLanguage();

// A) iterate all datasets
for (ds : content2.getDatasets()) {
    last = ds.getFormData().get(lang, "cs_lastname").get();
    context.logInfo(last);
}
```

```java
// B) query the schema session (de.espirit.or persistence API)
import de.espirit.or.Session;
import de.espirit.or.query.Select;
import de.espirit.or.query.Equal;
import de.espirit.or.EntityList;
import de.espirit.or.schema.Entity;

session   = content2.getSchema().getSession(false);
select    = session.createSelect(content2.getEntityType().getName());   // entity type = table
select.setConstraint(new Equal("Lastname", "Doe"));                     // column name (raw, not the FS field uid)
EntityList entities = session.executeQuery(select);

for (entity : entities) {
    ds = content2.getDataset(entity);                                   // Entity -> editable Dataset
    fd = ds.getFormData();
    context.logInfo(fd.get(lang, "cs_lastname").get() + ", " + fd.get(lang, "cs_firstname").get());
}
```

Note the two identifier worlds: `FormData.get(lang, "cs_lastname")` uses the **FS
input-component name**, while the `de.espirit.or` `Select`/`Equal` uses the
**schema column name** (`"Lastname"`). For the alternative project-wide search,
see the `QueryAgent` in `firstspirit-api-reference`.

## Prompt for input, then act (menu / context-menu script)

For a form defined on the script's own **Form** tab, `context.showForm(...)`
returns the entered `FormData` (or `null` on cancel):

```java
//!BeanShell
input = context.showForm(true);                 // true = show language tabs
if (input == null) return;                        // cancelled
name = input.get(context.getProject().getMasterLanguage(), "pt_name").get();
```

## Trigger a schedule from a script (SE/Core `publish_documentation`)

```java
//!BeanShell
import de.espirit.firstspirit.access.ServicesBroker;
import de.espirit.firstspirit.access.AdminService;
import de.espirit.firstspirit.access.schedule.RunState;

storage = context.requireSpecialist(ServicesBroker.TYPE)
                 .getService(AdminService.class)
                 .getScheduleStorage();
entry   = storage.getScheduleEntry(context.getProject(), "Publish");   // schedule name (must exist)
control = entry.execute();
control.awaitTermination();
ok = (control.getState().getState() == RunState.SUCCESS);
```

## More advanced SE/Core patterns

The `docu-design-master-project` scripts show further real patterns — a
**script-as-library** include (`eval(getScriptByName(...).getChannelSource(...))`),
a **BeanShell ⇄ ContentCreator JavaScript** bridge, the **`prm_` render-parameter**
convention for FS_BUTTON / `$CMS_RENDER$` field-fill scripts, and **AI-Suite**
integration. These are catalogued, with open questions for an expert, in the skill's
development notes; they are not yet distilled into this reference.
