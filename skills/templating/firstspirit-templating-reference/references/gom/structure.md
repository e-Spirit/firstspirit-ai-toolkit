# GOM: General Structure

All form component definitions follow this structure.

---

## CMS_MODULE wrapper

All components are wrapped in `<CMS_MODULE>`:

```xml
<CMS_MODULE>
  <!-- Components go here -->
</CMS_MODULE>
```

## Common attributes (available on all/most components)

| Attribute | Values | Default | Description |
|---|---|---|---|
| `name` | string | *required* | Variable identifier |
| `useLanguages` | YES/NO | YES | Multi-language support |
| `allowEmpty` | YES/NO | YES | Allow empty values |
| `hFill` | YES/NO | NO | Full-width display |
| `hidden` | YES/NO | NO | Hide from editor |
| `preset` | default/copy | default | Default value handling |
| `noBreak` | YES/NO | NO | Suppress line break after component |
| `searchRelevancy` | default/high/none | default | Search indexing weight |
| `convertEntities` | NONE/STANDARD/QUOTE | NONE | HTML entity conversion |

## LANGINFOS pattern (used in all components)

```xml
<LANGINFOS>
  <LANGINFO lang="*" label="Fallback Label" description="Tooltip text"/>
  <LANGINFO lang="DE" label="German Label" description="German tooltip"/>
  <LANGINFO lang="EN" label="English Label" description="English tooltip"/>
</LANGINFOS>
```

`lang="*"` is the fallback for all languages without specific definition.

## ENTRY value pattern (COMBOBOX, RADIOBUTTON, CHECKBOX, LIST)

```xml
<ENTRIES>
  <ENTRY value="stored_value">
    <LANGINFOS>
      <LANGINFO lang="*" label="Displayed label"/>
    </LANGINFOS>
  </ENTRY>
</ENTRIES>
```

- `value` is what gets stored (must be unique within ENTRIES)
- `label` is what editors see in the UI
