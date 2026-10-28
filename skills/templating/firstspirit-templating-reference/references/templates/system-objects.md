# Templates: System objects

Read-only context objects available in the output channel — the page, section, navigation,
current dataset and data-source row. Access with `$CMS_VALUE(...)$`.

---

## Page info

```
$CMS_VALUE(#global.page.id)$                                    $-- page ID --$
$CMS_VALUE(#global.page.changeDate)$                            $-- last modified --$
$CMS_VALUE(#global.page.changeDate.format("yyyy-MM-dd HH:mm"))$ $-- formatted --$
$CMS_VALUE(#global.page.editor.realname)$                       $-- last editor --$
$CMS_VALUE(#global.page.isTranslated)$                          $-- translation status --$
$CMS_VALUE(#global.page.body("content"))$                       $-- content area --$
```

## Section info

```
$CMS_VALUE(#global.section.id)$    $-- section ID --$
$CMS_VALUE(#global.section.name)$  $-- section name --$
```

## Global context

```
$CMS_VALUE(#global.node)$                   $-- current page ref --$
$CMS_VALUE(#global.language.abbreviation)$  $-- "DE", "EN" etc. --$
$CMS_VALUE(#global.isPreview())$            $-- true in preview (method) --$
$CMS_VALUE(#global.canonicalUrl)$           $-- canonical URL --$
$CMS_VALUE(#global.gca("gca_page"))$        $-- insert a Global Content Area page's output [odfs] --$
$CMS_SET(void, #global.logError("message"))$ $-- write to the generation log --$
$CMS_SET(void, #global.stopGenerate)$       $-- stop page generation (fail-fast guard) --$
```

## Global content area (GCA)

```
$CMS_VALUE(#global.gca("gca_page"))$        $-- type GCAPage; the argument is the reference name of the GCA page [odfs] --$
$CMS_VALUE(#global.page.body("content"))$   $-- type Body: a content area of the page [odfs] --$
```

`#global.gca("…")` `[odfs]` can be called from any template. The GCA page's template content is inserted at the place of the
call and that page's context starts there, so contexts nest `[odfs]`. **Design rule:** the template of the GCA holds
the output for everything it covers; the calling page template only places it. Do not loop over the GCA's form data
from the page template (the global content areas reference of the `firstspirit-template-design` skill).

Contexts and variables inside and around a GCA `[odfs]`:

| What | Behaviour |
|---|---|
| `#global.context("section")` | the **innermost** section: the GCA's section, not the section of the page it is placed on, because both contexts are named `section` |
| `#global.page.id`, `.name`, `.uid`; `#global.section.id`, `.name` | read the IDs and reference names of the current (innermost) page or section |
| variables set in a page or section template | visible in that element and everything inside it, by default not outside |
| `#global.context("PAGE")` | the way to make a variable visible to the elements outside |
| same identifier in page and GCA templates | the current element's variable wins; use unique identifiers across templates that can meet on one page |

## Dataset info (content projection / multiple pages)

```
$CMS_VALUE(#global.dataset)$               $-- current dataset --$
$CMS_VALUE(#global.dataset.webeditUrl)$    $-- ContentCreator edit link --$
$CMS_VALUE(#global.dataset.javaClientUrl)$ $-- SiteArchitect edit link --$
```

> `javaClientUrl` targets SiteArchitect; new features focus on ContentCreator, so prefer
> `webeditUrl` where you have the choice.

## Navigation

```
$CMS_VALUE(#nav.label)$          $-- menu name --$
$CMS_VALUE(#nav.id)$             $-- node id --$
$CMS_VALUE(#nav.ref.getUid())$   $-- referenced page-ref UID --$
$CMS_VALUE(#nav.levelPos)$       $-- position on its level; #nav.pos exists only in PageGroup/MenuGroup [core] --$
$CMS_VALUE(#nav.comment)$        $-- comment --$
$CMS_VALUE(#nav.isFirst)$        $-- first item? --$
$CMS_VALUE(#nav.hasSubFolders)$  $-- has children? --$
```

> `#nav.label` is user-entered — escape it against XSS when it reaches **HTML**
> (`#nav.label.convert2`); see `string-operations.md` → Output escaping. When the sink is a **JSON**
> channel (headless/CaaS), `.convert2` is the wrong escaper. Escape for the sink, not by reflex.

## Data-source rows

```
$CMS_VALUE(#row.columnName)$            $-- column value --$
$CMS_VALUE(#row.getEditor().realname)$  $-- last editor --$
$CMS_VALUE(#row.getAttributeNames())$   $-- all column names --$
```

> `#row` is the classic content-projection (dataset-page) context; a headless project projects
> datasets via `FS_INDEX` / CaaS instead, so `#row` does not appear there. How the projection
> works end to end, plus `#global.pageParams` / `#global.multiPageParams` for the generated
> pages: [content-projection.md](content-projection.md).

## The current object — `#this`

Inside a section, format template or loop, `#this` is the current object (the section, the catalog
card, the loop item). Common in id/anchor construction:

```
$CMS_VALUE(#this)$        $-- the current object --$
$CMS_VALUE(#this.id)$     $-- e.g. "teaser-" + #this.id --$
```

## FS_CATALOG item context — `#fs_catalog`, `#card`, `#index`

Inside a section or link template rendered **as an entry of an FS_CATALOG**, three system objects
describe the entry's place in the catalog `[odfs]`:

| Object | Yields | Notes |
| --- | --- | --- |
| `#fs_catalog.size` | Integer, number of entries | `#fs_catalog.isNull` is `true` when the template is rendered outside a catalog. **Not available when the catalog is output with `$CMS_FOR$`**; use the collection's own `.size` there. Never `$CMS_VALUE(#fs_catalog)$` bare: documented endless loop. |
| `#card` | the `Card` (entry) | `getId` (UUID), `getTemplate`, `getItem` (its `FormData`), `toJSON`, `isNull`. Also the loop variable name convention in `$CMS_FOR(#card, st_catalog)$`. |
| `#index` | position, 0-based | `#index.isNull` when not in a catalog; add 1 for display. |

`#index` is not catalog-specific `[core]`: the same 0-based counter is also set while a page's
sections render one by one. Inside a catalog the list object is `#fs_catalog`; prefer
`#fs_catalog` / explicit `$CMS_FOR$` counters in new templates.

Two production idioms built on them `[observed]`:

```
$-- item template adapts to how many siblings it has --$
$CMS_IF(#fs_catalog.size > 1)$ … two-column classes … $CMS_ELSE$ … single, centred … $CMS_END_IF$

$-- unique, stable DOM id per entry without a counter variable --$
<button aria-controls="faq-$CMS_VALUE(#card.getId)$">…</button>
<div id="faq-$CMS_VALUE(#card.getId)$">…</div>
```

## Format-template context (DOM rendering)

When a `CMS_INPUT_DOM` value renders through the assigned format templates, each format template
runs with its own context objects:

```
$CMS_VALUE(#content)$        $-- the content the format template wraps (its body) --$
$CMS_IF(#content.isEmpty)$…$CMS_END_IF$
$CMS_VALUE(#style)$          $-- the paragraph/inline style context; #style.isNull / .isEmpty --$
$CMS_VALUE(#cell.rowspan)$   $-- DOM-table cell: .rowspan / .colspan / .align / .color / .bgcolor --$
```

`#content` is the format template's body placeholder; `#cell` is bound in table format templates;
`#style` carries the applied style. See `dom-media.md` for how format templates style DOM output.

Lists and tables entered in `CMS_INPUT_DOM` / `CMS_INPUT_DOMTABLE` bind three more objects `[odfs]`:

```
$-- in the format templates ul and li --$
$CMS_VALUE(#list.style)$          $-- 0 paragraph indent · 1 bullet · 2 numbered · 3/4 letters lower/upper
                                     · 5/6 Roman lower/upper · 7 indent only · 8 user-defined --$
$CMS_VALUE(#list.start)$          $-- start value from listDefaultConfig; a start entered in a listConfig
                                     dialog came back only via #list.attr("start") [observed] --$
$CMS_VALUE(#list.count)$          $-- number of items; #list.count2 = start + count - 1 --$
$CMS_VALUE(#list.attr("pre"))$    $-- any field defined in listConfig, as String --$
$-- in li only --$
$CMS_VALUE(#listitem.index)$      $-- 1-based, or from #list.start when set; .indexText, .pre --$
$-- in the format templates table, tr, td and in the Table function --$
$CMS_VALUE(#table.cols)$ $CMS_VALUE(#table.rows)$ $CMS_VALUE(#table.lastCol)$ $CMS_VALUE(#table.lastRow)$
$CMS_VALUE(#cell.row)$            $-- 0-based row of the cell (.col likewise); .rowNumber / .colNumber 1-based --$
```

Two traps seen in a live FOP (PDF) template set `[observed]` (FS 5.2.261116, 2026-10-09 to 2026-10-12):

- In the `table` format template `#content` is a renderer object, not a string: `indexOf`, `substring` and the other string methods are undefined. Detect the header row in
  `tr` with a counter list (`CMS_SET` of a list shared by reference) or format it in `td` via
  `#cell.row == 0`; do not parse `#content`.
- `#list.style` is empty when the list was written as `<ol>` over the REST API; only a `<ul>` with
  list properties is a FirstSpirit list. The REST skill's *CMS_INPUT_DOM* section says how to write one.
- A `ul` format template that emits `list-style-type` as an inline `style` beats a stylesheet's
  `list-style: none` and shows a second marker beside a CSS `::before` marker; put the type in a class.
  An HTML `ul` format that does so, with `start` only for numbered types `[observed]`:

  ```
  $CMS_IF(#list.style < 2 || #list.style > 6)$<ul class="wp-list-$CMS_VALUE(#list.style)$">$CMS_VALUE(#content)$</ul>$CMS_ELSE$<ol class="wp-list-$CMS_VALUE(#list.style)$" start="$CMS_VALUE(#list.attr("start"), default:"1")$">$CMS_VALUE(#content)$</ol>$CMS_END_IF$
  ```

  Check both branches: a missing `>` in the one that did not render in your test shows up only
  with the other list type. PDF output of the same lists is in `pdf-fop.md`.

## Multiple pages — `#cs`

`#cs` is bound in **table templates used as data-source-based sections** of a page (content
projection); it describes the current sub-page of a multiple page and the current dataset in it
`[odfs]`. Other members of the same context are `#global.pageParams` and `#global.dataset`
(`content-projection.md`).

| Member | Yields | Notes |
| --- | --- | --- |
| `#cs.contentLength` | Integer | number of datasets on the current sub-page, counted from 1; same as `#global.pageParams.data.size` |
| `#cs.contentPosition` | Integer | index of the sub-page in the multiple page, from 0; same as `#global.pageParams.index` |
| `#cs.currentRowNumber` | Integer | number of the current dataset in the sub-page (the page's example adds 1 for display, so it counts from 0) |
| `#cs.dataset` | Dataset | the current dataset; for the **first** dataset of a multiple page use `#global.dataset` |
| `#cs.dataset.javaClientUrl`, `#cs.dataset.webeditUrl` | String | edit link in SiteArchitect / ContentCreator |
| `#cs.isFirstContentRow`, `#cs.isLastContentRow` | Boolean | same as `#global.pageParams.isFirst`, `.isLast` |
| `#cs.isEvenContentRow`, `#cs.isOddContentRow` | Boolean | parity of the dataset number in the sub-page |

```
$CMS_IF(#cs.isFirstContentRow)$<table>$CMS_END_IF$
<tr><td>$CMS_VALUE(#cs.currentRowNumber + 1)$/$CMS_VALUE(#cs.contentLength)$</td></tr>
$CMS_IF(#cs.isLastContentRow)$</table>$CMS_END_IF$
```

## Document groups — `#docGroup`, `#docNode`

Both belong to **document-group generation** (for example a table of contents in a print or PDF
template set); a document group's pages and menu levels are walked as a tree `[odfs]`. Everything
else about document groups is in the ODFS *Document groups* area, not here.

`#docGroup` is the (virtual) root of the current document group and, through dot notation, any node
of it. System objects are read-only in general; `pageFirst` is a deliberate exception.

| Member | Yields | Notes |
| --- | --- | --- |
| `#docGroup.childs` | list of nodes | children, **page references first, then menu levels** |
| `#docGroup.depth` | Integer | 0 for the top; the items of `childs` have 1 |
| `#docGroup.isFolder`, `.isPageRef` | Boolean | node type (menu level / page reference) |
| `#docGroup.index` | Integer | position in the parent's `childs` |
| `#docGroup.parent` | node | the parent; `null` on the root |
| `#docGroup.selected` | Boolean | the node itself or a child is being written to the output |
| `#docGroup.label` | String | root: the document group's name; menu level: menu name; page reference: sitemap name |
| `#docGroup.chapter` | String | chapter number such as `2.3.1` |
| `#docGroup.section` | String | like `chapter`, but only **folders** are numbered |
| `#docGroup.root` | node | the virtual root (equals `#docGroup`) |
| `#docGroup.pageFirst` | Boolean, **set** it | set to `true` with `$CMS_SET(...)$` in the start template to output pages before folders; read it with `$CMS_VALUE(...)$` |

`#docNode` is the **current element** (for example a page reference) while the document group is
generated; it is of the same type as a `#docGroup` node. Members: `#docNode.depth`,
`#docNode.chapter` (page reference or menu-level numbering), `#docNode.label`. `[odfs]`

`#depth` and `#docFolder` have a page each in the 2026.5 ODFS (*System objects*) **with no content**,
so nothing is documented about them. Do not guess a member list **[verify]**; for depth in a document
group use `#docGroup.depth` / `#docNode.depth`.

## Arithmetic precision — `#mathContext`

Controls the **division of numbers** (for example `$CMS_VALUE(100.0/33.0)$`) `[odfs]`:

| Member | Effect |
| --- | --- |
| `#mathContext.precision` | number of decimal places for the calculation; default **32** |
| `#mathContext.roundingMode` | `UP`, `DOWN`, `CEILING`, `FLOOR`, `HALF_UP` (default), `HALF_DOWN`, `HALF_EVEN`, `UNNECESSARY` (the `java.math.RoundingMode` names) |
| `#mathContext.useDefault` | resets both to the defaults |

```
$CMS_SET(#mathContext.precision, 3)$           $-- 100.0/33.0 gives 3.03 --$
$CMS_SET(#mathContext.roundingMode, "UP")$     $-- 100.0/33.0 gives 3.0303030303030303030303030303031 --$
$CMS_SET(_void, #mathContext.useDefault)$
```

The two outputs are the documented ones, with `precision` set to 3 and `roundingMode` set to `UP`
one after the other. How long a setting lasts (this template, this page, the
whole generation) is not documented **[verify]**. Number datatype: `datatypes.md`; operators: `expressions.md`.

## Generation time — `#startdate`

The time of the **last project change before the generation time**, so a generation of a historical
state yields the last change before that state `[odfs]`. A `java.util.Date`: the fields below plus
the methods of `Date`.

| Member | Yields |
| --- | --- |
| `.format("PATTERN")` | String, Java `SimpleDateFormat` pattern (`"dd.MM.yyyy HH:mm"`) |
| `.year`, `.month`, `.date` (= `.day_of_month`), `.day_of_week`, `.day_of_week_in_month`, `.day_of_year`, `.week_of_month`, `.week_of_year`, `.era` | BigInteger |
| `.hour` (0-11), `.hour_of_day` (0-23), `.am_pm` (0 AM, 1 PM), `.minute`, `.second`, `.millisecond` | BigInteger |
| `.dst_offset`, `.zone_offset` | BigInteger, milliseconds |
| `.milliseconds` | Long, Unix timestamp |


## Table rows — `#tr`

In the format template with the abbreviation `tr` and in the `Table` function `[odfs]`
(`small-functions.md`):

| Member | Yields |
| --- | --- |
| `#tr.row` | Integer, 0-based row number |
| `#tr.rowNumber` | Integer, 1-based |
| `#tr.firstRow`, `#tr.lastRow` | Boolean |

Cell and table information: `#cell`, `#table` (above).
