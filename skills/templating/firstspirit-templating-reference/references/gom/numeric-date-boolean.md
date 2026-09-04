# GOM: Numeric, Date, and Boolean Components

---

## CMS_INPUT_NUMBER -- Numeric input

```xml
<CMS_INPUT_NUMBER name="st_price" useLanguages="no" type="DOUBLE" min="0" max="9999.99">
  <LANGINFOS>
    <LANGINFO lang="*" label="Price" description="Enter price"/>
  </LANGINFOS>
</CMS_INPUT_NUMBER>
```

Key attributes: `type` (LONG/DOUBLE, default LONG), `min`, `max` (decimal separator must be point), `editable` (YES/NO).

## CMS_INPUT_DATE -- Date/time picker

```xml
<CMS_INPUT_DATE name="st_date" useLanguages="no" mode="date" allowInput="no">
  <LANGINFOS>
    <LANGINFO lang="*" label="Date" description="Select a date"/>
  </LANGINFOS>
</CMS_INPUT_DATE>
```

Key attributes: `mode` (date/time/datetime, default datetime), `allowInput` (YES/NO, manual entry), `preset` (default/copy/created/modified).

Timezone notes:
- `mode="datetime"` saves in UTC regardless of client timezone
- `mode="date"` and `mode="time"` display same in all timezones

## CMS_INPUT_TOGGLE -- Boolean toggle

```xml
<CMS_INPUT_TOGGLE name="st_active" useLanguages="no" type="CHECKBOX">
  <LANGINFOS>
    <LANGINFO lang="*" label="Active" description="Activate this element"/>
  </LANGINFOS>
</CMS_INPUT_TOGGLE>
```

Key attributes: `type` (CHECKBOX/RADIO, default CHECKBOX), `hideLabel` (YES/NO, with RADIO), `singleLine` (YES/NO, default YES).

Returns: `true` (activated), `false` (deactivated), `null` (no selection yet).

### With type="RADIO" and custom labels

```xml
<CMS_INPUT_TOGGLE name="st_active" useLanguages="no" type="RADIO">
  <LANGINFOS>
    <LANGINFO lang="*" label="Status"/>
  </LANGINFOS>
  <ON>
    <LANGINFO lang="*" label="Active"/>
    <LANGINFO lang="DE" label="Aktiv"/>
  </ON>
  <OFF>
    <LANGINFO lang="*" label="Inactive"/>
    <LANGINFO lang="DE" label="Inaktiv"/>
  </OFF>
</CMS_INPUT_TOGGLE>
```
