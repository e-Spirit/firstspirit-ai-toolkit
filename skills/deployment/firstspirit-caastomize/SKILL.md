---
name: firstspirit-caastomize
description: >-
  EXPERIMENTAL. Caastomize, the FirstSpirit module that delivers a lean CaaS JSON that
  template developers can customise: each page reference and dataset is rendered through
  the CaastomizeJSON output channel, which starts from the `leanJSON` variable and
  reshapes it with `remove`, `rename` and `put` or writes its own JSON, then PUTs it into
  the project's own CaaS collections beside CaaS Connect. Use for "lean / customisable
  CaaS JSON", "leanJSON", "CaastomizeJSON channel", the `CaaS` presentation channel,
  section and link template bodies, the service (`caastomize.json`, S3 media, eventing),
  the project app, full sync, eventing for page references and datasets, the lean JSON
  format (`_revision`, rich text, content projections, `$ref` and `_included`), project
  settings, routes, and how it differs from CaaS Connect's toJson. A
  pre-release: check the module version first. For reading CaaS, toJson and frontend
  authentication use firstspirit-headless.
metadata:
  source-commit: "17f78f9"
  published: "2026-11-02"
  toolkit-version: "0.8.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# Caastomize (experimental)

> **Pre-release, not generally available.** This skill describes Caastomize **0.0.21**
> (2026-10-27). Further features follow until the release, and behaviour, names and
> defaults can change between builds. Ask which version is installed, say that it is a
> pre-release, and do not present it as a supported replacement for CaaS Connect. Do not
> promise features or dates for later versions.

Caastomize is a FirstSpirit module that sends FirstSpirit content to CaaS as JSON **you
shape in a template**. It renders every page reference and dataset through an ordinary
output channel named `CaastomizeJSON`. That channel starts from a compact, CMS-agnostic
document (the variable `leanJSON`), and the template can trim, rename and extend it or
write its own JSON instead. The result goes into two CaaS collections of the project's
own. CaaS Connect and its collections stay untouched; both modules can run on one server
and one project.

Every fact below was read in the module source (`[core]`), unless a line is tagged
otherwise. `[verify]` marks what the source does not settle.

| | CaaS Connect | Caastomize 0.0.21 |
|---|---|---|
| JSON comes from | toJson, a fixed shape; change the form, not a template | The `CaastomizeJSON` output channel: `leanJSON` reshaped, or your own JSON; section and link templates can shape their own part, also as catalog cards |
| Shape | Full FirstSpirit structure (`firstspirit-headless/references/caas-connect.md`) | The lean JSON: envelope `_id`, `_type`, `_locale`, `_revision` (+ `_pageId`), form fields under their names, sections in `body:<name>`, references as `$ref`, media in `_included` (`references/lean-json-format.md`) |
| Elements | `firstspirit-headless/references/caas-connect.md` → *What gets synchronised* | Page references, datasets and the project settings as documents; media binaries to S3 (when configured) and linked from `_included`; no global pages |
| Collections | Same page → *Collections* | `<project-uuid>.caastomize.preview` / `.caastomize.release` (never CaaS Connect's) |
| Updates | Eventing on change and release, plus jobs | Full sync schedules, plus **eventing for page references and datasets** (change, release, delete; move for page references); sections, media and project settings only by full sync |
| Preview | ContentCreator preview of the frontend | The lean JSON in the ContentCreator and SiteArchitect preview through the `CaaS` presentation channel |

## The mental model (read this before answering)

1. **One output channel, by name.** Installing the project app creates the template set
   `CaastomizeJSON` (extension `json`; presentation channel `CaaS` when the server has one,
   else the system channel `JSON`) and fills an empty channel body on every page template
   (the project-properties template included) and every table template with the default
   body. Existing bodies are never overwritten. Section and link templates (catalog cards
   use them too) get no default; a body you write there shapes that element inside every document.
2. **The default body is one line: emit `leanJSON`.** `leanJSON` holds the element per
   language in Caastomize's default format, the lean JSON (`references/lean-json-format.md`).
   A template reshapes it by chaining `remove("field")`, `rename("old", "new")` and
   `put("_field", value)` before emitting it; fields you add get an underscore prefix.
   Details and examples: `references/lean-json-and-channel.md`.
3. **One document per element and language.** Document id `<gid>.<locale>` (`de_DE`), in the
   preview or release collection of the project. Only languages marked for generation are
   rendered. The rendered body must be exactly one JSON object. The project settings are
   one more document per language, `projectsettings.<locale>`.
4. **Two triggers.** The full sync schedules (*PREVIEW* and *RELEASE*) send every page
   reference and dataset of that state and, when an S3 target is configured, upload every
   medium's original binary first. Eventing sends a page reference's document when it or
   its page changes, is released, moved or deleted, and a dataset's document when the
   dataset changes, is released or deleted (deleted documents are removed). Sections, media
   and the project settings change only by full sync. `references/setup-and-sync.md`.
5. **Consumers read with scoped keys.** The module creates four API keys per project (read
   and read-write for each collection). Reading CaaS itself, secure tokens and filters are
   `firstspirit-headless/references/caas-platform.md`. References are not resolved: a
   consumer joins `$ref` with the document's own `_included`.

## Pick the reference

| You need… | Read |
|---|---|
| The `CaastomizeJSON` channel and its presentation channel, the lean JSON in the preview (Lean JSON Content Processor), the project-properties body and shared variables, `remove` / `rename` / `put`, `_included` post-processing, bodies on section and link templates (also for catalog cards), writing your own JSON, calling a script, URLs and routes, what makes a render fail, preview vs release rendering, languages | [references/lean-json-and-channel.md](references/lean-json-and-channel.md) |
| The lean JSON format: key names and the underscore prefix, envelope and `_revision` (with `_etag` and the `_pageRevision` workaround), bodies and sections, form fields per input component, rich text, `$ref` and `_included`, content projections, what the format leaves out | [references/lean-json-format.md](references/lean-json-format.md) |
| Installing and configuring: service (`caastomize.json` with the `s3` and `eventing` blocks), project app and its tabs, what activation creates, the full sync (media pass, document pass, project settings, the summary line), eventing (what it covers, the queue, what to do when it stops), limits, uninstall | [references/setup-and-sync.md](references/setup-and-sync.md) |
| What lands in CaaS and S3: collection names, document ids and URLs, media URLs, editing in ContentCreator (OCM), the API keys and how a consumer gets one, reading the lean documents, coexistence with CaaS Connect | [references/delivery-in-caas.md](references/delivery-in-caas.md) |

## Rules when answering

- **Say "pre-release" and name the version.** The answer is about 0.0.21. For an older
  build say that this skill describes 0.0.21 and ask what that build lacks. For a newer one
  say what may have changed. Never promise what a later version brings.
- **Eventing covers page references and datasets.** A changed section, medium or project
  setting reaches CaaS with the next full sync (a section also when its page reference is
  sent again). Say so before anyone plans a near-real-time feed of them.
- **Routes are the template's job.** The default JSON carries no route, and URLs come from
  the Advanced URLs factory set in the module. Bridge it with templating
  (`references/lean-json-and-channel.md` → *URLs and routes*), and say that the module is
  not generally available and that routing is not complete in this version.
- **Keep `_id` as it is.** CaaS rejects a document whose `_id` differs from the id in the
  URL. Do not `remove`, `rename` or `put` over `_id`; hand-written JSON writes it exactly as
  `<gid>.<locale>` (the module does not check it).
- **Emit one JSON object, always.** An array, a bare value, `null` or a render that logs an
  error fails that element and marks the run failed. `leanJSON` is `null` for element
  types the headless API does not support. The same holds for a section or link body,
  also in a catalog card: its failure fails the document that contains it.
- **The prototype tabs do nothing.** The project app's *Eventing*, *Error handling* and
  *JSON output* tabs carry a banner saying so; do not tell anyone to configure them.
- **Template syntax is not owned here.** For `$CMS_VALUE$`, `$CMS_IF$`, functions and
  `ChannelSource` files use `firstspirit-templating-reference`; for how to design JSON
  keys and templates for headless use `firstspirit-template-design`; for writing a
  channel body over REST use `firstspirit-rest-api` (*Channel-Sources*); for a script
  called from the body use `firstspirit-scripting`.
- **Treat `caastomize.json` as a secret.** It holds the CaaS tenant admin key and, with an
  S3 block, static S3 credentials; restrict the file to the server user. Never put the
  admin key in a frontend; hand out the scoped read key.
- **CaaS Connect questions go to `firstspirit-headless`.** Caastomize does not change CaaS
  Connect's toJson or collections and does not read its configuration.

## Pointers

- **CaaS read API, secure tokens, CORS, CaaS Connect's toJson:**
  `firstspirit-headless/references/caas-platform.md` and `firstspirit-headless/references/caas-connect.md`.
- **Template language and channel files:** `firstspirit-templating-reference`.
- **Designing templates and JSON for headless:** `firstspirit-template-design`.
- **Writing template bodies over REST:** `firstspirit-rest-api/references/content-templates.md`
  (*Channel-Sources*, *Determine Template-Set UID*).
- **Scripts called from a template:** `firstspirit-scripting/references/script-contexts.md`.
- **Installing modules, server configuration directories, presentation channels:**
  `firstspirit-operations`.
- **ContentCreator preview of a frontend (OCM, `TPP_SNAP`):**
  `firstspirit-headless/references/preview-and-editing.md`; what Caastomize adds is
  `references/delivery-in-caas.md` → *Editing in ContentCreator (OCM)*.

## Sources

Caastomize 0.0.21 (FirstSpirit 5.2.260507 or later): the module source and the source of
the library that builds the lean JSON; observations on a project running 0.0.21
(2026-10-28 and 2026-10-29).
Evidence tags: `[core]` read in the product source · `[observed]` seen on a running system
· `[verify]` not settled by the source or not yet seen on a running system.

<!-- feedback-footer:v1 -->
## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
