# FirstSpirit terminology — canonical spelling and casing

Use these terms exactly as written here. The **gloss** is a one-line
disambiguation to help you pick the right word — it is *not* the authoritative
definition. For the full definition, go to the skill named in **Owner**. When
this table and an owner skill disagree, the owner skill wins; fix this file.

Rule of thumb: if you're about to write a FirstSpirit noun and you're not certain
of the exact term or its casing, check here first. If it isn't here and you're
unsure, mark it `[verify]` rather than guessing.

---

## Clients and applications

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| FirstSpirit | internal capital; never "Firstspirit" / "First Spirit" | The CMS / content platform itself. | firstspirit-technical-product-knowledge |
| SiteArchitect | one word, internal capital | The Java desktop client for developers and advanced editors; full access to all stores. | firstspirit-technical-product-knowledge |
| ContentCreator | one word, internal capital | The in-context (WYSIWYG) web editing client for editors. Formerly WebEdit. | firstspirit-technical-product-knowledge |
| ServerManager | one word, internal capital | The client for server and project administration. | firstspirit-technical-product-knowledge |
| ServerMonitoring | one word, internal capital | The web interface for monitoring server state. | firstspirit-technical-product-knowledge |
| ODFS (Online Documentation FirstSpirit) | acronym in caps | The official FirstSpirit product documentation. | firstspirit-technical-product-knowledge |
| FirstSpirit AI Suite | as written | The AI feature set (includes Code Assistant among others). | firstspirit-ai-suite |
| TranslationStudio | one word, internal capital | Add-on integrating translation-provider workflows. | firstspirit-technical-product-knowledge |
| SmartSearch | one word, internal capital | Search product/add-on. | firstspirit-smartsearch |
| Connect for Commerce | as written | The e-commerce connector. | firstspirit-technical-product-knowledge |

## Store trees (the project's content stores)

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| Page Store | capitalised as a proper noun | Holds pages; a page has a body with sections. (DE: Seitenverwaltung.) | firstspirit-api-reference |
| Media Store | proper noun | Holds media — images and files, language-dependent or not. (DE: Medienverwaltung.) | firstspirit-api-reference |
| Site Store | proper noun | The site structure / navigation tree; holds page references (`PageRef`). (DE: Struktur-/Menüverwaltung.) | firstspirit-api-reference |
| Content Store / Data Sources | proper noun | Datasets held against a database schema. (DE: Datenquellen.) | firstspirit-api-reference |
| Template Store | proper noun | Holds templates, schemas, workflows, scripts, formats. (DE: Vorlagen.) | firstspirit-api-reference |
| Global Settings | proper noun | Project-wide settings store. | firstspirit-api-reference |

## Structural elements

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| page | lowercase (common noun) | A content page in the Page Store; contains a body with sections. | firstspirit-api-reference |
| body | lowercase | A named region of a page that holds sections. | firstspirit-api-reference |
| section | lowercase | A content element inside a page's body, based on a section template. Not "content block". | firstspirit-api-reference |
| page reference (`PageRef`) | lowercase term, `PageRef` interface | A node in the Site Store that places a page into the structure. Not "menu link". | firstspirit-api-reference |
| dataset | lowercase | A single record in a data source. (DE: Datensatz.) Not "database row" in editor-facing text. | firstspirit-api-reference |
| entity | lowercase | The data-layer object behind a dataset. | firstspirit-api-reference |
| database schema | lowercase | The schema in the Template Store that data sources build on. | firstspirit-templating-reference |

## Templates

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| page template | lowercase | Defines the structure and form of a page. (DE: Seitenvorlage.) | firstspirit-template-design |
| section template | lowercase | Defines a section's form and output. (DE: Absatzvorlage.) | firstspirit-template-design |
| format template | lowercase | Formatting rules applied within rich text (DOM). (DE: Formatvorlage.) | firstspirit-template-design |
| link template | lowercase | Defines a link/reference configuration. (DE: Verweis-/Linkvorlage.) | firstspirit-template-design |
| table template | lowercase | Output template for datasets from a schema. | firstspirit-template-design |

## Forms, components, template language

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| GOM (Generic Object Model) | acronym in caps | The XML form-definition model for input components in a template. | firstspirit-templating-reference |
| input component | lowercase | A form field in a template's form (`CMS_INPUT_*`, `FS_*`). | firstspirit-templating-reference |
| `CMS_INPUT_*` | exact casing, monospace | The classic input-component family (e.g. `CMS_INPUT_TEXT`, `CMS_INPUT_DOM`). | firstspirit-templating-reference |
| `FS_*` | exact casing, monospace | The newer input/component family (e.g. `FS_REFERENCE`, `FS_CATALOG`, `FS_INDEX`, `FS_DATASET`, `FS_BUTTON`). | firstspirit-templating-reference |
| Rules | capitalised when meaning the feature | Form logic: validation, visibility, editability, value. (DE: Regeln.) | firstspirit-templating-reference |
| instruction (`$CMS_…$`) | monospace; "instruction", not "Velocity tag" | Template-language construct in the output channel (`$CMS_VALUE$`, `$CMS_IF$`, `$CMS_FOR$`, `$CMS_REF$`, `$CMS_RENDER$`). | firstspirit-templating-reference |
| output channel / template set | lowercase | The rendering output of a template (e.g. HTML); a template can have several. | firstspirit-templating-reference |
| datatype | lowercase | The value type a component yields, read in the output channel. | firstspirit-templating-reference |

## API, scripting, modules

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| Access API | as written | The FirstSpirit Java API for reading/writing project content. | firstspirit-api-reference |
| SpecialistsBroker | one word, internal capital | The entry point that hands out agents/services in the Access API. | firstspirit-api-reference |
| agent | lowercase (e.g. StoreAgent, QueryAgent) | A service obtained from the broker; agent names keep internal capitals. | firstspirit-api-reference |
| UID / Uid | as the API spells it (`Uid`, `UidType`) | The unique identifier of a store element. | firstspirit-api-reference |
| BeanShell | one word, internal capital | The scripting language for FirstSpirit scripts. | firstspirit-scripting |
| script context (`context`) | lowercase; `context` in monospace | The bound object a script receives, varying by script type. | firstspirit-scripting |
| FSM (FirstSpirit Module) | acronym in caps | The packaging format for a module. | firstspirit-module-development |
| `module.xml` | monospace | The module descriptor: components and resource scopes. | firstspirit-module-development |

## Delivery, operations, headless

| Term | Casing note | One-line gloss | Owner |
|---|---|---|---|
| CaaS (Content as a Service) | acronym in caps | Released content exposed as JSON over a REST API for headless delivery. | firstspirit-headless |
| generation | lowercase | Rendering project content into deployable output. | ODFS |
| deployment | lowercase | Publishing generated output to a target. | ODFS |
| schedule | lowercase | A configured, runnable job (e.g. generation + deployment). (DE: Auftrag.) | ODFS |
| release | lowercase (verb/noun) | Making an editorial state the released version. (DE: freigeben.) Distinct from preview. | ODFS |
| preview | lowercase | The current editing state, before release. | firstspirit-operations |
| workflow | lowercase | A configured state/transition process on an element. | ODFS |
| permission | lowercase | Access right on a store element or action. | ODFS |

---

## Common corrections

| Don't write | Write |
|---|---|
| Firstspirit, First Spirit, firstSpirit | FirstSpirit |
| content block, content element (editor text) | section |
| menu link, nav item | page reference |
| database record/row (editor text) | dataset |
| Velocity tag, template tag | instruction (`$CMS_…$`) |
| WebEdit (as current name) | ContentCreator |
| the admin tool | ServerManager |
| CaaS solution "for all content needs" | (describe what it does; drop the marketing) |
| FS module / fs module | FirstSpirit Module (FSM) |
