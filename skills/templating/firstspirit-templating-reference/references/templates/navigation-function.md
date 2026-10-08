# The `Navigation` header function

The `Navigation` function renders a menu from the Site Store tree. It is declared in the
`<CMS_HEADER>` of a page template, stores its output in `resultname`, and is emitted with
`$CMS_VALUE(<resultname>)$` in the body. A worked, production-shaped example is in
[real-world.md](real-world.md) → *Navigation Function*; this file is the parameter reference
behind it.

Facts marked `[odfs]` are taken from the FirstSpirit Online Documentation (links at the end).
`[verify]` marks behaviour the documentation does not state.

## Skeleton

```
<CMS_HEADER>
  <CMS_FUNCTION name="Navigation" resultname="fr_nav">
    <CMS_PARAM name="expansionVisibility" value="standard"/>
    <CMS_PARAM name="wholePathSelected" value="1"/>

    <CMS_ARRAY_PARAM name="beginHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[<li>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
    <CMS_ARRAY_PARAM name="selectedHTML">
      <CMS_ARRAY_ELEMENT index="0..2"><![CDATA[<a class="selected" href="$CMS_REF(#nav.ref)$">$CMS_VALUE(#nav.label)$</a>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
    <CMS_ARRAY_PARAM name="unselectedHTML">
      <CMS_ARRAY_ELEMENT index="0..2"><![CDATA[<a href="$CMS_REF(#nav.ref)$">$CMS_VALUE(#nav.label)$</a>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
    <CMS_ARRAY_PARAM name="innerBeginHTML">
      <CMS_ARRAY_ELEMENT index="0..1"><![CDATA[<ul>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
    <CMS_ARRAY_PARAM name="innerEndHTML">
      <CMS_ARRAY_ELEMENT index="0..1"><![CDATA[</ul>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
    <CMS_ARRAY_PARAM name="endHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[</li>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
  </CMS_FUNCTION>
</CMS_HEADER>

$CMS_SET(set_nav, fr_nav.toString)$
$CMS_IF(!set_nav.isEmpty)$<ul>$CMS_VALUE(set_nav)$</ul>$CMS_END_IF$
```

`fr_nav` is the navigation **object**, not rendered text, and its `isEmpty` is always `false` — even
when the function renders nothing `[core]` `[observed]` (2026-10-07: `fr_nav.isEmpty` = false while
`fr_nav.toString.length` = 0). Render once with `.toString` and test the string, as above; a guard
on `fr_nav.isEmpty` still emits the empty `<ul></ul>`.

`CMS_ARRAY_ELEMENT index` names the **menu level** the fragment applies to; levels are counted
from `0`. `index="1..2"` covers a range. `[odfs]`

## The six HTML hooks and their order

Every rendered node goes through the hooks in this order `[odfs]`:

| # | Hook | Emitted |
|---|---|---|
| 1 | `beginHTML` | before the node and its sub-items |
| 2 | `selectedHTML` **or** `unselectedHTML` | the node itself, depending on selection |
| 3 | `innerBeginHTML` | before the node's children (only when children are rendered) |
| 4 | *children, recursively, at level + 1* | |
| 5 | `innerEndHTML` | after the children |
| 6 | `endHTML` | after the node and its sub-items |

So a leaf renders `beginHTML · (un)selectedHTML · endHTML`; a node with rendered children wraps
its children in `innerBeginHTML … innerEndHTML` between its own fragment and `endHTML`. Which
children are rendered is decided by `expansionVisibility`; which nodes count as selected is
decided by `wholePathSelected`.

Two related fragment parameters `[odfs]`:

- `delimiter` / `selectedDelimiter` — output **between** two nodes on the same level, not around
  each node like `beginHTML`/`endHTML`. When `selectedDelimiter` is not set, `delimiter` is used
  for selected nodes too `[core]`.
- `pageRefRendering` — like `selectedHTML`/`unselectedHTML`, but output for **all page references**
  of a menu level (used with `siteMap="1"`; see the sitemap pattern in
  [real-world.md](real-world.md)).

## `expansionVisibility` — which nodes render

The parameter is **mandatory**: a `$CMS_FUNCTION$` call without it fails with the parsing
error *parameter 'expansionVisibility' is missing*, and a value outside the table below fails
at render time `[core]`.

| Value | Renders `[odfs]` |
|---|---|
| `standard` | Tree is fully collapsed except along the current path: the current menu item with its children, its siblings, its parents and the siblings of its parents. |
| `all` | The entire tree, fully expanded. |
| `pathonly` | The current menu item, its children and the whole parent chain. No siblings. |
| `purepath` | As `pathonly`, but the children of the current item are hidden. Path only. |
| `parentpath` | As `purepath`, but the *Display in navigation menu?* setting (Site Store, *Names* tab) is evaluated for menu levels as well, not only for page references. |
| `subtree` | Only the subtree below the current menu item. Levels are counted from `0` **as of the children** of the current item, so the `index` values shift. |

Notes:

- `standard` is the default when the parameter is omitted. `[verify]` — the documentation
  presents `standard` first and describes it as the collapsed default, but does not state
  the fallback explicitly; set the value rather than relying on it.
- What `parentpath` does with a menu level that is flagged *not* to display (skip the level and
  pull its visible descendants up, or stop the path there) is not spelled out beyond "the
  setting is evaluated". `[verify]` on a live project before promising either.
- What renders when the current page is **not inside** the rendered tree (for example with a
  `root` outside the current path) is not documented per value. `[verify]`.

## `wholePathSelected` — which nodes count as selected

| Value | Effect `[odfs]` |
|---|---|
| `0` (default) | Only the element directly above the current page reference is treated as selected and rendered through `selectedHTML`; its ancestors go through `unselectedHTML`. |
| `1` | The whole path from the current element to the root is treated as selected; every node on it renders through `selectedHTML`. |

Use `1` for a top navigation that must highlight the open branch; use `0` for a breadcrumb
where only the last crumb is unlinked.

## Other parameters

| Parameter | Values | Meaning `[odfs]` |
|---|---|---|
| `root` | `pagefolder:UID` or `pageref:UID` | Start node of the navigation. |
| `selectedNode` | `pagefolder:UID` or `pageref:UID` | Treat this folder or page as the current/selected element instead of the page being generated. |
| `suppressEmptyFolders` | `0` (default) / `1` | Leave out menu levels that contain no page reference. |
| `menuFirst` | `1` (default) / `0` | Output menu levels before page references (`1`) or the other way round (`0`). |
| `siteMap` | `0` (default) / `1` | Also output the page references (for a sitemap), rendered with `pageRefRendering`. |
| `multiPages` | `0` (default) / `1` | In a sitemap, include all generated sub-pages of a content projection, not only the first. See [content-projection.md](content-projection.md). |

## `#nav` inside the fragments

Available inside every fragment of the function (the `#nav` object also exists in `MenuGroup`
and `PageGroup`, with a smaller member set; see [page-group.md](page-group.md)). `[odfs]`

| Member | Type | Meaning |
|---|---|---|
| `#nav.ref` | `PageRef` | The target node (or the start node). `$CMS_REF(#nav.ref)$` builds the link. |
| `#nav.label` | `String` | Name of the target node (the menu name). User-entered — escape it for HTML (`.convert2`), see [string-operations.md](string-operations.md). |
| `#nav.id` | `Long` | Server-wide id of the target node. |
| `#nav.level` | `Integer` | Menu level, from `0`. |
| `#nav.levelPos` | `Integer` | Position within the current level, from `0`. |
| `#nav.positions[n]` | `Integer` | Folder position at level `n`. |
| `#nav.isFirst` / `#nav.isLast` | `Boolean` | First / last element on its level. |
| `#nav.hasSubFolders` | `Boolean` | The node has child elements. |
| `#nav.selected` | `Boolean` | The node is selected (per `wholePathSelected`). |
| `#nav.folder` | `PageRefFolder` | The current folder within the menu structure. |
| `#nav.comment` | `String` | Comment entered on the node in the Site Store. |
| `#nav.data("uid")` | variable | Value of a Site Store variable on the node. |
| `#nav.media`, `#nav.mediaHighlight`, `#nav.mediaSelected`, `#nav.mediaHighlightSelected` | `Media` | Pictures entered on the node for the four states; `#nav.media.width` / `.height` in pixels. |

## Pattern: breadcrumb

Path only, last crumb unlinked, no wrapper hooks — the whole output is the sequence of
`unselectedHTML` fragments for the ancestors and one `selectedHTML` for the current page:

```
<CMS_FUNCTION name="Navigation" resultname="fr_breadcrumb">
  <CMS_PARAM name="expansionVisibility" value="purepath"/>
  <CMS_PARAM name="wholePathSelected" value="0"/>
  <CMS_ARRAY_PARAM name="unselectedHTML">
    <CMS_ARRAY_ELEMENT index="0..9"><![CDATA[<li><a href="$CMS_REF(#nav.ref)$">$CMS_VALUE(#nav.label.convert2)$</a></li>]]></CMS_ARRAY_ELEMENT>
  </CMS_ARRAY_PARAM>
  <CMS_ARRAY_PARAM name="selectedHTML">
    <CMS_ARRAY_ELEMENT index="0..9"><![CDATA[<li aria-current="page">$CMS_VALUE(#nav.label.convert2)$</li>]]></CMS_ARRAY_ELEMENT>
  </CMS_ARRAY_PARAM>
</CMS_FUNCTION>
…
$CMS_SET(set_crumbs, fr_breadcrumb.toString)$
$CMS_IF(!set_crumbs.isEmpty)$<ol class="breadcrumb">$CMS_VALUE(set_crumbs)$</ol>$CMS_END_IF$
```

The same rule as for the menu: the function result's `isEmpty` is always `false`; test the rendered
string `[core]`. A page whose folder sits directly below the root renders no crumbs at all.

Switch to `parentpath` when intermediate folders are flagged *not* to display in the menu and
you want that setting respected in the crumb too (see the `[verify]` note above on the exact
effect). Move the fragments into a format template with `$CMS_RENDER(template:"…")$` when
several page templates share the breadcrumb ([composition.md](composition.md)).

## Classic vs. headless

This function renders HTML at generation time and belongs to the classic output path. Headless
and CaaS projects usually deliver navigation as data through the Navigation Service module
instead of rendering it in a template; none of the reference projects mined for this skill use
the `Navigation` function in a JSON channel.

## Sources

- FirstSpirit Online Documentation — *Functions in the header: Navigation*
  `https://docs.e-spirit.com/odfs/template-develo/template-syntax/functions/header/navigation/index.html`
- FirstSpirit Online Documentation — *System object `#nav`*
  `https://docs.e-spirit.com/odfs/template-develo/template-syntax/system-objects/nav/index.html`
