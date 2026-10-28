# PDF output with Apache FOP

FirstSpirit renders a PDF through a second template set whose templates emit XSL-FO instead of
HTML; the server's FOP module turns the FO document into the PDF. Nothing in the content changes:
the same pages, sections and DOM fields render through a different set of channel sources.

Tags: `[odfs]` from the Online Documentation (FirstSpirit 2026.5 / 2026.11 pages), `[observed]` from a
live template set on FirstSpirit 5.2.261116 with FOP module 2.8 (2026-10-09 to 2026-10-12).

## Setup (administrator)

- The module `fs-fop.fsm` is installed through the ServerManager; it is on Apache FOP 2.8. After
  the installation a presentation channel is available in the server properties and template sets
  can be added in the project properties `[odfs]`.
- A template set (ServerManager → project properties → Template sets) has a name, a
  **presentation channel**, a **conversion rule**, a **target file extension** (used for the
  generated file name and links), *Template Inspection* on or off, display names per language, and
  *Activate* / *Deactivate* `[odfs]`. For the PDF set the inspection is off: the output is not HTML.
- Over the REST API the set appears in `GET /projects/{id}/template-sets/` as
  `{"uid":"PDF","extension":"pdf","conversionTable":"Unicode to FOP entities","active":true,
  "templateInspectionEnabled":false}` beside the `html` set `[observed]`. A conversion rule for FO
  entities must exist on the server (server properties → Conversion rules) before it can be picked.
- Fonts: the default is Helvetica. A missing font is substituted and FOP logs
  `Font "Symbol,normal,700" not found`; set the document font on `fo:root`
  (`font-family="Helvetica"`). Fonts in a Private Use Area (Wingdings and the like) are addressed by
  their PUA code point, for example `&#xF078;` for 0x78 since FOP 1.1 `[odfs]`. Embedding your own
  font (Public Sans, say) needs a FOP configuration on the server, which a project cannot ship
  `[observed]`.

## Templates: one more tab per template

Every page, section, format and link template gets a tab per template set `[odfs]`; the PDF tab
holds the FO source. Over the REST API that is `PUT …/templates/{kind}-templates/{uid}/channel-sources/{templateSetUid}`
with `text/plain` (`…/channel-sources/PDF` beside `…/channel-sources/html`); the REST skill has the
calls `[observed]`. Whether a format template formats a whole paragraph or a selection, and its display name,
are set in the client, not in the source: the *Section* box on the format template's Properties tab `[odfs]`
(FirstSpirit 2026.11, *Format templates → Properties tab*). Checked, the format applies to the entire section up to
the next line break and the editor picks it from the left-hand list of the DOM editor with nothing selected (the
block case: headings, paragraphs, lists); unchecked, it applies to selected text only, from the right-hand list
(the inline case: bold, links, spans). Alignment is offered only for section formats and reaches the output as
`%align%` in the format template's source. The design skill's rule that the setting matches the HTML the format
emits (`firstspirit-template-design`, principle 15) rests on this box.

### Page template: the document

```
$CMS_TRIM(level:3)$
<?xml version="1.0" encoding="UTF-8"?>
<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Helvetica" font-size="10pt"
         language="$CMS_VALUE(#global.language.abbreviation.toLowerCase())$">
  <fo:layout-master-set>
    <fo:simple-page-master master-name="cover" page-width="210mm" page-height="297mm" margin="22mm">
      <fo:region-body/>
    </fo:simple-page-master>
    <fo:simple-page-master master-name="main" page-width="210mm" page-height="297mm" margin="12mm 22mm 10mm 22mm">
      <fo:region-body margin-top="16mm" margin-bottom="16mm"/>
      <fo:region-before extent="12mm"/>
      <fo:region-after extent="12mm"/>
    </fo:simple-page-master>
  </fo:layout-master-set>

  $-- bookmarks for the PDF viewer: one per section with a title --$
  <fo:bookmark-tree>
    $CMS_FOR(for_s, #global.page.body("body").children)$
      $CMS_IF(!for_s.formData.st_title.isEmpty)$
        <fo:bookmark internal-destination="chapter-$CMS_VALUE(for_s.id)$"><fo:bookmark-title>$CMS_VALUE(for_s.formData.st_title)$</fo:bookmark-title></fo:bookmark>
      $CMS_END_IF$
    $CMS_END_FOR$
  </fo:bookmark-tree>

  <fo:page-sequence master-reference="cover">
    <fo:flow flow-name="xsl-region-body">
      <fo:block font-size="32pt" font-weight="bold">$CMS_VALUE(pt_title, default:"")$</fo:block>
    </fo:flow>
  </fo:page-sequence>

  <fo:page-sequence master-reference="main">
    <fo:static-content flow-name="xsl-region-before"><fo:block font-size="7.5pt">$CMS_VALUE(pt_header_text, default:"")$</fo:block></fo:static-content>
    <fo:static-content flow-name="xsl-region-after"><fo:block font-size="7.5pt" text-align-last="justify">$CMS_VALUE(pt_footer, default:"")$<fo:leader leader-pattern="space"/><fo:page-number/></fo:block></fo:static-content>
    <fo:flow flow-name="xsl-region-body">
      $-- table of contents with page numbers resolved by FOP --$
      $CMS_FOR(for_s, #global.page.body("body").children)$
        <fo:block text-align-last="justify"><fo:basic-link internal-destination="chapter-$CMS_VALUE(for_s.id)$">$CMS_VALUE(for_s.formData.st_title)$</fo:basic-link><fo:leader leader-pattern="space"/><fo:page-number-citation ref-id="chapter-$CMS_VALUE(for_s.id)$"/></fo:block>
      $CMS_END_FOR$
      $CMS_VALUE(#global.page.body("body"))$
    </fo:flow>
  </fo:page-sequence>
</fo:root>
$CMS_END_TRIM$
```

Points that cost time in a live set `[observed]`:

- Wrap the whole source in `$CMS_TRIM(level:3)$` so indentation does not land in the PDF; keep
  format-template sources on one line for the same reason.
- `#global.page.body("body").children` gives the sections, `.formData.st_title` their fields, `.id`
  a stable id for `internal-destination` and `ref-id`. The same loop builds bookmarks and the table
  of contents; page numbers come from `fo:page-number-citation`, not from the template.
- An image from the media store: `src="url('$CMS_REF(ps_logo, abs:1)$')"` with the height computed
  from `ref(ps_logo, abs:1).width` / `.height` and `scaling="non-uniform"`, otherwise FOP scales to
  the box.
- Padding in FO is outside the text margin: a callout or code block with `padding` needs
  `start-indent` / `end-indent` to stay inside the column.
- Superscript references (`baseline-shift="super"`) shift the line unless the containing block has
  `line-height-shift-adjustment="disregard-shifts"`.

### Section template: a chapter with a counter

A `$CMS_SET$` of a number in a section is local to that section; a **list** set in the page template
is shared by reference, so a counter is a list the sections append to `[observed]`:

```
$-- page template --$   $CMS_SET(set_pt_chapters, [])$
$-- section template --$
<fo:block id="chapter-$CMS_VALUE(#global.section.id)$"$CMS_IF(st_pagebreak)$ break-before="page"$CMS_END_IF$>
  $CMS_IF(!st_unnumbered)$$CMS_SET(void, set_pt_chapters.add(1))$
    <fo:block keep-with-next="always">CHAPTER $CMS_VALUE(set_pt_chapters.size)$</fo:block>$CMS_END_IF$
  <fo:block font-size="19pt" font-weight="bold" keep-with-next="always">$CMS_VALUE(st_title, default:"")$</fo:block>
  <fo:block>$CMS_VALUE(st_text)$</fo:block>
</fo:block>
```

### Format templates: DOM elements to FO

Each format template's PDF tab maps one DOM element to FO; `#content` is the wrapped text
`[odfs]`. The system formats `p`, `b`, `i`, `u`, `br`, `ul`, `li`, `table`, `tr`, `td`, `pre` need a
PDF source too, or the element is dropped from the PDF `[observed]`.

```
p    <fo:block space-after="3mm">$CMS_VALUE(#content)$</fo:block>
b    <fo:inline font-weight="bold">$CMS_VALUE(#content)$</fo:inline>
br   <fo:block/>
pre  <fo:block font-family="Courier" white-space-treatment="preserve" linefeed-treatment="preserve" white-space-collapse="false">$CMS_VALUE(#content)$</fo:block>
```

**Lists** read `#list.style` (type) and the list dialog's fields (`system-objects.md`): the `ul`
format chooses the block, the `li` format draws the label `[observed]`:

```
$-- ul --$
$CMS_SET(void, set_pt_li.clear())$   $-- item counter, a list from the page template --$
<fo:list-block provisional-distance-between-starts="$CMS_IF(#list.style >= 2 && #list.style <= 6)$7mm$CMS_ELSE$5mm$CMS_END_IF$" provisional-label-separation="1.5mm">$CMS_VALUE(#content)$</fo:list-block>
$-- li --$
<fo:list-item><fo:list-item-label end-indent="label-end()"><fo:block>$CMS_IF(#list.style == 2)$$CMS_SET(void, set_pt_li.add(1))$$CMS_IF(#list.attr("start").isEmpty)$$CMS_VALUE(set_pt_li.size)$$CMS_ELSE$$CMS_VALUE(#list.attr("start").toNumber() + set_pt_li.size - 1)$$CMS_END_IF$.$CMS_ELSE$&#x2022;$CMS_END_IF$</fo:block></fo:list-item-label><fo:list-item-body start-indent="body-start()"><fo:block>$CMS_VALUE(#content)$</fo:block></fo:list-item-body></fo:list-item>   $-- .toNumber() in arithmetic [observed] --$
```

`#list.style` and `#listitem.index` are empty when the `li` is not inside a list the editor
recognises (a `<ul>` written over REST without list properties, or an `<ol>`); the format then
falls back to the bullet branch without an error. Print `[$CMS_VALUE(#list.style)$/$CMS_VALUE(#listitem.index)$]`
in `li` once to see whether the list is recognised `[observed]`.

**Tables** need `fo:table-column` per column and a header that repeats on the next page
(`fo:table-header` before `fo:table-body`, at least one row each). In the `table` format `#content`
is a renderer object, not a string, so the first row is found with a counter
list, not by parsing `[observed]`:

```
$-- table --$
<fo:table table-layout="fixed" width="100%">$CMS_FOR(for_c, [0 .. #table.cols - 1])$<fo:table-column column-width="proportional-column-width($CMS_IF(for_c == 0)$1.4$CMS_ELSE$1$CMS_END_IF$)"/>$CMS_END_FOR$$CMS_SET(set_ft_n, [])$$CMS_VALUE(#content)$</fo:table>
$-- tr --$
$CMS_SET(void, set_ft_n.add(1))$$CMS_IF(#table.rows == 1)$<fo:table-body><fo:table-row>$CMS_VALUE(#content)$</fo:table-row></fo:table-body>$CMS_ELSE$$CMS_IF(set_ft_n.size == 1)$<fo:table-header><fo:table-row>$CMS_VALUE(#content)$</fo:table-row></fo:table-header><fo:table-body>$CMS_ELSE$<fo:table-row>$CMS_VALUE(#content)$</fo:table-row>$CMS_END_IF$$CMS_IF(set_ft_n.size == #table.rows)$</fo:table-body>$CMS_END_IF$$CMS_END_IF$
$-- td --$
<fo:table-cell padding="1.8mm 2.2mm"$CMS_IF(#cell.row == 0)$ font-weight="bold"$CMS_END_IF$><fo:block>$CMS_VALUE(#content)$</fo:block></fo:table-cell>
```

Column widths follow position only; a `CMS_INPUT_DOMTABLE` with the `Table` header function gives
cell properties when that is not enough.

## Checking the result

- Open the page in SiteArchitect with the PDF template set, or generate it; FOP errors ("unbalanced
  tag", an empty `fo:table-header`) point at the format templates, not the page `[observed]`.
- Check the PDF as an image, not through text extraction: extractors drop hyphens at line ends
  that are present in the PDF `[observed]`.
- A missing `>` in one branch of a format template shows only when that branch renders; test both
  branches (a numbered and a bulleted list) `[observed]`.
