# GOM: Real-World Patterns

Patterns extracted from production FirstSpirit projects. Each example includes the business context it solves.

---

## CMS_GROUP -- Tabbed Form Layout

Organizes complex forms into tabs. The outer `CMS_GROUP` has `tabs="top"` and an empty label. Inner groups become the tabs.

```xml
<CMS_MODULE>
  <CMS_GROUP tabs="top">
    <LANGINFOS>
      <LANGINFO lang="*" label=""/>
    </LANGINFOS>

    <CMS_GROUP name="cg_content">
      <LANGINFOS>
        <LANGINFO lang="*" label="Content"/>
      </LANGINFOS>
      <CMS_INPUT_TEXT name="st_headline" hFill="yes" useLanguages="yes">
        <LANGINFOS><LANGINFO lang="*" label="Headline"/></LANGINFOS>
      </CMS_INPUT_TEXT>
      <CMS_INPUT_DOM name="st_text" hFill="yes" useLanguages="yes">
        <FORMATS><TEMPLATE name="teaser_text"/></FORMATS>
        <LANGINFOS><LANGINFO lang="*" label="Text"/></LANGINFOS>
      </CMS_INPUT_DOM>
      <CMS_INPUT_LINK name="st_cta" hFill="yes" useLanguages="yes">
        <LANGINFOS><LANGINFO lang="*" label="CTA"/></LANGINFOS>
        <LINKEDITORS>
          <LINKEDITOR name="internal_link"/>
          <LINKEDITOR name="external_link"/>
        </LINKEDITORS>
      </CMS_INPUT_LINK>
    </CMS_GROUP>

    <CMS_GROUP name="cg_image">
      <LANGINFOS>
        <LANGINFO lang="*" label="Image"/>
      </LANGINFOS>
      <FS_REFERENCE name="st_image" hFill="yes" upload="yes" useLanguages="no">
        <FILTER><ALLOW type="picture"/></FILTER>
        <LANGINFOS><LANGINFO lang="*" label="Image"/></LANGINFOS>
      </FS_REFERENCE>
      <CMS_INPUT_RADIOBUTTON name="st_image_aspect_ratio" gridWidth="5" hFill="yes" useLanguages="no">
        <ENTRIES>
          <ENTRY value="4x3"><LANGINFOS><LANGINFO lang="*" label="4x3"/></LANGINFOS></ENTRY>
          <ENTRY value="16x9"><LANGINFOS><LANGINFO lang="*" label="16x9"/></LANGINFOS></ENTRY>
        </ENTRIES>
        <LANGINFOS><LANGINFO lang="*" label="Aspect Ratio"/></LANGINFOS>
      </CMS_INPUT_RADIOBUTTON>
    </CMS_GROUP>

    <CMS_GROUP>
      <LANGINFOS>
        <LANGINFO lang="*" label="Style"/>
      </LANGINFOS>
      <CMS_INPUT_RADIOBUTTON name="st_layout" gridWidth="3" hFill="yes" useLanguages="no">
        <ENTRIES>
          <ENTRY value="text-image"><LANGINFOS><LANGINFO lang="*" label="Text | Image"/></LANGINFOS></ENTRY>
          <ENTRY value="image-text"><LANGINFOS><LANGINFO lang="*" label="Image | Text"/></LANGINFOS></ENTRY>
          <ENTRY value="text"><LANGINFOS><LANGINFO lang="*" label="Text only"/></LANGINFOS></ENTRY>
        </ENTRIES>
        <LANGINFOS><LANGINFO lang="*" label="Layout"/></LANGINFOS>
      </CMS_INPUT_RADIOBUTTON>
    </CMS_GROUP>

  </CMS_GROUP>
</CMS_MODULE>
```

Key points:
- Outer group: `tabs="top"`, empty label `label=""`
- Inner groups: Optional `name` attribute (needed for rules referencing via `#form.groupName`)
- Tabs appear in order of definition

---

## Container/Item Pattern with FS_CATALOG

The fundamental FirstSpirit pattern for repeatable content blocks: a parent "container" template holds a catalog of child "item" templates.

**Container template** (e.g. `accordion`):

```xml
<CMS_MODULE>
  <CMS_INPUT_TEXT name="st_headline" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Headline"/></LANGINFOS>
  </CMS_INPUT_TEXT>
  <FS_CATALOG name="st_accordion">
    <LANGINFOS><LANGINFO lang="*" label="Accordion"/></LANGINFOS>
    <TEMPLATES type="section">
      <TEMPLATE uid="accordion_item"/>
    </TEMPLATES>
  </FS_CATALOG>
</CMS_MODULE>
```

**Item template** (e.g. `accordion_item`):

```xml
<CMS_MODULE>
  <CMS_INPUT_TEXT name="st_headline" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Title"/></LANGINFOS>
  </CMS_INPUT_TEXT>
  <CMS_INPUT_DOM name="st_text" hFill="yes" useLanguages="yes">
    <FORMATS><TEMPLATE name="p"/></FORMATS>
    <LANGINFOS><LANGINFO lang="*" label="Text"/></LANGINFOS>
  </CMS_INPUT_DOM>
</CMS_MODULE>
```

Key points:
- Container uses `<TEMPLATES type="section">` to restrict which item templates can be added
- Multiple item types can be allowed (e.g. `<TEMPLATE uid="item_text"/>` + `<TEMPLATE uid="item_image"/>`)
- Use rules to limit the number of items (see Rules examples)

---

## FS_CATALOG with Link Templates

Catalog of links (instead of sections) for navigation and link lists.

```xml
<FS_CATALOG name="st_links" useLanguages="yes">
  <LANGINFOS>
    <LANGINFO lang="*" label="Link List"/>
  </LANGINFOS>
  <TEMPLATES type="link">
    <TEMPLATE uid="internal_link"/>
    <TEMPLATE uid="dataset_link"/>
    <TEMPLATE uid="external_link"/>
  </TEMPLATES>
</FS_CATALOG>
```

Key points:
- `type="link"` uses link templates (not section templates)
- Link templates define the available fields per link type (URL, text, icon, etc.)

---

## Section Lifespan Pattern

Time-limited content with start/end dates, typically hidden from content editors.

```xml
<CMS_GROUP name="sectionLifespan">
  <LANGINFOS>
    <LANGINFO lang="*" label="Validity period"/>
  </LANGINFOS>
  <CMS_INPUT_DATE name="st_sectionLifespanFrom" hFill="yes">
    <LANGINFOS>
      <LANGINFO lang="*" label="Validation start date"/>
    </LANGINFOS>
  </CMS_INPUT_DATE>
  <CMS_INPUT_DATE name="st_sectionLifespanTo" hFill="yes">
    <LANGINFOS>
      <LANGINFO lang="*" label="Validation end date"/>
    </LANGINFOS>
  </CMS_INPUT_DATE>
</CMS_GROUP>
```

Key points:
- Dates are evaluated in output templates to show/hide the section
- The `CMS_GROUP name="sectionLifespan"` is included in every section template for consistency
- Controlled by a rule: `EQUAL STORETYPE "templatestore" -> VISIBLE source="#form.sectionLifespan"`

---

## Dual-Mode Template (Product vs Manual)

Content can auto-populate from a database record or be filled manually.

```xml
<CMS_MODULE>
  <CMS_INPUT_RADIOBUTTON name="st_type" hFill="yes" useLanguages="no">
    <ENTRIES>
      <ENTRY value="product"><LANGINFOS><LANGINFO lang="*" label="Product"/></LANGINFOS></ENTRY>
      <ENTRY value="manual"><LANGINFOS><LANGINFO lang="*" label="Manual"/></LANGINFOS></ENTRY>
    </ENTRIES>
    <LANGINFOS><LANGINFO lang="*" label="Type"/></LANGINFOS>
  </CMS_INPUT_RADIOBUTTON>

  <FS_INDEX name="st_product" height="1" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Product"/></LANGINFOS>
    <SOURCE name="DatasetDataAccessPlugin">
      <TEMPLATE uid="smartliving.product"/>
    </SOURCE>
  </FS_INDEX>

  <FS_REFERENCE name="st_image" hFill="yes" upload="yes" useLanguages="no">
    <FILTER><ALLOW type="picture"/></FILTER>
    <LANGINFOS><LANGINFO lang="*" label="Image"/></LANGINFOS>
    <PROJECTS>
      <LOCAL name="."><SOURCES><FOLDER name="images" store="MEDIASTORE"/></SOURCES></LOCAL>
    </PROJECTS>
  </FS_REFERENCE>

  <CMS_INPUT_TEXT name="st_title" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Headline"/></LANGINFOS>
  </CMS_INPUT_TEXT>

  <CMS_INPUT_DOM name="st_text" hFill="yes" useLanguages="yes">
    <FORMATS><TEMPLATE name="p"/></FORMATS>
    <LANGINFOS><LANGINFO lang="*" label="Text"/></LANGINFOS>
    <LINKEDITORS><LINKEDITOR name=""/></LINKEDITORS>
  </CMS_INPUT_DOM>

  <CMS_INPUT_LINK name="st_link" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Link"/></LANGINFOS>
    <LINKEDITORS>
      <LINKEDITOR name="internal_link"/>
      <LINKEDITOR name="external_link"/>
    </LINKEDITORS>
  </CMS_INPUT_LINK>
</CMS_MODULE>
```

Key points:
- Radio button selects the mode
- Rules show `st_product` when type="product", show manual fields when type="manual"
- Rules also limit `st_product` FS_INDEX to exactly 1 entry
- Output template reads product entity data when in product mode, form fields when in manual mode
