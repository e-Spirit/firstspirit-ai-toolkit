# Choosing an input component

Start from what the editor has to do, then pick the component. This table maps an editor's need to the
component, says what comes back, and names the alternatives and the cases to avoid. It is the lookup for
principle 5 in `SKILL.md`. Component facts come from `components-and-tags.md` and from the ODFS pages
(FirstSpirit 2026.11) `[odfs]`; syntax, parameters and output access are in the `firstspirit-templating-reference` skill
(its `datatypes.md` and `gom/parameters.md`).

Recommendation levels: **use** means the component fits the need and nothing speaks against it; **consider**
means a close alternative exists, compare; **avoid** means the ODFS or a portfolio principle advises against it
for this need. Where the ODFS states the reason, it is tagged.

## By editorial need

| The editor has to… | Use | Returns | Consider or avoid |
|---|---|---|---|
| type a short text (title, label, alt text) | `CMS_INPUT_TEXT` | String | Set `singleLine="NO"` for a uniform layout `[odfs]`. Not for text that needs formatting. |
| type several lines of plain text | `CMS_INPUT_TEXTAREA` | String | Editors cannot choose formatting. For formatted text use `CMS_INPUT_DOM` `[odfs]`. |
| write formatted running text | `CMS_INPUT_DOM` | DomElement | Allow only the formats the design uses (`FORMATS`) and the link types it needs (`LINKEDITORS`). Output depends on format templates. |
| edit a table | `CMS_INPUT_DOMTABLE` | Table | Section format templates cannot be used in a table `[odfs]`. For structured records used in several places, use a dataset instead. |
| pick a date or a time | `CMS_INPUT_DATE` | GregorianCalendar | Stored in UTC, shown in the client time zone; check the zone when the date drives output `[odfs]`. |
| enter a number | `CMS_INPUT_NUMBER` | Long, Integer or Double | `min` and `max` only warn; use a rule if the limit must hold `[odfs]`. |
| switch something on or off | `CMS_INPUT_TOGGLE` | Boolean (or `null` before the first choice) | Guard the `null` in the output and in rules `[odfs]`. For two named alternatives, a radio button may read better `[verify]`. |
| choose exactly one of up to four options | `CMS_INPUT_RADIOBUTTON` | Option | All options are visible at once. More than four: `CMS_INPUT_COMBOBOX` `[odfs]`. |
| choose exactly one of more than four options | `CMS_INPUT_COMBOBOX` | Option | `editable="YES"` lets editors type a value that only that component stores `[odfs]`; use it only on purpose. |
| choose any number of options | `CMS_INPUT_CHECKBOX` | Set of Option | For a long list, `CMS_INPUT_LIST` (same stored type). |
| choose many of a long list | `CMS_INPUT_LIST` | Set of Option | Shows at most 100 entries; above that use `FS_INDEX` `[odfs]`. |
| give a link (internal, external, media, mail) | `CMS_INPUT_LINK` | Link | Restrict the link types with `LINKEDITORS`; the output is whatever the link template produces. |
| select a page, image, file or any store object | `FS_REFERENCE` | TargetReference | Always add a `FILTER` so only valid object types are offered; `ALLOW` wins over `HIDE` `[odfs]`. |
| upload and select an image or file in one step | `FS_REFERENCE` with `upload="YES"` | TargetReference | Needs an upload folder on the source; in ContentCreator media can only be uploaded into folders where selection is allowed `[odfs]`. |
| repeat a group of fields (cards, accordion entries) | `FS_CATALOG` of section templates | Catalog | Restrict the allowed templates; in a headless project keep the nesting flat (principles 4 and 7). Not `forbidPolyglotDataHierarchy="YES"` on existing content without a backup `[odfs]`. |
| maintain a list of links in one field | `FS_CATALOG` of link templates | Catalog | Replaces the deprecated `CMS_INPUT_LINKLIST` (`deprecated.md`). Link templates are single-language and cannot be translated, so make the catalog language-independent (`useLanguages="NO"`) and do not rely on per-language entries (practice, `[verify]`). |
| order records of a data source (related items) | `FS_INDEX` | Index of records | 1:n, editor order kept. Each element can be added once; a limit needs a save-scope rule, the `ADD` rule is ignored in the ContentCreator preview `[odfs]`. |
| choose one record of a data source | `FS_DATASET` | DatasetContainer | A relation (n:1) if the database should know the link; the column otherwise only records it for editors (see the dependency table in `components-and-tags.md`). |
| offer an in-page navigation from existing sections | `CMS_INPUT_SECTIONLIST` | List of entries (anchor name, text, section name) | Builds on sections that already exist on the page; see its entry in `firstspirit-templating-reference`. |
| run a script or a class from the form | `FS_BUTTON` | none | Either `onClick` or `onDrop` must be set; a class implements `Executable` `[odfs]`. Not for content. |
| limit who sees something | `CMS_INPUT_PERMISSION` | Permissions | User permissions, evaluated with the DynamicPersonalization tags, not editorial rights. Do not set default values `[odfs]`. |

## The output channel does not decide the component

HTML, headless and PDF output place no restriction on which component an editor uses; choose by the editor's
task. The exception is a channel with format restrictions that the editor input cannot meet: for example a
Markdown table filled from a `CMS_INPUT_DOMTABLE` can contain line breaks that break the table. Then restrict the
input at editor level (a plain field, a rule, or a format template that cleans the value) instead of changing the
component (practice, `[verify]`).

## Required fields, language dependence, layout

These apply to every row above.

- **Restrictions: use rules, not component attributes.** `allowEmpty`, `editable`, `maxInputLength` and the
  `allowChoose` / `allowNew` / `allowEdit` / `allowDelete` attributes of `FS_DATASET` are better handled by rules:
  you control the level and give the editor your own message (practice, `[verify]`).
- **Required fields: use a rule** (`INFO`, `RELEASE` or `SAVE` level), not `allowEmpty="NO"`; the level is a
  choice the project makes once (principle 6). The ODFS describes `allowEmpty="NO"` as making the component
  mandatory.
- **Language dependence per field** (`useLanguages`): `YES` for translatable content, `NO` for neutral values;
  a general `NO` would leave content untranslated. The ODFS caution on `YES` concerns nesting inside
  `FS_CATALOG` (`localisation.md`).
- **Layout**: `hFill` and `singleLine` have no effect in ContentCreator (practice, `[verify]`); they shape the
  SiteArchitect form. Use `noBreak` only for fields that belong on one line; entries and labels per language go
  through `LANGINFOS`.
- **Defaults** (`preset`) are not recommended on `CMS_INPUT_PERMISSION` `[odfs]`; elsewhere decide per field
  whether a later change of the default should reach existing content (`DEFAULT`) or not (`COPY`). A copied
  value counts as filled, so `.isEmpty` is false (practice, `[verify]`).

## Deprecated and removed: do not choose these

| Instead of | Use |
|---|---|
| `FS_LIST` (removed) | `FS_CATALOG` or `FS_INDEX` |
| `CMS_INPUT_PICTURE`, `CMS_INPUT_FILE`, `CMS_INPUT_PAGEREF` | `FS_REFERENCE` with a `FILTER` |
| `CMS_INPUT_LINKLIST`, `CMS_INPUT_CONTENTAREALIST` | `FS_CATALOG` |
| `CMS_INPUT_CONTENTLIST`, `CMS_INPUT_TABLIST` | `FS_INDEX` |
| `CMS_INPUT_OBJECTCHOOSER` | `FS_DATASET` |

The full list with versions is `deprecated.md`.

## When the need is not on the list

Ask what the editor does with the value afterwards (read it, filter on it, link to it, send it somewhere), then
choose by the datatype and dependency it should produce (`components-and-tags.md`, dependency table). If two
components fit, take the one that offers only valid choices.
