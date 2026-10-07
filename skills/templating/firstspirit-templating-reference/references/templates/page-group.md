# The `PageGroup` header function

A **page group** is an ordered set of page references. Two things create one:

- a **document group** maintained by hand in the Site Store (the interface behind it is
  `de.espirit.firstspirit.access.store.sitestore.PageGroup`, with `getMembers()` /
  `add(PageRef)` `[jar]`), and
- a **content projection** that generates more than one page: "If more than one page is
  generated the pages are automatically part of a page group." `[odfs]` See
  [content-projection.md](content-projection.md).

The `PageGroup` header function renders *previous / next / first / last* links and a table of
contents across that group. Unlike `Navigation`, it does not assemble the output for you: it
returns an object whose members you place in the template yourself, and an empty check is done
on `groupSize`.

Facts marked `[odfs]` are from the FirstSpirit Online Documentation (link at the end).

## Declaration

```
<CMS_HEADER>
  <CMS_FUNCTION name="PageGroup" resultname="fr_pageGroup">
    <CMS_PARAM name="cycle" value="0"/>
    <CMS_CDATA_PARAM name="previousAvailable"><![CDATA[<a class="navArrow" href="$CMS_REF(#nav.ref)$">&lt;</a>]]></CMS_CDATA_PARAM>
    <CMS_CDATA_PARAM name="previousNotAvailable"><![CDATA[<span class="navArrow">&lt;</span>]]></CMS_CDATA_PARAM>
    <CMS_CDATA_PARAM name="nextAvailable"><![CDATA[<a class="navArrow" href="$CMS_REF(#nav.ref)$">&gt;</a>]]></CMS_CDATA_PARAM>
    <CMS_CDATA_PARAM name="nextNotAvailable"><![CDATA[<span class="navArrow">&gt;</span>]]></CMS_CDATA_PARAM>
    <CMS_CDATA_PARAM name="directoryRendering"><![CDATA[<a href="$CMS_REF(#nav.ref)$">$CMS_VALUE(#nav.pos)$</a>]]></CMS_CDATA_PARAM>
    <CMS_CDATA_PARAM name="directoryRenderingSelected"><![CDATA[<strong>$CMS_VALUE(#nav.pos)$</strong>]]></CMS_CDATA_PARAM>
    <CMS_CDATA_PARAM name="delimiter"><![CDATA[ | ]]></CMS_CDATA_PARAM>
  </CMS_FUNCTION>
</CMS_HEADER>
```

Fragments are `CMS_CDATA_PARAM`s, not level-indexed arrays — a page group has no levels.

## Parameters `[odfs]`

| Parameter | Fragment for |
|---|---|
| `cycle` | `1` makes the group cyclical: the last page's *next* is the first page, and vice versa. Default `0`. |
| `previousAvailable` / `previousNotAvailable` | the previous page, when it exists / when it does not |
| `nextAvailable` / `nextNotAvailable` | the next page, when it exists / when it does not |
| `firstAvailable` / `firstNotAvailable` | the first page of the group, when reachable / when the current page *is* the first |
| `lastAvailable` / `lastNotAvailable` | the last page of the group, likewise |
| `directoryRendering` | one **unselected** entry of the table of contents |
| `directoryRenderingSelected` | the **selected** entry (the current page) of the table of contents |
| `delimiter` | separator between two table-of-contents entries |

## The result object `[odfs]`

| Member | Yields |
|---|---|
| `fr_pageGroup.pos` | position of the current page in the group, **counting from 1** `[core]` |
| `fr_pageGroup.groupSize` | total number of pages in the group |
| `fr_pageGroup.previous` | the `previous*` fragment that applies |
| `fr_pageGroup.next` | the `next*` fragment that applies |
| `fr_pageGroup.first` | the `first*` fragment that applies |
| `fr_pageGroup.last` | the `last*` fragment that applies |
| `fr_pageGroup.directory` | all table-of-contents entries, `directoryRendering*` joined by `delimiter` |

Output, in whatever order the layout needs:

```
$CMS_IF(fr_pageGroup.groupSize > 1)$
<div class="navArrowContainer">
  $CMS_VALUE(fr_pageGroup.previous)$
  Page $CMS_VALUE(fr_pageGroup.pos)$ of $CMS_VALUE(fr_pageGroup.groupSize)$
  $CMS_VALUE(fr_pageGroup.next)$
</div>
$CMS_END_IF$
```

The documentation's own compact form is `|< < 2 / 4 > >|` built from `first`, `previous`,
`directory` (or `pos`/`groupSize`), `next`, `last`. `[odfs]` `pos` **counts from 1** (the
implementation returns the node's index plus one and documents it as "starting with 1") `[core]`, so
`pos` is printed as is — unlike `#global.pageParams.index` in a content projection, which counts
from `0` `[odfs]`. Not yet seen on a live page group.

## `#nav` inside the fragments `[odfs]`

| Member | Meaning |
|---|---|
| `#nav.ref` | the page the fragment is about — `$CMS_REF(#nav.ref)$` for the link |
| `#nav.label` | its name (Site Store or Page Store) |
| `#nav.pos` | its position in the group, counting from 1 `[core]` |
| `#nav.media` | the picture entered for it in the Site Store (sitemap picture) |

## Differences from `Navigation`

- The function does not decide the order of the output; you place `previous`, `directory`,
  `next` yourself.
- Only the fragments are styled inside the function; the counter text (`Page 2 of 3`) is
  template text around the members.
- Emptiness is checked on `groupSize`, not with `isEmpty`. With a single page the group has
  size `1` and every `*NotAvailable` fragment applies, so guard with `groupSize > 1`.

## Sources

- FirstSpirit Online Documentation — *Functions in the header: PageGroup*
  `https://docs.e-spirit.com/odfs/template-develo/template-syntax/functions/header/pagegroup/index.html`
- FirstSpirit Online Documentation — *System object `#nav`*
  `https://docs.e-spirit.com/odfs/template-develo/template-syntax/system-objects/nav/index.html`
- `PageGroup` interface: `javap` against the FirstSpirit runtime jar `[jar]`.
