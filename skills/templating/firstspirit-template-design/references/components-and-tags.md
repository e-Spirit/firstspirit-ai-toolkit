# Components, tags and structure

Look-up reference for the FirstSpirit building blocks: stores, template types, input components, CMS tags, datatypes and header functions. Source: an older FirstSpirit overview handout. For anything not here, the authoritative source is the ODFS (Online Documentation FirstSpirit).

**Source of truth.** Within the portfolio, the firstspirit-templating-reference skill owns the component and datatype facts (its `datatypes.md` and GOM references, which track the documentation). This catalogue is the design-oriented view the principles point to; where the two differ, templating-reference wins on the facts.

**Currency caveat.** This material comes from an older handout that predates headless projects and reflects the SiteArchitect, the Java fat client now being phased out. Template development in the ContentCreator differs in places. Verify headless, CaaS, ContentCreator and AI Suite specifics against current documentation.

**Headless and CaaS.** In a headless project delivered through CaaS, FirstSpirit renders the JSON in a fixed setup and nests components into each other. Design templates for that consumer: keep nesting flatter and shaped around what frontend developers need (see SKILL.md, principles 4 and 7).

## Stores

- **Page content:** content of single pages.
- **Data sources:** heavily structured content, embedded into the project.
- **Media:** files and images used in the project.
- **Site structure:** the project's navigation. Content referenced here is generated as files.
- **Templates:** layout of pages and sections.
- **Global settings:** user and project settings.

## Page templates and section templates

- **Page template:** the basic layout of a page and every element shown on every page of this type, including the navigation reference. The navigation reference comes from the site structure store and is independent of the content store.
- **Section template:** every variable part of a page, that is, everything an editor supplies.

Sections are based on section templates and are placed into content areas. A page can have any number of content areas, and a content area can be restricted to allow only certain section templates. Section templates can repeat on a page without limit, so anything that should appear only once belongs in the page template (for example the page title).

Render the sections of a content area with:

```
$CMS_VALUE(#global.page.body("myBody"))$
```

## Defining input components

Input components are the forms editors use, defined on the form tab. Each one:

- Sits within an opening and closing `<CMS_MODULE>` tag
- Contains valid XML only
- Has a tag name following the convention `<CMS_INPUT_Name ...>` or `<FS_Name ...>`
- Includes a `name` attribute, the variable used to read the content in the output channel
- May carry a description set via `<LANGINFOS>`

Every input component returns a value of a defined type (a Java class or interface), noted in its ODFS entry.

## Input component catalogue

| Component | Purpose |
|---|---|
| `CMS_INPUT_TEXT` | Single line text. |
| `CMS_INPUT_TEXTAREA` | Multiline text, no formatting. |
| `CMS_INPUT_DOM` | Continuous text; layout and output via format templates. |
| `CMS_INPUT_DOMTABLE` | Tables; output via the `Table` header function. |
| `CMS_INPUT_DATE` | Date selection. |
| `CMS_INPUT_TOGGLE` | Switch between two set values. |
| `CMS_INPUT_RADIOBUTTON` | Single selection by activation. |
| `CMS_INPUT_COMBOBOX` | Single selection via drop-down. |
| `CMS_INPUT_CHECKBOX` | Any number of selections. |
| `CMS_INPUT_LIST` | Multiple selection via drop-down. |
| `CMS_INPUT_SECTIONLIST` | Build a named list from a page's existing sections. |
| `CMS_INPUT_LINK` | Supply a link; output via link templates. |
| `CMS_INPUT_NUMBER` | Numerical values. |
| `CMS_INPUT_PERMISSION` | Set user rights (not editorial rights), evaluated via DynamicPersonalization. |
| `FS_REFERENCE` | Select any FirstSpirit object; restrict with the inner `FILTER` tag. |
| `FS_CATALOG` | Lists of section or link templates. |
| `FS_INDEX` | Lists from internal FirstSpirit data or external data. |
| `FS_DATASET` | Select a single dataset from the content store. |
| `FS_BUTTON` | Icon, button or link attached to a script or class. |

Note: `FS_LIST` was deprecated in 5.2R3 and removed in FirstSpirit 2020-07 (ODFS's planned date was "from 2020-01"). Prefer `FS_CATALOG` or `FS_INDEX`.

## Datatype and dependency mapping

The *column type* is what the component maps onto in a table template (schema editor types:
String, Integer, Long, Double, Boolean, Date, FirstSpirit editor). *Dependency* says what a
dataset-backed component stores and in which direction it points. The full type table and the
stored values are facts in the firstspirit-templating-reference skill's `gom/database-schema.md`;
this view is the design side.

| Component | Column type in a table template | Dependency / stored value |
|---|---|---|
| `FS_INDEX` (datasets) | FirstSpirit editor only (no relation mapping) | ordered list of dataset references, **1:n**, FirstSpirit-side — a query cannot join on it |
| `FS_CATALOG` | FirstSpirit editor | none (nested sections or links) |
| `FS_REFERENCE` | FirstSpirit editor | reference to a store element |
| `FS_DATASET` | **foreign-key relation** (1:N, one `<CONTENT>`) or FirstSpirit editor | one dataset, **n:1**; on the relation the database knows the link and a query can join, on the column it is editorial only |
| `LINK` | FirstSpirit editor | link template data |
| `COMBOBOX` / `RADIOBUTTON` (fixed entries) | String; Integer / Long / Double / Boolean when every entry parses as that type — the value is converted, `1` is stored as a number | none |
| `COMBOBOX` / `RADIOBUTTON` (database) | **foreign-key relation** (n:1), or a typed column holding the `<KEY>` value | one row; on the relation a join, on the column **the `<KEY>` column's value, else the row's GID** |
| `CHECKBOX` (database) | **foreign-key relation** (m:n), or FirstSpirit editor | set of rows, n, unordered |
| `TOGGLE` | Boolean | none |
| `TEXT` / `TEXTAREA` | String | none |
| `NUMBER` | Long, Integer or Double (per `type`) | none |
| `DATE` | Date, or Long (timestamp) | none |
| `DOM` / `DOMTABLE` | FirstSpirit editor | none |
| `LIST` (legacy) | FirstSpirit editor | foreign key dependency to n — replaced by `FS_INDEX` |

## Reading variables

Read a variable anywhere in the output with `$CMS_VALUE(variableName)$`. Use dot notation to reach further properties and methods on complex objects.

## CMS tag overview

| Tag | Purpose |
|---|---|
| `$CMS_FOR(var, list)$ ... $CMS_END_FOR$` | Iterate over an iterable list (a foreach). |
| `$CMS_IF(cond)$ ... $CMS_ELSE$ ... $CMS_END_IF$` | Conditional; nestable; else is optional. |
| `$CMS_REF(reference)$` | Resolve and return the path (URL) of a reference. |
| `$CMS_RENDER(template:"...")$` / `$CMS_RENDER(script:"...")$` | Call a format template or script and output the result; accepts parameters. |
| `$CMS_SET(name, value)$` | Set a variable. |
| `$CMS_SWITCH(obj)$ ... $CMS_CASE(v)$ ... $CMS_END_SWITCH$` | Test a value against multiple cases. |
| `$CMS_TRIM(...)$ ... $CMS_END_TRIM$` | Remove whitespace from enclosed code; `level` controls what counts as whitespace. |
| `$CMS_VALUE(name)$` | Output a variable; dot notation for complex objects. |

## Header functions

Defined in the source, within `<CMS_HEADER>`, valid XML, named via `<CMS_FUNCTION name="..." resultname="...">`. Parameters:

- `<CMS_PARAM name="..." value="constant"/>` for a constant
- `<CMS_VALUE_PARAM name="..." value="variableName"/>` for a variable
- `<CMS_CDATA_PARAM name="...">...</CMS_CDATA_PARAM>` for non-XML-compatible text

The three parameter types are interchangeable.

Available header functions:

- **ContentSelect:** output database content.
- **Table:** output a `CMS_INPUT_DOMTABLE`.
- **MenuGroup:** link folders of the same level (previous, next).
- **Navigation:** build navigation from the site structure.
- **PageGroup:** link merged pages, also used between detail pages from content projections.
- **Font:** multiline captions for background images; the inline `font()` function also exists.

CDATA hides non-XML-compatible content from the parser: `<![CDATA[ ... ]]>`. It cannot contain `]]>`, so CDATA sections cannot nest.
