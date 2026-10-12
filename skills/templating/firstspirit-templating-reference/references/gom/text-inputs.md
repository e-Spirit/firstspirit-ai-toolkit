# GOM: Text Input Components

---

## CMS_INPUT_TEXT -- Single-line text

```xml
<CMS_INPUT_TEXT name="st_headline" useLanguages="yes" allowEmpty="no" hFill="yes">
  <LANGINFOS>
    <LANGINFO lang="*" label="Headline" description="Enter a headline"/>
  </LANGINFOS>
</CMS_INPUT_TEXT>
```

Key attributes: `length` (width in chars), `maxInputLength` (char limit), `singleLine` (YES/NO), `password` (PLAIN/HASH/HIDDEN), `editable` (YES/NO).

## CMS_INPUT_TEXTAREA -- Multi-line plain text

```xml
<CMS_INPUT_TEXTAREA name="st_description" useLanguages="yes" hFill="yes" rows="4" columns="20">
  <LANGINFOS>
    <LANGINFO lang="*" label="Description" description="Enter a description"/>
  </LANGINFOS>
</CMS_INPUT_TEXTAREA>
```

Key attributes: `rows` (height, default 4), `columns` (width, default 20), `maxInputLength` (char limit).

## CMS_INPUT_DOM -- Rich text (formatted)

```xml
<CMS_INPUT_DOM name="st_text" useLanguages="yes" hFill="yes" rows="10">
  <LANGINFOS>
    <LANGINFO lang="*" label="Text" description="Enter formatted text"/>
  </LANGINFOS>
  <FORMATS>
    <TEMPLATE name="format_bold"/>
    <TEMPLATE name="format_italic"/>
  </FORMATS>
  <LINKEDITORS>
    <LINKEDITOR name="link_internal"/>
  </LINKEDITORS>
</CMS_INPUT_DOM>
```

Key attributes: `rows` (default 4), `width` (pixels, default 480), `maxCharacters`, `bold` (YES/NO, default YES), `italic` (YES/NO, default YES), `list` (YES/NO, default YES), `table` (YES/NO, default NO), `enableImport` (YES/NO, Office Connect).

List dialog `[odfs]`: `listConfig` defines the input fields of the list properties dialog ("Edit list properties"); without it the dialog offers only the list type. `listDefaultConfig` presets `style` (0 to 8, see `#list.style` in `templates/system-objects.md`), `start`, `pre` (user-defined text, wildcards `%index%` / `%count%`) and `mediaref`. ContentCreator supports `text` fields of `listConfig` fully, other field types only partly. The format templates read the values through `#list.style`, `#list.start` and `#list.attr("name")`.

A working `listConfig` with a type selector and a start value `[observed]` (FS 5.2.261116, both clients show the start field and take the value; a `number` field works in ContentCreator here):

```xml
listConfig="style:List type[1:Bullet|2:Numbers|3:Lower-case letters|4:Upper-case letters|5:Roman lower|6:Roman upper|7:No symbol],start:Start value[type=number;maxlen=3]"
```

The start value entered this way was read in the templates with `#list.attr("start")`; `#list.start` did not deliver it `[observed]` (ODFS ties `#list.start` to `listDefaultConfig`). ContentCreator shows the start value in the list properties and the preview but did not apply it in the form; SiteArchitect does `[observed]`.

Child tags:
- `<FORMATS>` -- Available format templates
- `<LINKEDITORS>` -- Available link templates (empty name = no links)

## CMS_INPUT_DOMTABLE -- Table with Cell Properties

Rich text table editor with custom cell-level properties.

```xml
<CMS_INPUT_DOMTABLE name="st_table" bold="no" hFill="yes" italic="no" list="no"
  propertyConfig="cell_type:Cell-Type[standard:Standard|headline:Headline]">
  <FORMATS>
    <TEMPLATE name="table_bold"/>
  </FORMATS>
  <LANGINFOS>
    <LANGINFO lang="*" label="Table"/>
  </LANGINFOS>
  <LINKEDITORS>
    <LINKEDITOR name="internal_link"/>
    <LINKEDITOR name="external_link"/>
  </LINKEDITORS>
</CMS_INPUT_DOMTABLE>
```

Key points:
- `propertyConfig` format: `property_name:Display-Label[value1:Label1|value2:Label2]`
- Cell properties are accessible in format templates via DOM attributes
- Shares `FORMATS` and `LINKEDITORS` with CMS_INPUT_DOM

## CMS_LABEL -- Informational Text

Displays non-editable help text or instructions within a form.

```xml
<CMS_LABEL bold="no" size="12">
  <LANGINFOS>
    <LANGINFO lang="*" label="Please choose the default filesystem connector, if you do not have any connector installed."/>
    <LANGINFO lang="DE" label="Falls kein Connector installiert ist verwenden Sie bitte den Filesystem Connector."/>
  </LANGINFOS>
</CMS_LABEL>
```

Key attributes: `bold` (YES/NO), `size` (font size in pt).
