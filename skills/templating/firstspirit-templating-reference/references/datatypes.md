# Datatypes: GOM component → datatype → output access

The spine of this reference. Each input component **stores** a specific datatype; the datatype
decides how you read it in the output channel and what methods are available. Use this table to
go from *a component in a form* (or in a sync export) to *how its value is accessed*.

## How to read this

- Access is through `$CMS_VALUE(identifier)$`, or `$CMS_VALUE(identifier.method)$` to call a
  method on the returned object. The table shows the **canonical** access; components with more
  than one idiom or a null/DB nuance have a fuller entry under **Access notes**.
- **Method names are Java and case-sensitive** (`getLabel`, `format`, `isEmpty`) — spell them
  exactly. Keyword casing *inside* `$CMS_…$` tags does not matter; GOM form-XML attribute values
  are lowercase by SiteArchitect default. See `identifiers-and-casing.md`.
- Deprecated components are marked → see `deprecated.md`.
- **Classic vs headless.** The canonical access is the classic HTML output channel. In a **headless
  (CaaS) project** the rendered channel is `ChannelSource_CaaS_CaaS.json` (same template language,
  different template set) and many components are serialised generically (`$CMS_VALUE(json(#this))$`)
  rather than accessed field-by-field — so an idiom being absent from a headless project does not
  make it wrong. Notes below flag which idioms the (headless) reference projects do and don't corroborate.

## Mapping

| GOM component | Stored datatype | Canonical output access | Notes |
|---|---|---|---|
| `CMS_INPUT_TEXT` | `String` | `$CMS_VALUE(st_x)$` | single-line text |
| `CMS_INPUT_TEXTAREA` | `String` | `$CMS_VALUE(st_x)$` | multi-line, plain text |
| `CMS_INPUT_DOM` | `DomElement` | `$CMS_VALUE(st_x)$` | renders HTML via the assigned format templates; `st_x.toText(false)` = plain text, `st_x.toText(true)` = HTML; `st_x.normalize` fixes list/table nesting |
| `CMS_INPUT_DOMTABLE` | `Table` | `$CMS_VALUE(st_x)$` | DOM table |
| `CMS_INPUT_NUMBER` | `Number` (`Long`/`Double` per `type`) | `$CMS_VALUE(st_x)$` | arithmetic; display format via `<LANGINFO format="…">` |
| `CMS_INPUT_DATE` | `GregorianCalendar` | `$CMS_VALUE(st_x.format("dd.MM.yyyy"))$` | `.format(pattern)` for display; `.after`/`.before` for comparison |
| `CMS_INPUT_TOGGLE` | `Boolean` (`true`/`false`/**`null`**) | `$CMS_IF(!st_x.isEmpty && st_x)$…$CMS_END_IF$` | **guard `null` first** — see notes |
| `CMS_INPUT_RADIOBUTTON` | `Option` | `$CMS_VALUE(st_x)$` (plain list) · `$CMS_VALUE(st_x.value)$` (DB) | plain option list: access directly; DB-connected: key column / `fs_id` — see notes |
| `CMS_INPUT_COMBOBOX` | `Option` | `$CMS_VALUE(st_x)$` (plain list) · `$CMS_VALUE(st_x.value)$` (DB) | as radiobutton — see notes |
| `CMS_INPUT_CHECKBOX` | `Set<Option>` | `$CMS_FOR(opt, st_x)$$CMS_VALUE(opt.value)$$CMS_END_FOR$` | set of options; same DB nuance per option — see notes |
| `CMS_INPUT_LINK` | `Link` | `$CMS_VALUE(st_x)$` | output is whatever the **link template** used here produces |
| `FS_REFERENCE` | `TargetReference` | `$CMS_REF(st_x)$` | `$CMS_REF$` resolves URL/link (media: `resolution:"…"`, `abs:1` — see notes); `$CMS_VALUE(st_x)$` gives the object, `st_x.get` the referenced element (`IDProvider`) |
| `FS_CATALOG` | `CatalogAccessor` / `Catalog<Catalog$Card>` | per item: `$CMS_FOR(item, st_x)$$CMS_VALUE(item)$$CMS_END_FOR$` · or `st_x.getItems().get(n)` | has an included section/link `<TEMPLATE>`, so each card can render itself — see notes |
| `CMS_INPUT_LIST` | `Set<Option>` | `$CMS_VALUE(st_x)$` | **legacy** (prefer `FS_CATALOG`/`FS_INDEX`); renders via included template, or loop — see notes |
| `FS_INDEX` | `Index<Index$Record>` | `$CMS_VALUE(st_x.values.first.<field>)$` · loop `st_x.values` | records reached via `.values`; **no included template → bare `$CMS_VALUE(st_x)$` does not render it** — see notes |
| `FS_DATASET` | `DatasetContainer` | `$CMS_VALUE(st_x)$` | one referenced dataset; fields reached through the container (in scripts: `getData()` / entity access) |
| `CMS_INPUT_IMAGEMAP` | `MappingMedium` | `$CMS_FOR(for_area, st_x.areas)$…$CMS_END_FOR$` | **loop over `.areas`** — see notes |
| `CMS_INPUT_PERMISSION` | `Permissions` | (permission checks) | access-control object, not typical output |
| `CMS_INPUT_SECTIONLIST` | `List<SectionListEntry>` | `$CMS_FOR(entry, st_x)$…$CMS_END_FOR$` | in-page section navigation |
| `FS_BUTTON` | *(no stored value)* | two use cases — see notes | form action (no output) **or** preview action (`fsbutton(...)` in ContentCreator) |

## Access notes

### Toggle — guard `null`

A toggle is three-state: `true`, `false`, or **`null`** when it was never touched, has no default,
and the component uses `preset="copy"`. A bare `$CMS_IF(st_x)$` breaks on `null`, so check
`isEmpty` first (the `&&` short-circuits before the boolean is evaluated):

```
$CMS_IF(!st_x.isEmpty && st_x)$…$CMS_END_IF$      $-- nullable toggle (preset="copy") --$
$CMS_IF(st_x)$…$CMS_END_IF$                        $-- two-state toggle that can't be null --$
```

The bare form is fine — and is what the reference projects use — when the toggle carries a default
or is otherwise never `null` (e.g. `type="radio"`/`type="checkbox"` with a preset). Use the
null-safe guard whenever the field can be `null`.

### Selection inputs (radiobutton, combobox, checkbox) — value and DB keys

**Plain option list** (`<ENTRIES>` in the GOM, no database) — the field yields the selected
option; you can output it directly, or read the entry's `.value` / `.key` explicitly:

```
$CMS_VALUE(st_x)$                          $-- output: yields the option's stored value string --$
$CMS_VALUE(st_x, default:"left")$          $-- with a fallback --$
$CMS_IF(st_x.value == "image")$…$CMS_END_IF$   $-- .value = entry value; .key = entry key --$
```

Both forms appear in the reference projects (`$CMS_VALUE(st_picturePosition, default:"left")$`
used directly; `media.value` / `st_sortingOrder.key` in expressions). For a **plain** list `.value`
is just the entry's value string — the database resolution below is a separate case.

**Database-connected** (`CMS_INCLUDE_OPTIONS type="database"`) — reach the row through `.value`:

- The selected option's value object is `st_x.value` (for a checkbox, iterate the set: `$CMS_FOR(opt, st_x)$$CMS_VALUE(opt.value)$$CMS_END_FOR$`).
- If `<key>key_column</key>` is set, that column is reachable directly: `$CMS_VALUE(st_x.key_column)$`.
- The default key is `fs_id`, reached via the value object: `$CMS_VALUE(st_x.value.id)$`.

*(The DB-connected idioms are production knowledge; the reference projects contain no
DB-connected selection input, so only the plain-list form above is corroborated there.)*

### FS_CATALOG / CMS_INPUT_LIST — per-item rendering

An `FS_CATALOG` carries an included `<TEMPLATE>` (its section or link template), so **each card
renders itself**. Reach the cards two ways — a loop, or an indexed accessor:

```
$CMS_FOR(item, st_x)$$CMS_VALUE(item)$$CMS_END_FOR$        $-- render each card via its template --$
$CMS_VALUE(if(!st_x.isEmpty, st_x.getItems().get(0)))$     $-- one card by index --$
```

`$CMS_VALUE(item)$` renders that card through its included template; `item.template.uid`
identifies which section template. A bare `$CMS_VALUE(st_x)$` over the whole catalog is a classic-
HTML idiom that the (headless) reference projects do not exercise — in a headless project the
catalog is serialised to CaaS JSON instead (`$CMS_VALUE(json(#this))$`).

### FS_INDEX — reach records through `.values` (conflict resolved)

An `FS_INDEX` has a `<SOURCE name="…DataAccessPlugin"/>` but **no `<TEMPLATE>`**, so — unlike
`FS_CATALOG` — there is no included template and a bare `$CMS_VALUE(st_x)$` does **not** render it.
Navigate into the record set instead: `.values` yields the records; take one with `.first` (FS
idiom) or `.iterator.next` (Java idiom); read fields off the record. Guard with `.isEmpty()`.

```
$CMS_IF(!st_x.isEmpty())$
  $CMS_SET(rec, st_x.values.first)$
  $CMS_VALUE(rec.id)$                          $-- a field property --$
  $CMS_VALUE(rec.getValueMap().get("code"))$   $-- a field by key --$
$CMS_END_IF$
```

For a Connect-for-Commerce index the record exposes `.entity`, whose fields follow
(`rec.entity.name`, `rec.entity.teaser_image`). An index can also be passed whole into a format
template that does the `.values` navigation itself: `$CMS_RENDER(template:"product_link_render", prodRef:lt_x)$`.

**The exact accessor depends on the DAP.** Dataset-backed indexes (`DatasetDataAccessPlugin`) and
some commerce DAPs use `.values.first` / `.values[n]` + `.entity`. Others expose the external key
through **`.identifiers`** and index the record set positionally:

```
$CMS_VALUE(st_product.identifiers[0])$      $-- external key (e.g. a Spryker SKU); .identifiers.get(0) works too --$
$CMS_VALUE(st_category.values[0].getNodeId)$ $-- positional record + a record method --$
```

So check the DAP: `.values.first.<field>` is the common shape, but commerce DAPs may want
`.identifiers[n]` (the external id) or `.values[n].<method>`. Guard with `.isEmpty()`.

This resolves the earlier `$CMS_VALUE` vs `$CMS_FOR` question: it is **neither** — the migration
doc was right that bare-value rendering is unsupported, but the real access is `.values.first`, not
a blanket loop. Verified across 16 `FS_INDEX` uses in the Connect-for-Commerce and SAP-Commerce
reference projects. Note those all use **commerce/external DAPs**, not `DatasetDataAccessPlugin`.

### Imagemap — loop over areas

```
$CMS_FOR(for_area, st_x.areas)$…$CMS_END_FOR$
```

*(Classic-HTML idiom; the one imagemap in the reference projects renders headless — its HTML
channel is empty and it is serialised to CaaS — so `.areas` iteration is not corroborated there.
Field-level accessors seen on the value are `.media`, `.media.filename`, `.empty`.)*

### FS_REFERENCE — `$CMS_REF$` and its parameters

`$CMS_REF(st_x)$` resolves the target to a URL. For a **media** reference, pass the rendition and
absolute-URL flags — the reference projects always do:

```
<img src="$CMS_REF(st_x, resolution:"BANNER_BIG", abs:1)$">
```

- `resolution:"<name>"` — the media resolution/rendition to emit (project-defined; `ORIGINAL` is the untouched upload).
- `abs:1` — absolute URL (default is project-relative).

To resolve a **page** reference by UID: `$CMS_REF(pageref:ps_detailpage.getUid())$` (add
`contentId:` for a dataset detail page). A reference can also be handed to a format template for
resolution: `$CMS_RENDER(template:"internal_link_render", ref:lt_pageRef)$`, which then reads
`ref.getPageRef().getPage()…` off it. Guard a reference with `!st_x.isEmpty()`.

### Guarding and preview hooks

- **Null/empty guards differ by type:** `CMS_INPUT_LINK` → `!st_x.isNull()`; `FS_REFERENCE` / `FS_INDEX` / `FS_CATALOG` → `!st_x.isEmpty()`. `.isEmpty` and `.isEmpty()` (with parens) are both accepted.
- **ContentCreator/TPP inline-edit hooks** appear alongside edited values: `previewId(element:st_x)` (emit as a `data-preview-id`) and `editorId(reloadPreview:true)`. These are the headless-preview counterparts to `fsbutton(...)`; detail belongs to the FirstSpirit headless delivery documentation (CaaS, TPP).

### FS_BUTTON — two use cases

1. **Action on the form** (editor triggers it in the input mask) → produces **no output**.
2. **Action in the preview** (editor triggers it in ContentCreator) → emit a `fsbutton(...)`
   inside a WebEdit guard:

```
$CMS_IF(#global.is("WEBEDIT"))$
<section $CMS_VALUE(
  fsbutton(
    editorName:"pt_createSection",
    parameter:{
      "page":#global.page.id,
      "body":"content"
    }
  )
)$></section>
$CMS_END_IF$
```

## Deprecated / removed — do not map to these

| Component | Status | Use instead |
|---|---|---|
| `FS_LIST` | removed (deprecated v5.2R3, discontinued Jan 2020) | by type — see `deprecated.md` |
| `CMS_INPUT_PICTURE` | deprecated | `FS_REFERENCE` with a `picture` filter |

## Sources

Datatypes verified against the GOM component definitions (`Returns`) and the source datatype pages under
`_source/…/template-syntax/data-types/`. Access idioms reflect production usage (Manon) where the
source pages were thin or stale, and were cross-checked against three official e-Spirit reference
projects (Connect for Commerce, SAP Commerce Cloud / ContentConnect, COMS Marketplace) — all
headless/CaaS, deploying without errors. Where an idiom is corroborated or, conversely, not
exercised by that (headless) corpus, the notes say so. For the full method list of a datatype, read
its source page; for component attributes and form examples, read the matching `gom/*.md` file.
