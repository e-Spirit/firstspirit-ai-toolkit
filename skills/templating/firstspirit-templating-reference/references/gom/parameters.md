# GOM: parameters by component, and whether to use them

Not every parameter exists on every component. This table answers "can I set X on this component?"
and "should I?". Source: the ODFS page of each component, FirstSpirit 2026.11 `[odfs]`. Defaults are the
documented ones; "since" is given only where it matters. For syntax and examples see the component files in
this folder; `structure.md` lists the attributes most components share.

**How to read "Recommendation".** *Documented* means the ODFS page says it. *Portfolio* means the advice
comes from the template-design principles, not from the component page. *No statement* means the page neither
recommends nor discourages it, which is not a recommendation to use it.

Component names are shortened: TEXT, TEXTAREA, DOM, DOMTABLE, DATE, TOGGLE, RADIO, COMBO, CHECK, LIST, LINK,
NUMBER, PERM = `CMS_INPUT_*`; REF, CAT, IDX, DS, BTN = `FS_REFERENCE`, `FS_CATALOG`, `FS_INDEX`, `FS_DATASET`,
`FS_BUTTON`. `CMS_INPUT_SECTIONLIST` is in `catalogs-indexes.md` (it takes `name`, `hidden`, `preset`,
`searchRelevancy`).

## Availability matrix

`x` = the parameter exists on the component, `–` = it does not. `name` is mandatory everywhere; `group` is
mandatory on PERM. Component columns as in the abbreviations above. Read from the ODFS component pages `[odfs]` FirstSpirit 2026.11; ordered by how many
components share the parameter.

| Parameter | TEXT | TEXTAREA | DOM | DOMTABLE | DATE | TOGGLE | RADIO | COMBO | CHECK | LIST | LINK | NUMBER | PERM | REF | CAT | IDX | DS | BTN |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `hidden` | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x |
| `preset` | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x |
| `searchRelevancy` | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | x | – |
| `useLanguages` | x | x | x | x | x | x | x | x | x | x | x | x | – | x | x | x | x | x |
| `convertEntities` | x | x | – | – | x | x | x | x | x | x | x | x | x | x | x | x | x | x |
| `hFill` | x | x | x | x | x | x | x | x | x | x | x | x | x | x | – | – | x | x |
| `allowEmpty` | x | x | x | x | x | x | x | x | x | x | x | x | x | x | – | – | x | – |
| `noBreak` | x | x | – | – | x | x | x | x | x | x | – | x | x | x | – | – | x | x |
| `length` | x | x | – | – | – | – | – | x | – | x | – | x | – | – | – | – | – | – |
| `singleLine` | x | – | – | – | x | x | – | x | – | – | – | x | – | – | – | – | – | – |
| `height` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | x | x | x | – |
| `sortOrder` | – | – | – | – | – | – | x | x | x | x | – | – | – | – | – | – | – | – |
| `editable` | x | – | – | – | – | – | – | x | – | – | – | x | – | – | – | – | – | – |
| `mode` | – | – | – | – | x | – | – | – | – | – | x | – | – | – | – | – | x | – |
| `rows` | – | x | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `bold` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `develop` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `enableImport` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `gridHeight` | – | – | – | – | – | – | x | – | x | – | – | – | – | – | – | – | – | – |
| `gridWidth` | – | – | – | – | – | – | x | – | x | – | – | – | – | – | – | – | – | – |
| `importRuleset` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `indexTreatment` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | x | – |
| `italic` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `list` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `listConfig` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `listDefaultConfig` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `maxInputLength` | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `onClick` | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | x |
| `type` | – | – | – | – | – | x | – | – | – | – | – | x | – | – | – | – | – | – |
| `viewMode` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | x | – | – |
| `width` | – | – | x | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `allowChoose` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – |
| `allowDelete` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – |
| `allowEdit` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – |
| `allowInput` | – | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `allowNew` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – |
| `alwaysEnabled` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x |
| `autoSave` | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – |
| `columnChange` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `columns` | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `combine` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `forbidPolyglotDataHierarchy` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – |
| `group` | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – |
| `hideLabel` | – | – | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – |
| `icon` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x |
| `imagePreview` | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – |
| `import` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `max` | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – | – |
| `maxCharacters` | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `min` | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – | – |
| `onDrop` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x |
| `onLoad` | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – |
| `onSave` | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – |
| `password` | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `priority` | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – | – |
| `properties` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `propertyConfig` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `rowChange` | – | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `sections` | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – |
| `selectorMode` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – |
| `style` | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | x |
| `table` | – | – | x | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| `upload` | – | – | – | – | – | – | – | – | – | – | – | – | – | x | – | – | – | – |
| `name` | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) | x (req.) |

## Shared parameters

| Parameter | Default | On | Not on | Recommendation |
|---|---|---|---|---|
| `name` | none, mandatory | all in the matrix | | Documented: the variable name used in templates. |
| `hidden` | NO | all in the matrix | | No statement. |
| `preset` | DEFAULT | all in the matrix | | Documented (PERM): default values are not recommended, display and output can differ. `COPY` copies the entered value so later changes to the default have no effect; the field then also counts as filled (`.isEmpty` is false), so a guard on `isEmpty` no longer catches it (practice, `[verify]`). |
| `searchRelevancy` | DEFAULT | all in the matrix | BTN | Documented: `NONE` is not indexed, but a value that also appears in a snippet header field is still found. A change reaches existing elements only after they are edited or the index is rebuilt; a rebuild is resource-intensive, schedule it for maintenance. |
| `useLanguages` | YES | all in the matrix | PERM | Documented on every page: from 5.2R5 `YES` may no longer be evaluated. The concern is nested language dependence inside `FS_CATALOG` (see `forbidPolyglotDataHierarchy`); it is not a reason to set `NO` in general, which would leave the field untranslated. Decide language dependence per field (`localisation.md` in template-design). |
| `allowEmpty` | YES | TEXT TEXTAREA DOM DOMTABLE DATE TOGGLE RADIO COMBO CHECK LIST LINK NUMBER PERM REF DS | CAT IDX BTN | Portfolio: use validation rules for required fields, not `allowEmpty="NO"`, so the level (INFO, RELEASE, SAVE) can be chosen. The ODFS describes `NO` as making the component mandatory. |
| `convertEntities` | NONE | TEXT TEXTAREA DATE TOGGLE RADIO COMBO CHECK LIST LINK NUMBER PERM REF CAT IDX DS BTN | DOM DOMTABLE | No statement (`STANDARD` and `QUOTE` apply the project's convert and quote rules). |
| `hFill` | NO | all in the matrix | CAT IDX | No statement. Has no effect in ContentCreator (practice, `[verify]`). |
| `noBreak` | NO | TEXT TEXTAREA DATE TOGGLE RADIO COMBO CHECK LIST NUMBER PERM REF DS BTN | DOM DOMTABLE LINK CAT IDX | No statement. |
| `singleLine` | TEXT TOGGLE COMBO NUMBER YES, DATE NO | TEXT DATE TOGGLE COMBO NUMBER | the rest | Documented: set `NO` for a uniform layout across components (TEXT, TOGGLE, COMBO, NUMBER). Has no effect in ContentCreator (practice, `[verify]`). |
| `length` | none; COMBO and LIST 20 | TEXT TEXTAREA COMBO LIST NUMBER | the rest | No statement. COMBO: no effect with `hFill`. DATE takes `length` on its `LANGINFO`. |
| `editable` | TEXT NUMBER YES, COMBO NO | TEXT COMBO NUMBER | the rest | Portfolio: lock a field with an editability rule, as with `allowEmpty`: better control and an own message for the editor (practice, `[verify]`). COMBO: with `YES` a typed value is stored in that component only; with `NO` the `label` is used. |

## Text, rich text, tables

| Parameter | Default | On | Recommendation |
|---|---|---|---|
| `maxInputLength` | none | TEXT TEXTAREA | Documented: lowering it later deletes the excess characters of existing values when an editor opens them. Portfolio: limit the length with a validation rule instead: better control over the level and an own message for the editor (practice, `[verify]`). |
| `password` | PLAIN | TEXT | Documented: `HASH` stores a base64 SHA value; `HIDDEN` stores plain text. Both mask the display. |
| `columns` `rows` | 20, 4 | TEXTAREA (`rows` also DOM, DOMTABLE) | No statement. |
| `width` | none | DOM DOMTABLE | Documented: ignored when `hFill` is set. |
| `maxCharacters` | none | DOM | No statement. |
| `bold` `italic` `list` | YES | DOM DOMTABLE | No statement. Switch off what the design has no format template for (see `cutting-an-artifact.md`). |
| `table` | NO | DOM | No statement. |
| `listConfig` `listDefaultConfig` | none | DOM DOMTABLE | Documented: only text is fully supported in ContentCreator. |
| `enableImport` `importRuleset` | NO, none | DOM DOMTABLE | Documented: needs a valid OfficeConnect licence; the rule set is evaluated only if the import is enabled. |
| `develop` | NO | DOM DOMTABLE | Debug output to the Java console; not for finished templates (portfolio). |
| `columnChange` `rowChange` `combine` `import` `properties` `propertyConfig` `height` | YES (`import` NO), `height` 6 | DOMTABLE | Documented: section format templates cannot be used in a table; character format templates, link templates and lists can. |
| child `FORMATS` / `TEMPLATE` | all format templates | DOM DOMTABLE | Restrict to the formats the design uses. If omitted, all project format templates are usable. |
| child `LINKEDITORS` / `LINKEDITOR` | all link templates | DOM DOMTABLE LINK | `<LINKEDITOR name=""/>` hides the link icon. If omitted, all link templates are usable. |

Component-level advice from the pages: TEXTAREA gives editors no formatting choice, use DOM for formatted
text. DOM and DOMTABLE are supported in ContentCreator
with restrictions.

## Date, number, toggle

| Parameter | Default | On | Recommendation |
|---|---|---|---|
| `mode` | DATETIME | DATE (DATE, TIME, DATETIME) | Documented: values are stored in UTC and shown in the client time zone; preview and generation use the server time zone. Changing the mode resets the unselected part. A table template column of type Date cannot use the date or time modes. |
| `allowInput` | NO | DATE | Documented: manual entries must match the format; not possible in ContentCreator. |
| `format` (on `LANGINFO`) | DATE `dd.MM.yyyy, HH:mm` | DATE NUMBER | NUMBER: applies a decimal separator only with `type="DOUBLE"`; an invalid pattern prevents saving the template. |
| `type` | NUMBER LONG; TOGGLE CHECKBOX | NUMBER, TOGGLE | TOGGLE returns Boolean; before the first choice the value is `null`, guard it (see `datatypes.md`). |
| `min` `max` | none | NUMBER | Documented: out-of-range values produce a note, they do not block input. Use a rule when the limit must hold. |
| `hideLabel` | NO | TOGGLE | Documented: use only with the radio display type. |
| child `ON` / `OFF` | | TOGGLE | Labels for the two states; useful with the radio type. |

## Selection

| Parameter | Default | On | Recommendation |
|---|---|---|---|
| `ENTRIES` / `ENTRY value` | | RADIO COMBO CHECK LIST | Documented: each `value` unique within `ENTRIES`. Entries can come from a database via `CMS_INCLUDE_OPTIONS`. |
| `sortOrder` | KEEP_ORDER | RADIO COMBO CHECK LIST | Documented: use `ASCENDING` or `DESCENDING`, especially for database entries. LIST output follows the form order; editors cannot change it. |
| `gridWidth` `gridHeight` | 2, none | RADIO CHECK | Documented: `gridHeight` wins when both are set. |
| entry `ignore` (on `LANGINFO`) | NO | RADIO COMBO CHECK LIST | Hides an entry in that language. |

Choosing between them: COMBO for more than four options, CHECK (or LIST) when several may be selected, LIST
shows at most 100 entries; above that use `FS_INDEX` `[odfs]`.

## References, links, catalogs, datasets, buttons, permissions

| Parameter | Default | On | Recommendation |
|---|---|---|---|
| `mode` | LINK DIALOG; DS DIALOG | LINK (DIALOG, INLINE), DS (DIALOG, SHEET, COMBOBOX) | LINK: the default matches the behaviour before FirstSpirit 5.0. DS: affects SiteArchitect only. |
| `imagePreview` `upload` `sections` | YES, NO, YES | REF | Documented: `upload` needs `uploadFolder` on the source; ContentCreator can upload only into folders where selection is allowed. |
| child `FILTER` (`ALLOW` / `HIDE`) | | REF | Documented: `ALLOW` wins over `HIDE`; use each type once. Portfolio: always filter, so only valid objects are offered. |
| child `PROJECTS` / `SOURCES` / `FOLDER` | | REF | Documented: remote and category sources need the licence for remote media access. |
| `viewMode` `height` | DETAILS, 4 | CAT IDX (`height` also DOMTABLE 6, DS 500 pixels) | No statement. |
| child `TEMPLATES type` / `TEMPLATE uid` | | CAT (type SECTION or LINK) | Documented: if no `TEMPLATE` is listed, all templates of that type are selectable. Restrict them. |
| `forbidPolyglotDataHierarchy` | NO | CAT (since 5.2.510) | Documented: `YES` risks data loss if existing content is not checked and backed up first; migration happens on save. Not recommended for existing content without that. |
| child `SOURCE` | | IDX | Documented: mandatory. The dataset plugin needs datasets with a GID; each element can be added once; the `ADD` rule is ignored in the ContentCreator preview, enforce a limit with a save rule. |
| `indexTreatment` | DEFAULT | IDX DS | Documented: `FOLLOW` can only extend the indexing path, never limit it, and must be set in every table along the path. |
| `allowChoose` `allowNew` `allowEdit` `allowDelete` | YES | DS | Documented: deleting is not supported in the page store; not stated to apply in ContentCreator. Portfolio: control what editors may do with rules, for the same reasons (practice, `[verify]`). |
| `selectorMode` | DIALOG | DS (DIALOG, LIST) | SiteArchitect only. |
| child `SOURCES` / `CONTENT`, `VIEWORDER`, `LEGACYTEMPLATE` | | DS | `LEGACYTEMPLATE` is only for migrating from `CMS_INPUT_OBJECTCHOOSER`; leave it out of new components. |
| `onClick` `onDrop` `icon` `style` `alwaysEnabled`, child `PARAMS`, `DROPTYPES` | | BTN | Documented: one of `onClick` or `onDrop` must be set; a referenced class implements `de.espirit.firstspirit.access.script.Executable`. |
| `group` `priority` `autoSave` `onClick` `onLoad` `onSave`, child `ACTIVITIES` | | PERM | `group` is mandatory. See the entry in `references-links.md`. |

## Statements on every component page

- A `*` fallback `LANGINFO` was required up to 4.2R2; from 4.2R4 it can be omitted and the first defined
  language becomes the fallback. Identical `LANGINFO` definitions are merged on save.
- Language codes in `lang` accept `-`, `_`, digits and letters; lower case is stored as upper case.
- Components are supported in ContentCreator, some with restrictions (see the ContentCreator restrictions
  chapter of the ODFS). Check the restriction before promising an editing behaviour there.

## Not covered here

`FS_LIST` and the deprecated `CMS_INPUT_*` components (see `deprecated.md`), `CMS_INPUT_IMAGEMAP` and
`CMS_INCLUDE_OPTIONS` (see `references-links.md` and `selection-inputs.md`), and `CMS_GROUP`, `CMS_LABEL`.
The *Since* versions of individual parameters are on the ODFS pages and omitted here.
