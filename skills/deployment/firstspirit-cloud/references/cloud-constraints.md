# Cloud constraints & specifics — plan around these

The headline reference. FirstSpirit Cloud trades **control for a managed
service**: the platform runs the server, so you gain "no infrastructure to run"
and lose direct access to the machine. Almost every Cloud-specific limitation
below descends from that. **Surface the relevant one while planning** — not at
go-live.

Each item states: what the constraint is, why it exists, and **the Cloud-native
way to meet the need**. Where a capability is customer-managed vs. a **Support
request** to the Cloud team, that is called out. Items not yet confirmed in
customer-facing docs are tagged **(UNVERIFIED)**.

## The managed-server constraints (the big four)

Confirmed in the official **Cloud vs. Self-Hosted → hosting-model-differences**
doc:

| Constraint | What it means | Cloud-native way to meet the need |
| --- | --- | --- |
| **No server file-system access** | The FirstSpirit file system is **fully platform-managed and cannot be accessed** — no reading/writing it, dropping files next to the server, or shell access | Ship file-based needs **inside a module** via the Cloud build pipeline; use **Media** for assets; use **S3** (`/error-pages/`, static assets) for delivery-layer files |
| **No server-admin role for customers** | The **Server Admin** role is **not available** in the Cloud; customers get **Project Admin** only | Server-level actions go through a **Support ticket** (list below). Plan project-admin tasks as self-service |
| **No custom *global* web apps** | Custom WebApps are **restricted to the local level**; you can't deploy a custom **global** web application (security). Project-specific ContentCreator/Preview apps with custom WebApp components are unavailable | You **can** add custom WebApp **components to existing global/shared apps** — but the initial setup is a **Support ticket**. See `firstspirit-module-development` |
| **Managed / locked server configuration** | Server properties are **centrally configured and optimised by the platform and cannot be manually adjusted** | Configurable behaviour comes through **project settings, module config, or a Support ticket** — don't design around editing server config |

**Planning rule:** if a requirement needs "a file on the server", "a change to
server config", "a server-admin action", or "a global web app", it is either a
**module**, a **Support ticket**, or a **redesign** — decide which early.

## What requires a Support ticket (not self-service)

The **cloud-specific-processes** doc names the actions that are **not
self-service** and must be raised with **Support**. Plan lead time for these —
they are not instant, and some only take effect on the next **patch day** (see
[operations-and-maintenance.md](operations-and-maintenance.md)):

- **Installing / uninstalling modules** (see the module nuance below) and
  **initial custom WebApp-component setup**
- **Adding / removing WebApp components** to ContentCreator / Preview
- **Restarting** the FirstSpirit ServerService or the Server / Tomcat
- **Editing conversion rules**, **modifying start-page entries**, **viewing the
  Module Issues screen**, **configuring Application-configuration group
  permissions**
- **Project imports** — must be handled by Support
- **Accessing archives** — reach out to Support (archiving is automatic, ~weekly)
- **Deleting a Keycloak user group** — a User-Manager **cannot** delete groups;
  it takes a Support request (empty new groups auto-delete after a preset time).
  See [identity-and-access.md](identity-and-access.md)
- **Setting up a federation** (partner-realm access) — the **customer** must
  request it from Support; the partner cannot

## Custom modules (FSM) — possible, but not a free-for-all

Custom Java modules are supported, but **arbitrary/complete FSMs cannot be
installed** directly ("for security reasons"). The Cloud path:

- **DEV / QA** — custom module code goes through the **Cloud build pipeline**
  (you **upload source** to the cloud repository; it's built there, not installed
  as a black-box FSM).
- **PROD** — installation is a **Support ticket**, and the module is installed on
  your PROD instance **on the following patch day**.

Design modules to the **supported extension points** (project apps,
ContentCreator/web-app *components*), not to arbitrary server-global installation.
Depth: `firstspirit-module-development`; workflow:
[environments-and-workflow.md](environments-and-workflow.md).

## Other Cloud restrictions (documented)

From the same two docs — plan around these:

- **No external-database integration.** Integrating **external databases** is
  **unsupported** in the Cloud. If a requirement assumes a customer-managed DB
  behind FirstSpirit, that's a redesign or a self-hosted decision.
- **Deployed files & staging aren't browsable.** **Staging directories are not
  accessible via the browser** and **deployed files are not directly
  accessible** — you observe delivery via the S3/CloudFront layer, not by
  browsing the server.
- **Archives aren't directly accessible.** Archiving runs **automatically
  (~weekly)**; retrieving an archive is a **Support** request.
- **Backup retention is limited.** Platform backups exist but **retention is
  limited** — factor this into any recovery expectation (and remember **CaaS is
  not backed up at all** — below). See
  [operations-and-maintenance.md](operations-and-maintenance.md).
- **Module availability differs by model.** Some modules are **Cloud-exclusive**
  (Navigation Service, S3 Deployment, URL Redirect, SmartSearch Connect, Connect
  for Commerce, RSYNC Deployment); **SAP Business Package is self-hosted only**;
  most (25+, incl. CaaS, SmartSearch, TranslationStudio, Workflows) are in both.
  Confirm a required module's availability against the doc, not assumption.

## Delivery-layer constraints (static / CloudFront)

These bite at **go-live and during content updates**. Depth in
[hosting-and-delivery.md](hosting-and-delivery.md).

- **Default no-cache for dynamic-ish types.** HTML, JSON, XML, TXT and PDF are
  served **no-cache** by default; other static assets get a **~30-day**
  max-age. If you expected HTML to be edge-cached, it isn't by default — plan
  cache headers deliberately.
- **Wildcard invalidation limit.** CloudFront allows a limited number of wildcard
  invalidation paths (**~15**); past that, the deploy forces a **full/global
  invalidation** — slower and broader than you may want. Structure paths and
  deploys to stay under it. **(verify the exact number against the live docs)**
- **CloudFront is not a web server.** Server-style behaviours are emulated:
  **folder redirects run through Lambda**, **URL redirects through DynamoDB +
  Lambda**, and **only `301`/`302`** are relevant. Don't assume `.htaccess`-style
  rewrites or arbitrary status codes.
- **Allowed characters (RFC 1738).** The deployment does **not** convert unsafe
  or reserved characters in paths; illegal characters break URLs. Keep generated
  paths within the safe set.
- **"Auto-detect" deploy is not recommended.** Choose the deploy mode explicitly
  (complete sync vs. deploy-only); auto-detect can misjudge what to publish. See
  [environments-and-workflow.md](environments-and-workflow.md).
- **Which CloudFront settings a customer can change directly** (security headers,
  WAF, certificates) vs. what must be **requested from Support** is **not fully
  documented** — treat as **(OPEN)** and confirm per setting. This is a known
  open question in the Cloud docs.

## Headless / CaaS constraints

Depth in `firstspirit-headless`; the Cloud-planning facts:

- **CaaS is not backed up by the platform.** Only **FirstSpirit** is backed up.
  If you deliver via CaaS, a **separate CaaS backup strategy is your
  responsibility** — the source of truth is FirstSpirit, but a CaaS
  outage/restore is your plan to make. Call this out in every headless design.
- **You own the frontend and its caching.** Static delivery gets CloudFront
  caching "for free"; headless means **you implement frontend caching** and
  **hide CaaS API keys behind middleware** (never ship a key to the browser).
- **Collaboration (editor comments) is unavailable for headless.** Delivering
  analysis/hygiene findings *to editors* via the Collaboration API works in
  ContentCreator, not on a headless frontend — an open route question. See
  the Collaboration module documentation.

## Identity & access constraints

Depth in [identity-and-access.md](identity-and-access.md):

- **Permissions are group-based only** (not roles). External groups in a project
  map to **Keycloak groups by exact, case-sensitive name** — a name mismatch
  silently grants nothing.
- **One Keycloak realm per customer.**
- **SAML setup in Azure is not supported** by FirstSpirit Cloud; **OIDC is the
  preferred** IdP protocol.
- **MFA requires your own IdP** — there is no MFA on the default Cloud identity
  without connecting an external identity provider.
- **Connecting an IdP is a Support-driven process** with prerequisites (working
  email, redirect and application-ID URIs), not a self-service toggle.

## Operations constraints

Depth in [operations-and-maintenance.md](operations-and-maintenance.md):

- **Patch windows are fixed and platform-scheduled** — ~every 4 weeks,
  **07:00–09:00 CET**, with **no patches in December** or near **Black Friday /
  Cyber Monday**. You schedule launches and freezes around them; you don't move
  them.
- **Standard support is business hours** (Mon–Fri **09:00–18:00 CET**); **24/7**
  needs a **maintenance agreement**.
- **Logging is via Kibana**, not raw server log files on disk (there's no disk
  access); **ServerMonitoring admin access is not available** in the Cloud
  (self-hosted only). Plan monitoring around the provided logging.

## Things that are *not* Cloud-specific (don't mislabel)

To keep the constraint list honest — these apply everywhere, not just Cloud, so
don't present them as Cloud limits:

- Editorial capability (what editors can do) is **the same** across static and
  headless delivery — delivery changes *who renders/caches/backs up*, not
  authoring.
- Template design, deprecated components, and API stability policy are
  product-wide (owned by the template/API skills), not Cloud constraints.

## Cloud vs. self-hosted — the limits that flip

If the constraint above is a blocker, **self-hosted** removes some of them (file
system access, server admin, server-config control) at the cost of owning
operations, upgrades, backups and delivery infrastructure. That is a **hosting
decision** — route it to the FirstSpirit product documentation (hosting choice, modules, licensing)
(`hosting-and-deployment.md`); it is not re-decided here. The official
comparison is the **Cloud vs. Self-Hosted → hosting-model-differences** doc (see
[documentation-map.md](documentation-map.md)).

---

*Sources: docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/hosting-model-differences
(managed-server limits, roles, module availability); docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/cloud-specific-processes
(support-ticket actions, custom-module pipeline, external-DB/staging/archive
restrictions, Kibana logging); the AWS S3 deployment module doc
(caching/invalidation/redirects/allowed characters); the FirstSpirit Cloud
documentation-home drafts (delivery-layer security-ownership open question);
reference architectures (headless backup/caching). Verified against the two
Cloud-vs-Self-Hosted docs 2026-07-31 — see the skill's review log.*
