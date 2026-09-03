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
  -d '{"uid":"standard_page","name":"Standard Page","description":"Default page layout","bodies":["content","sidebar"]}' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/page-templates/"
```
The `bodies` array defines the content areas (Body names) the page template provides.

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
    {"name": "st_text", "type": "CMS_INPUT_DOM", "description": "Text"},
    {"name": "st_image", "type": "FS_REFERENCE", "description": "Image"}
  ]
}
```

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
        <ENTRY value="red"><LANGINFO lang="*" label="Red"/></ENTRY>
        <ENTRY value="blue"><LANGINFO lang="*" label="Blue"/></ENTRY>
    </ENTRIES>
</CMS_INPUT_COMBOBOX>

<!-- Checkbox (multi-select) -->
<CMS_INPUT_CHECKBOX name="st_tags" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Tags"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="featured"><LANGINFO lang="*" label="Featured"/></ENTRY>
        <ENTRY value="new"><LANGINFO lang="*" label="New"/></ENTRY>
    </ENTRIES>
</CMS_INPUT_CHECKBOX>

<!-- Radiobutton (single-select) -->
<CMS_INPUT_RADIOBUTTON name="st_layout" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Layout"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="left"><LANGINFO lang="*" label="Left"/></ENTRY>
        <ENTRY value="right"><LANGINFO lang="*" label="Right"/></ENTRY>
    </ENTRIES>
</CMS_INPUT_RADIOBUTTON>

<!-- List (multi-select list) -->
<CMS_INPUT_LIST name="st_categories" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Categories"/></LANGINFOS>
    <ENTRIES>
        <ENTRY value="news"><LANGINFO lang="*" label="News"/></ENTRY>
        <ENTRY value="blog"><LANGINFO lang="*" label="Blog"/></ENTRY>
    </ENTRIES>
</CMS_INPUT_LIST>

<!-- Reference (to media, page, etc.) -->
<FS_REFERENCE name="st_image" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Image"/></LANGINFOS>
    <FILTER>
        <ALLOW type="MEDIA"/>
    </FILTER>
</FS_REFERENCE>

<!-- Catalog (repeating cards) -->
<FS_CATALOG name="st_slides" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Slides"/></LANGINFOS>
    <TEMPLATES>
        <TEMPLATE uid="slide_card"/>
    </TEMPLATES>
</FS_CATALOG>

<!-- Dataset reference -->
<FS_DATASET name="st_product" hFill="yes" useLanguages="no">
    <LANGINFOS><LANGINFO lang="*" label="Product"/></LANGINFOS>
</FS_DATASET>

<!-- Link -->
<CMS_INPUT_LINK name="st_link" hFill="yes" useLanguages="yes">
    <LANGINFOS><LANGINFO lang="*" label="Link"/></LANGINFOS>
    <TEMPLATES>
        <TEMPLATE uid="internal_link"/>
    </TEMPLATES>
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
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PUT -H "Content-Type: text/plain" \
  -d '$CMS_IF(!st_headline.isEmpty)$
<section class="hero">
    <h1>$CMS_VALUE(st_headline)$</h1>
    $CMS_IF(!st_text.isEmpty)$
    <div class="hero__text">$CMS_VALUE(st_text)$</div>
    $CMS_END_IF$
    $CMS_IF(!st_image.isEmpty)$
    <img src="$CMS_REF(st_image)$" alt="$CMS_VALUE(st_headline)$" />
    $CMS_END_IF$
</section>
$CMS_END_IF$' \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/hero_teaser/channel-sources/html"
```

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
            <ENTRY value="primary"><LANGINFO lang="*" label="Primary"/></ENTRY>
            <ENTRY value="secondary"><LANGINFO lang="*" label="Secondary"/></ENTRY>
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
