# SmartSearch Connect — FirstSpirit content straight into the index

The FirstSpirit module (`smartsearch-connect-<version>.fsm`) that sends released pages,
datasets and media to SmartSearch as JSON, on release (eventing) and in generation jobs.
Version **1.15.2**. Sources: *SmartSearch Connect* documentation, the *Server Administrator*
page and the release notes (`docs.e-spirit.com/module/smartsearch-connect/`) `[odfs]`, unless
a line says otherwise. Lines tagged `[core]` were read in the module source (1.15.2, plus
the SmartSearch server 5.12.2 it talks to); class names are not in the FirstSpirit runtime jar.

## What it does

1. On a full generation, a partial generation step or a release event, the module renders the
   element's FirstSpirit JSON (`fsToJsonVersion` 1.2 in the documented sample) plus URL,
   title, image URLs and metadata. Field for field identity with CaaS Connect's JSON was
   not compared.
2. It sends that JSON to SmartSearch, where an **API Data Generator** `FS_<name>` receives
   it and flattens it into a SmartSearch document. `<name>` is the configured name, else the
   project name **at the time of the run** `[core]`. Calls go to the generic API,
   `…/rest/api/<v1|v2>/smartsearchconnect/FS_<name>/<language>/<uid>` (PageRef or media uid,
   dataset identifier) (`indexing.md` → *Generic API*) `[core]`.
3. On first contact SmartSearch creates the DG and an identically named **Prepared Search**,
   already linked. The DG stays *API Ready*; data is committed to Solr after **30 seconds**.

Not supported: projects that use **fragments**. The module is deliberately "not compatible
with every FirstSpirit project".

## Setup

### Server: *SmartSearch ConnectConfigurationService*

ServerManager → *Server Properties → Modules*, install the FSM, configure the service:

| Field | Meaning |
|---|---|
| **Endpoint** | SmartSearch server URL **including the port** (on-prem typically `:8181`) |
| **Authentication** | `BASIC` (default): user and password of a SmartSearch user with all rights to create Data Generators and Prepared Searches. `OAUTH` (1.15.0+, for a server in OIDC mode): token endpoint, client id, client secret; OAuth 2.0 client-credentials grant (`[core]`). The endpoints the module calls need *Data Generator* Read, Write and Execute (`indexing.md` → *Permissions*) |
| **Ignore missing ssl certificate (just for tests)** | Accept an invalid certificate. Test systems only |

- For OAUTH, prepare the identity provider first: a client with service account and
  client-credentials grant; the service account needs an **email address** and membership in
  the group that grants the DG/PS rights (`operations.md`, OIDC).
- Password and client secret are stored **encrypted** when FirstSpirit configuration
  encryption is on (start parameter `password.encryption.active=1`, 1.12.0). Since 1.15.0 the
  file has an `auth` block; the old top-level `user` / `pwd` format is still read as BASIC.
- Saving the configuration **restarts the service** (1.15.0).
- Everything else is project configuration, identical on-prem and in the cloud.

### Project: *SmartSearch ConnectProjectApp*

ServerManager → *Project Properties → Project Components → Add*:

| Setting | Meaning |
|---|---|
| **Name** for DG and PS | Default: the project name. Letters, digits, `_` and `-` only |
| **Initialize in SmartSearch!** | Creates DG and PS now. The result is in the FirstSpirit server log (and the dialog). Doubles as the test of the service configuration |
| **URL Creator** and **prefix** | The same URL factory and prefix as the website generation, otherwise result links are wrong. Headless: see below |
| **Inherit metadata** | Without it a document carries only the element's own metadata. (noindex inheritance works regardless) |
| **API version** (*Configure API Request*) | V1 or **V2** (recommended). The module's default when nothing is set is **V1** `[core]`, so select V2 explicitly; optional extra output channel |
| **Media types** | Active file extensions to transfer; custom extensions can be added (layout reworked in 1.14.0) |
| **Image resolutions** | Resolutions whose URLs are sent; the original is always sent |
| **SmartSearchObject mode** | *Use only FormData* (default `[core]`) / *FormData and SmartSearchObject* / *only SmartSearchObject* (see SmaSeJSON) |

Only media **referenced** in the project are processed.

## Filling and updating the index

| Trigger | How | Effect |
|---|---|---|
| **Full generation** | Project job with the action *SmartSearch Connect push* | Sends every released element; **afterwards deletes every document it did not update**. Since 1.15.2 that cleanup no longer runs after failed transfers (earlier versions could delete documents), and since 1.14.12 temporary network errors are retried instead of aborting the job |
| **Partial generation** | Add a script action **after** the generation action: `#! executable-class` then `com.espirit.smartsearch.initialdeployment.PushPreviousGenerationExecutable` (class confirmed in 1.15.2 `[core]`) | Pushes the released state of what the preceding generation produced |
| **Eventing** | Automatic on release (create, change, delete) | Requires a workflow that also releases dependent objects (page → its page references), for example **BasicWorkflows** |

How the full run cleans up `[core]`: it remembers the server time of its first successful
write and afterwards deletes every document of its DG that was last written before that
instant. The pruning is skipped when the run was cancelled or failed. Send errors 500, 502, 503, 504
and timeouts are retried; **401 and 403 abort** the run (credentials or permissions).

Run a full generation first, then regularly (media below). Data appears in search shortly
after the 30-second commit; the cockpit's field list for the DG is cached and can take a few
minutes to show new fields.

## Shaping the document

### SmaSeJSON template set

Create a template set named **`SmaSeJSON`** with target extension **JSON** and set the
ProjectApp mode to include the SmartSearchObject. In each page or table template's SmaSeJSON
channel, output a JSON object:

```text
{
  "title": "$CMS_VALUE(pt_title)$",
  "locale": "$CMS_VALUE(#global.locale)$"
}
```

- **Flat only:** strings and arrays of strings. No nesting.
- Values here **override** the automatically generated ones (`title` above replaces the
  computed title).
- An **empty string clears** a generated field, e.g. to keep a sensitive input out of the
  index: `{"FS_pt_supersecret": ""}`.
- Fields computed later on the SmartSearch side (enhancers) can override your values; check
  the DG's enhancers if a change does not show.
- Datasets are sent without a page around them, so their JSON differs from what the preview
  shows.
- The output must be valid JSON. The module renders the channel named exactly `SmaSeJSON`
  and parses the result; it does **no escaping** of its own. On invalid JSON it logs an
  error (the uid only at DEBUG level) and sends the document with an
  **empty** `smartSearchDocument`, so the job does not fail `[core]`. Escaping `$CMS_VALUE$`
  output for JSON (quotes, backslashes, line breaks) is the template's job; for the helpers see
  `firstspirit-templating-reference`.

### Field names: API V1 vs V2

| Version | Pattern | Example |
|---|---|---|
| V1 | `FS_L<depth>_<input name>` | `FS_L5_st_title` (fifth level: page reference → page → section …) |
| **V2** (recommended, focus of development) | `FS_<input name>___<child input name>` | `FS_pt_slider___st_description`; repeated names become multi-value |

Text content is merged into `content` in both. Inputs usable as facets (dates, drop-downs)
are processed differently between the versions. The facet **`fsType`** holds the FirstSpirit
element type (`PageRef`, `Dataset`, …), and `identifier` the element UUID.

To see the JSON a page reference produces, run this BeanShell in SiteArchitect on it
(context `e` = the element); URL, image links and title are added later by the module:

```text
renderingAgent = context.requireSpecialist(de.espirit.firstspirit.agency.RenderingAgent.TYPE);
templateSource = "$CMS_SET(#global.json.dataRenderDepth, 1)$$CMS_SET(#global.json.formatVersion, 1.2)$"
  + "$CMS_SET(#global.json.sectionTemplateRendering, false)$$CMS_SET(#global.json.useDefaultHtmlTemplateProvider, true)$"
  + "$CMS_SET(#global.json.metaDataRendering, true)$$CMS_SET(#global.json.resolveDynamicContent, true)$"
  + "$CMS_VALUE(json(#global.node))$";
jsonOutput = renderingAgent.createRenderer(templateSource).linkRoot(e).render();
```

For a dataset the documentation renders `json(idProvider)` with
`linkRoot(<site store>)` and `additionalContext("idProvider", e)`.

## Keeping things out

| What | How |
|---|---|
| **Pages** (and folders) | Metadata input `CMS_INPUT_TOGGLE name="md_smartsearch_noindex"`; add a rule so it is visible only in the site store (`STORETYPE` = `sitestore`). A set flag on a folder hides its pages (fixed for hidden parent folders in 1.3.7) |
| **Datasets** | Boolean column **`smartsearch_noindex`** in the table, with an input in the table template |
| **Single fields** | Empty string in SmaSeJSON |
| **Untranslated pages** | Removed automatically when a page is no longer marked translated (1.11.4) |

```xml
<CMS_INPUT_TOGGLE name="md_smartsearch_noindex" type="radio" hFill="yes">
  <LANGINFOS><LANGINFO lang="*" label="Hide"/></LANGINFOS>
  <ON><LANGINFO lang="*" label="On" description="Hide this site from search index."/></ON>
</CMS_INPUT_TOGGLE>
```

- Setting the flag removes already indexed elements without a new full generation (1.11.4).
  Folder changes still need a full generation or a change to an affected page.
- Adding the dataset column later with a default value only takes effect when each dataset
  changes; update many datasets by script.

## Datasets

- Sent through the **preview page** registered on the table template; with several templates,
  the one with the **most input fields** is used. A preview page is therefore mandatory.
- Datasets are indexed **even if** the preview page is hidden (they can be used in a
  single-page app via CaaS). Hide the preview page and **content-projection pages**, otherwise
  records appear several times.

## Media

- **Images are not analysed**, and `thumbnail` is **not** filled. Select the resolution you need
  in the ProjectApp and map its URL in the result template (or copy it to `thumbnail` in an
  enhancer).
- **Files** (PDF, DOCX …) are **not sent**: the module sends the URL and SmartSearch
  **downloads** the file, so the URL must be reachable from SmartSearch. With eventing the
  file may not be published yet when SmartSearch fetches it, hence regular full generations.
- An image-only PDF has empty `content` and is not indexed; give it content in an enhancer.
- Not processed: media embedded via `CMS_INPUT_IMAGEMAP`, `FS_INDEX` or the Media DAP.
- **Remote media**: the resolution must exist in both projects; the remote project's
  configuration builds the URL. Events for remote files fire only in the remote project, and a
  full generation covers only the source project's files: configure Connect for the remote
  project too and combine both DGs in one Prepared Search.
- Media-type filter caveat: if a medium has different types per language, types not in the
  filter are transferred too when another language's medium qualifies.

## Headless with CaaS

The search result must lead to CaaS content, not to a static URL. Two options:

1. Select the **CaaS Connect Url Factory** as URL creator: `link` then holds the CaaS path of
   the element.
2. Keep another URL creator and build the CaaS URL on the client: the element UUID is in
   `identifier`; add the locale with SmaSeJSON (`"locale": "$CMS_VALUE(#global.locale)$"`),
   and take the collection prefix from the CaaS Connect ProjectApp (*CaaS REST API endpoints
   → Release Collection API*). Output `identifier`, `locale` and `link` in the Prepared Search.

CaaS URL structure, URL factories and document ids are owned by
`firstspirit-headless/references/caas-connect.md`.

## In SmartSearch afterwards

- Add **`link`** (and other fields you render) to the auto-created PS's output.
- Facets `language` and `fsType` are available immediately.
- Debug logging of incoming data: logger `de.arithnea.haupia.datageneration.crawler.api.reactive`
  at `DEBUG` (`logback-spring.xml` or the actuator, `operations.md`).
- Test only: `API_CRAWLER_COMMIT_WITHIN=1000` (ms) on the SmartSearch system shortens the
  30-second commit. Not for production.
- On-prem: `haupia.connect.datagenerator.pool.size` caps how many FirstSpirit projects get a DG
  (default cores × 500); below the number of connected projects, some projects' data is not
  received (admin manual).

## Limits and traps

- **Project name:** no spaces. **Do not rename the project**: SmartSearch cannot follow and
  creates a new DG and PS, i.e. a new index. A **name configured in the ProjectApp** is used
  instead of the project name, so it survives a rename `[core]`; set one before going live.
- Renaming a resolution's display name loses its selection in the ProjectApp.
- The docs name the auto-created objects `FS_<project>` in one chapter and `FS<Project name>`
  in another. The module always prefixes `FS_` to the configured or project name `[core]`.
- The document structure in the index follows the project's template structure; there is no
  generic schema. Inspect it in *Data → Browser*.
- The *Configure API Request* help refers to a "SmartSearch output channel" chapter; the
  request configuration itself is described in the Connect module documentation.
