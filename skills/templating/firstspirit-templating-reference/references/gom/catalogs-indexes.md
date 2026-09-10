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

Note: Referenced datasets must have a GID column ("FS_GID").

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
