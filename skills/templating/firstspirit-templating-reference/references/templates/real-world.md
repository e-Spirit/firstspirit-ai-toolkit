# Templates: Real-World Patterns

Patterns extracted from production FirstSpirit projects. Each example includes the business context it solves.

---

## Navigation Function ($CMS_FUNCTION)

The Navigation function generates multi-level menus from the SiteStore structure.

```
<CMS_HEADER>
  <CMS_FUNCTION name="Navigation" resultname="fr_nav">
    <CMS_PARAM name="expansionVisibility" value="all"/>

    $-- HTML wrapping around sub-menus (inner nesting) --$
    <CMS_ARRAY_PARAM name="innerBeginHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[
        <div id="$CMS_VALUE(#nav.id)$" class="sub-menu">
      ]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>

    $-- HTML before each menu item --$
    <CMS_ARRAY_PARAM name="beginHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[<li>]]></CMS_ARRAY_ELEMENT>
      <CMS_ARRAY_ELEMENT index="1"><![CDATA[<ul>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>

    $-- HTML for non-active items at each depth level --$
    <CMS_ARRAY_PARAM name="unselectedHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[
        $CMS_IF(#nav.hasSubFolders)$
          <button aria-expanded="false" aria-controls="$CMS_VALUE(#nav.id)$">
            $CMS_VALUE(#nav.label)$ ▼
          </button>
        $CMS_ELSE$
          <a href="$CMS_REF(#nav.ref, abs:1)$">$CMS_VALUE(#nav.label)$</a>
        $CMS_END_IF$
      ]]></CMS_ARRAY_ELEMENT>
      <CMS_ARRAY_ELEMENT index="1..2"><![CDATA[
        <li><a href="$CMS_REF(#nav.ref, abs:1)$"
          $CMS_IF(#nav.level == 1)$class="font-bold"$CMS_END_IF$>
          $CMS_VALUE(#nav.label)$</a></li>
      ]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>

    $-- HTML for active (current) items --$
    <CMS_ARRAY_PARAM name="selectedHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[
        <a href="$CMS_REF(#nav.ref, abs:1)$" class="active">$CMS_VALUE(#nav.label)$</a>
      ]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>

    $-- HTML after each menu item --$
    <CMS_ARRAY_PARAM name="endHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[</li>]]></CMS_ARRAY_ELEMENT>
      <CMS_ARRAY_ELEMENT index="1"><![CDATA[</ul>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>

    <CMS_ARRAY_PARAM name="innerEndHTML">
      <CMS_ARRAY_ELEMENT index="0"><![CDATA[</div>]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
  </CMS_FUNCTION>
</CMS_HEADER>

$CMS_IF(!fr_nav.isEmpty)$
  <nav><ul>$CMS_VALUE(fr_nav)$</ul></nav>
$CMS_END_IF$
```

Key points:
- `CMS_FUNCTION name="Navigation"` generates the output, stored in `resultname`
- `CMS_ARRAY_ELEMENT index="0"` = depth 0 (top-level), `index="1"` = depth 1, `index="1..2"` = depths 1 and 2
- `#nav.label` = menu name, `#nav.ref` = page reference, `#nav.id` = element ID
- `#nav.hasSubFolders` = has child pages, `#nav.level` = current depth
- `#nav.isFirst`, `#nav.pos`, `#nav.comment` = position info
- `expansionVisibility="all"` renders all levels regardless of current page
- `beginHTML`/`endHTML` wrap each item, `innerBeginHTML`/`innerEndHTML` wrap sub-level containers
- `unselectedHTML` vs `selectedHTML` distinguish current page from others

---

## Sitemap Navigation (siteMap + multiPages)

XML sitemap with hreflang alternates and lastmod dates.

```
<CMS_HEADER>
  <CMS_FUNCTION name="Navigation" resultname="fr_sitemap">
    <CMS_PARAM name="expansionVisibility" value="all"/>
    <CMS_PARAM name="siteMap" value="1"/>
    <CMS_PARAM name="multiPages" value="1"/>

    <CMS_ARRAY_PARAM name="pageRefRendering">
      <CMS_ARRAY_ELEMENT index="0..99"><![CDATA[
        <url>
          <loc>$CMS_REF(#nav.ref, abs:1)$</loc>
          $CMS_FOR(lang, #global.project.languages.filter(l -> #nav.ref.page.isTranslated(l)))$
            <xhtml:link rel="alternate"
              hreflang="$CMS_VALUE(lang.getAbbreviation().toLowerCase())$"
              href="$CMS_REF(#nav.ref, language: lang, abs:1)$"/>
          $CMS_END_FOR$
          $CMS_IF(#nav.ref.page.getReleaseRevision() != null)$
            $CMS_SET(lastmod, DATE_CLASS.new(#nav.ref.page.getReleaseRevision().getCreationTime()))$
            <lastmod>$CMS_VALUE(lastmod.format("yyyy-MM-dd'T'HH:mm:ss'Z'"))$</lastmod>
          $CMS_END_IF$
        </url>
      ]]></CMS_ARRAY_ELEMENT>
    </CMS_ARRAY_PARAM>
  </CMS_FUNCTION>
</CMS_HEADER>

$CMS_SET(DATE_CLASS, class("java.util.Date"))$
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
$CMS_TRIM(level:2)$
  $CMS_VALUE(fr_sitemap)$
$CMS_END_TRIM$
</urlset>
```

Key points:
- `siteMap="1"` outputs all pages (not just navigation-visible ones)
- `multiPages="1"` includes content projection pages (dataset detail pages)
- `pageRefRendering` replaces the normal HTML arrays with a custom XML format
- `index="0..99"` applies the same rendering to all depth levels
- `#nav.ref.page.isTranslated(lang)` checks if a page has content in a language
- `$CMS_REF(#nav.ref, language: lang, abs:1)$` generates a language-specific URL
- `class("java.util.Date")` creates a Java class reference for instantiation
- `getReleaseRevision().getCreationTime()` gets the last release timestamp

---

## Responsive Image Rendering (picture/source)

Serves different image resolutions for different screen sizes using `<picture>` elements.

```
$CMS_SET(mediaQueries, [
  {"key": "2xl", "query": "media=\"(min-width: 1536px)\""},
  {"key": "xl",  "query": "media=\"(min-width: 1280px)\""},
  {"key": "lg",  "query": "media=\"(min-width: 1024px)\""},
  {"key": "md",  "query": "media=\"(min-width: 768px)\""},
  {"key": "sm",  "query": "media=\"(min-width: 640px)\""}
])$

$CMS_IF(!prm_image.isEmpty() && !prm_defaultResolution.isEmpty())$
  <picture $CMS_VALUE(if(!prm_cssClasses.isEmpty(), "class=\"" + prm_cssClasses + "\""))$
    $CMS_IF(!prm_inputName.isEmpty())$
      $CMS_SET(croppingResolutions, [])$
      $CMS_SET(void, if(isSet(prm_resolutions) && !prm_resolutions.isEmpty(), croppingResolutions.addAll(prm_resolutions.values)))$
      $CMS_SET(void, croppingResolutions.add(prm_defaultResolution))$
      $CMS_VALUE(editorId(editorName: prm_inputName, resolution: croppingResolutions))$
    $CMS_END_IF$>

    $CMS_FOR(mq, mediaQueries)$
      $CMS_IF(prm_resolutions.containsKey(mq.key))$
        <source $CMS_VALUE(mq.query)$
          srcset="$CMS_REF(prm_image, abs:1, resolution: prm_resolutions[mq.key])$">
      $CMS_END_IF$
    $CMS_END_FOR$

    $CMS_SET(defaultImg, ref(prm_image, abs:1, resolution: prm_defaultResolution))$
    <img src="$CMS_REF(defaultImg)$" alt="$CMS_VALUE(altText)$"
      height="$CMS_VALUE(defaultImg.height)$" width="$CMS_VALUE(defaultImg.width)$">
  </picture>
$CMS_END_IF$
```

Called as a format template with parameters:

```
$CMS_RENDER(template:"render_image",
  prm_image: st_image,
  prm_defaultResolution: "4x3_M",
  prm_resolutions: {"md": "4x3_S", "lg": "4x3_M"},
  prm_cssClasses: "w-full",
  prm_inputName: "st_image")$
```

Key points:
- `$CMS_REF(image, resolution: "resName")$` generates a URL for a specific image resolution
- `editorId(editorName:..., resolution:...)` enables ContentCreator image cropping
- `ref()` function (without `$CMS_` prefix) returns a reference object with `.height` and `.width`
- Map lookup `prm_resolutions[mq.key]` accesses resolution name by breakpoint key

---

## CTA Button / Link Dispatch ($CMS_SWITCH)

Reusable button component that dispatches by link template type.

```
$CMS_IF(!prm_link.isEmpty())$
  $CMS_SET(styles, {
    "button_l": {"link": "rounded-full bg-purple-600 px-9 py-5 text-white", "icon": "fill-white"},
    "text_l": {"link": "text-purple-600 inline-flex gap-2", "icon": "fill-purple-600"}
  })$
  $CMS_SET(style, if(!prm_style.isEmpty(), prm_style, "button_l"))$

  $CMS_SWITCH(prm_link.template.uid)$
    $CMS_SET(set_ref, "")$
    $CMS_SET(set_text, "")$
    $CMS_SET(set_target, "_self")$
  $CMS_CASE("internal_link")$
    $CMS_SET(link, prm_link.formData.lt_link)$
    $CMS_IF(!link.isEmpty())$
      $CMS_SET(set_ref)$$CMS_REF(link, abs:1)$$CMS_IF(link.getSection() != null)$#$CMS_VALUE(link.getSectionName())$$CMS_END_IF$$CMS_END_SET$
    $CMS_END_IF$
    $CMS_SET(set_text, prm_link.text())$
  $CMS_CASE("external_link")$
    $CMS_SET(set_ref, prm_link.formData.lt_link)$
    $CMS_SET(set_text, prm_link.text())$
    $CMS_SET(set_target, "_blank")$
  $CMS_CASE("dataset_link")$
    $CMS_SET(set_ref)$$CMS_RENDER(template:"render_link_dataset_url",
      prm_dataset: prm_link.formData.lt_dataset.dataset)$$CMS_END_SET$
    $CMS_SET(set_text, prm_link.text())$
  $CMS_CASE("media_link")$
    $CMS_SET(set_ref, ref(prm_link.formData.lt_link, abs:1))$
    $CMS_SET(set_text, prm_link.text())$
    $CMS_SET(set_target, "_blank")$
  $CMS_END_SWITCH$

  <a class="$CMS_VALUE(styles[style].link)$" target="$CMS_VALUE(set_target)$"
    href="$CMS_VALUE(set_ref)$">$CMS_VALUE(set_text)$</a>
$CMS_END_IF$
```

Key points:
- `$CMS_SWITCH(prm_link.template.uid)$` dispatches by which link template the editor chose
- Default values go between `$CMS_SWITCH$` and the first `$CMS_CASE$`
- `prm_link.formData.lt_link` accesses the link template's form field values
- `prm_link.text()` returns the link's display text
- `link.getSection()` / `link.getSectionName()` handles section anchoring
- Style map lookup `styles[style].link` selects CSS classes by style variant

---

## Content Select (Database Query)

Queries database entities and builds data structures for use in templates.

### Translation lookup map

```
<CMS_HEADER>
  <CMS_FUNCTION name="contentSelect" resultname="fr_translations">
    <CMS_PARAM name="schema" value="crownpeak"/>
    <QUERY entityType="translation"/>
  </CMS_FUNCTION>
</CMS_HEADER>

$CMS_SET(ps_translations, {:})$
$CMS_FOR(row, fr_translations)$
  $CMS_SET(void, ps_translations.put(row.key, row.translation))$
$CMS_END_FOR$
```

Usage:

```
$CMS_VALUE(ps_translations.readMore)$
$CMS_VALUE(ps_translations["readMore"])$
```

Key points:
- `{:}` creates an empty ordered map (LinkedHashMap), `{}` would create a set
- `.put(key, value)` adds entries to the map
- `$CMS_SET(void, ...)$` discards the return value (`.put()` returns the previous value)
- `row.columnName` accesses entity columns by name

### JSON feed generation

```
<CMS_HEADER>
  <CMS_FUNCTION name="contentSelect" resultname="fr_locations">
    <CMS_PARAM name="schema" value="smartliving"/>
    <QUERY entityType="location"/>
  </CMS_FUNCTION>
</CMS_HEADER>

[$CMS_FOR(loc, fr_locations)$
  $CMS_IF(!#for.isFirst)$,$CMS_END_IF$
  {
    "id": $CMS_VALUE(loc.fs_id)$,
    "name": "$CMS_VALUE(loc.name.toJSON())$",
    "lat": $CMS_VALUE(loc.lat)$,
    "long": $CMS_VALUE(loc.long)$
  }
$CMS_END_FOR$]
```

---

## Dataset URL Resolution (Content Projection)

Resolves a dataset to its detail page URL based on the dataset's table template type.

```
$CMS_TRIM(level:4)$
$CMS_IF(!prm_dataset.isEmpty())$
  $CMS_SWITCH(prm_dataset.getTableTemplate().getUid())$
    $CMS_VALUE(#global.logWarning("Unknown dataset type: '" + prm_dataset.getTableTemplate().getUid() + "'"))$
  $CMS_CASE("crownpeak.blog")$
    $CMS_REF(ps_blog_detail_page, abs:1, contentId: prm_dataset.getEntity().getId())$
  $CMS_CASE("crownpeak.event")$
    $CMS_REF(ps_event_detail_page, abs:1, contentId: prm_dataset.getEntity().getId())$
  $CMS_CASE("crownpeak.partner")$
    $CMS_REF(ps_partner_detail_page, abs:1, contentId: prm_dataset.getEntity().getId())$
  $CMS_END_SWITCH$
$CMS_END_IF$
$CMS_END_TRIM$
```

Key points:
- `prm_dataset.getTableTemplate().getUid()` returns the fully qualified table template UID
- `$CMS_REF(pageref, contentId: entityId)$` generates a content projection URL
- `prm_dataset.getEntity().getId()` gets the dataset's entity ID
- Default case (between SWITCH and first CASE) logs a warning for unknown types

---

## Format Template as Reusable Component

Simple utility -- replace newlines with `<br>`:

```
$-- Format template: break_replace --$
$CMS_VALUE(prm_string.toString.replace("\n", "<br />"))$
```

Called as:

```
$CMS_RENDER(template:"break_replace", prm_string: st_description)$
```

Key points:
- Parameters are passed as named key-value pairs after `template:"name"`
- Inside the format template, parameters are accessed directly by name
- Use `$CMS_SET(block)$...$CMS_END_SET$` to capture a render call's output into a variable
- `style:true` flag is NOT needed when passing custom parameters

---

## Smart Headline (H1 Management)

Ensures the first heading on a page renders as `<h1>`, all subsequent headings use a configurable default tag.

```
$CMS_IF(!prm_headline.isEmpty())$
  $CMS_SET(tag, prm_defaultTag)$
  $CMS_IF(set_h1Rendered.isEmpty())$
    $CMS_SET(tag, "h1")$
    $CMS_SET(#global.context("PAGE")["set_h1Rendered"], true)$
  $CMS_END_IF$
  <$CMS_VALUE(tag)$
    $CMS_IF(!prm_cssClasses.isEmpty())$class="$CMS_VALUE(prm_cssClasses)$"$CMS_END_IF$>
    $CMS_VALUE(prm_headline.convert2())$
  </$CMS_VALUE(tag)$>
$CMS_END_IF$
```

Key points:
- `#global.context("PAGE")` provides a page-scoped map that persists across all template renders within one page generation
- First call sets `set_h1Rendered = true`, all subsequent calls find it already set
- `convert2()` converts special characters to HTML entities (including quotes)
- Dynamic tag names via `<$CMS_VALUE(tag)$>` allow programmatic HTML tag selection

---

## Debug Logging

```
$-- Log a warning (visible in server log and generation log) --$
$CMS_VALUE(#global.logWarning("Skip CTA button, missing link."))$

$-- Log an error --$
$CMS_VALUE(#global.logError("Missing required parameter: " + prm_name))$
```

Key points:
- `#global.logWarning(message)` and `#global.logError(message)` write to the generation log
- The `$CMS_VALUE()$` wrapper is needed to execute the method
