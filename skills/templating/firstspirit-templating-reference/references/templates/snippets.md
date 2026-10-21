# Snippets: thumbnail, label, extract

A snippet defines how an object (page, section, dataset, medium, link) is shown to the editor in lists, search
results, reports and selection dialogs. `[odfs]` FirstSpirit 2026.11, *Snippets*. It is set on the **Snippet tab**
of a template, with three fields. Design guidance (when and what to put there) is in the `firstspirit-template-design` skill
(its `snippets.md`).

| Field | Shows | Export file |
|---|---|---|
| Thumbnail | a representative image | `SnippetThumb.txt` |
| Label | a short title text | `SnippetHeader.txt` |
| Extract | a text excerpt | `SnippetExtract.txt` |

Each file holds one expression (no XML wrapper). Link templates have a Snippet tab as well; media use a metadata
template configured under the project settings in the ServerManager.

A snippet describes an individual object by its content. It is not the **preview image** of a template, which is shown
when the template is chosen (`preview-image.md`).

## Where it is used

- Search and the project history (the author's statement for the history, `[verify]` against the ODFS; the project
  history in ContentCreator lists changed objects with name, author and time `[observed]` 2026-10-16).
- SiteArchitect: search results, reports, selection dialogs, the display of `FS_CATALOG` link entries.
- ContentCreator: search results, reports, selection dialogs; the snippet of a link template is also the tooltip in
  `CMS_INPUT_DOM`, `CMS_INPUT_DOMTABLE` and InEdit mode.
- FragmentCreator: the fragment list; without a definition it shows the variant ID and the folder path.
- Without a definition (or with empty inputs) the object name and path are shown. Links show no tooltip in ContentCreator.

## Expression syntax

- Input components of the template by variable name (`card_title`); methods through the returned type.
- Objects referenced in input components (`lt_reference.pageRef.page.formData.pt_intro`) and media information.
- `if(cond, a, b)` for empty checks (`if(!cs_name.isEmpty, cs_name, "N/A")`), `truncate(text, 65)` for long extracts.
- `xmlEscape()` on `String` results used in label or extract: apply it to logic results so special characters become entities.
- `#form.IDENTIFIER.LANGABBREVIATION` selects a language, `#master` the master language, `#language` / `#global.language`
  the current one; `#meta.IDENTIFIER` outputs a metadata field.
- For `FS_REFERENCE` fields check the type (`elementType`, for example `"Page"` or `"PageRef"`) before reading properties.

Examples from the ODFS `[odfs]`:

```
#filename + "." + #extension + if(#mediumtype == "Picture", " (" + #resolution + "px)", "")      (medium label)
truncate(lt_reference.pageRef.page.formData.pt_intro, 65)                                          (link template extract)
```

Examples from template exports of the author's own projects `[observed]` (2026-10):

```
SnippetHeader.txt   card_title
SnippetExtract.txt  card_text
SnippetThumb.txt    card_image
SnippetHeader.txt   tt_key
SnippetExtract.txt  if(!tt_name.isEmpty, tt_name) + if(!tt_order.isEmpty, " (" + tt_order + ")")
```

## Thumbnail sources

`[odfs]` FirstSpirit 2026.11, *Snippets → Thumbnail*. The field defines the teaser image of a search hit, shown at the
right edge of the result. It can stay empty when the template has no image field.

```
st_picture                                              (image input component)
if(!st_picture.isEmpty, st_picture, st_imagemap)        (fallback to a second component)
medium("REFERENCENAME")                                 (static medium; the plain "REFERENCENAME" is equivalent)
medium("REFERENCENAME", "REMOTEPROJECTNAME")            (medium of a remote project)
if(!pt_product.isEmpty, pt_product.dataset.formData.cs_picture)   (image of a selected dataset)
```

Image components named by the page: `FS_REFERENCE` and `CMS_INPUT_IMAGEMAP`. `Entity` objects are not supported in
snippets; go through `.formData` as in the last line. List entries are usually output with `map(String)`.

## Label and extract per input component

`[odfs]` FirstSpirit 2026.11, *Snippets → Label / Extract*. Label is the title of the teaser, extract the text excerpt.
Without either, the object name and path are shown; for datasets the data source name and `#ID` (for example
`Press releases: #128`). Join parts with `+`, static text in double quotes.

| Component | Expression |
|---|---|
| `FS_CATALOG` | `field.map(x->x.getItem().field2)` (`field2` is a variable of the entry template) |
| `FS_CATALOG` (via the entries' snippets) | `field.snippets.map(x->x.header).toString(" / ")`; fields `thumbnail`, `header` (label), `extract` |
| `CMS_INPUT_CHECKBOX`, `CMS_INPUT_LIST` | values `field`; labels `field.map(x->x.label(#language)).toString(", ")` |
| `CMS_INPUT_COMBOBOX`, `CMS_INPUT_RADIOBUTTON` | value `field`; label `field.label(#language)` (also for options from a referenced table: `if(!cs_country_choice.isEmpty, cs_country_choice.label(#language))`) |
| `FS_DATASET` | `field.dataset.formData.field2` |
| `CMS_INPUT_DOM` | `field.toText(false)` |
| `FS_INDEX` | `field.values.map(x->x.formData.field2).toString(",")` (`field2` from the linked table template) |
| `CMS_INPUT_LINK` | `field.text` |
| `FS_REFERENCE` (medium or file) | `field.Media.Filename` |
| `FS_REFERENCE` (page reference) | `field.pageRef.uid`, or `field.pageRef.page.formData.field2` |

Shortening and style: `truncate(field, N)` cuts to N characters and appends `...`; `bold()` and `italic()` set the style
(bold has no effect in the label, titles are bold already); `toUpperCase`/`toLowerCase` on text components; `format` on
`CMS_INPUT_NUMBER` and `CMS_INPUT_DATE`. Limit length at the source where possible (`maxInputLength`, `maxCharacters`),
or by a rule (see `gom/parameters.md`).

```
italic(truncate(if(!pt_headline.isEmpty, pt_headline), 30) +
    if(!pt_headline.isEmpty && !pt_subheadline.isEmpty, " / ") +
truncate(if(!pt_subheadline.isEmpty, pt_subheadline), 15))
"valid " + if(cs_newsdate > #now,"from ","since ") + cs_newsdate.format("MM/dd/yy")
"Press release " + italic(#id)
```

System objects `[odfs]`:

- `#id`: dataset ID in the snippet of a table template.
- `#now`: the current date at query time.
- `#item`: the tree element, with the methods of `IDProvider`: `#item.getDisplayName(#language)`, `#item.Uid`,
  `#item.getEntity().getGid()` (tree elements that hold datasets). Not available in the Card data type, and not in
  some situations such as object creation, where an `UnsupportedOperationException` or `RuntimeException`
  ("Expression failed") is logged.

## In the API, for module development

Snippets are also what reports and the project history show, which is why the API has them; a module that supplies
its own objects (data access, reports) supplies their snippets. Checked with `javap` against 5.2.261011 `[jar]`:

- `Snippet` (`de.espirit.firstspirit.access.store.templatestore`): the three expressions as strings,
  `getThumbnail()`, `getHeader()`, `getExtract()` and the setters. `SnippetContainer` (implemented by templates):
  `getSnippet()` and `setSnippet(Snippet)`.
- `SnippetAgent` (`de.espirit.firstspirit.agency`, `SnippetAgent.TYPE`): `getSnippetProvider(IDProvider)` for an
  element, `getSnippetProvider(FormData, Snippet)` and, with a `SnippetContext`, the evaluated snippet for form data;
  `getTypeIcon(IDProvider)`. `DataSnippet` holds the evaluated result: `getThumbnail()` (an `Image`), `getHeader()`,
  `getExtract()`.
- For the objects of a module's own data source, `DataSnippetProvider<D>`
  (`de.espirit.firstspirit.client.plugin.dataaccess`): `getIcon(D)`, `getThumbnail(D, Language)`,
  `getHeader(D, Language)`, `getExtract(D, Language)`. The module side is in `firstspirit-module-development`
  (data access and reports).

## Restrictions

- Saving checks only the general syntax; a syntax error prevents saving. Variable names and whether a method fits the
  object type are not checked.
- The preview is only on the Snippet tab and needs a preview page selected in the template's properties.
- Language abbreviations used in expressions must be defined in the ServerManager under *Language templates*.
- Snippets are not created over REST `[observed]` 2026-10-16 (see `firstspirit-rest-api`).
