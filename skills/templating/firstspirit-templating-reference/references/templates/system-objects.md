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
$CMS_VALUE(#global.gca("gca_page"))$        $-- render a Global Content Area page's channel [odfs] --$
$CMS_SET(void, #global.logError("message"))$ $-- write to the generation log --$
$CMS_SET(void, #global.stopGenerate)$       $-- stop page generation (fail-fast guard) --$
```

## Dataset info (content projection / multiple pages)

```
$CMS_VALUE(#global.dataset)$               $-- current dataset --$
$CMS_VALUE(#global.dataset.webeditUrl)$    $-- ContentCreator edit link --$
$CMS_VALUE(#global.dataset.javaClientUrl)$ $-- SiteArchitect edit link --$
```

> `javaClientUrl` targets SiteArchitect, which is being phased out in favour of ContentCreator;
> prefer `webeditUrl` where you have the choice.

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
> channel (headless/CaaS), `.convert2` is not the right escaping and the reference projects emit
> `#nav.label` unescaped into JSON. Escape for the sink, not by reflex.

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

`#index` is not catalog-specific `[core]`: the same 0-based counter is set when a page's section
list or a `FormDataList` renders section by section, together with `#sectionList` (the list being
rendered, so `#sectionList.size` gives the sibling count). Inside a catalog the list object is
`#fs_catalog` instead. `#sectionList` is not on the ODFS system-objects page `[verify]`; use it
for reading exports and prefer `#fs_catalog` / explicit `$CMS_FOR$` counters in new templates.

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
