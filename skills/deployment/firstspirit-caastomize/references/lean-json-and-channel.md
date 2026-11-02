# The CaastomizeJSON channel and `leanJSON`

Caastomize 0.0.21, a pre-release that is not generally available. `[core]` applies to every
line unless it says otherwise; `[observed]` lines were seen on projects running 0.0.21 on
2026-10-28 and 2026-10-29. The format of the JSON itself is `lean-json-format.md`.
For the template language itself (`$CMS_VALUE$`, `$CMS_IF$`, functions, `ChannelSource` files) see
`firstspirit-templating-reference`.

## The channel

| Property | Value |
|---|---|
| Template set uid and display name | `CaastomizeJSON` |
| Presentation channel | `CaaS` when the server has a presentation channel of that name, otherwise the system channel `JSON` |
| File extension | `json` |
| Active | yes |
| Rendered as documents | page references (through the **page template**), datasets (through the **table template**) and the project settings (through the **project-properties template**, a page template) |
| Rendered inside a document | sections, links and catalog cards whose **section or link template** has a body in this channel (a catalog card uses a template from the catalog's sources) |
| Not rendered | media (they are `_included` entries and binaries in S3) |

The module creates the template set when the project app is installed or updated, or from
the project app configuration (*General → Create output channel*, later *Recreate output
channel*). Each run fills the channel body of page templates (the project-properties
template included) and table templates whose body is **effectively empty**: blank, or only `<CMS_HEADER></CMS_HEADER>`, which FirstSpirit
puts into every new channel. A body with anything else in it is yours and is never
overwritten, also not by *Recreate*. Section and link templates are not
filled; a body there is always yours (next sections).

### The project-properties body

The project-properties template gets the same default body, but use this one there:

```
$CMS_VALUE(leanJSON, default:"")$
```

FirstSpirit evaluates the project-properties body before every page and dataset render as
well, without `leanJSON` (seen as one `Undefined variable 'leanJSON'` warning per page,
dataset and language in a full sync, 2026-10-28, 0.0.21 `[observed]`). With the plain
default body each of those evaluations logs that warning; `default:""` keeps the log clean. The body renders the project settings document
(`setup-and-sync.md` → *Project settings*) and must emit one JSON object like any other.

Variables the body sets with `$CMS_SET$` stay available to every page and table template
`[verify]` (FirstSpirit behaviour, not the module's), so
shared values are defined once:

```
$CMS_SET(set_site, "Acme")$
$CMS_VALUE(leanJSON, default:"")$
```

and used in a page template:

```
$CMS_VALUE(leanJSON.put("_site", set_site))$
```

**A page or table template added after installation has no body and sends nothing**
until provisioning runs again (*Recreate output channel* or a project app update). A full
sync reports such templates (see `setup-and-sync.md` → *Reading the result*). For a template
created over REST, write the body in the same step: the channel source `CaastomizeJSON` with
`$CMS_VALUE(leanJSON)$` (`firstspirit-rest-api/references/content-templates.md` →
*Channel-Sources*).

### The `CaaS` presentation channel and the preview

The system channel `JSON` cannot carry a post-processor, so the lean JSON is not visible in
the preview through it. For the preview an administrator creates, once per server, a
presentation channel named **`CaaS`** (exactly that spelling), file extension `json`, with
the **Lean JSON Content Processor** (public component `leanJSON`) as its post-processing;
where presentation channels live in the server properties is `firstspirit-operations`.

- A template set created **after** that uses the `CaaS` channel. A `CaastomizeJSON`
  template set that already exists keeps its channel; switch it by hand in the project
  properties (*Template sets* → `CaastomizeJSON` → presentation channel `CaaS`).
- In a preview generation (ContentCreator and SiteArchitect) the processor puts `leanJSON`
  into the context, so the same body renders there as in the sync. The full sync does not
  use the processor; its renderer supplies the variable itself.
- A body whose output is **empty or only whitespace** gets the lean JSON document as its
  output in the preview; in the sync it is a failure ("not a JSON object"). Do not rely on
  the preview's leniency.
- What ContentCreator shows is the project's choice, and both ways are fine: to see the
  lean JSON in the preview, set `CaastomizeJSON` as the preview template set in the project
  properties; for an editable frontend, set an external preview URL instead
  (`delivery-in-caas.md` → *Editing in ContentCreator (OCM)*).
- Asset URLs in the preview come from the service's media settings (next sections); a
  project without an S3 target shows `_included` assets without `url`.

## The default body

The shipped body is a comment and one statement: emit `leanJSON`.

```
$-- leanJSON holds the CMS-agnostic representation of this element. Customise it before
    emitting by chaining remove("field"), rename("old", "new") and put("field", value).
    Section and link templates can have a body like this one, too. --$
$CMS_VALUE(leanJSON)$
```

(Comment shortened; the shipped one says the same, and that the body must emit exactly one
JSON object.)

## What `leanJSON` is

- A variable the module puts into the render context for every element and language. It
  holds the element in Caastomize's default format, the lean JSON, built from the element's
  form data (`lean-json-format.md`).
- Built **once** per element and language, on first use. Changes you chain onto it stay for
  the rest of that render.
- Emitted as JSON: `$CMS_VALUE(leanJSON)$` prints the current document serialised as JSON.
  The characters `<`, `>`, `&`, `=` and `'` appear escaped in the raw text (`\u003c` and so
  on); every JSON parser turns them back, so only a search in the raw JSON sees the
  difference.
- `null` when the headless API does not support the element type; the module logs a warning
  naming the element, and the render then fails because `null` is not a JSON object.

### The format and `_included`

The keys, the envelope (`_id`, `_type`, `_locale`, `_revision`, `_pageId`), sections, form
fields, rich text, references and content projections are in `lean-json-format.md`. To see
a real document, open the preview with the `CaaS` channel, or run a preview full sync and
read one document from the preview collection (`delivery-in-caas.md`).

After the body has rendered, the module post-processes a document that has `_included`:

- Every `_included` entry nothing in the document references any more is dropped (so a
  `remove` of the referencing field also removes the include), and an empty `_included` is
  removed. A reference *inside* `_included` does not keep another entry alive.
- Every remaining **asset** gets a `url`: the public URL of its original binary in the
  configured S3 target (`delivery-in-caas.md` → *Media*). Without an S3 target there is no
  `url`.
- Nothing is resolved into place: `_included` holds media only, and the consumer joins
  `$ref` with it itself. References to page references and datasets stay pointers.

## Reshaping it

Three methods, each returns `leanJSON`, so they chain:

| Method | Effect |
|---|---|
| `remove("field")` | Drops a top-level field |
| `rename("old", "new")` | Moves the value to a new key; nothing happens when `old` is absent |
| `put("field", value)` | Adds or replaces a top-level field; `put("field", null)` removes it, so an empty form field handed over as `null` does not fail the render |

```
$CMS_VALUE(leanJSON.remove("pt_internalNote").rename("pt_headline", "title").put("_channel", "web"))$
```

- The methods act on **top-level keys only**. There is no path syntax for nested fields
  `[core]`; nested changes need your own JSON (next section) or a body on the nested
  element's template (*Bodies on section and link templates*).
- `put` takes strings, numbers, booleans, and lists or maps built in the template.
  Convert a FirstSpirit object to a string or number first (`.toString()`, `.id`,
  `.uid`): put as it is, it is serialised field by field, unpredictably, and a circular
  object fails the render.
- We recommend an underscore prefix for every field you add (`_channel`, `_route`): it
  marks what is not maintained content from a form field (`lean-json-format.md` → *Key
  names*).
- Never touch `_id` (see *What makes a render fail*).
- `leanJSON.get()` returns the document map itself (`null` for unsupported types). Use it
  only to **read**, for example `$CMS_IF(leanJSON.get().containsKey("st_image"))$` or
  `leanJSON.get().get("pt_headline")`. Change the document only with `put`, `remove` and
  `rename`; changing the map directly is not recommended.

### Calling a script from the body

A script can transform what the template cannot, for example turn a rich-text structure
into plain text. Pass the map for reading, let the script compute, and `put` its result:

```
$CMS_SET(set_doc, leanJSON.get())$
$CMS_RENDER(script:"caastomize_shape", doc:set_doc)$
```

The call syntax and how a template script receives its parameters and returns output are
`firstspirit-templating-reference` (*composition*) and
`firstspirit-scripting/references/script-contexts.md` (*Template / generation script*);
the script reads the map and returns its result; the template writes it with `put`, so the
body shows every change. A script that changed the map itself would change the document
too, which the body would not show: not recommended.

## Bodies on section and link templates

A section template or a link template may carry a `CaastomizeJSON` body too. A catalog
card (`FS_CATALOG`) is not a template type of its own: it uses one of the templates the
catalog's sources name in the form (a section or a link template), and that template's
body shapes the card. Then:

- Its `leanJSON` holds the JSON of **that** section, link or card, and the body's output
  **replaces** that element's default JSON in every document that contains it (page
  documents, and datasets that reference it).
- A template without a body, or whose body is empty or only the marker `$-- not edited --$`,
  keeps the default JSON. Provisioning never fills these templates; the body is always
  yours. Over REST: `firstspirit-rest-api/references/content-templates.md` → *Channel-Sources*.
- The body must render **exactly one JSON object** with no template error; a failure fails
  the whole document that contains the element ("Rendering section '…' failed").
- Bodies of links and of catalog cards render with the containing element as link root (a page
  reference, or the site store root for a dataset), so `$CMS_REF$` works in them.
- The page template's body sees the nested output already in place: `leanJSON` on the page
  level contains the reshaped sections. A page body that writes its own JSON without
  `leanJSON` ignores the nested bodies.

## Writing your own JSON instead

The channel is an ordinary output channel, so the body can be any template code that emits
**one JSON object**: hand-written fields, values from the form, `$CMS_IF$` for optional
parts, links via `$CMS_REF$`. The template language and its functions (including JSON
encoding of values) are `firstspirit-templating-reference`. Write `_id` exactly as
`<gid>.<locale>`. A hand-written body that
wants media URLs has to write `_included` with `$ref` and `_type: "asset"` entries itself;
the post-processor then adds the `url`.

A sensible middle path is to keep `leanJSON` and only trim it, so that new form fields keep
arriving without template work.

## Languages, preview and release

- One render per **language marked for generation**. Other languages produce no document.
- **Preview** syncs and eventing of the preview store render the unreleased state (the
  module switches the renderer to preview), also for datasets. **Release** renders the
  released state.

## URLs and routes

This version puts no route into the JSON. Bridge what is missing with templating.

- **The renderer uses the Advanced URLs factory**, set in the module; this version has no
  setting for it. Advanced URLs is part of FirstSpirit (`firstspirit-operations` for its
  configuration).
- **No document carries a route.** The default JSON has no URL for a page reference and
  none for a dataset; add what the frontend needs in the page template's body.
- `$CMS_REF$` in the `CaastomizeJSON` channel yields paths of that channel `[observed]`:
  `ref(#global.node).url` gives only the file name (`home.json`), with `abs:1` the
  full path (`/home/home.json`), with `.json` and without a language prefix. In
  the SiteArchitect preview the same expression yields a preview URL.
- **For frontend routes, reference the HTML template set** `[observed]`, so the path has no
  `.json`:

  ```
  $CMS_SET(route)$$CMS_REF(#global.node, abs:1, templateSet:"html")$$CMS_END_SET$
  $CMS_VALUE(leanJSON.put("_route", route.toString()))$
  ```

  The result is the page's HTML path, for example `/products/overview.html` or
  `/about-us/company/index.html`: with `.html`, without a language prefix, and with a
  suffix such as `index-2.html` where paths collide, as the project's Advanced URLs
  configuration decides. The frontend maps it to its own URL (strip the extension, add the
  language). `templateSet` takes the uid of the project's HTML template set.
- A body emits **one** JSON object: with several additions, collect them with
  `$CMS_SET(void, leanJSON.put(…))$` and end with a single `$CMS_VALUE(leanJSON)$`.

- Detail pages of a content projection have no route per dataset; the frontend builds them
  itself, for example `<route of the detail page>/<dataset gid>`.
- Media URLs in `_included` come from the media target, independent of all this
  (`delivery-in-caas.md` → *Media*).

## What makes a render fail

Each failure skips that element and language, is logged, and marks the run failed (the
schedule ends with an error; an eventing operation logs a warning):

| Cause | What happens |
|---|---|
| The body rendered with an error (for example an undefined variable) | Failure, **even if** the output is still valid JSON: a half-rendered template must not be stored |
| The output is not JSON, or is an array, a string, a number or `null` | Failure: "rendered a …, not a JSON object" |
| A section or link body in the document (also of a catalog card) failed or did not render one JSON object | Failure of the containing document, naming the nested element |
| The element's template has no `CaastomizeJSON` body | Skipped and counted separately ("skipped because their template has no CaastomizeJSON body"); one log line names all such templates |
| The project has no `CaastomizeJSON` template set at all | The run stops at once with one message |
| `_id` in the body differs from the document id | CaaS rejects the PUT; the log shows the HTTP status and CaaS's reason ("_id in content body is different than id in URL"). Exception: the project settings document, whose `_id` Caastomize always sets to its key |

Up to five render failures per template are logged in full; the rest are summarised in one
line per template, so one broken table template does not flood the server log.
