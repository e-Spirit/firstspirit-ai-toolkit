# Release Notes

## 0.7.0 — 2026-10-28

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 8a9c029 (beta)
- `firstspirit-templating-reference` @ 8a9c029 (beta)
- `firstspirit-scripting` @ 8a9c029 (beta)
- `firstspirit-rest-api` @ 8a9c029 (beta)
- `firstspirit-external-sync-export` @ 8a9c029 (beta)
- `firstspirit-operations` @ 8a9c029 (beta)
- `firstspirit-contentcreator-extensions` @ 8a9c029 (beta)
- `firstspirit-template-design` @ 8a9c029 (beta)
- `firstspirit-cloud` @ 8a9c029 (beta)
- `firstspirit-headless` @ 8a9c029 (beta)
- `firstspirit-module-development` @ 8a9c029 (beta)
- `firstspirit-ai-suite` @ 8a9c029 (beta)
- `firstspirit-smartsearch` @ 8a9c029 (beta)
- `firstspirit-collaboration` @ 8a9c029 (beta)
- `firstspirit-technical-product-knowledge` @ 8a9c029 (beta)
- `firstspirit-technical-tone-of-voice` @ 8a9c029 (beta)
- `firstspirit-workflow-development` @ 8a9c029 (beta)
- `firstspirit-installation` @ 8a9c029 (beta)
- `firstspirit-configuration` @ 8a9c029 (beta)

Changes since 0.6.0 — three new setup skills, and the FragmentCreator-module facts in two existing skills.

- **New: `firstspirit-installation`** — installing FirstSpirit on-premises (Java wrapper, ports,
  launcher, licence file, update and backup) and installing, updating and activating modules per
  server and project: BasicWorkflows, Development Tools, CaaS Connect, Navigation Service, OCM 3.0,
  AI Suite, Collaboration, SmartSearch Connect, DQM Connect, Multisite Management,
  VideoManagementPro, Connect for Commerce. Built from the product documentation; the steps marked
  `[verify]` have not been run on a server yet.
- **New: `firstspirit-configuration`** — configuring a project after it exists: groups and roles,
  store and workflow permissions, external groups on FirstSpirit Cloud, ServerManager labels, and a
  plan-apply-verify permissions tool (a role policy as JSON, applied and read back through the REST
  API). First topic is permissions; module configuration is documented, not yet run.
- **New: `firstspirit-workflow-development`** — building your own workflows: the workflow model,
  building one in the Template Store or from a script, why a workflow is not offered on an element
  (store authorisation, Start-transition rights, the ContentCreator flag, display logic, status
  colours, stuck instances), server-side release options and `ReleaseOperation`, the BasicWorkflows
  and ODFS examples as models. The "not offered" checklist's first two items are verified in
  ContentCreator; the Hello World build is documented from the tutorial and marked `[verify]`.
- **`firstspirit-technical-product-knowledge`** — FragmentCreator: maintenance mode since 2025.1,
  not available from 2025.12, and the modules that went with it; the Markdown Editor module left
  on a server breaks the SiteArchitect's form view on the 2026 releases.
- **`firstspirit-module-development`** — a section on modules that stop linking after a server
  update (why the JVM fails a class the module never calls, how to find the module from the
  client's jar cache, the fix).
- **`firstspirit-installation`** also carries the rule of thumb: deactivate modules of
  discontinued products after a server update.
- Toolkit: README rows for the three skills; release-notes provenance and the session-end note
  as data (polish before 0.7.0); an issue form for skill feedback.


## 0.6.0 — 2026-10-21

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 92709aa (beta)
- `firstspirit-templating-reference` @ 92709aa (beta)
- `firstspirit-scripting` @ 92709aa (beta)
- `firstspirit-rest-api` @ 92709aa (beta)
- `firstspirit-external-sync-export` @ 92709aa (beta)
- `firstspirit-operations` @ 92709aa (beta)
- `firstspirit-contentcreator-extensions` @ 92709aa (beta)
- `firstspirit-template-design` @ 92709aa (beta)
- `firstspirit-cloud` @ 92709aa (beta)
- `firstspirit-headless` @ 92709aa (beta)
- `firstspirit-module-development` @ 92709aa (beta)
- `firstspirit-ai-suite` @ 92709aa (beta)
- `firstspirit-smartsearch` @ 92709aa (beta)
- `firstspirit-collaboration` @ 92709aa (beta)
- `firstspirit-technical-product-knowledge` @ 92709aa (beta)
- `firstspirit-technical-tone-of-voice` @ 92709aa (beta)

Changes since 0.5.0 — two new orientation skills, a session-end feedback hook, and content
updates to nine existing skills.

- **New: `firstspirit-technical-product-knowledge`** — product knowledge for project decisions:
  what FirstSpirit is and is not, Cloud vs. self-hosted, static push vs. headless pull via CaaS
  vs. hybrid, the documented reference architectures, which module or extension a requirement
  needs, what needs a licence, and where the official documentation lives. Statements are tied
  to public documentation; where the documentation is silent, the skill says so and points to
  the CSM, Sales or Support.
- **New: `firstspirit-technical-tone-of-voice`** — tone of voice and terminology for technical
  FirstSpirit texts: product and feature names, developer-facing wording, and rewriting
  existing text to match.
- **New: session-end feedback hook** — an opt-in note at the end of a session and a hand-in of
  feedback as a GitHub issue (`hooks/session-end`, `scripts/submit-feedback.sh`). Nothing is
  sent without your confirmation. The README says how to turn it on (`FIRSTSPIRIT_FEEDBACK=1`). It is
  registered for Claude Code and Cursor; the transcript is read in one pass, and the version
  without `jq` reads escaped paths.
- **`firstspirit-template-design`** — choosing an input component from an editor's need, common
  wording mapped to FirstSpirit terms, cutting a page into templates, output conventions
  (`editorId`, inline vs. form), snippets and the template preview image; corrections after
  the DevCon run. New reference on global content areas: the global content area's template
  renders everything it covers, and the page template only places it with `$CMS_VALUE(#global.gca("REFERENCE_NAME"))$`.
- **`firstspirit-templating-reference`** — availability matrix for GOM parameters, new entries
  for `CMS_INPUT_SECTIONLIST` and `CMS_INPUT_PERMISSION`, snippets, label/extract/thumbnail and
  the preview image; `CMS_INPUT_LIST` is not legacy; a section on global content
  areas (`#global.gca`, nested contexts, variable visibility).
- **`firstspirit-headless`** — new `fsxa-api` reference and a pointer to the public example
  repository for the frontend section.
- **`firstspirit-rest-api`** — the REST module's acquisition path (support ticket, Download
  Portal for on-premise) and SaaS availability (DEV and QA only), plus corrections from the
  DevCon tour and a review of the crash and exception wording. The smoke test's S4 and S5 now
  check the PUT status before judging `/execute`.
- **`firstspirit-cloud`** — one Support-ticket bullet for the REST module. **Correction:**
  earlier versions said CaaS is not backed up. CaaS data in the SaaS environment is backed up
  periodically; the text now says so and points to your CSM or Support for scope, frequency and
  restore (a CaaS you operate yourself still needs your own backup).
- **`firstspirit-api-reference`** — snippets in reports and the API.
- Wording: "FirstSpirit" instead of "Crownpeak" in prose; no team names in shipped text.
- CI shellchecks the skills' scripts as well.


## 0.5.0 — 2026-10-14

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ ba64160 (beta)
- `firstspirit-templating-reference` @ ba64160 (beta)
- `firstspirit-scripting` @ ba64160 (beta)
- `firstspirit-rest-api` @ ba64160 (beta)
- `firstspirit-external-sync-export` @ ba64160 (beta)
- `firstspirit-operations` @ ba64160 (beta)
- `firstspirit-contentcreator-extensions` @ ba64160 (beta)
- `firstspirit-template-design` @ ba64160 (beta)
- `firstspirit-cloud` @ ba64160 (beta)
- `firstspirit-headless` @ ba64160 (beta)
- `firstspirit-module-development` @ ba64160 (beta)
- `firstspirit-ai-suite` @ ba64160 (beta)
- `firstspirit-smartsearch` @ ba64160 (beta)
- `firstspirit-collaboration` @ ba64160 (beta)

Changes since 0.4.1 — three new product skills, and a customer-readability pass over every
published skill after a review by the CaaS product team.

- **New: `firstspirit-ai-suite`** — the FirstSpirit AI Suite in ContentCreator: the four assistants
  and their limits, connecting a model (OpenAI or Azure endpoint, API key header, self-hosted
  models), activating assistants per server and project, prompt configuration (system, global,
  shared and project prompts; operations, options, tags, functions), calling AI from a script or
  module (`GenerativeAIAgent`, `PromptConfigurationAgent`, structured output, function calling,
  streaming) and the plugin points. Beta: the product team has not yet confirmed the text; the
  open statements are marked in the skill.
- **New: `firstspirit-smartsearch`** — SmartSearch: Prepared Searches, data generators and
  indexing, the search API (GET and the 5.13 POST variant, autocomplete), smartsearch.js, the
  SmartSearch Connect module and operations. Reviewed by the SmartSearch team before publication;
  describes 5.12.2 with the 5.13 additions marked.
- **New: `firstspirit-collaboration`** — the Collaboration Java API (comment threads on editors in
  ContentCreator): agents, DTOs, enums, anchoring a conversation to an element, posting as an AI
  agent. The API is `@Experimental`; names verified with javap, no live install behind the text.
- **`firstspirit-headless`** — the CaaS product team's pre-publication review applied: internal
  mechanism descriptions, version history and prototype references removed; the aggregation
  timeout and the "internal fields" claim gone; `sync-gql-apps` as documented; CORS and the
  proxy advice attributed; the ContentCreator API section reduced to a pointer; the
  `firstspirit-pwa` pointers replaced by the public fsxa-api / PWA template; no `[verify]` marks
  left in the text.
- **Every published skill** — a readability pass against the public-text rules: process notes
  ("at research time", "first pass", gap markers) removed, internal names and ticket keys removed,
  pointers to unpublished
  or retired skills replaced by the covering skill or the public documentation and Javadoc, the
  ContentCreator focus wording aligned, a Professional Services helper reference removed from
  `firstspirit-template-design`. Facts read in product source now carry a recorded verdict and
  ship only where the documentation names the surface. The evidence tags (`[jar]`, `[javadoc]`,
  `[odfs]`, `[core]`, `[observed]`, `[verify]`) stay by design: they tell the reader how a claim
  was checked; `[verify]` was cleared only in `firstspirit-headless` and `firstspirit-smartsearch`.
- **Renamed:** `firstspirit-headless/references/for-later-configuration-and-install.md` is now
  `references/configuration-and-install.md` (same content, reviewer's title); the skill's index
  points at the new name.
- Restamped with those edits only: `firstspirit-api-reference`, `firstspirit-templating-reference`,
  `firstspirit-scripting`, `firstspirit-rest-api`, `firstspirit-external-sync-export`,
  `firstspirit-operations`, `firstspirit-contentcreator-extensions`, `firstspirit-template-design`,
  `firstspirit-cloud`, `firstspirit-module-development`.


## 0.4.1 — 2026-10-12

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 2e7b7bc (beta)
- `firstspirit-templating-reference` @ 2e7b7bc (beta)
- `firstspirit-scripting` @ 2e7b7bc (beta)
- `firstspirit-rest-api` @ 2e7b7bc (beta)
- `firstspirit-external-sync-export` @ 2e7b7bc (beta)
- `firstspirit-operations` @ 2e7b7bc (beta)
- `firstspirit-contentcreator-extensions` @ 2e7b7bc (beta)
- `firstspirit-template-design` @ 2e7b7bc (beta)
- `firstspirit-cloud` @ 2e7b7bc (beta)
- `firstspirit-headless` @ 2e7b7bc (beta)
- `firstspirit-module-development` @ 2e7b7bc (beta)

Changes since 0.4.0 — a corrections release. No new skills; six skills carry corrections from a
source-check of the 0.4.0 texts against the product sources and from live re-tests, the other
five are republished unchanged from the same source commit.

- **`firstspirit-templating-reference`** — new `references/templates/pdf-fop.md`: PDF output
  through a second template set and the Apache FOP module (setup, page sequences, bookmarks,
  table of contents, format templates for lists and tables in XSL-FO). The `#list`, `#listitem`,
  `#table` and `#cell` system objects and `listConfig` documented from the product documentation;
  an HTML `ul` format with classes; `.toNumber()` in arithmetic. Rules: a validation's scope is
  inherited unchanged and only the rule's inclusion scope is raised; `ONSAVE` rules never block a
  release; the catalog action is `NEW`, not `ADD`; a null toggle keeps a field visible in
  SiteArchitect and hides it in ContentCreator. Description shortened.
- **`firstspirit-rest-api`** — DOM lists: a list keeps its properties only as `<p><ul style
  start>`, a bare `<ul>` loses them and ContentCreator resets the list type on save; `<ol>` is not
  a FirstSpirit list. Smoke probes W26/W27 for both forms and S1 extended (all run on module
  0.0.25-beta). `POST /scripts/` ignores `location` as well as `type` and `description`; the
  `/execute` body is the script's log records, an uncaught exception is a 500. Never rebuild a page
  blind: revisions endpoints return metadata only; replace single sections by id; reload the
  client store after deleting elements.
- **`firstspirit-scripting`** — FS_BUTTON bound variables corrected (`context`, `element`,
  `language`, `properties`, `drop`, `dropdata` plus PARAMs; `values`, `$field$` and `isDrop` never
  existed); `gc` and `context` per context; BeanShell limits settled on a live engine (`class …
  implements` works, one generic type parameter parses, multi-catch does not); `/execute` returns
  the script's log records.
- **`firstspirit-api-reference`** — `TEMPLATESTORE_SCHEMA` as the uid type of table templates
  and queries; `getName()` deprecated in favour of `getUid()`; `LanguageDataProvider` and agent
  surfaces corrected; `UrlRegistryAgent` is internal API and no longer recommended; templates
  expose `getGomSource` / `getFormDefaults` / `getChannelSource` / `getMetaFormData`.
- **`firstspirit-external-sync-export`** — fs-cli port per connection mode (HTTP 8000, SOCKET
  1088, HTTPS 443), `-e` is a boolean flag, schemas export through `entities:`, the `GidAgent`
  route for missing GIDs, every line re-read in the FSDevTools 4.8.9 sources; the wrapper passes
  the password through the environment only.
- **`firstspirit-template-design`** — build one sample in the client and read the stored form
  back before designing format templates or imports; remove the `FORMATS` reference before
  deleting a format template.
- Restamped unchanged: `firstspirit-operations`, `firstspirit-contentcreator-extensions`,
  `firstspirit-cloud`, `firstspirit-headless`, `firstspirit-module-development`.


## 0.4.0 — 2026-10-08

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 9c191a5 (beta)
- `firstspirit-templating-reference` @ 9c191a5 (beta)
- `firstspirit-scripting` @ 9c191a5 (beta)
- `firstspirit-rest-api` @ 9c191a5 (beta)
- `firstspirit-external-sync-export` @ 9c191a5 (beta)
- `firstspirit-operations` @ 9c191a5 (beta)
- `firstspirit-contentcreator-extensions` @ 9c191a5 (beta)
- `firstspirit-template-design` @ 9c191a5 (beta)
- `firstspirit-cloud` @ 9c191a5 (beta)
- `firstspirit-headless` @ 9c191a5 (beta)
- `firstspirit-module-development` @ 9c191a5 (beta)

Changes since 0.3.1 — three skills join the toolkit (all beta); the eight existing skills are
republished from the same source commit with the corrections listed below.

- **New: `firstspirit-cloud`** (`skills/deployment/`) — FirstSpirit Cloud, the managed SaaS on
  AWS: the constraints to plan around (no server file-system or server-admin access, no custom
  global web apps, locked server configuration, what is self-service and what is a Support
  request, SSO and MFA limits, what is backed up and what is not), the DEV/QA/PROD stages and
  promotion, Git-based development and Template Transport, the module build pipeline and its
  Gradle / FSM-plugin / JDK compatibility chain, identity and access (Keycloak realms, external
  identity providers), S3 + CloudFront caching and invalidation, deploy and generation options,
  redirects, patch days and maintenance windows, backup and recovery, logging and monitoring,
  the go-live checklist. Beta: several operational values (patch cadence, invalidation limit,
  shared-bucket delivery) are documented from one environment and marked for confirmation.
- **New: `firstspirit-headless`** (`skills/deployment/`) — the headless delivery stack: CaaS
  Platform (REST and GraphQL, filtering, sort and projection, reference resolution, named
  aggregations and aggregation stages in GraphQL apps, WebSocket change streams, API keys and
  secure tokens, limits and error codes), CaaS Connect (the `toJson` document shape, preview vs
  release collections, media and rendition URLs), the Navigation Service (endpoints, the `caas`
  format with `idMap` / `seoRouteMap`, route resolution, `customData`) and OCM / TPP / SNAP (the
  `TPP_SNAP` API, `data-preview-id` decoration, the non-headless JavaScript APIs to avoid). Built
  from the product documentation and the platform sources, cross-checked against live sessions
  where noted; items the author could not run are marked **(UNVERIFIED)** in the text.
- **New: `firstspirit-module-development`** (`skills/project/`) — building FirstSpirit modules
  (FSM): `module.xml` and the `@…Component` annotations, resource scopes and Isolated Mode, the
  Gradle multi-project layout (`fsServerCompile` / `fsModuleCompile` / `fsWebCompile`, the 7.x
  plugin split, `checkCompliance`), the Cloud build pipeline, every component type with a
  skeleton (`Executable`, `Service` / `ServiceProxy`, `ValueService`, `ProjectApp` and
  `Configurable`, client plugins, schedule tasks, web-app components, `DataAccessPlugin`,
  `Report`, `UrlFactory`, `UploadHook`, `IDProviderEventAgent` listeners, `GadgetSpecification`),
  the broker idioms, the non-public packages to avoid with their public replacements, and
  `ConnectionManager` from a standalone application. Every class and method name was checked
  with `javap` against the 5.2.261011 and 5.2.240208 runtime jars; the official ContentCreator
  example modules compile against the API the skill describes. Beta: a full review by a module
  SME is still open.
- **`firstspirit-rest-api`**: link-template cards, the inline-link 500, list-attribute rewrite,
  table templates — from a live session, tagged `[observed]`. REST module `0.0.25-beta`: the
  content areas of an existing page template are now a resource (`GET|POST
  …/page-templates/{uid}/bodies/`, `PUT|DELETE …/bodies/{bodyName}`, with the whitelist
  semantics the API document states); "bodies are create-only" is gated to older modules; the
  version-drift notes no longer point at a non-existent `info.version`; the smoke test gains a
  read-only probe for the new resource (R12), which checks that the template exists before
  reading a 404 as a version signal. The content-area *write* behaviour stays `[verify]`: the
  read surface was verified live, no write probe exists yet. From the credentialed runs against
  a `0.0.25-beta` module: the smoke test addresses sections by numeric id from `0.0.24-beta`
  (R6/W3/W4, with a GET-verified fallback to the name on older modules); the module never
  answers `415`; only `name`, `type` and `content` are read on a form PATCH; the GOM examples
  parse (`LANGINFOS` inside `ENTRY`, catalog `TEMPLATES type`, `LINKEDITORS` on links); dataset
  writes are marked as not working yet in the beta module. The OpenAPI snapshot directory is
  resolved from the script's location and the previous snapshot is picked by the timestamp in
  its name, not by modification time.
- **`firstspirit-templating-reference`**: `.convert`/`.convert2` apply the template set's
  conversion rule (no rule = text unchanged); inline `if()` evaluates only the chosen branch
  (corrects an earlier observation); the Navigation result's `isEmpty` is never true, so guards
  test the rendered string; page-group `pos` counts from 1; casing of instructions, functions and
  variables is strict, the getter alias is the only tolerance; `CMS_SWITCH` default placement;
  editor order follows the GOM. Settled by Core reading and a probe page previewed on a 2026.11
  server.
- **`firstspirit-api-reference`**: templates expose `getGomSource` / `getFormDefaults` /
  `getChannelSource` / `getMetaFormData`, not `getFormData`; nothing in the TemplateStore can be
  released; pointers to the new skills.
- **`firstspirit-scripting`**: nothing in the TemplateStore can be released; pointers aligned.
- **`firstspirit-external-sync-export`**: `test` proves the connection only (`test project` opens
  the project); the wrapper hands the password to fs-cli through the environment; the client jar
  must be the server's exact build; pointers to the new skills.
- **`firstspirit-contentcreator-extensions`**: pointers to the new skills.
- `firstspirit-operations` and `firstspirit-template-design` are republished unchanged apart from
  the provenance stamp.


## 0.3.1 — 2026-10-01

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 889cb43 (beta)
- `firstspirit-templating-reference` @ 889cb43 (beta)
- `firstspirit-scripting` @ 889cb43 (beta)
- `firstspirit-rest-api` @ 889cb43 (beta)
- `firstspirit-external-sync-export` @ 889cb43 (beta)
- `firstspirit-operations` @ 889cb43 (beta)
- `firstspirit-contentcreator-extensions` @ 889cb43 (beta)
- `firstspirit-template-design` @ 889cb43 (beta)

Changes since 0.3.0 — a hook fix, and the first community corrections to the skills:

- **`firstspirit-api-reference`: seven agents added to the catalogue** (pull request #19 by
  @lopesra): `ModuleAgent`, `ServerConfigurationAgent`, `FileSystemsAgent`, `ProcessAgent`,
  `FeatureToggleAgent`, `UrlRegistryAgent`, `EventBusAgent`, each with its methods. Re-checked
  with `javap` against the 5.2.261011 and 5.2.240208 runtime jars; `FeatureToggleAgent` exists
  only on the newer one and the row says so.
- **`firstspirit-api-reference` / `firstspirit-scripting`: Access API signatures and
  persistence behaviour** (pull requests #17 and #18 by @lopesra, merged into 0.3.0 without a
  release-notes entry — recorded here). Five signatures corrected (`createSection` /
  `createSectionReference` live on `Body`, `Page.getBodyByName`, no `PageRef.getTarget(boolean)`
  / `getUrl()`, `getElementType()` returns `String`, `ClientScriptOperation` is in
  `webedit.server`, release is element-level via `IDProvider.release()`), all confirmed with
  `javap` on both jars. Five persistence statements from a live FirstSpirit 5.2.251308
  (`setFormData` before `save()`, structural operations persist at once, no explicit lock needed
  for `createSection` / `createDataset`, `save("comment")` on an unchanged dataset writes a
  revision, language-independent media return the same binary for any language) are tagged
  `[observed]`. The `createSection` line now also notes the declared `throws LockException`.
- The other six skills are republished unchanged apart from the provenance stamp.

- **Fix (issue #15, second report)**: the PowerShell session-start hook
  (`hooks/session-start.ps1`) failed to parse in Windows PowerShell 5.1. That shell reads a
  `.ps1` without a byte-order mark in the ANSI code page, where the UTF-8 em dash on the
  "Toolkit root" line decodes to a sequence ending in a curly double quote, which PowerShell
  accepts as a string delimiter. The script is now pure ASCII (the em dash and ellipsis are
  built from code points, so the emitted text still matches the bash hook), reads files with
  `-Encoding UTF8`, and escapes non-ASCII in its JSON output as `\uXXXX` so the console code
  page cannot garble it. `scripts/test-manifests.sh` now fails on any non-ASCII byte in
  `hooks/*.ps1`. Not yet confirmed on a Windows machine — see the issue.

## 0.3.0 — 2026-09-30

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 239a7e2 (beta)
- `firstspirit-templating-reference` @ 239a7e2 (beta)
- `firstspirit-scripting` @ 239a7e2 (beta)
- `firstspirit-rest-api` @ 239a7e2 (beta)
- `firstspirit-external-sync-export` @ 239a7e2 (beta)
- `firstspirit-operations` @ 239a7e2 (beta)
- `firstspirit-contentcreator-extensions` @ 239a7e2 (beta)
- `firstspirit-template-design` @ 239a7e2 (beta)

Changes since 0.2.1 — three skills join the toolkit (all beta); the five existing skills are
republished from the same source commit with the corrections and two issue fixes listed below.

- **New: `firstspirit-operations`** (`skills/project/`) — the catalogue of client operations
  obtained through `OperationAgent`: per operation the exact `perform(...)` parameter type
  (`javap`-verified), the configuration setters it really has, the return value, known traps
  and which client (SiteArchitect / ContentCreator) it runs in; the `DataProvider` vs
  `IDProvider` trap behind `bsh.ReflectError: Method perform(…) not found`; the operation ×
  client capability matrix.
- **New: `firstspirit-contentcreator-extensions`** (`skills/project/`) — the ContentCreator
  browser side (`top.WE_API` Common / Dialog / Preview / Report, FSID, `jumpTo` by numeric id,
  partial reload, report shortcodes, `addItemsPlugin`), the server→browser bridges
  `ClientScriptOperation` (the callback-must-fire rule) and `ClientResourceOperation`,
  `top.MPP_API` and `top.JC_API` with the twin table for both `WEBEDIT` branches, a
  "does not work in ContentCreator" list, documentation traps in the ODFS examples, and the
  Java plug-in interfaces (`Webedit…Plugin`, timeline, translation, focus areas) with
  `[jar]`-verified signatures.
- **New: `firstspirit-template-design`** (`skills/templating/`) — fourteen design principles
  for building and reviewing FirstSpirit templates (content vs presentation, constraining
  content areas, headless vs classic structure, component choice, form design and restriction
  levels, naming and prefixes, reuse, datasets and dependency order, deprecated components,
  documenting a template set, the two language dimensions) with references for naming,
  components and tags, deprecated components, template documentation and localisation. The
  prefix tables govern variables, not template reference names (first external contribution).
- `firstspirit-templating-reference`: new `gom/database-schema.md` — schema → table template →
  data source → dataset, `fs_id` / `FS_GID`, one physical column per language, the seven column
  types and which input component maps onto which (a selection component mapped onto a numeric
  column stores a converted number), dataset references as foreign-key relation vs column
  (`FS_INDEX` maps onto a FirstSpirit-editor column only), what each database-backed component
  stores (`<KEY>` value, else GID), cross-schema references vs schema-bound queries, Remote Data,
  why a mandatory schema column is a bad idea (use a rule), never force-delete a table template,
  `Entity` (the database row) vs `Dataset` (what FirstSpirit holds). Facts verified against the
  product source and the ODFS. Rule examples use the current `st_` prefix instead of the legacy
  `cs_` (ContentStore) prefix.
- `firstspirit-api-reference`: how to reach the table template behind a database-backed
  combobox / radiobutton / checkbox through public API (`GomIncludeOptions` →
  `OptionFactory.getOptionModel` → `TableTemplateProvider`) instead of the internal
  `ContentOptionFactory`; the entity type alone cannot identify the template.
- `firstspirit-scripting`: the dataset example uses the `tt_` prefix for table-template inputs.
- `firstspirit-contentcreator-extensions`: a global ContentCreator web-app deployment is the
  normal choice (project-specific web-app components are not wanted on FirstSpirit Cloud), one
  web-app component per module is enough; the `cxt-cc-api` jar is not generally published.
- **Fix (issue #14)**: every published skill's frontmatter description is now at most 1024
  characters, the limit Claude.ai's plugin import enforces (`templating-reference`,
  `api-reference`, `scripting`, `external-sync-export`, `operations`,
  `contentcreator-extensions`, `template-design` were over it — the largest at 2602). Same
  trigger phrases, fewer examples. `scripts/lint-skills.sh` now fails on a longer description,
  and the publishing pipeline stops before a copy can ship over the limit.
- **Fix (issue #15)**: the session-start hook runs on Windows. GitHub Copilot on Windows
  executes plugin hooks through PowerShell, which reported a parse error on the quoted bash
  command in `hooks/hooks.json` (the skills still loaded). The shared command now starts with
  `bash` and the manifests carry a `powershell` variant that runs the new
  `hooks/session-start.ps1` with `-NoProfile -ExecutionPolicy Bypass -File`; the PowerShell twin
  detects the same project markers and emits the same context. `scripts/test-manifests.sh`
  checks both variants. Not yet confirmed on a Windows machine — see the issue.
- **Registry**: the bootstrap skill's *Available Skills* list now has a two-line entry per
  skill — when to use it and what it covers — instead of a truncated description sentence
  (review feedback on 0.2.1; the same entries are on that branch).
- **All skills**: pointers to these three skills are now real links; in 0.2.x they read
  "not part of this toolkit" or were rewritten as documentation pointers
  (`firstspirit-scripting` → operations catalogue, `firstspirit-templating-reference` →
  template-design principles 7 and 12). Pointers to skills still outside the toolkit remain
  softened. Every relative link is checked to resolve inside the published skill.


## 0.2.1 — 2026-09-25

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 30f3b27 (beta)
- `firstspirit-templating-reference` @ 30f3b27 (beta)
- `firstspirit-scripting` @ 30f3b27 (beta)
- `firstspirit-rest-api` @ 30f3b27 (beta)
- `firstspirit-external-sync-export` @ 30f3b27 (beta)

Changes since 0.2.0 — a verification release: every Java name was re-checked with `javap` against
the FirstSpirit runtime jar 5.2.261011 (R2610) and the 5.2.240208 jar, template and rule
semantics against the FirstSpirit product source, REST paths against the REST module source,
and the whole set against the official ODFS example modules. Corrections are tagged in place
(`[jar]`, `[core]`, `[odfs]`, `[observed]`).

- `firstspirit-templating-reference`: new references for the Navigation function (all
  `expansionVisibility` modes, hook order), PageGroup, and content projection / dataset pages;
  rule execution time (`<RULE when=…>`) and scope priority; `INFO` is the XML spelling of the
  internal `EVENT` scope and `scope="EVENT"` is rejected; `<ON_SAVE>` / `<ON_RELEASE>` blocks;
  `scope="SAVE"` blocks the save completely while the rule fails (confirmed internally); the
  getter-shorthand rule and the `.empty` trap on objects without `isEmpty()`; `#sectionList`;
  FS_CATALOG item context (`#fs_catalog`, `#card`, `#index`); `$CMS_RENDER$` macro semantics;
  JSON in an HTML attribute needs `.toJSON` then `.convert2`.
- `firstspirit-rest-api`: breaking drift in REST module 0.0.24-beta documented with version
  gates (sections addressed by numeric id, creation is `POST …/sections/`); Global Content
  Area endpoints; error-code table (403, 409, 410, 413, 429); whole-form GET returns
  `content: null` by design; page bodies require `allowedTemplates`; link-editor GOM shape;
  duplicate script name → 500; WebP/SVG upload as FILE; a language-path PATCH on a
  `useLanguages="no"` FS_CATALOG answers 200 and writes nothing; warning against using
  `/scripts/{name}/execute` exceptions as a return channel.
- `firstspirit-scripting`: the context hierarchy is a Mermaid class diagram plus a text tree
  (was a PNG); datasets persist only changed values, verify with a fresh read; relation lists
  are mutated in place; `Dataset.getEntity()` / `Entity.setValue` verified on the jar.
- `firstspirit-api-reference`: the object model is text trees (was a PNG); `BrokerAgent` by
  project id; `requestSpecialist` vs `requireSpecialist` as an environment probe; the nested
  lock/save/unlock rationale; two sibling links in `references/references.md` fixed.
- `firstspirit-external-sync-export`: external-sync file names confirmed against the product
  source, no text change beyond the stamp.
- All skills: examples are presented as small getting-started material, not as course content;
  every relative link is checked to resolve inside the published skill (new gate).


## 0.2.0 — 2026-09-15

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 468d904 (beta)
- `firstspirit-templating-reference` @ 6ad95ec (beta)
- `firstspirit-scripting` @ 7ce2e12 (beta)
- `firstspirit-rest-api` @ 2556131 (beta)
- `firstspirit-external-sync-export` @ 978980c (beta)

Changes since 0.1.0:

- First skill batch (beta): the five skills above replace the category stubs, marked beta and
  registered in the bootstrap Available Skills list.
- `firstspirit-rest-api`: "Set as Start Node" corrected to Page Reference Settings (`filename`,
  `showInSitemap`); List Resolutions added; `scripts/claim-coverage.md` ships with the smoke test;
  the smoke test writes `results/firstspirit-rest-api/<run>/` and appends a run line to `logs/`.
- `firstspirit-external-sync-export`: findings from a second FirstSpirit Cloud environment
  (client build-number mismatch, launcher JRE 21 or 25); the fs-cli wrapper keeps each run's
  redacted output under `results/` and appends a run line to `logs/`.
- `firstspirit-scripting`: the `DataProvider` / `IDProvider` trap table is inlined; the pointer to
  an unpublished operations catalogue is replaced by the Javadoc packages.
- All skills: references to skills that are not in this toolkit (template design, module
  development, headless, Cloud, operations) are rewritten as generic pointers, so no skill sends
  the user to something not installed; every SKILL.md carries a provenance stamp
  (`metadata: source-commit / published / toolkit-version`) — quote it when reporting an issue.


## 0.1.0 — 2026-09-01

Initial scaffold. Platform manifests for Claude Code, GitHub Copilot, Codex App,
Gemini CLI, and Cursor. Conditional session-start bootstrap, skill index, and
five domain-category stub skills. Version management, linting, and CI scripts
included.
