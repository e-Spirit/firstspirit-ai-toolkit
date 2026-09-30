# Database schema, table templates, data sources

The facts behind every dataset-backed input component (`FS_DATASET`, `FS_INDEX` with the
`DatasetDataAccessPlugin`, `CMS_INCLUDE_OPTIONS type="database"`) and behind content projection.
Which *relation* to model with which component is design judgement and lives in
`firstspirit-template-design` (principle 11); this file states what the objects are and what
each component stores.

Evidence tags: `[odfs]` ODFS *Composition of templates → Database schemata* and *Forms →
FS_DATASET / FS_INDEX / CMS_INCLUDE_OPTIONS type="database"* (FirstSpirit 2026.5 export);
`[core]` behaviour read in the FirstSpirit product source (file and line recorded in the skill's
working notes, which do not ship); `[jar]` `javap` on `fs-isolated-runtime` 5.2.261011.

## The objects

- A **database schema** lives in the Template Store and holds **table templates** and
  **queries**. One table template per table: it defines the columns (schema editor) and carries
  the GOM form whose input components are **mapped** onto the columns (*Mapping* tab). `[odfs]`
- A **data source** (Content Store; interface `Content2`) is created *from* a table template
  and holds the **datasets** — the rows — of that table. Datasets are edited through the table
  template's form. `[odfs]`
- **Reference format.** Every dataset-backed component addresses the *table template* by its
  UID; the client suggests `<schema uid>.<table name>` when the template is created, so the
  conventional form is `Products.products`. `<TABLE>Products.products</TABLE>`,
  `<TEMPLATE uid="Products.products"/>`, `queryUid="Products.myQuery"`. `[odfs]` The UID is one
  project-wide namespace shared by table templates and queries (`TEMPLATESTORE_SCHEMA`); the
  dot is a naming convention, not a lookup path. `[core]` The external-sync export shows the
  same: `Schemes/<schema>/<schema.table>/`.
- `FS_DATASET` does not point at a table template but at **data sources** (`<SOURCES><CONTENT
  name="<data source uid>"/>`); without `<SOURCES>` every data source of the project is
  selectable. `[odfs]`

## Columns

- **`fs_id`** — every table has it: the integer primary key, hidden, consecutive per table.
  `[odfs]` `[core]`
- **`FS_GID`** — a UUID system column. The ODFS names datasets with a GID as *mandatory* for the
  `DatasetDataAccessPlugin` (`FS_INDEX`). `[odfs]` The implementation falls back to the primary
  key when a row has no GID, and logs "Entity has no GID. The database has to be updated for
  Index-use." — treat the GID as required in practice. `[core]`
- **Language-dependent columns.** *Generate for all languages* in the schema editor creates one
  column per project language (suffixed with the language code). A form component with
  `useLanguages="yes"` must be mapped to such a set, one column per language; a
  language-independent component is mapped to the same column for every language. `[odfs]`
  Each language is its own physical column: when a **project language is added**, the column
  for it has to be created for every language-dependent attribute before editors can work in
  that language — the schema editor's *Collapse language-dependent columns* view deliberately
  keeps a column expanded when one language's column is missing, so the gap stays visible.
  `[odfs]` (confirmed internally at FirstSpirit, 2026-09-28)
- **Foreign keys** are relations between two tables of the same schema: 1:1, 1:N or M:N, in one
  direction or both (*Both* inserts a column on each side); *Aggregation* deletes / releases
  the linked dataset together with its owner. `[odfs]`

## Column data types and the components that map onto them

The schema editor offers seven column types. The *Possible field type* column is the ODFS
statement `[odfs]`; the last column is the mapping filter of the client, which also lets a
selection component (`COMBOBOX` / `RADIOBUTTON` / `CHECKBOX` with fixed `<ENTRIES>`) map onto a
`Boolean`, `Integer`, `Long` or `Double` column when **every** entry value parses as that type,
and lets a date component map onto a `Long`. `[core]`

| Column type (schema editor) | XML type | Java type | Possible field type `[odfs]` | Also accepted by the mapping filter `[core]` |
| --- | --- | --- | --- | --- |
| String | `xs:string` | `String` | `CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA`, `CMS_INPUT_COMBOBOX`, `CMS_INPUT_RADIOBUTTON` | any component whose value is a `String`; selection components always |
| Integer | `xs:integer` | `Integer` | `CMS_INPUT_NUMBER`, `CMS_INPUT_COMBOBOX`, `CMS_INPUT_RADIOBUTTON` | selection components whose entries are all integers |
| Long | `xs:long` | `Long` | `CMS_INPUT_NUMBER`, `CMS_INPUT_COMBOBOX`, `CMS_INPUT_DATE`, `CMS_INPUT_RADIOBUTTON` | date components (timestamp); selection components whose entries are all integers |
| Double | `xs:decimal` | `Double` | `CMS_INPUT_NUMBER` | selection components whose entries are all numbers |
| Boolean | `xs:boolean` | `Boolean` | `CMS_INPUT_TOGGLE` | selection components whose only entries are `true` / `false` |
| Date | `xs:date` | `Date` | `CMS_INPUT_DATE` (`mode="datetime"`) | — |
| FirstSpirit editor | `xml` | `XMLValue` (default length 65 535, raisable) | **every** field type — the column stores the component's serialised value | the **only** possible column for `CMS_INPUT_DOM` / `DOMTABLE`, `FS_REFERENCE`, `FS_CATALOG`, `FS_INDEX`, `CMS_INPUT_LINK`, `IMAGEMAP` and every other component whose value is not a plain string, number, boolean or date |

- **A selection component stores a real number when mapped onto a numeric column.** The
  mapping converts the entry value on save (`Conversion.convert` to the column's Java type), so
  a `CMS_INPUT_RADIOBUTTON` with entries `1`, `2`, `3` mapped onto an `Integer` column stores the
  integer `1`, not the string `"1"`; mapped onto a `String` column it stores the string. The
  editor offers the numeric column only when *every* entry parses. `[core]`
- A column typed **String / Integer / Long / Double / Boolean / Date** is queryable and
  comparable in a query condition; a **FirstSpirit editor** column is an opaque XML blob for the
  database — use it for rich text, references and catalogs, never for a value a query filters on.
- **Allow empty value** (per column, default on). Switched off, the column is *mandatory* at the
  database level and shown red in the schema model `[odfs]`. Not recommended: a dataset with the
  column empty cannot be saved and the editor gets the database's error, which rarely says what
  to fix. Express "required" as a not-empty validation rule on the form instead (confirmed
  internally at FirstSpirit, 2026-09-28).

The runtime knows further column types (`binary`, `uuid`, `json`) that the schema editor does
not offer for new columns. `[jar]` `[core]`

### Dataset references: relation or column

A component that holds datasets can be mapped two ways on the *Mapping* tab, and the choice
decides whether the database knows about the link: `[core]`

| Component | Onto a **foreign-key relation** of the schema | Onto a column |
| --- | --- | --- |
| `FS_DATASET` | yes, when exactly one `<CONTENT>` is given — the 1:N relation, table B is the parent (n:1 from the child) `[odfs]` | yes, a FirstSpirit editor column — the reference is serialised, the database has no join |
| `CMS_INPUT_COMBOBOX` / `RADIOBUTTON` with `type="database"` | yes — n:1, the same relation an `FS_DATASET` would take | yes — a typed column storing the `<KEY>` value (or GID) as a plain value |
| `CMS_INPUT_CHECKBOX` with `type="database"` | yes — **m:n** | yes — FirstSpirit editor column |
| `FS_INDEX` (`DatasetDataAccessPlugin`) | **no** — the index has no relation mapping | FirstSpirit editor column only: the ordered list is FirstSpirit-side, a query cannot join on it |

Map onto the relation when a query, content projection or a foreign-key *Aggregation* must see
the link; map onto a column when the reference is editorial only.

## Which component stores what

| Component | Stored value | Cardinality | Editor order kept | Read in the output channel |
| --- | --- | --- | --- | --- |
| `CMS_INPUT_COMBOBOX` / `RADIOBUTTON` + `CMS_INCLUDE_OPTIONS type="database"` | with `<KEY>col</KEY>`: the value of that column; without: the row's **FS_GID**, or its primary key (`fs_id`) when the row has no GID `[odfs]` `[core]` | 1 | — | `Option`: `.value` is the resolved row (`Entity`), `.key` the identifying value `[odfs]` |
| `CMS_INPUT_CHECKBOX` + `type="database"` | a set of the above | n | no | `Set<Option>`, loop |
| `FS_DATASET` in a **page / section / link template** | one dataset reference: GID + key + table-template UID `[odfs]` | 1 | — | `DatasetContainer`: `.dataset` (may be `null`), `.gid`, `.key`, `.templateUid` `[odfs]` |
| `FS_DATASET` in a **table template** | the **foreign key** of the schema relation it is linked to (the parent's key) `[odfs]` | 1 | — | as above; the linked row's columns are reachable in the form via the relation |
| `FS_INDEX` + `DatasetDataAccessPlugin` | a list of record identifiers — JSON `{gid, table, schema}` (or `{keyValue, table, schema}` without GID) `[core]` | n | **yes** | `Index` of `Record`s; each record is resolved through the plugin's session (`.values` / `.entity`) `[odfs]` |

- `<KEY>` needs a **unique** column: on read the option factory throws "Key '…' is not unique
  in table …" when two rows match. `[core]` The ODFS says the same in words: use `KEY` only "if
  the users themselves can guarantee the uniqueness". `[odfs]` No rule can enforce that across
  rows; the writer (editor discipline, seed script, REST client) must.
- The database-backed selection components list at most **100** rows; above that the ODFS
  recommends `FS_INDEX` with the `DatasetDataAccessPlugin`. `[odfs]`
- **Cross-schema.** All three components resolve the table template (or data source) by UID
  against the whole Template Store / Content Store, not against the schema of the form that
  contains them: a component in table template `A.x` may reference `B.y`, and so may a section
  template. `[core]` They do **not** share one plugin: the option factory, the dataset editor
  and the `DatasetDataAccessPlugin` are three implementations that share the same lower layer —
  look up the table template by UID, open its schema's session. If a table is reachable for one
  of them it is reachable for all. `[core]` (confirmed internally at FirstSpirit, 2026-09-28)
- **New datasets from the component.** Both `FS_DATASET` (`allowNew`, default yes) and
  `FS_INDEX` (the *NEW* action; a rule on `NEW` can disable it) let the editor create a dataset
  in the referenced table from inside the form. Deleting datasets from there works only in the
  Content Store; in the ContentCreator the component removes the reference, never the row.
  `[odfs]`

In Java, the table template behind a database-backed selection component is reached through
the component's option model (`TableTemplateProvider`), not through the entity — the entity
type name is not unique across table templates. Worked example: `firstspirit-api-reference`,
values and data.

## FS_DATASET as a foreign key (table template)

In a table template `FS_DATASET` **must** be linked with a foreign key: the table that carries
the component is table A of a **1:N** relation to table B, and exactly **one** `<CONTENT>` may be
given. `[odfs]`

```xml
<!-- table template Products.products: the product belongs to one category -->
<FS_DATASET name="tt_category" allowChoose="yes" allowNew="no" useLanguages="no">
  <LANGINFOS>
    <LANGINFO lang="*" label="Category"/>
  </LANGINFOS>
  <SOURCES>
    <CONTENT name="product_categories"/>   <!-- data source uid, exactly one -->
  </SOURCES>
</FS_DATASET>
```

On the *Mapping* tab the component is mapped onto the relation `products → product_categories`,
not onto a typed column. `[odfs]` The linked row's columns can then be used in expressions of
the form (rules, snippets) and the relation is what a query joins on. `[odfs]`

## Queries

- A query is a **child of a schema** and operates on that schema's session: it can filter,
  sort and join (`<SUBSELECT>`) only entity types of **its own schema**; a foreign entity type is
  rejected when the query is parsed ("The schema … doesn't contain the entity type …").
  `[core]` `[odfs]` So: components may reference across schemas, joins may not.
- Queries are defined in the Template Store (schema → *New → Create query*; Wizard mode or XML),
  inline in the `contentSelect` header function (`schema` + `<QUERY entityType="…">`, or
  `queryUid="Schema.query"`), and inside `FS_INDEX` / `CMS_INCLUDE_OPTIONS type="database"`
  (`<QUERY name="…"><PARAM …/></QUERY>`). `[odfs]`
- **Parameters** are set on the query's *Parameters* tab, per `<PARAM>` in the form, and for
  content projection on the *Data* tab of the page reference. A rule can set a query parameter
  of a database-backed selection at runtime (`<PROPERTY source="st_dish" name="query.supplier_id"/>`
  — `rules/value-manipulation.md`). `[odfs]`
- Content projection filters and sorts its datasets with a query (*Filtering configuration*):
  `templates/content-projection.md`. `[odfs]`

## Remote Data (one source project, read-only copies)

- Content is edited in **one source project** and read in target projects: the schema is
  stored in the source project's **standard database layer**; in every other project that layer
  is configured **read-only** with *No schema sync*. `[odfs]`
- The target project **imports** the schema (SiteArchitect): schema and table templates are
  copied and cannot be edited there. Then a data source is created from the imported schema with
  **the same reference name** as in the source project; search index and reference graph are
  re-initialised. `[odfs]`
- Content changes propagate automatically; **structural** changes to the schema (new table,
  new column) are adjusted manually in every target project. `[odfs]`
- **Same server only.** Remote projects are projects "located on the same FirstSpirit server"
  `[odfs]`; the remote-project configuration has a project name, a login and the *use remote
  schemata* switch, but no host or URL field. `[core]`
- A component in the target project addresses the imported data source exactly like a local
  one. The ODFS calls the source the "source of truth", not a master schema. `[odfs]`

## Deleting

- **Never force-delete a table template.** The normal delete refuses while a data source
  references the template (the check reports the incoming reference and skips the element; it
  has been in the server since 2007). A delete that *ignores incoming references* removes the
  template anyway, and the data source is left pointing at nothing: every access throws
  `ReferenceNotFoundException`, nothing cascades. `[core]` Unlike a dangling reference elsewhere
  (which only fails at generation or in the preview), this **breaks the data source itself**, and
  creating a new table template under the same name does **not** repair it — the data source
  stays broken and is hard to fix. Either keep the template, or delete in the right order: the
  data source first, then the table template (confirmed internally at FirstSpirit, 2026-09-28).
- Deleting a **table** in the schema editor is immediate and without confirmation; table
  templates and queries on that table must be adapted by hand. `[odfs]`
- Deleting a dataset with a foreign-key *Aggregation* deletes the linked datasets too. `[odfs]`

## Entity and Dataset

Two Access API interfaces, both usable in the template language with their documented methods
(long form `x.getValue("name")` or bean short form `x.name`; the ODFS *Data types* pages for
`Entity` and `DatasetContainer` list them):

- **`Entity`** (`de.espirit.or.schema.Entity`) is **what is stored in the database**: a
  `Map<String,Object>` of column values with `getValue` / `setValue`, `getGid()`, `getKeyValue()`,
  `isReleased()`. It is the same row an external application sees when the schema sits on an
  external database layer — nothing FirstSpirit-specific beyond `fs_id` / `FS_GID`. `[jar]`
- **`Dataset`** (`de.espirit.firstspirit.access.store.contentstore.Dataset`) is **what
  FirstSpirit holds around the row**: the Content Store element with its table template, the
  form data mapped from the entity, revisions, and release state per language
  (`getReleaseRevision(Language)`; `Content2.release(Entity, String)`). `getEntity()` returns the
  row, `getParent()` the data source. `[jar]` `[core]`
- Scripts change values through the dataset's form data and save the dataset, so that mapping,
  language columns, revisions and release state stay consistent; writing the entity directly
  bypasses the form and leaves no FirstSpirit revision (`firstspirit-scripting`, datasets persist
  only changed values). `[jar]`

## Where the rest lives

- Output side: `templates/content-projection.md` (`#row`, entries per page, detail pages,
  `contentId`), `templates/system-objects.md` (`#global.dataset`), `templates/real-world.md`
  (`contentSelect`).
- Form syntax of the components: `selection-inputs.md`, `references-links.md`,
  `catalogs-indexes.md`; datatypes in the output channel: `../datatypes.md`.
- Which relation to model with which component, key uniqueness, ordering, language per column:
  `firstspirit-template-design` principle 11.
- Datasets in CaaS (`DatasetReference`, `routes`): the FirstSpirit headless delivery documentation (CaaS, TPP).
