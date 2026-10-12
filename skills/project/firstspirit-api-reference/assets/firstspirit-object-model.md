# FirstSpirit object model — store hierarchies

The six SiteArchitect store trees and the Access-API interface behind every node (replaces the
former `firstspirit-object-model.png` overview diagram; same trees, as text). Nesting = which
element types appear as children of which. Every node is a `StoreElement`; all but a few also
implement `de.espirit.firstspirit.access.store.IDProvider`. Every interface name below exists in
the runtime jar `[jar]`; the store package is given per tree.

Folder types nest in folders of their own kind (the poster drew that for `PageRefFolder` and
`MediaFolder`; `PageFolder`, `TemplateFolder` and the other folders nest the same way). The trees
show one representative expansion, not every legal combination.

## Page content — `pagestore`

Root `PageStoreRoot` · package `de.espirit.firstspirit.access.store.pagestore`

- PageFolder
  - Page
    - Body
      - Section
      - Section
    - Body
      - Section
- PageFolder
  - Page
    - Body
      - SectionReference
      - Section
    - Body
      - Content2Section

## Data sources — `contentstore`

Root `ContentStoreRoot` · package `de.espirit.firstspirit.access.store.contentstore`

- ContentFolder
  - Content2 *(the rows are `Dataset` / `Entity`, see `references/values-and-data.md`)*

## Site structure — `sitestore`

Root `SiteStoreRoot` · package `de.espirit.firstspirit.access.store.sitestore`

- PageRefFolder
  - PageRefFolder
    - PageRef
  - PageRef
- PageRefFolder
  - PageRefFolder
    - DocumentGroup
    - PageRef

## Global settings — `globalstore`

Root `GlobalStoreRoot` · package `de.espirit.firstspirit.access.store.globalstore`

- ProjectProperties *(project settings; `getProjectProperties()`)*
- URLProperties *(`getUrlProperties()`)*
- GlobalContentArea *(container; itself a `GCAFolder`, so it may hold `GCAPage`s directly)*
  - GCAPage
  - GCAFolder
    - GCAPage
      - GCABody
        - GCASection
        - GCASection
      - GCABody
        - GCASection
  - GCAFolder
    - GCAPage

## Media — `mediastore`

Root `MediaStoreRoot` · package `de.espirit.firstspirit.access.store.mediastore`

- MediaFolder
  - MediaFolder
    - Media
  - Media
  - Media
  - Media
- MediaFolder

## Templates — `templatestore`

Root `TemplateStoreRoot` · package `de.espirit.firstspirit.access.store.templatestore`.
The first level is a fixed set of containers, each its own interface:

- PageTemplates *(container)*
  - TemplateFolder
    - PageTemplate
  - PageTemplate
- SectionTemplates *(container)*
  - TemplateFolder
    - SectionTemplate
  - SectionTemplate
- FormatTemplates *(container)*
  - FormatTemplateFolder
  - FormatTemplate
- LinkTemplates *(container)*
  - TemplateFolder
    - LinkTemplate
  - LinkTemplate
- Scripts *(container)*
  - ScriptFolder
  - Script
- Schemes *(container — "Database Schemata" in the UI)*
  - SchemaFolder
    - Schema
      - Query
      - TableTemplate
  - Schema
    - Query
    - TableTemplate
- Workflows *(container)*
  - WorkflowFolder
  - Workflow

## Element index

Parents and children as drawn above (folders nest recursively in addition).

| Interface | Store | Kind | Parents | Children |
|---|---|---|---|---|
| PageFolder | pagestore | folder | PageStoreRoot, PageFolder | PageFolder, Page |
| Page | pagestore | element | PageFolder | Body |
| Body | pagestore | element | Page | Section, SectionReference, Content2Section |
| Section | pagestore | element | Body | — |
| SectionReference | pagestore | element | Body | — |
| Content2Section | pagestore | element | Body | — |
| ContentFolder | contentstore | folder | ContentStoreRoot, ContentFolder | ContentFolder, Content2 |
| Content2 | contentstore | element | ContentFolder | — (rows: Dataset / Entity) |
| PageRefFolder | sitestore | folder | SiteStoreRoot, PageRefFolder | PageRefFolder, PageRef, DocumentGroup |
| PageRef | sitestore | element | PageRefFolder | — |
| DocumentGroup | sitestore | element | PageRefFolder | — |
| ProjectProperties | globalstore | element | GlobalStoreRoot | — |
| URLProperties | globalstore | element | GlobalStoreRoot | — |
| GlobalContentArea | globalstore | container | GlobalStoreRoot | GCAFolder, GCAPage |
| GCAFolder | globalstore | folder | GlobalContentArea, GCAFolder | GCAFolder, GCAPage |
| GCAPage | globalstore | element | GCAFolder | GCABody |
| GCABody | globalstore | element | GCAPage | GCASection |
| GCASection | globalstore | element | GCABody | — |
| MediaFolder | mediastore | folder | MediaStoreRoot, MediaFolder | MediaFolder, Media |
| Media | mediastore | element | MediaFolder | — |
| PageTemplates | templatestore | container | TemplateStoreRoot | TemplateFolder, PageTemplate |
| SectionTemplates | templatestore | container | TemplateStoreRoot | TemplateFolder, SectionTemplate |
| FormatTemplates | templatestore | container | TemplateStoreRoot | FormatTemplateFolder, FormatTemplate |
| LinkTemplates | templatestore | container | TemplateStoreRoot | TemplateFolder, LinkTemplate |
| Scripts | templatestore | container | TemplateStoreRoot | ScriptFolder, Script |
| Schemes | templatestore | container | TemplateStoreRoot | SchemaFolder, Schema |
| Workflows | templatestore | container | TemplateStoreRoot | WorkflowFolder, Workflow |
| TemplateFolder | templatestore | folder | PageTemplates, SectionTemplates, LinkTemplates, TemplateFolder | TemplateFolder, PageTemplate, SectionTemplate, LinkTemplate |
| PageTemplate | templatestore | element | PageTemplates, TemplateFolder | — |
| SectionTemplate | templatestore | element | SectionTemplates, TemplateFolder | — |
| FormatTemplateFolder | templatestore | folder | FormatTemplates, FormatTemplateFolder | FormatTemplateFolder, FormatTemplate |
| FormatTemplate | templatestore | element | FormatTemplates, FormatTemplateFolder | — |
| LinkTemplate | templatestore | element | LinkTemplates, TemplateFolder | — |
| ScriptFolder | templatestore | folder | Scripts, ScriptFolder | ScriptFolder, Script |
| Script | templatestore | element | Scripts, ScriptFolder | — |
| SchemaFolder | templatestore | folder | Schemes, SchemaFolder | SchemaFolder, Schema |
| Schema | templatestore | element | Schemes, SchemaFolder | Query, TableTemplate |
| Query | templatestore | element | Schema | — |
| TableTemplate | templatestore | element | Schema | — |
| WorkflowFolder | templatestore | folder | Workflows, WorkflowFolder | WorkflowFolder, Workflow |
| Workflow | templatestore | element | Workflows, WorkflowFolder | — |
