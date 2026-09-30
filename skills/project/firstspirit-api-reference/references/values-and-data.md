# Value objects: form data, languages, datasets

The objects you read and write *through* store elements: field values
(`FormData`), languages, template sets, and Content-Store records.

---

## `FormData` and `FormField` — reading/writing fields

`FormData` is the container of an element's input-component values; a `FormField`
is one component's value (language-dependent where the component is).

The elements that carry content — `Page`, `Section`, `GCASection`, `Dataset` —
share the **`DataProvider`** interface, which is where `getFormData()` lives. So
the read/write pattern below is identical across all of them: `getFormData()` →
`get(language, "name")` → `get()` / `set(...)`.

```
import de.espirit.firstspirit.forms.FormData;

FormData fd = section.getFormData();                 // language-independent (current store)
FormData fd = section.getFormData(language);         // language-specific

FormField field = fd.get(language, "st_headline");   // by component name
Object    value = field.get();                       // the value
field.set(newValue);                                 // write (element must be locked)
section.setFormData(fd);                             // write the form back before save()
// iterate all fields: for (FormField f : fd) { f.getName(); f.getEditorValue(); }
```

- Component **names** are the input-component identifiers from the form (GOM) — see
  `firstspirit-templating-reference`.
- After `set(...)`, write the form back with `element.setFormData(fd)`, then `save()` the owning element (inside a
  lock). `getFormData()` returns a copy: without `setFormData` the change is not persisted `[observed]` (Page,
  Section, Dataset). Meta data works the same way: `getMetaFormData()`, change it, `setMetaFormData(fd)`, `save()`.
- The concrete value type depends on the input component (String, list,
  reference, etc.) — the datatype table is in `firstspirit-templating-reference`.

## `Language` and the master language

```
import de.espirit.firstspirit.agency.LanguageAgent;

Project project = context.getProject();
Language master = project.getMasterLanguage();
List<Language> langs = project.getLanguages();

// or via the agent:
langAgent = context.requireSpecialist(LanguageAgent.TYPE);
```

Always resolve a `Language` before reading language-dependent values; defaulting
to the master language is the common fallback.

> **Language-dependent release & permissions (recent — verify against the current
> Javadoc).** As of FirstSpirit **2026.4** the **release** state is language-aware
> (an element can be approved/published per project language, not all-or-nothing),
> and **2026.7** adds **language-dependent user permissions** (editing restricted
> per project language). Release-notes-named entry points to confirm before use:
> `LanguageDataProvider#getFormData` (2026.3), `IDProviderChange#isFirstRelease(Language…)`
> / `hasFirstRelease()` (2026.9), and language-specific release info on
> `IDProviderEventAgent` (2025.13). Treat the method names as pointers sourced from
> the release notes, not confirmed signatures — grep the Javadoc before relying on
> them; the concept (release/permissions now carry a `Language` dimension) is the
> durable part.

## `TemplateSet` — output channels

A project defines one or more **template sets** (output channels: HTML, JSON, …).
In a generation script `gc.getTemplateSet()` tells you which is generating (see
`firstspirit-scripting`). `TemplateSet` carries the channel name/uid used to pick
channel-specific behaviour.

## Content Store: `Dataset`, `Entity`, `EntityType`

Structured records from the Content Store (`Content2`, see [stores.md](stores.md)).

```
List<Dataset> rows = content2.getDatasets(language, false);
for (Dataset ds : rows) {
    Entity e = ds.getEntity();                  // the raw record
    FormData fd = ds.getFormData(language);     // dataset field values
    Object v = e.getValue("attributeName");     // raw attribute access
}

EntityType type = content2.getEntityType();     // schema entity type
Dataset one = ... ; // content2.getEntity(keyValue) -> Entity; wrap/lookup as needed
```

- `Dataset` is the store-side, lockable/savable wrapper; `Entity` is the record.
- Modify via lock → `FormData`/entity write → `save` on the dataset.
- The Content-Store script context (`Content2ScriptContext`) exposes `getData()` /
  `getSelectedRow()` directly — see `firstspirit-scripting`.

### From a database-backed selection component to its `TableTemplate`

A `CMS_INPUT_COMBOBOX` / `RADIOBUTTON` / `CHECKBOX` with `<CMS_INCLUDE_OPTIONS type="database">`
yields `Option` values whose `getValue()` is an `Entity`. To turn that into a `Dataset` (for an
`FS_DATASET` or `FS_INDEX` target, or to read form data) you need the **table template the
component is bound to** — and the `Entity` alone cannot give it: several table templates may
sit on the same table, so `entity.getEntityType().getName()` is not unique, and neither is a
`Content2` lookup by entity type. Do not reach for the runtime class
`de.espirit.firstspirit.store.access.contentstore.ContentOptionFactory` (`getTable()`): it is
`@ApiStatus.Internal` `[jar]` and `checkCompliance` rejects it. The public path goes through
the option model (confirmed internally at FirstSpirit, 2026-09-30):

```java
import de.espirit.firstspirit.access.editor.TableTemplateProvider;
import de.espirit.firstspirit.access.editor.value.OptionModel;
import de.espirit.firstspirit.access.store.templatestore.TableTemplate;
import de.espirit.firstspirit.access.store.templatestore.gom.*;

@Nullable
TableTemplate tableTemplateOf(AbstractGomSelect gomSelect, SpecialistsBroker broker, Language language) {
    GomIncludeConfiguration include = gomSelect.getEntries().getIncludeConfiguration();   // null for fixed <ENTRIES>
    if (include instanceof GomIncludeOptions opts && opts.getType() == IncludeType.DATABASE) {
        OptionModel model = opts.getOptionFactory().getOptionModel(broker, language, false); // false = current state
        if (model instanceof TableTemplateProvider provider) {
            return provider.getTableTemplate();          // null if the template no longer exists
        }
    }
    return null;
}
// then: Dataset ds = tableTemplate.getDataset(entity);  DatasetContainer.Factory.create(ds, language)
```

Every hop is Access API on both 5.2.240208 and 5.2.261011 `[jar]`: `AbstractGomSelect.getEntries()`
→ `GomList.getIncludeConfiguration()`; `GomIncludeOptions.getType()` / `.getOptionFactory()`;
`OptionFactory.getOptionModel(SpecialistsBroker, Language, boolean release)`;
`de.espirit.firstspirit.access.editor.TableTemplateProvider.getTableTemplate()` (since 4.0,
`@Nullable`). The database option model implements `TableTemplateProvider`; the fixed-entries
model does not, hence the `instanceof` `[core]`. The `boolean` selects the release state the
model reads from.

## Editor values

`FormField` has **no `getEditorValue()`** (checked on the 5.2.240208 jar — its surface is
`getName()`, `getType()`, `isSet()`, `isEmpty()`, `isDefault()`, `get()`, `set(Object)`,
`setToDefault()`, `validate(T)`). The typed value simply comes from **`get()`**, and
`getType()` tells you which class to expect — e.g. `String` for CMS_INPUT_TEXT,
`TargetReference` for FS_REFERENCE, `DomElement` for CMS_INPUT_DOM. The `…EditorValue` classes
in `de.espirit.firstspirit.access.editor` (`DomEditorValue`, `ReferenceEditorValue`, …) are the
editor-side value types behind those; you meet them through the template/GOM layer, not via
`FormField`. For the mapping from input component to datatype, defer to
`firstspirit-templating-reference`.
