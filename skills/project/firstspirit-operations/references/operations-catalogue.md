# Operations catalogue

Per operation: package · `TYPE` · **exact `perform` signature** · configuration setters ·
return · client availability. Verification key: **[jar]** = `javap` against
`fs-isolated-runtime.jar` FS 5.2.240208 (2026-09-14); **[javadoc]** = FirstSpirit Access API
Javadoc; **[verify]** = not yet
confirmed — read the Javadoc, then the jar, before relying on it.

Obtain every operation via `OperationAgent`
(`de.espirit.firstspirit.agency.OperationAgent`, `getOperation(OperationType)` — returns
`null` when the operation is unavailable in the current client): [javadoc]

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
ops = context.requireSpecialist(OperationAgent.TYPE);
op  = ops.getOperation(<Operation>.TYPE);
```

## Dialogs and messages

### `RequestOperation` — `de.espirit.firstspirit.ui.operations` [jar]

The **only** dialog operation in the API (there is no `QuestionOperation`,
`InputOperation`, `SelectOperation`). A message box with configurable answers.

| Member | Signature | Note |
| --- | --- | --- |
| `TYPE` | `static final OperationType` | |
| `setKind` | `void setKind(RequestOperation.Kind)` | `INFO` (default) · `WARN` · `ERROR` · `QUESTION` |
| `addYes` / `addNo` / `addOk` / `addCancel` | `RequestOperation.Answer add…()` | each returns the `Answer` it adds |
| `addAnswer` | `Answer addAnswer(String label)` | custom label |
| `setTitle` | `void setTitle(String)` | dialog title; each `Kind` has a localised default ("Question", "Warning", …) [jar] |
| `setInitialAnswer` | `void setInitialAnswer(Answer)` | preselected answer; **default = the last answer added** [javadoc/odfs] |
| `getConfigurator` | `<C extends ClientSpecificConfigurator> C getConfigurator(Class<C>)` `throws IllegalArgumentException` | client-specific tweaks; not yet catalogued [verify] |
| **`perform`** | **`Answer perform(String question)`** | `@Nullable` per Javadoc — treat `null` as "closed without an answer" (the ODFS narrative says "always returns"; code to the Javadoc) |

`Kind` defaults (ODFS "Message Boxes"): `INFO` / `WARN` / `ERROR` → an "OK" button; `QUESTION`
→ "Yes" / "No". `Answer` is a marker interface (no methods) — compare the returned value with
the `Answer` you added using **`equals`**, as the ODFS example does.

Client: SiteArchitect and ContentCreator. Two ContentCreator differences: **`WARN` and `INFO`
render identically** (both with the exclamation icon — ODFS "Message Boxes"), and HTML in the
message text renders in SiteArchitect but is **escaped in ContentCreator** [observed —
field test 2026-09-11, reproduce]. All such differences: `references/client-capability-matrix.md`.

Minimal confirm dialog — works from an FS_BUTTON (`ClientScriptContext`), where
`context.showForm()` does not exist:

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.ui.operations.RequestOperation;

req = context.requireSpecialist(OperationAgent.TYPE).getOperation(RequestOperation.TYPE);
req.setTitle("Release page");
req.setKind(RequestOperation.Kind.QUESTION);
yes = req.addYes();
req.addNo();
answer = req.perform("Release the current page now?");
if (answer != null && answer.equals(yes)) {
    // proceed
}
```

### `OpenMergeDialogOperation` — `de.espirit.firstspirit.ui.operations` [javadoc]

Three-column merge view of two texts (original · merged · modified).
`setDialogTitle(String)`, `setOriginalHeader(String)`, `setModifiedHeader(String)`;
**`String perform(String originalText, String modifiedText)`** returns the merged text.
(From the Javadoc's own script example.)

### `ShowFormDialogOperation` — `de.espirit.firstspirit.ui.operations` [jar]

Shows an arbitrary **form definition** (`Form`) as a dialog and returns what the user entered.
The way to ask for structured input from a context that has no `showForm()`.

| Member | Signature | Note |
| --- | --- | --- |
| `TYPE` | `static final OperationType` | |
| `setUiStyle` | `void setUiStyle(Store.Type)` | look of the form; falls back to the context's style [javadoc] |
| `setTitle` | `void setTitle(String)` | |
| `setOkText` | `void setOkText(String)` | default: the common OK text [javadoc] |
| `setMultiLanguage` | `void setMultiLanguage(boolean)` | allow multi-language input |
| `setValidation` | `void setValidation(boolean)` | if `true`, data must be valid to confirm |
| `setDisabled` | `void setDisabled(boolean)` | read-only form |
| `setModified` | `void setModified(boolean)` | mark initially modified — **an unmodified form usually cannot be confirmed, only cancelled** [javadoc] |
| `setFormData` | `void setFormData(FormData)` | initial values; **not** used to store the result; its form definition is ignored [javadoc] |
| `setDefaults` | `void setDefaults(FormData)` | defaults applied where nothing was set; overrides the form's own defaults [javadoc] |
| `setContextElement` | `void setContextElement(IDProvider)` | contextual element, need not relate to the form |
| `setRuleset` | `void setRuleset(String xml)` | XML ruleset definition |
| `setPreselectedLanguage` | `void setPreselectedLanguage(Language)` | |
| **`perform`** | **`FormData perform(Form form, List<Language> languages)`** `throws ShowFormDialogOperation.InvalidRulesetDefinition` | `@Nullable` — **`null` = cancelled** [javadoc] |

The `Form` comes from a template's form definition (`FormsAgent` / a template's `getForm()`) —
`firstspirit-api-reference/references/values-and-data.md`. `InvalidRulesetDefinition` is a
`RuntimeException`. [jar]

## Opening an element's forms

### `OpenElementDataFormOperation` — `de.espirit.firstspirit.ui.operations` [jar]

Opens the **data** form of a page-store data element.

| Member | Signature | Note |
| --- | --- | --- |
| `TYPE` | `static final OperationType` | |
| `setLanguage` | `void setLanguage(Language)` | which language's data to show |
| `setField` | `void setField(String name)` | field to focus; ignored if absent / not focusable |
| `setFormData` | `void setFormData(FormData)` | overriding values; unset fields keep the element's values |
| `setOpenEditable` | `void setOpenEditable(boolean)` | request edit mode; **silently** read-only if refused |
| **`perform`** | **`RemoteFormData perform(pagestore.DataProvider element)`** `throws OperationSetupException` | **asynchronous** — returns at once; calls on the `RemoteFormData` block until the form is open, and may time out if made from the event-dispatch thread |

`DataProvider` is `de.espirit.firstspirit.access.store.pagestore.DataProvider` — pages,
sections and the other page-store data elements. **A `Media` is not a `DataProvider`**:
`perform(medium)` → `bsh.ReflectError: Method perform(…MediaImpl) not found in class
'…WebeditOpenElementDataFormOperation'`.

### `OpenElementMetaFormOperation` — `de.espirit.firstspirit.ui.operations` [jar]

Opens the **meta-data** form of any element that has one.

| Member | Signature | Note |
| --- | --- | --- |
| `TYPE` | `static final OperationType` | |
| `setField` | `void setField(String name)` | |
| `setFormData` | `void setFormData(FormData)` | **no effect** when meta data is inherited |
| `setOpenEditable` | `void setOpenEditable(boolean)` | |
| **`perform`** | **`RemoteFormData perform(store.IDProvider element)`** `throws OperationSetupException` | accepts a `Media`; **no `setLanguage`** |

## Preview

### `PreviewOperation` — `de.espirit.firstspirit.ui.operations` [jar]

"Control the preview in the original client." [javadoc]

| Member | Signature | Note |
| --- | --- | --- |
| `TYPE` | `static final OperationType` | |
| `setElement` | `void setElement(IDProvider element)` `throws OperationSetupException` | make the preview show this element; throws if it cannot be previewed (unsupported type, no preview defined) [javadoc] |
| **`perform`** | **`void perform()`** | **no parameter** — without `setElement`, "the currently shown preview will be refreshed/reloaded" [javadoc] |

Note the shape: configure with a setter, then a parameterless `perform()`. Passing the element
to `perform` is the wrong overload — there is none.

## ContentCreator-only operations — `de.espirit.firstspirit.webedit.server` [jar]

Signatures here; behaviour, traps and examples in `firstspirit-contentcreator-extensions`.
Expect `getOperation(...)` to return `null` in SiteArchitect [verify].

### `ClientScriptOperation`

`Serializable perform(String script, boolean asynchronous)` [jar] — sync vs async, the
callback-must-fire rule, return values:
`firstspirit-contentcreator-extensions/references/client-script-operation.md`.

### `ClientResourceOperation`

| Member | Signature |
| --- | --- |
| `addScriptUrl` | `void addScriptUrl(String url)` |
| `addStylesheetUrl` | `void addStylesheetUrl(String url)` |
| **`perform`** | **`void perform(boolean waitForResources)`** |

Relative URLs resolve against the ContentCreator web-app context path (`/fs5webedit/`) [javadoc].
Use and pattern: `firstspirit-contentcreator-extensions/references/client-resource-operation.md`.

### `SelectOptionOperation`

| Member | Signature | Note |
| --- | --- | --- |
| `addOption` | `void addOption(String label, String value)` | order of calls = display order [verify] |
| **`perform`** | **`String perform()`** | the chosen option's **value**; `@Nullable` — **`null` = cancelled** [javadoc] |

"Lightweight selection of a list of simple options" — the ContentCreator answer to "pick one of
these" when `RequestOperation` answers would be too many buttons.

### `TranslationOperation`

| Member | Signature | Note |
| --- | --- | --- |
| `setElement` | `void setElement(pagestore.DataProvider element)` | **`DataProvider`** again — pages/sections, not media |
| `setSourceLanguage` / `setTargetLanguage` | `void set…Language(Language)` | |
| `setTranslationPlugin` | `void setTranslationPlugin(String pluginType, boolean automatic)` | plugin for the initial translation; `automatic` = run it without asking [javadoc] |
| **`perform`** | **`boolean perform()`** | `true` if the translation was saved [javadoc] |

### `NewSectionOperation`, `CropDialogOperation`, `ComparisonDialogOperation` [jar]

Fluent-style, on the jar, not yet described beyond the signature:

| Operation | Configure | `perform` |
| --- | --- | --- |
| `NewSectionOperation` | `body(Body)`, `section(Section)`, `template(SectionTemplate)`, `reloadAfterCreation(String)`, `dropData(CommodityContainer)`, `filterAvailableTemplates(Filter<SectionTemplate>)`, `delegateContext(Map)`, `preselectedLanguage(Language)` — each returns the operation | `Section<?> perform()` |
| `CropDialogOperation` | `setMedia(Media)`, `setLanguage(Language)`, `setResolutions(List<Resolution>)` | `void perform()` |
| `ComparisonDialogOperation` | `baseRevision(Revision)`, `compareToRevision(Revision)`, `languages(List<Language>)` — each returns the operation | `void perform(pagestore.DataProvider)` |

`ShowReportOperation` (`ui.operations`, "open and refresh a plugin based report") exists in
the Javadoc; not yet read [verify].

Client availability for all of the above: `references/client-capability-matrix.md`.

## Known documentation traps

| Source | Says | Reality |
| --- | --- | --- |
| ODFS "Working With Store Elements" | `context.requireSpecialist(OpenElementDataFormDialogOperation.TYPE)` | the class does not exist → `OpenElementDataFormOperation`; and operations are obtained via `OperationAgent.getOperation(…TYPE)`, not as specialists [jar] |
| Operation names | "open element form" sounds like one operation | two, with different `perform` parameter types (`DataProvider` vs `IDProvider`) and different setters — see the trap table above [jar] |
| `PreviewOperation` by analogy with the form operations | `perform(element)` | `perform()` takes nothing; the element goes into `setElement(IDProvider)` first [jar] |
| `ShowFormDialogOperation.setFormData` | "the result lands in the FormData I passed" | it does not — initial values only; the result is `perform`'s return value [javadoc] |
