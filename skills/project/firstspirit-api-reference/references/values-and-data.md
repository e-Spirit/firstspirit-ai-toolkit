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
// iterate all fields: for (FormField f : fd) { f.getName(); f.getEditorValue(); }
```

- Component **names** are the input-component identifiers from the form (GOM) — see
  `firstspirit-templating-reference`.
- After `set(...)`, `save()` the owning element (inside a lock).
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

## Editor values

Individual component values can also be read as typed **editor values** (e.g.
text, picture, reference) via `FormField.getEditorValue()` — useful when you need
the component's structured value rather than a plain object. For the mapping from
input component to datatype, defer to `firstspirit-templating-reference`.
