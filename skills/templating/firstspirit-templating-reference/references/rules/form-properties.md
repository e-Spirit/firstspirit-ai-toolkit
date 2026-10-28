# Rules: form properties (`<PROPERTY name="…"/>`) that are not about one field's state

Rule properties that report the **context a form was opened in** (read them with
`source="#global"`), plus the ones that steer **selection** and **list entries**. The common
state properties (`VISIBLE`, `EDITABLE`, `VALID`, `VALUE`, `EMPTY`, `ENTRY`, `NEW`, `STORETYPE`,
`ELEMENTTYPE`) have patterns in `visibility.md`, `editability.md`, `validation.md`,
`value-manipulation.md` and `real-world.md`.
Source for everything here: **[odfs]** *Template development › Rules › Form properties*
(`property-body`, `-containertype`, `-copy`, `-deselect`, `-edit`, `-focus`, `-gid`, `-id`,
`-preset`, `-section`, `-select`, `-translated`, `-uid`), FirstSpirit 2026.5. The examples are the
page's, not run on a server **[verify]**.

How a rule reads: the property in `<WITH>` is read; a property in `<DO>` receives the value of
`<WITH>` (`<WITH><FALSE/></WITH>` + `<DO><PROPERTY name="EDIT" …/>` switches `EDIT` off).

## Overview

| Property | `source` | Type | Reads / does | Where it works |
| --- | --- | --- | --- | --- |
| `BODY` | `#global` | text | name of the content area the form was opened in | **section templates only**; elsewhere the error "No such fact" |
| `CONTAINERTYPE` | `#global` | text | type of the object that contains the component | any form |
| `PRESET` | `#global` | boolean | `TRUE` while the editor is in the "Edit form defaults" dialog | any template with form defaults |
| `TRANSLATED` | `#global` | boolean | the page option "Page is completely translated to this language" | page level, page store; **not in link templates** |
| `GID` | `#global` | text | global ID of the current element | any form |
| `ID` | `#global` | number | ID of the current element | any form |
| `UID` | `#global` | text | reference name of the current element | any form |
| `FOCUS` | the component | boolean | the editor has focus in the component | the component named by `source` |
| `SECTION` | an `FS_REFERENCE` | — | whether a section is selected | `FS_REFERENCE` that can select sections |
| `SELECT` | option component | write | selects entries from another component's value | `CMS_INPUT_CHECKBOX`, `COMBOBOX`, `LIST`, `RADIOBUTTON` |
| `DESELECT` | option component | write | removes entries | `CMS_INPUT_CHECKBOX`, `CMS_INPUT_LIST` |
| `COPY` | `FS_CATALOG` | write | switches "Duplicate" on or off | `FS_CATALOG` |
| `EDIT` | `FS_CATALOG` / `FS_INDEX` | write | switches "Edit entry" on or off | `FS_CATALOG`, `FS_INDEX` |

Related properties, not repeated here: `INCLUDED` (a section is part of the output, the section-level
sibling of `TRANSLATED`), `STORETYPE`, `ELEMENTTYPE`, `NEW`, `EMPTY`.

## Context properties (`source="#global"`)

### BODY: which content area

`<PROPERTY source="#global" name="BODY"/>` returns the content-area name; compare with
`<EQUAL>` and `<TEXT>`. Use it to show a field of a section template only in certain content
areas. The value does not change while the form is open, so a **precondition** (`<IF>`) is the
right place. The page's pattern: for each area, `<IF>` the area is `content_a`, `<WITH><FALSE/></WITH>`,
`<DO>` the `VISIBLE` property of every field that does **not** belong there:

```xml
<RULE>
  <IF><EQUAL><PROPERTY source="#global" name="body"/><TEXT>content_a</TEXT></EQUAL></IF>
  <WITH><FALSE/></WITH>
  <DO><PROPERTY source="Text_B" name="VISIBLE"/><PROPERTY source="Text_C" name="VISIBLE"/></DO>
</RULE>
```

The page writes the name as `BODY` in the text and `body` in its code. Which content areas a section template is allowed in is set on the page template.

### CONTAINERTYPE: what the field sits in

Returns the type name in capitals; compare it with `<TEXT>`:

| Value | The component is inside |
| --- | --- |
| `FS_CATALOG`, `CMS_INPUT_DOM`, `CMS_INPUT_DOMTABLE`, `CMS_INPUT_LINK`, `CMS_INPUT_IMAGEMAP` | a component of that type (for example the form of a catalog card) |
| `BODY` | a section under a content area |
| `NONE` | no container: opened in a dataset, on a page, or through the API |

To tell a page from other elements use `ELEMENTTYPE` instead (`real-world.md`).

```xml
<RULE>
  <WITH><EQUAL><PROPERTY name="CONTAINERTYPE" source="#global"/><TEXT>FS_CATALOG</TEXT></EQUAL></WITH>
  <DO><PROPERTY name="VISIBLE" source="st_text"/></DO>
</RULE>
```

### PRESET: the "Edit form defaults" dialog

Template defaults are entered in the dialog "Edit form defaults" (icon on the template's *Form*
tab). `PRESET` is `TRUE` there and `FALSE` in normal editing. Show a field **only** in that dialog:
`<IF><NOT><PROPERTY name="PRESET" source="#global"/></NOT></IF>`, `<WITH><FALSE/></WITH>`, `<DO>`
`VISIBLE` of the field. [odfs] (A field a template developer needs only for defaults, for
example an "instruction" label, belongs here.)

### TRANSLATED: "completely translated"

The page-level checkbox "Page is completely translated to this language" (page store only) says whether
the content of that language counts for generation. `TRANSLATED` reads it. Two cautions from the page:

- It interacts with the project's **language substitution** setting: content of an untranslated
  language can still be generated (substitution "Ignore" or "Use master language").
- A rule that depends on it **must also test the store**, because the option exists only in the
  page store: `<AND><EQUAL><PROPERTY source="#global" name="STORETYPE"/><TEXT>pagestore</TEXT></EQUAL><PROPERTY source="#global" name="TRANSLATED"/></AND>`.
  Language tabs inside a language-independent subform (`show-language-tabs` on section lists) are a
  configuration error that, together with a rule, can make the form unsaveable. [odfs]

### GID, ID, UID: identify the element

`<PROPERTY source="#global" name="GID|ID|UID"/>` in `<WITH>`; typically copied into a read-only
text field with `when="ONLOCK"` (runs when the editor switches to edit mode or creates the element, before editing: `validation.md` → *Execution time*):

```xml
<RULE when="ONLOCK">
  <WITH><PROPERTY name="UID" source="#global"/></WITH>
  <DO><PROPERTY name="VALUE" source="UID"/></DO>   <!-- a text component named UID -->
</RULE>
```

Which element answers: for a section or a catalog card the property returns the data of the
**page** (even from a paragraph inside an `FS_CATALOG`); in **metadata** it returns the element the
metadata belongs to; for a **section** `UID` returns the display name, as sections have no
reference name. [odfs]

## FOCUS

`<PROPERTY source="st_text" name="FOCUS"/>` is `TRUE` while the editor has the cursor in the
component or has opened its combo box. The page's example shows a hint text while the field is
focused: negate it in `<WITH>` so the validation fires (a validation fires when `<WITH>` is
`FALSE`): `<WITH><NOT><PROPERTY source="st_text" name="FOCUS"/></NOT></WITH>` + `<VALIDATION>`.
The page also points to using `FOCUS` to run an expensive action only while a dependent field
has focus. [odfs]

## SECTION: a section picked in an FS_REFERENCE

An `FS_REFERENCE` that points to a page, page reference or global page with at least one section
offers a section list (the basis of anchor links). `<PROPERTY name="SECTION" source="st_link"/>` is
tested with `<NULL/>` / `<NOT_NULL/>`. If no section can be selected (`sections="no"`, a page reference
without sections, a type without sections) a warning is logged on the Java console:
`The element '…' does not support a property named 'SECTION'`. [odfs]

> **Polarity not settled.** The documented text and its examples read `NULL` and `NOT_NULL` in opposite ways: the examples use `NOT_NULL` for "You can select a section additionally" (shown when none is selected) and `NULL` for "Section selected". Test both on a server before shipping a rule on `SECTION`. **[verify]**

## Writing properties

### SELECT and DESELECT

Fill or empty an option component from the value of another component. Source in `<WITH>`:
`<PROPERTY name="VALUE" source="gadget1"/>` (a `CMS_INPUT_COMBOBOX`, `NUMBER`, `RADIOBUTTON`, `TEXT`
or `TEXTAREA`); target in `<DO>`: `<PROPERTY name="SELECT" source="gadget2"/>` or `name="DESELECT"`.
Only values defined in the target's `<ENTRIES>` (or its `CMS_INCLUDE_OPTIONS`) can be set; any
other value is ignored and the Java console shows `Invalid value 'e' for property 'SELECT'`
(`'DESELECT'` likewise). [odfs]

| Target | Selection count | Ways to remove a selection |
| --- | --- | --- |
| `CMS_INPUT_CHECKBOX` | 0, 1 or n | the GUI, or `DESELECT` |
| `CMS_INPUT_COMBOBOX` | 0 or 1 | the GUI, or `EMPTY` |
| `CMS_INPUT_LIST` | 0, 1 or n | the GUI, or `DESELECT` |
| `CMS_INPUT_RADIOBUTTON` | exactly 1 | cannot be removed |

`DESELECT` exists only for checkbox and list. The page's example: the editor types `a` in
`st_text`; with `DESELECT` on a checkbox that had all four entries selected, `a` is deselected.

### COPY and EDIT on catalogs and indexes

`FS_CATALOG` offers "Duplicate" (context menu) by default, `FS_CATALOG` and `FS_INDEX` offer "Edit
entry". Unlike most components, these are switched with rules, not in the GOM definition. [odfs]

- **`COPY`** controls "Duplicate". **Without an explicit `COPY` rule, `NEW` decides.** To allow
  duplicating but forbid adding new entries, enable `COPY` and disable `NEW`:

  ```xml
  <RULE><WITH><TRUE/></WITH>
    <DO><PROPERTY name="COPY" source="catalog"/><NOT><PROPERTY name="NEW" source="catalog"/></NOT></DO>
  </RULE>
  ```

  The EasyEdit icons in the ContentCreator preview cannot be influenced by rules; to remove
  "Duplicate" there use the Tailored UI
  (`firstspirit-contentcreator-extensions/references/customising-contentcreator.md`).
- **`EDIT`**: `<RULE when="ONLOCK"><WITH><FALSE/></WITH><DO><PROPERTY name="EDIT" source="fs_index"/></DO></RULE>`
  makes the "edit entry" icon inactive.
