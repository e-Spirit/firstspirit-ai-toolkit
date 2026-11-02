# The lean JSON format

The lean JSON is Caastomize's default format: what `leanJSON` holds before a template
reshapes it, and what a document looks like when the body is the default
`$CMS_VALUE(leanJSON)$`. Caastomize 0.0.21, read in the source of the module and of the
library that builds the format `[core]` unless a line says otherwise; `[observed]` lines
were seen on projects running 0.0.21 on 2026-10-28 and 2026-10-29. Caastomize is a pre-release and not generally
available; the format can change before the release.

How to reshape the format, and how the channel renders it, is `lean-json-and-channel.md`.

## Key names

- Keys the format owns carry an underscore prefix at every level: documents, sections,
  catalog cards, links, reference pointers and rich-text nodes (`_id`, `_type`, `_content`,
  …).
- Content that editors maintain in form fields keeps the field's name without a prefix
  (`pt_headline`, `st_text`, `lt_text`), as do the settings an editor makes in a content
  projection (`pagination`, `ordering`).
- **We recommend the prefix for every field you add yourself** that is not maintained
  content from a form field, for example `_route`, `_navigation` or `_site`. It keeps your
  fields apart from the form fields of any template. It is a recommendation, not a
  requirement; the examples in this skill apply it throughout.

## The envelope

Envelope keys come first, then the form fields in form order, then the bodies, then
`_included`.

| Key | On | Value |
|---|---|---|
| `_id` | every document | `<gid>.<locale>`, the CaaS document id; the locale with an underscore (`de_DE`) |
| `_type` | every document | see the next table |
| `_locale` | every document except assets | the language tag with a hyphen (`de-DE`) |
| `_revision` | every document | a FirstSpirit revision id (number); on a page reference, see *`_revision`* below |
| `_pageId` | page references | the GID of the page behind the reference, without a locale |

| Element | `_type` | Holds |
|---|---|---|
| Page reference | `page:<page template uid>` | `_pageId`, the page's form fields and bodies; `_contentProjection` when it has a content projection |
| Dataset | `dataset:<schema>.<table>` | the form fields |
| Project properties | `projectSettings` | the form fields; the document id is `projectsettings.<locale>` (`setup-and-sync.md` → *Project settings*) |
| Medium | `asset` | see *References and `_included`* |

### `_revision`

- On a **page reference** it is the revision of the page reference itself, **not** of the
  page. Editing the page or one of its sections does not change it. On a dataset, the
  project settings and an asset it is the element's own revision.
- **To notice that a document was rewritten**, compare `_etag` (`delivery-in-caas.md` →
  *Reading it*, which points at the platform's description). Use it to refresh a cache or a
  preview.
- **Gaps in 0.0.21:** nothing in the document tells whether its *content* changed (a full
  sync rewrites unchanged documents with a new `_etag`); only a comparison of the content in
  FirstSpirit with the document in CaaS does. Ordering changes by revision has the same
  gap where `_etag` is not enough. To compare preview and release, read the document from
  both collections.
- **Workaround for the page's revision** `[observed]`: add it in the `CaastomizeJSON` body
  of **every** page template:

  ```
  $CMS_VALUE(leanJSON.put("_pageRevision", #global.page.revision.id))$
  ```

  After a full sync every page reference document of that template carries
  `_pageRevision`.

## Bodies and sections

- One array per page body, keyed `body:<body name>`; empty bodies are left out.
- A section is `{"_id": "<gid>", "_type": "section:<section template uid>", …form fields}`.
  Its `_id` is the GID **without** a locale; sections have no `_locale` and `_revision` of
  their own.

```json
"body:content": [
  { "_id": "<section-gid>", "_type": "section:teaser", "st_headline": "Headline" }
]
```

## Form fields

Empty fields are left out; there are no `null` values. Fields appear in form order.

| Input component | JSON |
|---|---|
| `CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA` | string |
| `CMS_INPUT_NUMBER` | number, as FirstSpirit holds it |
| `CMS_INPUT_TOGGLE` | boolean |
| `CMS_INPUT_DATE` (date) | `"yyyy-MM-dd"` |
| `CMS_INPUT_DATE` (date and time) | `"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"`, UTC |
| `CMS_INPUT_COMBOBOX`, `CMS_INPUT_RADIOBUTTON` | the option **key** as a string; a reference object (`$ref`) when the options come from a database table |
| `CMS_INPUT_CHECKBOX` | array of option keys |
| `FS_REFERENCE` | reference object to a medium or a page reference |
| `FS_DATASET` | reference object |
| `FS_INDEX` | array of reference objects (FirstSpirit's own dataset data access plugin) |
| `FS_CATALOG` | array of cards (next section) |
| `CMS_INPUT_LINK` | `{"_type": "link:<link template uid>", …link form fields}` |
| `CMS_INPUT_DOM` | rich-text object |
| `CMS_INPUT_DOMTABLE` | rich-text object around one `table` node |

### Catalog cards

Cards are shaped like sections: the card's id as `_id` and `section:<uid>` or `link:<uid>`
as `_type`, following the type of the template the card uses (one of the catalog's sources).

```json
"st_cards": [ { "_id": "…", "_type": "section:card", "ct_title": "…" } ],
"gc_links": [ { "_id": "…", "_type": "link:internal_link", "lt_link": { "$ref": "…", "_type": "page:standard" } } ]
```

## Rich text

`CMS_INPUT_DOM` and `CMS_INPUT_DOMTABLE` give `{"_type": "richtext", "_content": [ … ]}`, a
tree shaped like a ProseMirror or TipTap document with prefixed keys:

| Node | JSON |
|---|---|
| Text | `{"_type": "text", "_text": "…", "_marks": ["…"]}`; `_marks` only when the text has inline formats |
| Line break | `{"_type": "linebreak"}` |
| Paragraph (format template in paragraph mode) | `{"_type": "paragraph", "_style": "format.<uid>", "_content": […]}` |
| Inline format | no node of its own: its name is added to `_marks` of every text below it, outermost first |
| List | `{"_type": "list", "_style": …, "_listStyle": …, "_content": […]}` |
| List item | `{"_type": "listItem", "_content": […]}` |
| Table, row, cell | `table`, `tableRow`, `tableCell`, each with `_content`; merged cells appear once |
| Link | `{"_type": "link:<uid>", …link form fields, "_content": […]}`, the anchor text mirrored into `_content` |

- `_listStyle` is the style name as FirstSpirit stores it. Unordered: `bullet`, `dash`,
  `empty`, `default`, `userDefined`. Ordered: `numbered`, `alphabeticalLowercase`,
  `alphabeticalUppercase`, `romanNumbersLowercase`, `romanNumbersUppercase`.
- A list can arrive **inside** a `paragraph` node `[observed]`; render `paragraph` as a
  block element that may contain a list, not as `<p>`.
- A rich-text field without content is left out.

## References and `_included`

`FS_REFERENCE`, `FS_DATASET`, `FS_INDEX` and database options are pointers, not nested
content:

```json
"st_image": { "$ref": "<media-gid>", "_type": "asset" }
"st_category": { "$ref": "<dataset-gid>", "_type": "dataset:shop.category" }
```

- `$ref` is the plain GID **without** a locale. Append `.<locale>` to get the CaaS
  document id.
- **`_included` holds the referenced media only**, keyed by GID:
  `{"_id", "_type": "asset", "_revision", "mimeType", "width", "height", "url"}` (`width`
  and `height` for pictures, from the original resolution; `url` from the media target,
  `delivery-in-caas.md` → *Media*).
- **References to page references and datasets stay `$ref` pointers.** Read the target
  from the same collection as `<gid>.<locale>`. A copy embedded in the referencing document
  would be outdated as soon as the target changed; a pointer stays correct.
- A reference to an element that cannot be read is left out.

## Content projections

A page reference with a content projection carries `_contentProjection`, and the page body
marks where the projection sits:

```json
"_contentProjection": {
  "_type": "mapping:shop.shop.product",
  "_mode": "detail",
  "_source": "dataset:shop.product",
  "ordering": [ { "field": "tt_price", "ascending": true } ]
},
"body:content": [ { "_id": "<section-gid>", "_type": "contentProjection" } ]
```

| Key | Value |
|---|---|
| `_type` | `mapping:<schema>.<table template uid>`, the table template the datasets are shown with on this page |
| `_mode` | `detail` (one dataset per page, no page limit) or `list` |
| `_source` | the `_type` of the projected dataset documents |
| `pagination` | only for paged lists: `recordCountPerPage`, and `maxPageCount` when the number of pages is limited |
| `ordering` | the effective sort order as form fields of the dataset documents, in priority order; an ordering that maps to no form field is dropped with a warning in the server log; absent when nothing remains |

- **The query and the filter of the projection are not in the document.** In 0.0.21 the
  frontend applies the selection itself: the template developer knows which datasets the
  projection is meant to show and filters on `_type` equal to `_source` plus the fields
  that decide it (a CaaS filter; `firstspirit-headless/references/caas-platform.md`).
- Detail pages have no route per dataset; see `lean-json-and-channel.md` → *URLs and
  routes*.

## What the format leaves out

Caastomize 0.0.21 is a pre-release and not generally available. In this version:

- **Left out without a message, the document is still sent:** the input components
  `CMS_INPUT_LIST`, `CMS_INPUT_SECTIONLIST`, `CMS_INPUT_IMAGEMAP` and
  `CMS_INPUT_PERMISSION`, the components deprecated since FirstSpirit 5.0, input components
  a module registers, and references to elements that no longer exist.
- **Not part of the format:** metadata (no document has a `_meta`); a list's start number,
  custom bullet and bullet image; `FS_INDEX` with a data access plugin other than
  FirstSpirit's dataset plugin.
- **The document fails** when FirstSpirit cannot read the form, for example a
  `CMS_INCLUDE_OPTIONS type="PUBLIC"` whose class belongs to a module that is no longer
  installed. That one document is not sent; the version in CaaS stays as it was.

What the format leaves out can be added in the `CaastomizeJSON` body with `put`, or by a
body on the section or link template (`lean-json-and-channel.md`).
