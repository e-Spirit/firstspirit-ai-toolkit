# The assistants — what they do, where, and their limits

Four assistants plus one workflow step, all built on the same model connection and prompt
configuration (`setup-and-configuration.md`, `prompt-configuration.md`). The sources are
the AI Suite docs, *What the assistants do* (`docs.crownpeak.com/ai-suite/what-the-assistants-do/`)
`[odfs]`, unless a line says otherwise.

| Assistant | Where it appears | Works on | Tag in the prompt configuration |
|---|---|---|---|
| Content Assistant | Speech bubble in single-line text fields and the rich-text editor; InEdit in the preview; chat-style report panel | The active paragraph or the selected text; free prompts in the report | `ContentAssistant` |
| Analyze Assistant | Report panel | The whole displayed page; proposes changes per element | `AnalyzeAssistant` |
| Image Assistant | Media Management (on upload, Rescan button) | Images: focus-area cropping, alt text | `ImageAssistantAltText` (alt-text prompt) |
| Code Assistant | Template Development for ContentCreator (full-screen view and preview); Media Management for JS/CSS | Output HTML; JS and CSS media | `[verify]` (not named in either doc set) |

The tag names come from the older docs (`docs.e-spirit.com/contentcreator/ai-powered-tool/`)
`[odfs]`.

## Content Assistant

- **Inline:** click into a text field and a speech bubble offers the operations tagged
  `ContentAssistant`. The selected operation runs on the active paragraph or on the selection.
  Options appear as drop-downs with the **first entry preselected**. An empty selection is
  impossible. Options with a single entry are hidden but still applied.
- **Result handling:** accept (overwrites the paragraph), discard, compare, step back and
  forward through generations, stop, regenerate, open *Edit operation* (admins).
  Changing the text, switching the language or opening another element **re-runs** the
  operation until the editor accepts or rejects.
- **Per-section off switch:** stored on the element and kept across views and languages.
- **Report panel:** a free chat with the model. The result is dragged into fields; dropping
  into the preview needs a drop editor in the project configuration.
- **Presets:** Review, Shorten, Expand, Improve (with a *Style* option), Translate (with a
  *Language* option), Create.
- **Limits:** quality depends on the model; output must be reviewed. The report panel does
  not act on the project (it does not create or publish pages).

## Analyze Assistant

- Open the report and pick an operation; the analysis starts immediately and streams proposals.
  Cancelling keeps what was generated so far. Navigating away asks whether to go back or
  re-analyse.
- After the run, **all entries are preselected**. Hovering highlights the element on the page.
  The compare view (combined, side by side, preview) allows editing before applying.
  *Save Draft* keeps your edits without applying them.
- **Bulk apply cannot be undone in one step.** Each element is restored individually through
  the project history. Say this whenever someone plans a bulk run on live content.
- **Presets:** Review, Improve / Simple language, Improve / Formal language, Shorten, Tone of
  Voice, SEO.
- **Limits:** only content projections with a **single dataset** are supported.
- Server-side throughput: the module service runs 1–16 parallel requests per page, 8 by
  default (`setup-and-configuration.md`).

## Image Assistant

- **Cropping:** on upload, image recognition picks a focus area. The priority is one face, then
  several faces, then one object, then several objects. The image is cropped for every
  configured resolution, and editors can adjust any crop. *Rescan* re-runs the analysis.
- **Alt text:** generated on upload with the configured prompt and the connected model, and
  stored in the metadata field **`fsai_altText`**. That field must exist in the project's
  metadata template (`setup-and-configuration.md`).
  - **Single language only.** Metadata holds one value per field across all languages; the
    prompt decides the language. Localised alt text in page context needs a project-level
    script (*What the assistants do*), for example one built with `ai-api.md`.
  - Rescanning an image **overwrites** its alt text. Rescanning a folder only fills the images
    that have no alt text yet.
- Two global alt-text prompts (German, English) ship; custom ones need the
  `ImageAssistantAltText` tag. On Azure, image token usage can exceed the deployment's limits
  (older docs, alt-text page) `[odfs]`.
- **Limits:** no image generation; only JPEG, PNG and WebP; quality drops with blurry or
  low-resolution images.
- The docs list alt text both as working out of the box (*Working with AI in FirstSpirit*) and as
  requiring the metadata template (*Image Assistant*). Treat the metadata field as required.

## Code Assistant

- Analyses, does **not generate**, output code:
  - HTML: accessibility, SEO, web best practice.
  - JavaScript: readability, modern practice, performance, bugs, security.
  - CSS: clean code, selector efficiency, property usage.
- Entries link to the file and line. If nothing appears for the current template, untick
  *Only for current template* to see the whole page.
- Active automatically with a valid AI Suite license (developer getting-started page).
- **Limited in pure headless projects**, where no HTML, CSS or JS is maintained in FirstSpirit.

## AI Content Review (BasicWorkflows, beta)

- An optional AI quality check inside the BasicWorkflows release process. It is not a chat;
  editors give it no instructions at runtime.
- **It never releases.** The four-eyes principle and release rights stay as they are.
- Requires the AI Suite license. Severity levels, the result dialog, the *AI Review Report*
  sidebar and its custom prompt are documented in the **BasicWorkflows documentation**, not in
  the AI Suite docs. Point there for configuration.
- Pair it with the Analyze Assistant and DQM for rule-based checks
  (`docs.crownpeak.com/ai-suite/ai-workflows/`).

## Collaboration AI agents

`@FirstSpiritAI` and custom agents in Collaboration comment threads need the AI Suite
license. A custom agent is a prompt operation enabled for Collaboration by a project admin.
Everything else is owned by
`firstspirit-collaboration/references/concepts-and-setup.md`.

## Data flow (what to tell a privacy question)

Content travels from the FirstSpirit backend to the configured model. The docs say no user
metadata is sent, and every AI-made change is recorded in the project history
(*Working with AI in FirstSpirit*) `[odfs]`. Which vendor sees the content is decided by the
endpoint configuration — OpenAI, an Azure deployment, or a custom connector. The older
privacy page has no AI-specific statement.
