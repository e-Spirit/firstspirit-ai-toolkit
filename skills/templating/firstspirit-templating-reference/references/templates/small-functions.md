# Templates: `$CMS_INCLUDE$`, `define`, `Table`, `Font` and `font(...)`, `dataAssociation(...)`

Smaller instructions and functions of the template language. **[odfs]** *Template development ›
Template syntax › Instructions / Functions* (`$CMS_INCLUDE`, header functions `define`, `Table`,
`Font`, instruction functions `font`, `dataAssociation`), FirstSpirit 2026.5. Not run on a server
**[verify]**. Header-function syntax in general (`<CMS_FUNCTION>` in `<CMS_HEADER>`): see
`navigation-function.md` and `page-group.md`. `#table`, `#cell`, `#content`, `#tr`: `system-objects.md`.

## `$CMS_INCLUDE(...)$`: insert a Media Store file

Inserts the **contents** of a file from the Media Store into the template (a stylesheet, a script,
a text snippet). Not the same as `$CMS_RENDER$` (`composition.md`), which runs a template, and not
`CMS_INCLUDE_OPTIONS` (a form tag, `gom/selection-inputs.md`).

```
$CMS_INCLUDE(media:"css", parse:true, language:#global.project.masterLanguage)$
$CMS_INCLUDE(file:"stylesheet", lang:"DE")$
```

| Part | Meaning |
| --- | --- |
| identifier | object type and reference name: `file:"name"` (file) or `media:"name"` (any medium); a variable holding the identifier also works. The syntax names `media` and `file`. |
| `parse` | `true`: FirstSpirit expressions in the file are evaluated; `false`: inserted as they are. Without it the file's own "Parse File" setting applies. |
| `encoding` | encoding of the inserted content (any Java encoding); without it the file's encoding setting |
| `lang` / `language` | project language of a **language-dependent** file, as abbreviation string or language object; default is the current language |

Example from the page: with a file containing `$CMS_VALUE(output)$` and `$CMS_SET(output,"This is an
output")$` before the include, `parse:true` prints `This is an output`, `parse:false` prints
`$CMS_VALUE(output)$` literally.

## Header function `define`

Defines a variable in the **header** of a page or section template. It is kept mainly for
compatibility with FirstSpirit 3.1; `$CMS_SET(...)$` does the same in the body, the one argument for
`define` is that it sits prominently at the top. It can also hold a condition. The result
(`resultname`) is used in the header and in the HTML with `$CMS_VALUE(...)$`.

```xml
<CMS_FUNCTION name="define" resultname="name">
  <CMS_PARAM name="source" value="A constant"/>                 <!-- 1: string constant -->
</CMS_FUNCTION>
<CMS_FUNCTION name="define" resultname="calc">
  <CMS_VALUE_PARAM name="source" value="4 * 2 - 5"/>             <!-- 2: expression -->
</CMS_FUNCTION>
<CMS_FUNCTION name="define" resultname="choice">
  <CMS_CDATA_PARAM name="source"><![CDATA[                       <!-- 3: template fragment -->
    $CMS_IF(!myVar.isEmpty)$first_option$CMS_ELSE$second_option$CMS_END_IF$
  ]]></CMS_CDATA_PARAM>
</CMS_FUNCTION>
```

The CDATA form takes any template body, so `$CMS_SWITCH(myVar.toString)$ … $CMS_CASE("ABC")$ …`
gives a case distinction in the header. The test `!myVar.isEmpty` is on emptiness. For new work prefer `$CMS_SET$`.

## Header function `Table`: format a `CMS_INPUT_DOMTABLE` by position

By default a DOM table renders through the format templates `table`, `tr` and `td` (one per table,
row and cell), which suits projects whose tables all look alike. Use `Table` when tables need
**different or complex** output depending on row, column or content. Rows, columns or cells without
a definition fall back to those format templates. (Inline tables, `CMS_INPUT_DOM` with `table="yes"`,
are another option and are not described here.)

```xml
<CMS_FUNCTION name="Table" resultname="fr_st_table">
  <CMS_VALUE_PARAM name="tableData" value="st_table"/>          <!-- the DOMTABLE component -->
  <CMS_NODE_PARAM name="tableFormat">
    <HEADERSPEC><![CDATA[<table>$CMS_VALUE(#content)$</table>]]></HEADERSPEC>
    <ROW number="ALL"><![CDATA[<tr>$CMS_VALUE(#content)$</tr>]]></ROW>
    <CELL row="ALL" col="ALL"><![CDATA[<td colspan="$CMS_VALUE(#cell.colspan)$"
         rowspan="$CMS_VALUE(#cell.rowspan)$">$CMS_VALUE(#content)$</td>]]></CELL>
  </CMS_NODE_PARAM>
</CMS_FUNCTION>
```

`tableData` and `tableFormat` are mandatory. Output: `$CMS_VALUE(fr_st_table)$`.

| Tag | Purpose |
| --- | --- |
| `HEADERSPEC` | the frame of the table, evaluated once (`<table>…</table>` around `#content`) |
| `ROW number="…"` | one row definition |
| `ROWSPEC name="…"` | a reusable row template; used by `<ROW number="ALL" spec="name"/>` (the `ROW` then has **no** CDATA) |
| `CELL row="…" col="…"` | one cell definition; optional `filltype="FILLED"` or `"EMPTY"` (empty cells output differently); or `spec="name"` |
| `CELLSPEC name="…"` | a reusable cell template (the `CELL` using it has **no** CDATA) |

`number`, `row` and `col` take: `ALL`, `ODD`, `EVEN`, `LAST` (= the wildcard `%n`), an integer (a
position), a range `1-3` or `2-%n`. Definitions are evaluated from the most specific (an integer) to the most general
(`ALL`), and the first applicable one is output.

System objects inside the tags: `#table` and `#content` in `HEADERSPEC`, `ROWSPEC`, `ROW`; **also `#cell`**
only in `CELLSPEC` and `CELL`; `#tr` is documented for the format template `tr` and the `Table` function.
Where a DOM table renders to PDF through format templates: `pdf-fop.md`.

## Text as an image: header function `Font` and instruction function `font(...)`

Both render text in a **TrueType font stored on the server** to a picture; use them for graphic
headings and navigations. The font is a reference name of an installed font (administrator
documentation, *Installed fonts*). Output the picture with `<img src="$CMS_REF(name)$"/>`; the
result has `.width` and `.height` (pixels).

| | `Font` (header function) | `font(...)` (instruction function) |
| --- | --- | --- |
| Where | `<CMS_FUNCTION name="Font" resultname="…">` in the header | inside `$CMS_REF(...)$` or `$CMS_VALUE(...)$`, or `$CMS_SET(x, font(...))$` |
| Text areas | **several** per picture; parameters apply to the text areas that follow them, and the **last value set before a `text`** is used | **one** |
| Picture size | from the background picture `media` (mandatory) | the text area; or `height` + `width`; `bounds:"image"` takes the size from `media` |
| Wrapping | at spaces when text exceeds `width` (mandatory) | none |
| Mandatory | `font`, `media`, `width`, `text`; the first three must be set **before** the first `text` | `text` (and it must be the **last** parameter); `font` missing means the built-in `SansSerif` |
| `filetype` | `png` (default), `jpg` | `png` (default), `jpg`, `webp` |
| Own parameters | — | `bgcolor` (default `#FFFFFF`), `bounds`, `text_antialiasing`, `fractionalmetrics`, `height` |

Shared parameters (the `Font` syntax block also lists a `resolution` parameter with no description **[verify]**): `size` (pt, default 14), `color` (`#RRGGBB`, default `#000000`), `alpha` (0-100,
default 100; **0 is invisible**), `lineheight` (pt, default twice `size`; smaller than `size`
overlaps lines), `style` (font-dependent, for example `italic`, `bold`), `boxjustify` (`left`,
`center`, `right`; the text area on the picture), `boxvalign` (`top`, `center`, `bottom`), `justify`
(the text inside its area), `xoffset`, `yoffset` (pixels; negative moves left or up).

Behaviour to remember: a **transparent GIF or PNG** `media` gives a transparent PNG, any other `media`
a picture with **black** background; with a transparent background `Font` renders **no text**.
`font(...)`: `width` has an effect only together with `height`, and neither has any if `media` is
given (use `bounds:"image"`). `text_antialiasing:false` with small sizes can overlap letters;
`fractionalmetrics:false` prevents that.

```
<img src="$CMS_REF(font(font:"Arial", size:14, filetype:"jpg", color:"#FF0000", text:"Hello"))$"/>

$CMS_SET(set_font, font(font:"Arial", size:14, filetype:"jpg", text:"Hello"))$
<img src="$CMS_REF(set_font)$" width="$CMS_VALUE(set_font.width)$" height="$CMS_VALUE(set_font.height)$"/>
```

## `dataAssociation(...)`: markers from report results (ContentCreator only)

Links an area of the **ContentCreator preview** to a DataAccess plug-in so that the area is
highlighted when associated objects appear in the **result list of a report** (for example the
number of search hits shown at a menu item), and the highlight can change the report's filter.
Only in HTML-generating template sets.

```
<div $CMS_VALUE(dataAssociation({"namespace":"identifier"}))$> … </div>
```

The one parameter is a map with at least one pair: the **key** is the namespace defined in a
`DataAssociationHandler.Type`, the **value** a String that the plug-in uses as identifier. Quote the
key (it may contain blanks or special characters). The Java side (handler, agent, aspect):
`firstspirit-contentcreator-extensions/references/editing-in-the-preview.md` (hit marker) and
`firstspirit-module-development/references/data-access-and-reports.md`.
