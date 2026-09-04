# GOM: Selection Components

---

## CMS_INPUT_COMBOBOX -- Dropdown (single choice)

```xml
<CMS_INPUT_COMBOBOX name="st_category" useLanguages="no" hFill="yes">
  <ENTRIES>
    <ENTRY value="news">
      <LANGINFOS>
        <LANGINFO lang="*" label="News"/>
      </LANGINFOS>
    </ENTRY>
    <ENTRY value="blog">
      <LANGINFOS>
        <LANGINFO lang="*" label="Blog"/>
      </LANGINFOS>
    </ENTRY>
  </ENTRIES>
  <LANGINFOS>
    <LANGINFO lang="*" label="Category" description="Select a category"/>
  </LANGINFOS>
</CMS_INPUT_COMBOBOX>
```

Key attributes: `editable` (YES/NO, allow custom values), `sortOrder` (KEEP_ORDER/ASCENDING/DESCENDING).

### With database entries

```xml
<CMS_INPUT_COMBOBOX name="st_category" useLanguages="no">
  <CMS_INCLUDE_OPTIONS type="database">
    <LABELS>
      <LABEL lang="*">#item.name</LABEL>
    </LABELS>
    <TABLE>categories</TABLE>
  </CMS_INCLUDE_OPTIONS>
  <LANGINFOS>
    <LANGINFO lang="*" label="Category"/>
  </LANGINFOS>
</CMS_INPUT_COMBOBOX>
```

## CMS_INPUT_RADIOBUTTON -- Radio buttons (single choice)

```xml
<CMS_INPUT_RADIOBUTTON name="st_layout" useLanguages="no" hFill="yes">
  <ENTRIES>
    <ENTRY value="left">
      <LANGINFOS>
        <LANGINFO lang="*" label="Left aligned"/>
      </LANGINFOS>
    </ENTRY>
    <ENTRY value="right">
      <LANGINFOS>
        <LANGINFO lang="*" label="Right aligned"/>
      </LANGINFOS>
    </ENTRY>
  </ENTRIES>
  <LANGINFOS>
    <LANGINFO lang="*" label="Layout" description="Choose layout"/>
  </LANGINFOS>
</CMS_INPUT_RADIOBUTTON>
```

Key attributes: `gridWidth` (options per row, default 2), `gridHeight` (options per column, overrides gridWidth), `sortOrder`.

## CMS_INPUT_CHECKBOX -- Checkboxes (multiple choice)

```xml
<CMS_INPUT_CHECKBOX name="st_tags" useLanguages="no" gridWidth="3">
  <ENTRIES>
    <ENTRY value="featured">
      <LANGINFOS>
        <LANGINFO lang="*" label="Featured"/>
      </LANGINFOS>
    </ENTRY>
    <ENTRY value="promoted">
      <LANGINFOS>
        <LANGINFO lang="*" label="Promoted"/>
      </LANGINFOS>
    </ENTRY>
  </ENTRIES>
  <LANGINFOS>
    <LANGINFO lang="*" label="Tags"/>
  </LANGINFOS>
</CMS_INPUT_CHECKBOX>
```

Returns: `Set<Option>` for template iteration.

## CMS_INPUT_LIST -- List (multiple choice)

```xml
<CMS_INPUT_LIST name="st_colors" useLanguages="no">
  <ENTRIES>
    <ENTRY value="red">
      <LANGINFOS>
        <LANGINFO lang="*" label="Red"/>
      </LANGINFOS>
    </ENTRY>
    <ENTRY value="blue">
      <LANGINFOS>
        <LANGINFO lang="*" label="Blue"/>
      </LANGINFOS>
    </ENTRY>
  </ENTRIES>
  <LANGINFOS>
    <LANGINFO lang="*" label="Colors"/>
  </LANGINFOS>
</CMS_INPUT_LIST>
```

Note: Display limited to 100 entries (browser limitation). `sortOrder` only affects display, NOT output order.

## CMS_INCLUDE_OPTIONS -- Dynamic Dropdown Sources

### type="language" -- Project languages

```xml
<CMS_INPUT_COMBOBOX name="st_language" hFill="yes" useLanguages="no">
  <CMS_INCLUDE_OPTIONS type="language">
    <LABELS>
      <LABEL lang="*">#item.abbreviation</LABEL>
    </LABELS>
  </CMS_INCLUDE_OPTIONS>
  <LANGINFOS>
    <LANGINFO lang="*" label="Source Language"/>
  </LANGINFOS>
</CMS_INPUT_COMBOBOX>
```

### type="database" -- Database table rows

```xml
<CMS_INPUT_COMBOBOX name="st_newsTag" hFill="yes" useLanguages="no">
  <CMS_INCLUDE_OPTIONS type="database">
    <LABELS>
      <LABEL lang="*">#item.name</LABEL>
    </LABELS>
    <TABLE>smartliving.tag</TABLE>
  </CMS_INCLUDE_OPTIONS>
  <LANGINFOS>
    <LANGINFO lang="*" label="News Tag"/>
  </LANGINFOS>
</CMS_INPUT_COMBOBOX>
```

Key points:
- `<TABLE>schema.tablename</TABLE>` uses format `schemaName.tableTemplateName`
- `<LABEL lang="*">#item.columnName</LABEL>` accesses any column of the table template
- type `"language"` populates from project languages, `"database"` from a content source table
- type `"templateset"` populates from configured template sets
- type `"public"` supports custom GOM option providers (plugin classes)
