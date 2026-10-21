# Hosting & deployment — decision reference

Decision 1 of the four: **where the FirstSpirit server runs and how output is
deployed.** This is an operations/architecture decision, usually made once per
project. Install/config *procedures* are out of scope here — this file is for
*deciding and explaining*.

## The hosting models

| Model | What it is | Choose when | Notes |
| --- | --- | --- | --- |
| **FirstSpirit Cloud** (managed SaaS on AWS) | Vendor-managed, multi-stage environment on AWS (S3 + CloudFront), Keycloak identity, regular patches | Default. Fastest to stand up, no infra to run, continuous updates | DEV/QA/PROD stages, Git-based template transport, standard support hours |
| **Self-hosted** (a.k.a. **on-prem** / on-premises) | Customer runs the FirstSpirit server in their own environment | Strict data-residency, network isolation, or existing datacenter mandates | Customer owns ops, upgrades, backups, and delivery infra |

**Default recommendation:** FirstSpirit Cloud unless a concrete data-residency,
network-isolation, or regulatory constraint forces self-hosting. Lead the
conversation with the constraint, not the model.

## Self-hosted — system requirements (decision input)

**Self-hosted only** — for the Cloud these are the provider's problem. For
**self-hosted**, meeting *and maintaining* them across FirstSpirit versions
(Java/Tomcat/DB upgrades) is a real cost input to the Cloud-vs-self-hosted choice.
Orientation only; the **live version matrix** is the Technical requirements doc —
**don't quote versions from here.**

- **Server:** 64-bit OS (Windows Server or Linux — Debian / RHEL / SUSE / Ubuntu);
  **OpenJDK 21** is the reference version; from **2026.5** operation with Java 17 is
  no longer possible (bytecode level 21), and Java 25 is officially supported
  (release notes 2026.3). On SaaS the runtime moves from Java 21 to Java 25 with the
  2026.11 patch day (DEV and QA 2026-10-14, PROD 2026-10-21; Support Portal article
  "FirstSpirit will run on Java 25 starting with release 2026.11 in SaaS
  environments"). Since 2026.9 the Launcher starts the desktop clients with Java 25 by
  default (release notes 2026.9). Treat the exact floor as drift → live doc.
- **Web tier (ContentCreator etc.):** a servlet container — **Apache Tomcat**
  (Jakarta from 2023.9, **Tomcat 11** from 2025.13). **Jetty** is no longer
  available from **2026.2** (release notes 2025.9, web server documentation);
  **Embedded Tomcat** (since 2023.9, the default since 2024.12) is for tests and not
  recommended for production, where an external web server such as Tomcat is
  recommended (web server documentation).
  Modern browsers (Chrome / Edge / Firefox / Safari — not IE).
- **Database:** a supported RDBMS — PostgreSQL (reference), or DB2 / MariaDB /
  MySQL / SQL Server / Oracle.
- **Desktop clients (SiteArchitect / ServerManager):** Windows or macOS
  (incl. Apple Silicon); the FirstSpirit Launcher bundles its own JRE — no separate
  JDK on the client.
- **Sizing:** S / M / L by concurrent editors, projects, page count, and media —
  scope with an architect; no fixed hardware figures are published.
- Doc: `docs.e-spirit.com/odfs/edocs/admi/technical-requi/`.

## Versioning & maintenance window

Version support differs sharply by hosting — a real input to the choice.

- **Cloud:** each Patch Day (every four weeks) rolls out the latest FirstSpirit
  release, DEV and QA first and PROD one week later; urgent security patches can
  come outside it. The Cloud Maintenance Window Schedule on the Support Portal
  lists the dates and is the source of truth.
- **Self-hosted:** the version line is the rolling `YYYY.N` line (FirstSpirit left
  major.minor numbering after **5.2 (2015)**). The self-hosted support policy is not
  restated here; see the [Governance Center](https://www.firstspirit.com/policies/legal/).
  Self-hosting means you own staying inside the supported window.
- Context: [product-overview.md](product-overview.md) (version history) and
  [naming-and-aliases.md](naming-and-aliases.md) (why old names/flags persist).

## FirstSpirit Cloud — the technical shape

The Cloud's shape is documented in detail; the decision-level facts follow.

> **Depth & best practice → `firstspirit-cloud`.** This section is the *decision-
> level* shape of the Cloud. Once Cloud is chosen, the **constraints to plan
> around** (no file-system/server-admin access, self-service vs. Support request,
> caching/invalidation limits, MFA needing an IdP, backup scope) and the
> **development/maintenance best practice** (DEV→QA→PROD workflow, Template
> Transport, Git-based dev, deploy modes, go-live checklist) are in the
> **`firstspirit-cloud`** skill. Route Cloud *operational* questions there; this
> file covers the *hosting choice*.

### Stages
Three isolated environments, each a distinct role in the delivery lifecycle:

- **Development (DEV)** — templates are built here (in SiteArchitect).
- **Quality Assurance (QA)** — validation/staging.
- **Production (PROD)** — live delivery.

Content and templates move **DEV → QA → PROD**. The **Template Transport**
feature moves the whole template store (plus the Technical Media Assets folder
and configured Resolutions) across stages; it requires membership in the
**Template Distribution** group on the target project.

### Identity & permissions
- **Keycloak** at `accounts.e-spirit.cloud`, **one realm per customer**.
- Permissions are assigned **exclusively via groups** (not roles). External
  groups in a FirstSpirit project map to Keycloak groups by **matching
  (case-sensitive) name**.
- Default groups (pattern): `<customer>-users-[dev/qa/prod]`,
  `<customer>-chiefeditors` (direct content release), `<customer>-editors`,
  `<customer>-developer`, `<customer>-git-user`,
  `<customer>-projectadmins-[dev/qa/prod]`, `<customer>-template-distribution`.
- Keycloak roles: **User-Manager** (at least one per realm — manages users) and
  **password-user** (local password for non-SSO CLI/API access).

### Hosting URL patterns
- FirstSpirit access: `https://<customer>[stage].e-spirit.hosting`
- S3 / CDN delivery endpoints: `https://<customer>[stage].e-spirit.cloud`

### Patch cadence (operations)
- Patches roughly **every 4 weeks**; downtime window **07:00–09:00 CET/CEST**.
- **No patch day in December**; the patch day in Black Friday week can be skipped for
  e-commerce customers.
- A public **Patch Day Calendar** exists (crownpeak.com/patchday-calendar); the
  Cloud service status page (https://firstspiritstatus.crownpeak.com/) offers
  subscription to maintenance notifications.
- **Support:** standard **Mon–Fri 09:00–18:00** (except federal holidays; no time zone is stated); 24/7 support may be
  available, depending on the software maintenance agreement level.
- Source: Cloud first-steps, *Patch day & maintenance*
  (https://docs.crownpeak.com/firstspirit/first-steps/). Urgent security patches can
  be rolled out outside the schedule.

### CI / delivery toolchain (Cloud)
- **Bamboo** (CI/CD), **Bitbucket** Git repositories, **Artifactory**
  (module/artifact storage), plus a logging GUI.
- Module (FSM) development integrates with the Cloud Artifactory (Maven/Gradle).
  Build/packaging detail is owned by `firstspirit-module-development`.

## Output deployment (how generated content leaves the server)

Deployment is distinct from the *delivery strategy* (static vs. headless — see
[delivery-and-architectures.md](delivery-and-architectures.md)). For **static**
delivery in the Cloud:

- **AWS S3** via the `aws-services-s3` module — generated static assets (HTML,
  CSS, JS, media) land in an S3 bucket.
- **CloudFront CDN** distributes and caches them; supports custom CNAME/SSL,
  cache invalidation (via `aws-services-s3`), wildcard forwarding to
  `/index.html`, basic-auth, `301/302` redirects (via `aws-services-url-redirect`),
  and custom `403/404` pages from `/error-pages/` in S3.
- **SFTP module** — alternative deployment to a **customer-managed webserver**
  instead of S3/CloudFront.
- **rsync deployment** — sync generated static output to a remote server over
  **SSH (public-key auth)** with efficient **delta transfer** (only changed data);
  the preferred alternative to plain FTP / local-filesystem publishing. **Available
  for both Cloud (right away) and self-hosted (enabled via Support).** Config
  (destination host/path, SSH key, optional jump host) → the
  [rsync deployment](https://docs.crownpeak.com/firstspirit/rsync-deployment/) doc
  and the `firstspirit-cloud` skill.

For **headless** delivery, content is pushed to **CaaS** (and media to S3) by
CaaS Connect rather than pre-generated — see the architecture reference.

## Backup note (important for headless)

In the Cloud, **FirstSpirit is backed up** by the platform, and CaaS data in the
SaaS environment is backed up periodically; the reference architectures describe a
backup strategy for the FirstSpirit server only. The source of truth is
FirstSpirit. Confirm scope, frequency and restore options with your CSM or Support; a CaaS you operate yourself needs your own backup. Call this out in any headless design.

## How to decide (summary)

1. **Any hard data-residency / isolation / regulatory constraint?** → self-hosted
   Otherwise → **Cloud**.
2. **Cloud chosen** → the shape above is fixed: DEV/QA/PROD, Keycloak groups,
   regular patches, Git template transport.
3. **Static or headless output?** → that's decision 2
   ([delivery-and-architectures.md](delivery-and-architectures.md)); it
   determines S3/CloudFront vs. CaaS, not the hosting model.

---

*Sources: docs.crownpeak.com/firstspirit/first-steps; docs.crownpeak.com/firstspirit/user-management;
docs.e-spirit.com Cloud Development Handover; docs.e-spirit.com Technical requirements.*
