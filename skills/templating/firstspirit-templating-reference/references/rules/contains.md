# Rules: `<CONTAINS/>`, the content check for multi-value components

`<CONTAINS source="…">` asks whether a multi-value component **holds** a value. It sits in
`<WITH>` (or in a precondition `<IF>`) like any comparison. **[odfs]** *Template development ›
Rules › Comparative expressions › `<CONTAINS/>`*, FirstSpirit 2026.5. Examples are the page's,
not run on a server **[verify]**.

Components it can check (`source`): `CMS_INPUT_CHECKBOX`, `CMS_INPUT_LIST`, `FS_CATALOG`,
`FS_INDEX`.

| What it is compared with | Written as | Note |
| --- | --- | --- |
| A fixed text | `<TEXT>a</TEXT>` inside `<CONTAINS>` | For `FS_CATALOG` the text is the **UID of the section template** of an entry |
| A text field's content | `<PROPERTY name="VALUE" source="st_text"/>` | `CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA` |
| The current choice of another option component | `<PROPERTY name="ENTRY" source="st_radiobutton"/>` | `CMS_INPUT_COMBOBOX`, `CMS_INPUT_RADIOBUTTON`; the compared value is the `ENTRY` value defined on the option component |
| Values of a `CMS_INCLUDE_OPTIONS` source (a table, project languages, template sets) | `<TEXT>` with a dataset **ID**, or the column given in `<KEY/>` of the `CMS_INCLUDE_OPTIONS` | the values come from the include, not from `<ENTRY>` tags |

`FS_INDEX` is compared on the **identifier the DataAccessPlugin supplies for an entry**; use that only
if the identifier structure stays stable over time. [odfs]

```xml
<!-- "a" and "c" must not be selected -->
<RULE>
  <WITH><NOT><OR>
    <CONTAINS source="st_checkbox"><TEXT>a</TEXT></CONTAINS>
    <CONTAINS source="st_checkbox"><TEXT>c</TEXT></CONTAINS>
  </OR></NOT></WITH>
  <DO><VALIDATION scope="SAVE">
    <PROPERTY name="VALID" source="st_checkbox"/>
    <MESSAGE lang="*" text="'a' or 'c' cannot be selected!"/>
  </VALIDATION></DO>
</RULE>
```

```xml
<!-- the selection must differ from the radio button's current entry -->
<WITH><NOT><CONTAINS source="st_checkbox"><PROPERTY name="ENTRY" source="st_radiobutton"/></CONTAINS></NOT></WITH>
```

```xml
<!-- FS_CATALOG "articles": no entry may use the section template with UID technical_article -->
<WITH><NOT><CONTAINS source="articles"><TEXT>technical_article</TEXT></CONTAINS></NOT></WITH>
```

Reading it: `CONTAINS` is `TRUE` when the value is present, so a **forbidden value** is
`NOT(CONTAINS)` in `<WITH>` — a validation fires when `<WITH>` is `FALSE` (`validation.md`).
The page's example 4 checks a `CMS_INPUT_LIST` filled from a table (`CMS_INCLUDE_OPTIONS` with
`<TABLE>` and `<KEY>`) against the `ENTRY` of a radio button, that is: all selected contacts must
belong to the selected location.
