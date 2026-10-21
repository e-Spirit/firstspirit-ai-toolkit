# GOM: List/Catalog Components

---

## FS_CATALOG -- Inline section/link list

### With section templates

```xml
<FS_CATALOG name="st_items" useLanguages="yes" height="4" viewMode="DETAILS">
  <LANGINFOS>
    <LANGINFO lang="*" label="Items" description="Add items"/>
  </LANGINFOS>
  <TEMPLATES type="section">
    <TEMPLATE uid="item_text"/>
    <TEMPLATE uid="item_image"/>
  </TEMPLATES>
</FS_CATALOG>
```

### With link templates

```xml
<FS_CATALOG name="st_links" useLanguages="yes" height="4">
  <LANGINFOS>
    <LANGINFO lang="*" label="Links" description="Add links"/>
  </LANGINFOS>
  <TEMPLATES type="link">
    <TEMPLATE uid="link_internal"/>
    <TEMPLATE uid="link_external"/>
  </TEMPLATES>
</FS_CATALOG>
```

Key attributes: `height` (visible rows, default 4), `viewMode` (DETAILS/HEADERS/SYMBOLS), `forbidPolyglotDataHierarchy` (YES/NO).

Child tags:
- `<TEMPLATES type="section">` -- Available section templates (mandatory `type` attribute)
- `<TEMPLATES type="link">` -- Available link templates
- Inside: `<TEMPLATE uid="reference_name"/>` (mandatory `uid` attribute, NOT `name`)
- If no `<TEMPLATE>` tags inside `<TEMPLATES>`, all templates of that type are selectable

## FS_INDEX -- External data index (typically datasets)

```xml
<FS_INDEX name="st_datasets" useLanguages="yes" height="4" viewMode="DETAILS">
  <LANGINFOS>
    <LANGINFO lang="*" label="Datasets" description="Select datasets"/>
  </LANGINFOS>
  <SOURCE name="DatasetDataAccessPlugin">
    <TEMPLATE uid="Products.products"/>
  </SOURCE>
</FS_INDEX>
```

Key attributes: `height`, `viewMode`, `indexTreatment` (default/follow).

Child tags:
- `<SOURCE name="DatasetDataAccessPlugin">` -- Data access plugin name
- `<TEMPLATE uid="Schema.table"/>` -- Table template reference (mandatory `uid` attribute, format: `SchemaName.tableName`)

Notes:
- Referenced datasets must have a GID column (`FS_GID`) `[odfs]`; a row without a GID falls back
  to its primary key and a warning is logged asking for the database to be updated for index
  use `[core]` — treat the GID as required.
- The table template may belong to **any schema** of the project; the lookup is by UID over the
  whole Template Store `[core]`. Stored per entry: `{gid, table, schema}` `[core]`; editor order
  is kept.
- The *NEW* action creates a dataset in the referenced table from inside the index; a rule on
  `NEW` disables it `[odfs]`.
- Schema, columns, what each dataset-backed component stores: `database-schema.md`.

### External / commerce DAP (no `<TEMPLATE>`)

When the source is an external data-access plugin rather than the dataset store, the `<SOURCE>`
names that plugin and carries **no `<TEMPLATE>`** (there is no table template to point at):

```xml
<FS_INDEX name="st_product" useLanguages="no">
  <LANGINFOS>
    <LANGINFO lang="*" label="Product"/>
  </LANGINFOS>
  <SOURCE name="FirstSpirit Connect for Commerce/FirstSpirit Connect for Commerce - Products Data Access Plugin"/>
</FS_INDEX>
```

Other DAPs seen in the reference projects: `…- Categories Data Access Plugin`,
`ContentConnectSAPCommerceCloud/ContentConnectSAPCommerceCloud_ProductDataAccessPlugin` (and
`_CategoryDataAccessPlugin`), `YouTube-DAP-Integration/YoutubeVideoDataAccessPlugin`.

### Output access

An `FS_INDEX` has no included template, so it is **not** rendered by a bare `$CMS_VALUE(st_x)$`.
Reach the records via `.values`, take one with `.first` / `.iterator.next`, then read fields —
`.id`, a commerce `.code`, `.getValueMap().get("<key>")`, or (Connect for Commerce) `.entity.<field>`:

```
$CMS_IF(!st_product.isEmpty())$
  $CMS_VALUE(st_product.values.first.entity.name)$
$CMS_END_IF$
```

See `datatypes.md` → FS_INDEX for the full idiom. (Verified against 16 real `FS_INDEX` uses.)

## CMS_INPUT_SECTIONLIST -- list of the page's own sections

Builds a list of all sections on the page. The editor chooses which sections to include and gives each
one a display text; a template reads the result to build in-page navigation (anchor links). `[odfs]`
*Forms → Input components → CMS_INPUT_SECTIONLIST* (FirstSpirit 2026.11).

```xml
<CMS_INPUT_SECTIONLIST name="pt_sectionlist">
  <LANGINFOS>
    <LANGINFO lang="*" label="Quick navigation" description="Choose the sections to link"/>
  </LANGINFOS>
</CMS_INPUT_SECTIONLIST>
```

Key attributes: `name` (mandatory), `hidden`, `preset` (`DEFAULT` / `COPY`), `searchRelevancy`
(`NONE` / `DEFAULT` / `HIGH`; changing it re-weights existing elements only after a re-index, which is
resource-intensive: plan it for a maintenance period) `[odfs]`. Mark it required with a rule, not
`allowEmpty` (see `firstspirit-template-design`, principle 6). There are no child tags beyond
`LANGINFOS`; unlike `FS_CATALOG` it has no `<TEMPLATES>` and creates no new sections, it points at
existing ones.

### Output access

The value is a `List<SectionListEntry>`; loop it. Each entry has `anchorName`, `text` (the display text
the editor assigned) and `sectionName`. `[odfs]` `[jar]` `de.espirit.firstspirit.access.editor.value.SectionListEntry`
has `getAnchorName()`, `getText()` and `getSectionName()` (5.2.261011 and 5.2.240208).

```
<ul>
  $CMS_FOR(section, pt_sectionlist)$
    <li><a href="#$CMS_VALUE(section.anchorName)$">$CMS_VALUE(section.text)$</a></li>
  $CMS_END_FOR$
</ul>
```

- Sections used together in one list must not share a name. `[odfs]`
- For the anchor links to work, activate the `<a>` tag in the *File extension* area of the *Properties*
  tab of the section templates. `[odfs]`
- `FS_LIST` of type `PAGE` was replaced by this component (`deprecated.md`).

