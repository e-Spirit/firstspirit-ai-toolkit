# Template Development via REST API

## Table of Contents
- [Create Templates](#create-templates)
- [GOM (Form Definition)](#gom-form-definition)
- [Rules](#rules)
- [Channel-Sources (HTML Output)](#channel-sources)
- [Full Workflow Example](#full-workflow)

---

## Create Templates

### Section Template
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"hero_teaser","name":"Hero Teaser","description":"A hero section with headline and image."}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/"
```

### Page Template
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"standard_page","name":"Standard Page","description":"Default page layout",
       "bodies":[{"name":"content","allowedTemplates":["hero_teaser","text"]},
                 {"name":"sidebar","allowedTemplates":[]}]}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/page-templates/"
```
The `bodies` array defines the content areas the page template provides. Each entry is a
`TemplateBodyDTO {name, allowedTemplates}` (the OpenAPI document), not a bare string.

> **Two things about `bodies` that the API document does not say** *(observed live by the PS
> website-migration tool, 2026-08-07/08 — one project each):*
> - **`allowedTemplates` is optional to read and required to write.** A body sent as
>   `{"name":"chrome"}` answered `500 … Instantiation of [TemplateBodyDTO] value failed`. Send
>   the key always, `[]` for a body that allows nothing. The section templates it names must
>   already exist (import them first); an allow-list that was imported earlier in the same run
>   was read back intact.
> - **Bodies are create-only up to `0.0.24-beta`.** No resource adds a content area to an
>   existing page template. A template created without the right bodies is repaired only by
>   `DELETE` and re-create, and every section write against a body name that does not exist
>   answers 404. Decide the body names before the first POST. **From `0.0.25-beta`** the page
>   template has a `bodies` resource — see the next block.

### Content areas of an existing page template (`0.0.25-beta`)

Present in the OpenAPI document of `0.0.25-beta` (read live 2026-10-06); the behaviour below is
what that document states and has not been exercised yet `[verify]`:

```
GET    /projects/{id}/templates/page-templates/{uid}/bodies/            # [TemplateBodyDTO] with the *effective* allowed templates
POST   /projects/{id}/templates/page-templates/{uid}/bodies/            # {"name","allowedTemplates"?} → 201; 409 name exists; 400 unknown template uid
PUT    /projects/{id}/templates/page-templates/{uid}/bodies/{bodyName}  # rename and/or replace the whitelist → 200; 409 target name in use
DELETE /projects/{id}/templates/page-templates/{uid}/bodies/{bodyName}  # 204; the API document says it is allowed while pages use the template [verify]
```

Each statement below is what the operation descriptions of the API document say; none has been
exercised on a server yet:
- Adding and renaming are described as safe for templates already used by pages, with existing
  content in a renamed area preserved `[verify]`. Deleting an area is described as allowed while
  pages use the template; the content pages stored in it then become unreachable `[verify]` — do
  not try this on a shared project until a run has shown what happens to those pages.
- **Whitelists are evaluated per page template, not per content area** `[verify]`. While no area of
  the template has a whitelist, every section and table template is allowed in every area (and the
  GET lists all of them for every area). As soon as one area has a whitelist, every other area
  without one allows nothing. So an empty `allowedTemplates` means "everything" in an unrestricted
  template and "nothing" next to a restricted area. (The GET itself is probed: R12.)
- On `PUT`, omitting `allowedTemplates` keeps the current whitelist; `[]` drops this area's entries
  `[verify]`. On `POST`, omitting or `[]` creates the area without a whitelist of its own `[verify]`.

### Format Template
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"bold_format"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/format-templates/"
```

### Link Template
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"internal_link"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/link-templates/"
```

---

## GOM (Form Definition)

The GOM defines what input components (editors) a template has. Sent and received as **raw XML** with Content-Type `application/xml`.

### Read GOM
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -H "Accept: application/xml" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/gom"
```

### Write GOM
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/xml" \
  -d '<CMS_MODULE>
    <CMS_INPUT_TEXT name="st_headline" hFill="yes" singleLine="yes" useLanguages="yes">
        <LANGINFOS>
            <LANGINFO lang="*" label="Headline" description="The main headline"/>
            <LANGINFO lang="DE" label="Überschrift"/>
        </LANGINFOS>
    </CMS_INPUT_TEXT>
    <CMS_INPUT_DOM name="st_text" hFill="yes" useLanguages="yes">
        <LANGINFOS>
            <LANGINFO lang="*" label="Text"/>
        </LANGINFOS>
    </CMS_INPUT_DOM>
    <FS_REFERENCE name="st_image" hFill="yes" useLanguages="no">
        <LANGINFOS>
            <LANGINFO lang="*" label="Image"/>
        </LANGINFOS>
        <FILTER>
            <ALLOW type="MEDIA"/>
        </FILTER>
    </FS_REFERENCE>
</CMS_MODULE>' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/gom"
```

> **The write answers an empty `200`, and that is success.** `PUT …/gom` (and `PUT …/rules`)
> return an **empty body** — do not read it as a failed write. Send `Accept: */*`; a JSON-only
> `Accept` can `500` here. GOM and rules go as **raw XML**. *(Confirmed live against a real
> project — source: PS website-migration tool, `knowledge/fs-facts.md` §1.)*
>
> **A GOM the parser rejects leaves the template CREATED WITH NO FORM.** The `PUT` answers
> `400 Parsing error: Unsupported Tag '<tag>'! (at line N, column M)` naming the offending element,
> and the template stays in the project as an empty shell that renders nothing. The one shape that
> trips this in practice: `<LINKEDITORS>` takes `<LINKEDITOR name="…"/>` children, while
> `<FORMATS>` takes `<TEMPLATE name="…"/>` — a `<TEMPLATE>` inside `<LINKEDITORS>` is the 400.
> Re-`PUT` the corrected GOM; nothing else needs undoing. *(Observed twice on two projects,
> 2026-08-27 — PS website-migration tool.)* Three more shapes the parser rejects the same way,
> read in the GOM parser and the editor classes [core]: a bare `<LANGINFO>` directly inside an
> `<ENTRY>` of COMBOBOX / CHECKBOX / RADIOBUTTON / LIST (`<ENTRY>` takes only a `<LANGINFOS>` block);
> `hFill` on `FS_CATALOG` (fixed value, "Unsupported attribute"); `<TEMPLATES>` on `CMS_INPUT_LINK`
> (link editors are allow-listed with `<LINKEDITORS>`). An `FS_CATALOG` `<TEMPLATES>` without
> `type="section"` or `type="link"` fails verification instead ("Must define the type of templates.").

### Read Parsed Form Summary (read-only)
Returns JSON list of editors with name, type, description — no content values:
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/gom/form"
```
Response:
```json
{
  "editors": [
    {"name": "st_headline", "type": "CMS_INPUT_TEXT", "description": "The main headline"},
    {"name": "st_text", "type": "CMS_INPUT_DOM", "description": null},
    {"name": "st_image", "type": "FS_REFERENCE", "description": null}
  ]
}
```
`description` is the `description` attribute of the editor's `<LANGINFO>` (`<LANGINFO lang="*" label="Headline" description="The main headline"/>`),
not the label; an editor without that attribute answers `null`. [core]

### Common GOM Elements

```xml
<!-- Text input (single-line or multi-line) -->
<CMS_INPUT_TEXT name="st_headline" hFill="yes" singleLine="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Headline"/></LANGINFOS>
</CMS_INPUT_TEXT>

<!-- Textarea (multi-line, no formatting) -->
<CMS_INPUT_TEXTAREA name="st_description" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Description"/></LANGINFOS>
</CMS_INPUT_TEXTAREA>

<!-- Rich text (DOM editor) -->
<CMS_INPUT_DOM name="st_richtext" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Content"/></LANGINFOS>
</CMS_INPUT_DOM>

<!-- Number -->
<CMS_INPUT_NUMBER name="st_count" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Count"/></LANGINFOS>
</CMS_INPUT_NUMBER>

<!-- Date -->
<CMS_INPUT_DATE name="st_date" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Date"/></LANGINFOS>
</CMS_INPUT_DATE>

<!-- Toggle/Boolean -->
<CMS_INPUT_TOGGLE name="st_active" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Active"/></LANGINFOS>
</CMS_INPUT_TOGGLE>

<!-- Combobox (single-select dropdown) -->
<CMS_INPUT_COMBOBOX name="st_color" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Color"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="red"><LANGINFOS><LANGINFO lang="*" label="Red"/></LANGINFOS></ENTRY>
        <ENTRY value="blue"><LANGINFOS><LANGINFO lang="*" label="Blue"/></LANGINFOS></ENTRY>
    </ENTRIES>
</CMS_INPUT_COMBOBOX>

<!-- Checkbox (multi-select) -->
<CMS_INPUT_CHECKBOX name="st_tags" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Tags"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="featured"><LANGINFOS><LANGINFO lang="*" label="Featured"/></LANGINFOS></ENTRY>
        <ENTRY value="new"><LANGINFOS><LANGINFO lang="*" label="New"/></LANGINFOS></ENTRY>
    </ENTRIES>
</CMS_INPUT_CHECKBOX>

<!-- Radiobutton (single-select) -->
<CMS_INPUT_RADIOBUTTON name="st_layout" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Layout"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="left"><LANGINFOS><LANGINFO lang="*" label="Left"/></LANGINFOS></ENTRY>
        <ENTRY value="right"><LANGINFOS><LANGINFO lang="*" label="Right"/></LANGINFOS></ENTRY>
    </ENTRIES>
</CMS_INPUT_RADIOBUTTON>

<!-- List (multi-select list) -->
<CMS_INPUT_LIST name="st_categories" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Categories"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="news"><LANGINFOS><LANGINFO lang="*" label="News"/></LANGINFOS></ENTRY>
        <ENTRY value="blog"><LANGINFOS><LANGINFO lang="*" label="Blog"/></LANGINFOS></ENTRY>
    </ENTRIES>
</CMS_INPUT_LIST>

<!-- Reference (to media, page, etc.) -->
<FS_REFERENCE name="st_image" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Image"/></LANGINFOS>
    <FILTER>
        <ALLOW type="MEDIA"/>
    </FILTER>
</FS_REFERENCE>

<!-- Catalog (repeating cards). No hFill: FS_CATALOG always fills (fixed value, the attribute is
     rejected as unsupported). TEMPLATES needs type="section" or type="link" or the GOM fails verification. [core] -->
<FS_CATALOG name="st_slides" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Slides"/></LANGINFOS>
    <TEMPLATES type="section">
        <TEMPLATE uid="slide_card"/>
    </TEMPLATES>
</FS_CATALOG>

<!-- Dataset reference -->
<FS_DATASET name="st_product" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Product"/></LANGINFOS>
</FS_DATASET>

<!-- Rich text with an allow-list of format templates AND of link templates -->
<CMS_INPUT_DOM name="st_body" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Body"/></LANGINFOS>
    <FORMATS>
        <TEMPLATE name="b"/>              <!-- FORMATS takes TEMPLATE … -->
        <TEMPLATE name="i"/>
    </FORMATS>
    <LINKEDITORS>
        <LINKEDITOR name="internal_link"/> <!-- … LINKEDITORS takes LINKEDITOR, never TEMPLATE -->
    </LINKEDITORS>
</CMS_INPUT_DOM>

<!-- Link. Link templates are allow-listed with LINKEDITORS, exactly as in CMS_INPUT_DOM;
     CMS_INPUT_LINK has no TEMPLATES child (unsupported tag → 400). [core] -->
<CMS_INPUT_LINK name="st_link" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Link"/></LANGINFOS>
    <LINKEDITORS>
        <LINKEDITOR name="internal_link"/>
    </LINKEDITORS>
</CMS_INPUT_LINK>

<!-- Group (visual grouping, no data) -->
<CMS_GROUP>
    <LANGINFOS><LANGINFO lang="*" label="Settings"/></LANGINFOS>
    <!-- nested editors here -->
</CMS_GROUP>
```

---

## Rules

Rules define validation, visibility, and computed behavior. Sent and received as **raw XML** with Content-Type `application/xml`.

### Read Rules
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -H "Accept: application/xml" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/rules"
```

### Write Rules
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/xml" \
  -d '<RULES>
    <RULE when="ONSAVE">
        <WITH>
            <NOT>
                <PROPERTY name="EMPTY" source="st_headline"/>
            </NOT>
        </WITH>
        <DO>
            <VALIDATION scope="save">
                <PROPERTY name="VALID" source="st_headline"/>
                <MESSAGE lang="*" text="Headline is required"/>
                <MESSAGE lang="DE" text="Überschrift ist erforderlich"/>
            </VALIDATION>
        </DO>
    </RULE>
</RULES>' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/rules"
```

### Empty Rules
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/xml" \
  -d '<RULES/>' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/rules"
```

### Important: Rules XML must follow the FirstSpirit Rules schema exactly.
Consult the `/the FirstSpirit ODFS documentation` skill for Rules syntax — never construct Rules from memory.

---

## Channel-Sources

Channel-Sources contain the HTML/output template code. Sent and received as **raw text** with Content-Type `text/plain`.

### Read Channel-Source
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -H "Accept: text/plain" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/channel-sources/html"
```

### Write Channel-Source

Template code goes in a **file**, never inline in `-d '…'`: a single apostrophe in the markup
(`$CMS_VALUE(#nav.label)$'s`, a German quote) ends the shell string. Same rule as for JSON.

```bash
# hero_teaser.html
$CMS_IF(!st_headline.isEmpty)$
<section class="hero">
    <h1>$CMS_VALUE(st_headline)$</h1>
    $CMS_IF(!st_text.isEmpty)$
    <div class="hero__text">$CMS_VALUE(st_text)$</div>
    $CMS_END_IF$
    $CMS_IF(!st_image.isEmpty)$
    <img src="$CMS_REF(st_image)$" alt="$CMS_VALUE(st_headline.convert2)$" />
    $CMS_END_IF$
</section>
$CMS_END_IF$
```

```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: text/plain" \
  --data-binary @hero_teaser.html \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/channel-sources/html"
```

**The loop that keeps REST-driven template work reviewable** (a marketing-site rebrush ran
53 templates through it `[observed]`):

1. **GET and keep** the current source in a git-tracked directory before every PUT. The PUT
   replaces the whole channel; there is no server-side history you can diff against.
2. **Balance-check before PUT:** every `$CMS_IF$` has its `$CMS_END_IF$`, `$CMS_FOR$` /
   `$CMS_END_FOR$`, `$CMS_SET(x)$` block form / `$CMS_END_SET$`, `$CMS_SWITCH$` /
   `$CMS_END_SWITCH$`, `<CMS_ARRAY_ELEMENT>` pairs and `<![CDATA[ … ]]>` inside
   `<CMS_HEADER>`. The endpoint accepts unbalanced code; the preview fails later.
3. **PUT**, then a human redeploys or previews and checks the page. Template changes do not
   show in the delivered site until generation runs.
4. **GET again** into the same directory and commit, so the repository is the export.

Note that only channel sources travel this way. GOM and Rules have their own endpoints, and
database-schema templates expose no channel source over REST at all (the schema collection can
only be listed).

### List Available Channel-Sources
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/channel-sources/"
```

### Determine Template-Set UID
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/template-sets/"
```
Use the `uid` value (e.g., `html`) as `{templateSetUid}`.

---

## Full Workflow

Complete example: Create a Section Template with form, rules, and HTML output.

Steps 3–5 are independent and **must be sent as parallel tool calls**.

```bash
source .env

# 1. Create template
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X POST -H "Content-Type: application/json" \
  -d '{"uid":"cta_button","name":"CTA Button","description":"Call-to-action button"}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/"

# 2. Verify the template exists (HTTP 200) before calling any sub-endpoints.
#    The listing alone is not a reliable existence proof — always confirm with a direct GET.
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/cta_button"

# 3. Set GOM (∥ with 4 and 5 — send as parallel tool calls)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/xml" \
  -d '<CMS_MODULE>
    <CMS_INPUT_TEXT name="st_label" hFill="yes" singleLine="yes" useLanguages="yes">
        <LANGINFOS><LANGINFO lang="*" label="Button Label"/></LANGINFOS>
    </CMS_INPUT_TEXT>
    <CMS_INPUT_TEXT name="st_url" hFill="yes" singleLine="yes" useLanguages="no">
        <LANGINFOS><LANGINFO lang="*" label="URL"/></LANGINFOS>
    </CMS_INPUT_TEXT>
    <CMS_INPUT_COMBOBOX name="st_style" hFill="yes" useLanguages="no">
        <LANGINFOS><LANGINFO lang="*" label="Style"/></LANGINFOS>
        <ENTRIES>
            <ENTRY value="primary"><LANGINFOS><LANGINFO lang="*" label="Primary"/></LANGINFOS></ENTRY>
            <ENTRY value="secondary"><LANGINFOS><LANGINFO lang="*" label="Secondary"/></LANGINFOS></ENTRY>
        </ENTRIES>
    </CMS_INPUT_COMBOBOX>
</CMS_MODULE>' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/cta_button/gom"

# 4. Set Rules (∥ with 3 and 5)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: application/xml" \
  -d '<RULES>
    <RULE when="ONSAVE">
        <WITH><NOT><PROPERTY name="EMPTY" source="st_label"/></NOT></WITH>
        <DO>
            <VALIDATION scope="save">
                <PROPERTY name="VALID" source="st_label"/>
                <MESSAGE lang="*" text="Label is required"/>
            </VALIDATION>
        </DO>
    </RULE>
</RULES>' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/cta_button/rules"

# 5. Set Channel-Source HTML (∥ with 3 and 4)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: text/plain" \
  -d '<a href="$CMS_VALUE(st_url)$" class="btn btn--$CMS_VALUE(st_style)$">
    $CMS_VALUE(st_label)$
</a>' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/cta_button/channel-sources/html"

# 6. Verify all components (∥ — send GOM/rules/channel-sources GETs as parallel tool calls)
```
