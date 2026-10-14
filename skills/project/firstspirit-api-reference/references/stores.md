# Stores and their element interfaces

Per-store: the element interfaces and their most-used methods. Almost all extend
`IDProvider` — `Picture`, `File` and `PictureResolution` below are plain `StoreElement`s `[jar]`
(see [object-model.md](object-model.md) for the shared methods —
`getUid`, `getChildren`, `setLock`/`save`, …). Reach a store root via the
`StoreAgent` (see [agents.md](agents.md)).

Packages are under `de.espirit.firstspirit.access.store.<store>`.

---

## Page content — `PAGESTORE` (`.pagestore`)

Content lives here as pages composed of bodies and sections.

```
// Page
FormData     page.getFormData();                 // page fields (DataProvider)
FormData     ((LanguageDataProvider) page).getFormData(lang);   // not declared on Page: LanguageDataProvider, 5.2.261011 jar only, not 5.2.240208 [jar]; equals getFormData() outside a language-dependent release state [javadoc]
PageTemplate page.getTemplate();
Listable     page.getChildren(Body.class, false);
Body         page.getBodyByName(name);

// Body (a content area on the page; named slot from the page template)
String       body.getName();
// bodies contain sections

// Section — the editable content unit
FormData     section.getFormData();              // the section's field values
FormData     ((LanguageDataProvider) section).getFormData(lang);   // same rule as for Page: cast, 5.2.261011 only [jar]
T            section.getTemplate();              // its SectionTemplate

// Create (declared on Body / GCABody, not on Page)
Section          body.createSection(name, template);        // persists at once, no explicit lock needed [observed]; declared `throws LockException` [jar]
SectionReference body.createSectionReference(name, source);  // reuse another section
```

- `SectionReference` — a reference to a section elsewhere (reuse).
- `Content2Section` — a section that renders Content-Store data on a page.

## Site structure — `SITESTORE` (`.sitestore`)

The navigation tree; `PageRef` nodes point at pages and are what actually gets
generated as URLs.

```
Page       pageRef.getPage();                    // the referenced Page (nullable)
boolean    pageRef.isStartNode();                // is this the folder's start page
FormData   pageRef.getMetaFormData();            // navigation/meta fields
String     pageRef.getStoredUrl(language, templateSet, null);   // URL stored by the last generation (ContentProducer) [jar]
// preview URL: requireSpecialist(PreviewUrlAgent.TYPE).getContentProducerBuilder()…getUrl(pageRef)
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
PictureResolution picture.getPictureResolution(Resolution);  // per-resolution data — Picture has NO getResolution()
Resolution context.requireSpecialist(ResolutionAgent.TYPE).getResolutionByName("thumb");  // Resolution by uid (or Project.getResolutionByName); @Nullable — there is no getResolution(String)
int        pictureResolution.getWidth(); pictureResolution.getHeight();  // pixel size of this rendition
Resolution pictureResolution.getResolution();     // the Resolution comes back from the PictureResolution
byte[]     picture.getPreviewImage();            // preview bytes; getPreview() deprecated since 5.0, no getThumbnail()
FormData   media.getMetaFormData();              // media metadata
```

Media created language-dependent have one binary per language; a language-independent media
(`languageDependent = false`) returns the same binary for every language and for `null` `[observed]`. Build
media URLs via `PreviewUrlAgent.getMediaBuilder()…getUrl(media)` (preview) or
`media.getStoredUrl(language, resolution)` (the generated URL) `[jar]` rather than string-building —
**not** via `UrlAgent`, which only lists stored SEO / short URL entries (see [agents.md](agents.md)).

## Data sources — `CONTENTSTORE` (`.contentstore`)

Structured, database-backed content. `Content2` is the query/table node; rows are
`Dataset` (an editable store wrapper) / `Entity` (the raw record).

```
Schema         content2.getSchema();
TableTemplate  content2.getTemplate();
EntityType     content2.getEntityType();
List<Dataset>  content2.getDatasets();                        // master language, current
List<Dataset>  content2.getDatasets(Language, boolean release);   // 5.2.261011 jar only — 5.2.240208 has getDatasets() and getDatasets(Language) [jar]
Entity         content2.getEntity(Object keyValue);
Dataset        content2.createDataset();                      // no arguments: new entity of the table's type [jar]; works without a lock [observed]; locking the Content2 is conventional
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
// Templates are not DataProviders: no getFormData() on Template, MasterTemplate, PageTemplate,
// SectionTemplate or FormatTemplate [jar]. They expose the form definition, its defaults,
// the output channels (per TemplateSet) and their own metadata:
String   gom  = template.getGomSource();                 // form definition (GOM XML)   — GomSourceProvider
FormData defs = template.getFormDefaults();              // default values of that form  — GomSourceProvider
String   src  = template.getChannelSource(templateSet);  // output channel source        — ChannelSourceProvider
FormData meta = template.getMetaFormData();              // the template's metadata form — IDProvider
// GOM/form and channel sources are edited via the templatestore.gom.* types
```

For the template *language* and GOM form components, use
`firstspirit-templating-reference`; this skill is the object/interface layer.
