# Templates: Properties-tab switches that decide what editors see

`[odfs]` FirstSpirit 2026.5, the *Properties tab* pages of the page, link, section, format and table templates
(*Templates (basics) → Composition of templates*). Read 2026-10-30.

| Template type | Switch on the Properties tab | What it does |
|---|---|---|
| Page template | *In selection list*: show / hide | hidden, the template is not offered when an editor creates a page |
| Link template | *Hide in selection list* | hidden, the link template is not offered when a link is added to a page or a dataset |
| Section template | none | which section templates an editor may add is decided by the content areas of the page template (allowed section templates) and by the `TEMPLATES` list of an `FS_CATALOG` |
| Table template | none | offered through data sources and the `TEMPLATES` list of `FS_INDEX` / `FS_DATASET` components |
| Format template | *Section* box | checked, the format applies to the whole paragraph up to the next line break and is picked from the left-hand list of the DOM editor with nothing selected; unchecked, it applies to selected text only (details and the alignment setting: `pdf-fop.md`, *Section box*). Which formats a DOM field offers is the field's `FORMATS` list |

Also on the Properties tab of page, section and table templates: the preview image (`preview-image.md`).

Judgement (which templates to hide, what a visible technical template means in a review) is the
`firstspirit-template-design` skill's (principle 10).
