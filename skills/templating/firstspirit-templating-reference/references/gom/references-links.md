# GOM: Reference and Link Components

---

## CMS_INPUT_LINK -- Link editor

```xml
<CMS_INPUT_LINK name="st_link" useLanguages="yes" mode="dialog">
  <LANGINFOS>
    <LANGINFO lang="*" label="Link" description="Add a link"/>
  </LANGINFOS>
</CMS_INPUT_LINK>
```

Key attributes: `mode` (dialog/inline, default dialog).

### With Multiple LINKEDITORS

Offers editors a choice of link types (internal pages, external URLs, datasets, media downloads).

```xml
<CMS_INPUT_LINK name="st_cta" hFill="yes" useLanguages="yes">
  <LANGINFOS>
    <LANGINFO lang="*" label="CTA"/>
  </LANGINFOS>
  <LINKEDITORS>
    <LINKEDITOR name="internal_link"/>
    <LINKEDITOR name="dataset_link"/>
    <LINKEDITOR name="external_link"/>
    <LINKEDITOR name="media_link"/>
  </LINKEDITORS>
</CMS_INPUT_LINK>
```

Key points:
- Each `<LINKEDITOR name="..."/>` references a link template UID
- `<LINKEDITOR name=""/>` (empty name) means no links allowed (disables linking in DOM editors)
- Editors choose the link type when creating the link
- In output templates, dispatch by `link.template.uid` to render different link types

## FS_REFERENCE -- Reference to any FS object

```xml
<FS_REFERENCE name="st_image" useLanguages="yes" imagePreview="yes" upload="no">
  <LANGINFOS>
    <LANGINFO lang="*" label="Image" description="Select an image"/>
  </LANGINFOS>
  <FILTER>
    <ALLOW type="PICTURE"/>
  </FILTER>
</FS_REFERENCE>
```

Key attributes: `imagePreview` (YES/NO, default YES), `sections` (YES/NO/ONLY, default YES), `upload` (YES/NO, default NO).

### FILTER types

- `<ALLOW type="..."/>` -- Only these types can be selected. If set, all other types are excluded.
- `<HIDE type="..."/>` -- These types are hidden from the selection dialog.

| Store | Types |
|---|---|
| Page Store | PAGE, PAGEFOLDER |
| Content Store | CONTENT2, CONTENTFOLDER (no selection) |
| Media Store | PICTURE, FILE, MEDIAFOLDER |
| Site Store | PAGEREF, PAGEREFFOLDER (alias: SITESTOREFOLDER), DOCUMENTGROUP |
| Template Store | TEMPLATE, SECTIONTEMPLATE, FORMATTEMPLATE, STYLETEMPLATE, TABLEFORMATTEMPLATE, LINKTEMPLATE, SCRIPT, SCHEMA, WORKFLOW, TEMPLATEFOLDER (no selection), FORMATTEMPLATEFOLDER (no selection), LINKTEMPLATEFOLDER (no selection) |
| Global Settings | GCAPAGE, GCAFOLDER (no selection) |
| Wildcards | MEDIA (pictures + files), FOLDERS (all folder types), ALL (all element types) |

> The `type` values are case-insensitive; SiteArchitect and the reference projects usually write
> them **lowercase** (`<ALLOW type="picture"/>`, `type="pageref"`) even though the docs list them
> uppercase. Read either.

### With PROJECTS/LOCAL/uploadFolder

Allows editors to upload media directly from the form into a specific media folder.

```xml
<FS_REFERENCE name="st_image" hFill="yes" sections="no" upload="yes" useLanguages="no">
  <FILTER>
    <ALLOW type="picture"/>
  </FILTER>
  <LANGINFOS>
    <LANGINFO lang="*" label="Image"/>
  </LANGINFOS>
  <PROJECTS>
    <LOCAL name="." uploadFolder="cloud_logos">
      <SOURCES>
        <FOLDER name="images" store="MEDIASTORE"/>
      </SOURCES>
    </LOCAL>
  </PROJECTS>
</FS_REFERENCE>
```

Key points:
- `upload="yes"` enables the upload button in the form
- `uploadFolder="cloud_logos"` sets where uploaded files are stored in the media store
- `<LOCAL name=".">` means current project (`.` = self)
- `<FOLDER name="images" store="MEDIASTORE"/>` restricts the file browser to that folder
- `sections="no"` disables section anchoring in the selection dialog

## FS_DATASET -- Dataset Reference in Link Templates

References datasets for linking to detail pages.

```xml
<FS_DATASET name="lt_dataset" allowChoose="yes" mode="sheet" useLanguages="no">
  <LANGINFOS>
    <LANGINFO lang="*" label="Dataset"/>
  </LANGINFOS>
  <SOURCES>
    <CONTENT name="news"/>
    <CONTENT name="product"/>
  </SOURCES>
</FS_DATASET>
```

Key points:
- `allowChoose="yes"` shows a dataset picker dialog
- `mode="sheet"` displays a sheet-style selection
- `<CONTENT name="..."/>` restricts which data sources are available
- In templates, access via `formData.lt_dataset.dataset` to get the entity

## FS_BUTTON -- Script Trigger

Integrates a button that executes a server-side BeanShell script, passing form field references as parameters.

```xml
<FS_BUTTON name="st_generateFAQ" onClick="script:ai_generate_faq">
  <LANGINFOS>
    <LANGINFO lang="*" label="Generate FAQ"/>
  </LANGINFOS>
  <PARAMS>
    <PARAM name="prm_accordionFF">#field.st_accordion</PARAM>
    <PARAM name="prm_questionFFName">st_headline</PARAM>
    <PARAM name="prm_answerFFName">st_text</PARAM>
  </PARAMS>
</FS_BUTTON>
```

Key points:
- `onClick="script:script_name"` references a script in the TemplateStore
- `<PARAM name="...">#field.fieldname</PARAM>` passes a live form field reference to the script
- `<PARAM name="...">literal_value</PARAM>` passes a string value
- The script can read and write the referenced fields

## CMS_INPUT_IMAGEMAP -- Interactive Image Hotspots

```xml
<CMS_INPUT_IMAGEMAP name="st_imagemap" hFill="yes" simpleMode="yes">
  <LANGINFOS>
    <LANGINFO lang="*" label="Imagemap"/>
  </LANGINFOS>
  <LINKEDITORS>
    <LINKEDITOR name="interactive_image_link"/>
  </LINKEDITORS>
  <PROJECTS>
    <LOCAL name=".">
      <SOURCES>
        <FOLDER name="images"/>
      </SOURCES>
    </LOCAL>
  </PROJECTS>
</CMS_INPUT_IMAGEMAP>
```

Key points:
- `simpleMode="yes"` uses simplified hotspot drawing
- `<LINKEDITORS>` defines what link templates are available for each hotspot
- `<PROJECTS>` restricts the image source folder
