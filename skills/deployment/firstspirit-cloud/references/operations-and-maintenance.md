# Operations & maintenance — patch days, backups, logging, go-live

Running and maintaining a FirstSpirit Cloud project: the maintenance rhythm you
plan around, what is (and isn't) backed up, how to observe the system, and a
go-live checklist. Governance/legal topics are **linked, never restated** —
they live at the Governance Center.

## Patch days & maintenance windows

The platform patches the Cloud on a fixed rhythm you **schedule around** — you
don't move it.

- **Cadence:** roughly **every 4 weeks**.
- **Downtime window:** **07:00–09:00 CET**.
- **Freezes:** **no patches in December**, and **none near Black Friday / Cyber
  Monday** (peak-commerce protection).
- A public **Patch Day Calendar** is published (crownpeak.com/patchday-calendar);
  the authoritative **Maintenance Window Schedule** is in the support knowledge
  base (**reposted yearly** — link the *section*, not a year-specific article; see
  [documentation-map.md](documentation-map.md)).
- **Urgent fixes are deployed immediately**, outside the scheduled patch days —
  so a critical fix doesn't wait for the next window.
- **PROD custom-module installs land on the following patch day** (see
  [environments-and-workflow.md](environments-and-workflow.md)) — sequence module
  releases against the calendar.
- **Subscribe to notifications** — the KB explains how to get maintenance and
  status notifications.

**Best practice:** never schedule a **go-live, large deploy, or DNS cutover**
inside the 07:00–09:00 CET window or during a December / Black-Friday freeze;
build the patch calendar into the project plan.

## Support hours

- **Standard support:** **Mon–Fri 09:00–18:00 CET**.
- **24/7 support:** available **only under a maintenance agreement**.

Scope the support tier against the customer's availability requirements — a
24/7-critical site needs the agreement in place before launch.

## Backup, archiving & recovery

- **FirstSpirit is backed up** by the platform — the CMS repository (source of
  truth) is covered — but **backup retention is limited**. Don't assume long
  historical restore points; confirm the retention window for a recovery
  commitment (or route to the Governance Center if it's an SLA term).
- **Archiving is automatic (~weekly)**, but **archives are not directly
  accessible** — retrieving one is a **Support** request.
- **CaaS is *not* backed up.** If you deliver headless, a **separate CaaS backup
  strategy is your responsibility** (see [cloud-constraints.md](cloud-constraints.md)
  and `firstspirit-headless`).
- **Static (S3/CloudFront) output** is regenerable from FirstSpirit — a full
  generation reproduces it; **deployed files aren't directly accessible** anyway,
  so treat S3 as derived, not a system of record.
- There is a support KB on **backup, recovery and data consistency** — note it is
  **self-hosted-oriented** (DE); use it for **consistency concepts**, not as a
  Cloud DIY procedure (the platform runs Cloud backups). See
  [documentation-map.md](documentation-map.md).

**Recovery-planning rule:** the recoverable system of record is **FirstSpirit**;
everything downstream (S3 output, CaaS documents, search indexes) is either
regenerable or **your** backup responsibility. Map each downstream store to
"regenerate" or "back up" explicitly.

## Logging & monitoring

- No server file-system access means **no raw log files on disk** — Cloud
  customers view server logs in **Kibana**.
- **ServerMonitoring admin access is not available** in the Cloud (self-hosted
  only) — plan monitoring around Kibana + the status page, not the server-admin
  monitoring UI.
- Additional sources: the **Cloud Logging** doc and the **SaaS Customer Logging
  quick start** KB (being consolidated to one canonical logging page — see
  [documentation-map.md](documentation-map.md)).
- **Status page:** `firstspiritstatus.crownpeak.com` — live service status and
  incident history. It is **noindex** (won't show in search), so **link it
  prominently** and add it to runbooks. Component names there (e.g. "CDN",
  "Source Control") map to features (CloudFront hosting, Git-based development) —
  align terminology so a status entry is recognisable.

**Best practice:** wire the **status page** and **Cloud logging** into the
project's monitoring/runbook from day one; subscribe to status + maintenance
notifications.

## Incidents & status

- Live status and incident history: the **status page** above.
- How to **subscribe** to status and maintenance notifications: the support KB
  (see [documentation-map.md](documentation-map.md)).
- Standard-hours support handles incidents unless a 24/7 agreement is in place.

## Go-live checklist

A consolidated launch checklist for a Cloud project (static delivery):

- [ ] **Correct deploy option** chosen — **not auto-detect**; first launch =
  **full generation + complete sync** (see
  [environments-and-workflow.md](environments-and-workflow.md)).
- [ ] **Domain & DNS cutover** planned; **TLS certificate** in place for the
  custom domain (confirm self-service vs. Support for cert/headers/WAF —
  **OPEN**, see [hosting-and-delivery.md](hosting-and-delivery.md)).
- [ ] **Cache & invalidation sanity checks** — confirm caching intent per type;
  verify invalidation worked; watch for **duplicate-URL / path-discrepancy**
  warnings.
- [ ] **Redirects** verified — folder vs. URL-module behaviour, `301`/`302` only.
- [ ] **Access** ready — Keycloak groups mapped (exact names), `template-
  distribution` granted, **SSO/IdP** connected if required (Support-driven; start
  early), MFA plan if required.
- [ ] **Backup plan** confirmed — FirstSpirit covered; **CaaS backup** owned if
  headless.
- [ ] **Logging & monitoring** wired — Cloud logging + **status page** in the
  runbook; notifications subscribed.
- [ ] **Patch calendar** respected — launch **not** inside 07:00–09:00 CET or a
  December / Black-Friday freeze.
- [ ] **Rollback approach** defined — regenerate from FirstSpirit; know how to
  revert a bad deploy.

## Maintenance rhythm (steady state)

- Deploy routine updates as **delta/partial + a chosen deploy mode**, staying
  under the wildcard-invalidation limit.
- Promote template changes as **coherent Template Transports** (or via Bamboo),
  never by editing PROD directly.
- Track the **patch calendar**; freeze changes around patch windows and peak
  periods.
- Re-check the **status page** during incidents; keep notification subscriptions
  current.

### Compatibility Plans (Java / runtime rollouts)

Ahead of raising the JVM (or the FirstSpirit runtime) under customer modules, the Cloud
adds a Bamboo plan named like **"Compatibility (Eclipse Temurin N)"** that rebuilds each
module against the target before the upgrade reaches any stage `[observed]`.

- **Red** means the module will not build once the rollout lands; **green** means it is
  ready.
- What you fix is the **module's build toolchain** (Gradle, FSM plugin, test setup), not the
  managed server. How the toolchain moves with the JDK is in
  [firstspirit-module-development → isolated-mode-and-packaging.md].
- CI injects its own `firstspirit.version.compatibility`, which **overrides** the value in
  `gradle.properties` `[observed]`; a local build can pass while the plan fails for that
  reason.
- This is the separate "Compatibility and Compliance" plan that runs per branch (see
  [environments-and-workflow.md]); the Compatibility plans for a rollout are the same
  mechanism run ahead of the upgrade `[verify]`.

---

*Sources: docs.crownpeak.com/firstspirit/first-steps (patch days, support hours);
docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/cloud-specific-processes
(Kibana logging, ServerMonitoring unavailable, limited backup retention, weekly
archiving, archive/import via Support, urgent fixes deployed immediately);
crownpeak.com/patchday-calendar; firstspiritstatus.crownpeak.com; support KB —
Maintenance Window Schedule, Product Status Pages & Maintenance Notifications,
SaaS Customer Logging quick start, Backup/recovery/data-consistency;
docs.crownpeak.com/cloud-logging; the reference architectures (CaaS backup).
First pass, version-dependent — see the skill's review log.*
