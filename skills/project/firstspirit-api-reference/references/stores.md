# Stores and their element interfaces

Per-store: the element interfaces and their most-used methods. All extend
`IDProvider` (see [object-model.md](object-model.md) for the shared methods —
`getUid`, `getChildren`, `setLock`/`save`, …). Reach a store root via the
`StoreAgent` (see [agents.md](agents.md)).

Packages are under `de.espirit.firstspirit.access.store.<store>`.

---

## Page content — `PAGESTORE` (`.pagestore`)

Content lives here as pages composed of bodies and sections.

```
// Page
FormData     page.getFormData();                 // page metadata / fields
FormData     page.getFormData(Language);
PageTemplate page.getTemplate();
Listable     page.getChildren(Body.class, false);

// Body (a content area on the page; named slot from the page template)
String       body.getName();
// bodies contain sections

// Section — the editable content unit
FormData     section.getFormData();              // the section's field values
FormData     section.getFormData(Language);
T            section.getTemplate();              // its SectionTemplate

// Create
Section          page.createSection(name, template);        // needs lock
SectionReference page.createSectionReference(name, source);  // reuse another section
```

- `SectionReference` — a reference to a section elsewhere (reuse).
- `Content2Section` — a section that renders Content-Store data on a page.

## Site structure — `SITESTORE` (`.sitestore`)

The navigation tree; `PageRef` nodes point at pages and are what actually gets
generated as URLs.

```
Page       pageRef.getPage();                    // the referenced Page (nullable)
IDProvider pageRef.getTarget(boolean release);   // generic target
String     pageRef.getUrl();                     // generated URL
boolean    pageRef.isStartNode();                // is this the folder's start page
FormData   pageRef.getMetaFormData();            // navigation/meta fields
```

- `DocumentGroup` — groups several `PageRef`s into one output document.
- `PageRefFolder` — the navigation folders.

## Media — `MEDIASTORE` (`.mediastore`)

Binary assets. A `Media` is either a **Picture** or a **File**; branch on
`getType()`.

```
int        media.getType();                      // Media.PICTURE or Media.FILE
Picture    media.getPicture(Language);           // if getType()==PICTURE
File       media.getFile(Language);              // if getType()==FILE
String     media.getFilename();
Resolution picture.getResolution();              // resolutions for a picture
FormData   media.getMetaFormData();              // media metadata
```

Media are language-dependent (a language is required to fetch the binary). Build
media URLs via `UrlAgent` / `PreviewUrlAgent` rather than string-building.

## Data sources — `CONTENTSTORE` (`.contentstore`)

Structured, database-backed content. `Content2` is the query/table node; rows are
`Dataset` (an editable store wrapper) / `Entity` (the raw record).

```
Schema         content2.getSchema();
TableTemplate  content2.getTemplate();
EntityType     content2.getEntityType();
List<Dataset>  content2.getDatasets();                        // master language, current
List<Dataset>  content2.getDatasets(Language, boolean release);
Entity         content2.getEntity(Object keyValue);
Dataset        content2.createDataset(...);                   // needs lock
```

`Dataset.getEntity()` → the underlying `Entity`; read/write fields via `FormData`
or the entity's attributes. See [values-and-data.md](values-and-data.md).

## Global settings — `GLOBALSTORE` (`.globalstore`)

Project-wide content, the **Global Content Area (GCA)**. Same shape as the page
store: `GCAFolder` → `GCAPage` → `GCABody` → `GCASection`, accessed with the same
`getFormData()` / `getTemplate()` methods. Use for content shared across all
pages (headers, footers, global config).

## Templates — `TEMPLATESTORE` (`.templatestore`)

The definitions everything else references.

| Interface | Is |
| --- | --- |
| `PageTemplate` | page template (bodies + form + output channels) |
| `SectionTemplate` | section template |
| `FormatTemplate` | inline format / `$CMS_RENDER(template:…)$` fragment |
| `LinkTemplate` | link template |
| `Script` | a BeanShell script element (see `firstspirit-scripting`) |
| `Schema` | database schema → contains `Query`, `TableTemplate` |
| `Workflow` | workflow definition |

```
// Templates expose their form definition, rules, and output channels (TemplateSet).
template.getFormData();                           // template's own metadata
// GOM/form and channel sources are edited via the templatestore.gom.* types
```

For the template *language* and GOM form components, use
`firstspirit-templating-reference`; this skill is the object/interface layer.
