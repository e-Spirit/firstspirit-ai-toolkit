# Common wording to FirstSpirit terms

Customers, partners and design briefs rarely use FirstSpirit's words. Before you design or ask a
question, translate what was said into the FirstSpirit term, use that term from then on, and say once
which word you mapped. This table is a starting point for that translation; it is not a statement about
the product. Where one word can mean several things, **ask which one is meant** instead of choosing.

The FirstSpirit terms are defined in `components-and-tags.md` (stores, page and section templates,
content areas, input components) and `naming-and-conventions.md` (prefixes). For component syntax and
datatypes use `firstspirit-templating-reference`.

| Said | Usually means | Can also mean, so ask | Used in questions as |
|---|---|---|---|
| "component", "building block" | a **section template**: a variable part of a page that an editor fills in and may repeat | a **format template** (recurring template code, not editor-facing); a **global content area** (content shared across pages); an **input component** (`CMS_INPUT_*`, one field of a form) | the FirstSpirit term, after asking |
| "page type", "layout", "page template" | a **page template** | a different **output channel** of the same template | page template |
| "content block", "module", "widget" | a **section template**, or a **section** (one use of it on a page) | a FirstSpirit **module** (code that extends the product; unrelated to page content); a **format template** | avoid "module" and "widget" for page content |
| "main content area", "body" | a **content area**: a place in the page template where sections go; it can be limited to certain section templates | the whole page | content area |
| "list of items", "repeater", "cards" | **nested items** in a section (a catalog), or a **dataset** in a data source | separate sections placed one after another | catalog of items or dataset, after asking |
| "header", "footer" | content fixed in the **page template**, or a **render template** (a format template called with `$CMS_RENDER$`) with content from the **project settings** | a **global content area**, if the content varies by place in the site tree, needs its own rights, or is released as content (see `cutting-an-artifact.md`) | the FirstSpirit term, after asking where the content lives |
| "menu", "navigation" | a navigation built from the **site structure** and referenced from the page template | a hand-maintained list of links | navigation from the site structure |
| "global elements", "site settings" | a **global content area** (its own template renders it; the page template only places it, see `global-content-areas.md`) or the **project settings** | content on every page, maintained per page | global content area |
| "rich text", "text editor" | a **`CMS_INPUT_DOM`** field, with its output set by **format templates** | a plain text field | rich-text field |
| "SEO fields", "meta tags" | fields in the page template that feed the html head | fields on every section | page-template fields |
| "publish", "go live" | **release** (an editorial step, if the project uses the release function), or **deployment** after **generation** | both | release, or generation and deployment, after asking |
| "translation" | content in another **project language**, or editor-facing labels in another language | both; see `localisation.md` | project language, or label language, after asking |
| "folder for images" | a folder in the **media store** | a folder of technical assets (CSS, JS, icons) | media folder |

German wording `[verify]`: Seitenvorlage (page template), Absatzvorlage (section template),
Formatvorlage (format template). The other terms are not yet collected; add them as they come up.

## Words to avoid in questions and documents

- **"Region"** and **"area"** without "content": they suggest a place on a page or a geographic or
  organisational area, depending on the reader. Say content area, or name the part of the page.
- **"Module"** for page content (see the table).
- **"Template"** alone: say page, section, format or link template.
- **"Component"** alone: say which of the three meanings.

Keep generic web wording and FirstSpirit terms apart in one sentence: say "the teaser (a section
template)" once, then "the teaser section template".
