# Environments & development workflow — best practice

How a FirstSpirit Cloud project is **structured across stages** and the
recommended way to **develop, promote, and deploy** on it. This is the
development-and-maintenance best-practice core.

Boundaries: *template design* is `firstspirit-template-design`; *module
packaging* is `firstspirit-module-development`; the *headless* delivery path is
`firstspirit-headless`. This file owns the **Cloud workflow around** them.

## The three stages

Every Cloud project is delivered across three isolated environments, each a
distinct role in the lifecycle:

| Stage | Role | Who works here |
| --- | --- | --- |
| **DEV** (Development) | Templates and structure are **built** (SiteArchitect + Git) | Developers, template developers |
| **QA** (Quality Assurance) | **Validation / staging** before production | Editors validating, PM sign-off |
| **PROD** (Production) | **Live delivery** (to CloudFront or CaaS) | Editors publishing, live traffic |

Content and templates move **DEV → QA → PROD** — never backwards as a normal
flow. Each stage has its own URL and its own Keycloak groups (see
[identity-and-access.md](identity-and-access.md)).

- FirstSpirit access URL pattern: `https://<customer>[stage].e-spirit.hosting`
- S3 / CDN delivery endpoint pattern: `https://<customer>[stage].e-spirit.cloud`

## Two things move differently: templates vs. content

A common Cloud planning mistake is treating template promotion and content
promotion as one mechanism. They are not.

### Templates → Template Transport
The **Template Transport** feature moves the **whole Template Store** across
stages, together with the **Technical Media Assets** folder and configured
**Resolutions**.

- **Gated on group membership:** requires the **Template Distribution** group
  (`<customer>-template-distribution`) on the **target** project.
- It moves the template *set*, not individual selective changes — plan template
  releases as coherent transports, not cherry-picks.

### Templates in development → Git-based (distributed) development
The recommended way to build is **Git-based distributed development** — the
project's **design elements** (templates, technical media, data sources with
technical content) live in a **Git repository**, and each Git branch maps to its
own FirstSpirit **branch project**. Verified against the *Distributed development
of FirstSpirit projects* doc (**2026.8**).

> **Boundary — template *technology* is not here.** *How to write templates*
> (template language, GOM/forms, output channels, rules) is owned by
> **firstspirit-template-design** / **firstspirit-templating-reference** (the
> product-knowledge skill routes there). This section owns only the **Cloud Git
> workflow around** that work.

**The branch-project model:**
- A developer creates a Git **topic branch** (e.g. `feat42`) from `main`. Pushing
  it **auto-creates a FirstSpirit branch project** for isolated dev/testing.
- Review is a normal **pull request** (over both the branch project and the code);
  approval **merges to `main`** and updates the main project.
- Deleting the Git branch **auto-deactivates/deletes** the orphaned branch
  project; a cleanup plan **deactivates inactive branch projects after ~30 days**.

**The moving parts:**
- **External Synchronization (ExternalSync)** — serialises the project to/from the
  Git working tree.
- **FS-CLI** — the local command-line client for export/import (mirrors the CI
  plans; needs env vars `fshost`/`fsport`/`fsmode`/`fsuser`/`fspwd`).
- **ContentTransport** — moves *design* between stages and seeds branch projects
  with test content.
- **Bamboo** runs four core plans: **Sync FS project → Git** (export), **Sync Git
  → FS project** (import), **Auto-create branch project** (on push), **Auto-cleanup
  branch projects**. **Bitbucket** holds the repos; **Artifactory** holds modules.
- **`fs-project.yaml`** at the repo root is the control file: the main project +
  its `qa`/`prod` project names, `externalSync.exportElements` (what's serialised —
  use **`projectproperty:ALL`** to include *all* project settings, the doc's
  recommended default), and `features` for test content and stage transport.

**DEV → QA → PROD promotion (in the Git workflow):** design is transported via
**ContentTransport**, driven by `fs-project.yaml` keys — **`designForQa`**
(dev→qa), **`designForProd`** (qa→prod), and **`designForSubprojects`** (within
prod, e.g. multi-project/multi-country rollout). This is distinct from the manual
**Template Transport** feature above; a Git-based project promotes through these
plans, not by hand.

**Best practice:**
- Treat **Git as the source of truth** for design; don't hand-edit templates on
  QA/PROD — promote through the plans.
- **Export all settings** (`projectproperty:ALL`) unless you have a reason not to.
- **Validate the export** on a throwaway branch (CSS, icons, templates, content
  all present) before relying on it; **check the ContentTransport package in
  SiteArchitect on DEV is current** before a stage transport.
- Resolve Git conflicts locally (`git fetch` / `git merge`), then run **Sync Git →
  FS project** to update the branch project and validate before the PR merge.
- Create **dependencies before dependents** (schema before table template;
  `FS_CATALOG` before its inner section template) and **delete in reverse**.
- The doc is a known **findability ticket-driver** — link it prominently; it's
  complete and command-level. See [documentation-map.md](documentation-map.md).

## Deployment & generation options (static delivery)

For static (CloudFront) delivery, the generation and deploy modes have
real trade-offs. Depth and caching in
[hosting-and-delivery.md](hosting-and-delivery.md).

**Generation scope:**
- **Full** — regenerate everything (use for first go-live, template-wide
  changes).
- **Partial / Delta** — regenerate only what changed (faster routine updates).

**Deploy mode:**
- **Complete sync** — reconcile S3 to match the generated output (removes stale
  files).
- **Deploy only** — push generated files without full reconciliation.
- **Auto-detect** — **not recommended** (can misjudge what to publish). Choose
  the mode explicitly.

**Best practice:** first go-live = **full generation + complete sync**; routine
updates = delta/partial + a deploy mode you've chosen deliberately; sanity-check
**cache invalidation** after each deploy (see hosting-and-delivery).

## Modules on the Cloud

Custom Java modules (FSM) are supported, but built and shipped the Cloud way —
you don't just upload and install a black-box FSM (arbitrary/complete FSMs are
**blocked** "for security reasons"):

- **DEV / QA** — custom module code goes through the **Cloud build pipeline**:
  you **commit the source** to a **Bitbucket repo** (`git.e-spirit.hosting`) and
  **Bamboo builds it** and publishes the FSM to **Artifactory** — it's **built
  there**, not installed as an opaque FSM.
- **PROD** — installation is a **Support ticket**, and the module is installed on
  the PROD instance **on the following patch day**. Uninstalls also go through
  Support. Plan module releases around the patch calendar.
- Design to the **supported extension points** (project apps,
  ContentCreator/web-app *components* added to existing shared apps — initial
  component setup is itself a Support ticket), per the constraints in
  [cloud-constraints.md](cloud-constraints.md). Packaging/component design is
  owned by `firstspirit-module-development`.

### The module repo (Cloud archetype)

The Cloud team provides a **Gradle project archetype** as the Bitbucket repo's
initial commit. Its shape is load-bearing for the pipeline — fill it in, don't
restructure it:

- **Kotlin DSL** (`build.gradle.kts` / `settings.gradle.kts`), the
  `de.espirit.firstspirit-module` plugin plus `maven-publish` +
  `net.researchgate.release`. Branch model is **`master` + `develop`**;
  releases require `main|master`.
- **`ci.properties`** is read by the pipeline (`fsm.project.path` = the FSM
  subproject, empty for a root-project build).
- **All values live in `gradle.properties`** (`rootProjectName`, `groupId`,
  `firstSpirit.version`, `java.languageLevel`, the `firstSpiritModule.*` names, publishing
  repos `es-snapshot-local` / `es-release-local`); the build fails if required ones are blank.
  Set `firstSpirit.version` / `java.languageLevel` to the **target server's** level — read it
  from the server's About page (`https://<server>/about.jsp`, needs a FirstSpirit login) or the
  ODFS [Technical Requirements](https://docs.e-spirit.com/odfs/edocs/admi/technical-requi/index.html)
  data sheet (details in `firstspirit-module-development` → isolated-mode-and-packaging).
- **A passing unit test is mandatory** — the archetype ships an intentionally
  *failing* `ExampleTest` so an empty test suite can't slip through; replace it.
- **Push it, the pipeline builds and deploys it.** Committing to a branch triggers
  that branch's Bamboo plans — note it's **more than one plan**: a **build** plan
  *and* a separate **Compatibility and Compliance** plan (multiple jobs) both run per
  branch, so a green branch means all of them passed. Merging a PR into the
  **integration branch** (`develop`) builds the FSM and **installs it on DEV** — you
  don't hand-install the FSM. PROD is still a Support ticket on a patch day (see
  *Modules on the Cloud* above). *(Confirm the exact branch→stage mapping for a given
  customer's pipeline.)*
- **Credentials.** The build resolves two things from the Crownpeak/e-Spirit
  **Artifactory** — the **FirstSpirit Module Gradle plugin** and the
  **`fs-isolated-runtime`** artifact — using `artifactory_hosting_username` /
  `artifactory_hosting_password` from the developer's `~/.gradle/gradle.properties`
  (never committed). How customers and partners obtain that access varies; don't
  assume a specific host, credential type, or that every developer can even build
  locally — the **CI pipeline injects its own credentials**, so a working local build
  is not a precondition for the pipeline to build and deploy. Module-build details are
  owned by `firstspirit-module-development`.

## Development best-practice checklist

- **Build on DEV, validate on QA, publish on PROD** — respect the flow; don't
  edit templates on PROD.
- **Everything in Git** that can be (templates via External Sync); use FS-CLI and
  Bamboo, not manual copies.
- **Coherent template transports** — the Template Store moves as a set; plan
  releases accordingly, and ensure Template Distribution group membership on the
  target before you need it.
- **Dependency order** on create; reverse on delete; confirm before destructive
  operations.
- **Explicit deploy modes**; avoid auto-detect; full+complete-sync for go-live.
- **Plan around patch windows** — don't schedule a go-live inside the
  07:00–09:00 CET patch window or during a December / Black-Friday freeze (see
  [operations-and-maintenance.md](operations-and-maintenance.md)).

---

*Sources: docs.crownpeak.com/template-development-guide/distributed-development-of-firstspirit-projects
(**verified 2026.8** — branch-project model, ExternalSync/FS-CLI/ContentTransport,
the four Bamboo plans, `fs-project.yaml` + `designForQa/Prod/Subprojects`, 30-day
cleanup, conflict flow); docs.crownpeak.com/template-development-guide/ (guide
root — its template-development *technology* is owned by the template skills, not
restated here); docs.crownpeak.com/firstspirit/first-steps;
docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/cloud-specific-processes
(custom-module DEV/QA pipeline + PROD ticket/patch-day install); the AWS S3
deployment module doc (generation & deploy options). See
the skill's review log.*
