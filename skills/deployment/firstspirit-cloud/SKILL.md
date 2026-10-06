---
name: firstspirit-cloud
description: >-
  FirstSpirit Cloud (the managed SaaS on AWS): what the platform does differently or
  does not allow, and how to build and run a project on it. Covers the constraints to
  plan around (no server file-system or server-admin access, no custom global web apps,
  locked configuration, self-service vs Support request, SSO and MFA limits, CaaS not
  backed up), the DEV/QA/PROD stages and promotion, Git-based development and Template
  Transport, identity and access (Keycloak realms, external IdPs), hosting and delivery
  (S3 + CloudFront caching, invalidation, deploy and generation options, redirects) and
  operations (patch days, backup and recovery, logging, incidents, go-live checklist).
  Use it once Cloud hosting is chosen or being scoped: "what can't I do on FirstSpirit
  Cloud", "move templates from DEV to PROD", "how does caching or invalidation work",
  "set up SSO", "when are the patch days", "is my content backed up", "go-live
  checklist".
metadata:
  source-commit: "8b27f9a"
  published: "2026-10-06"
  toolkit-version: "0.4.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit Cloud — constraints & best practice

The **Cloud depth layer**. Once a project is (or will be) on **FirstSpirit
Cloud** — the managed SaaS on AWS — this skill answers *what the Cloud
does differently, what it does not allow, and how to develop and maintain a
project on it well.*

It sits **below** the FirstSpirit product documentation (hosting choice, modules, licensing). That skill makes
the **decision** (*Cloud vs. self-hosted, static vs. headless, which modules,
which edition*). This skill takes over **after Cloud is chosen** and owns the
operational reality: the constraints to plan around and the recommended
practice. Use it to **signal a limitation before it bites a plan**, not to
re-argue the hosting choice.

> **Naming & branding → follow the FirstSpirit product documentation (hosting choice, modules, licensing).** The
> product is **FirstSpirit** (the managed service is **FirstSpirit Cloud** / "the
> platform"); **Crownpeak Technology GmbH** is only the **legal entity**, used
> where a legal entity is required. The branding is **in transition and not yet
> reflected in all documentation** — so quoted doc wording and literal URLs
> (`docs.crownpeak.com`, `support.rezolve.com`, `*.e-spirit.hosting/.cloud`) may
> still carry legacy names; keep those **verbatim**, but write **prose**
> FirstSpirit-first. The rule is owned by product-knowledge's
> `product-overview.md` "Naming & branding" — don't restate it, follow it.

**Scope discipline:** this skill is for **deciding, planning, and explaining** —
not step-by-step install/config/admin procedures. Those are parked for a future
configuration/admin skill (see [documentation-map.md](references/documentation-map.md)).
Where a fact is customer-managed vs. a Support request, this skill says *which* —
it does not walk through the ticket.

## What FirstSpirit Cloud is (in one screen)

FirstSpirit Cloud runs the server for you on **AWS**. You get a
**three-stage** environment (**DEV → QA → PROD**), **Keycloak** single sign-on,
**Git-based** template development, and either **static** delivery (pre-generate
→ **S3 + CloudFront**) or **headless** delivery (**CaaS**). The server itself is
**managed**: you do **not** get shell/file-system access, a server-admin role,
or the freedom to change server configuration directly. That trade — less
control for no infrastructure to run — is the source of most Cloud-specific
constraints below.

```
   FirstSpirit Cloud (managed platform on AWS)
   ┌──────────────────────────────────────────────────────────┐
   │  DEV ───transport──▶ QA ───transport──▶ PROD               │
   │  (build templates)   (validate)         (live delivery)    │
   │  Keycloak SSO · group-based permissions · one realm/customer│
   │  Git (Bitbucket) · Bamboo CI · Artifactory (modules)        │
   └───────────────┬───────────────────────┬───────────────────┘
        static push │                       │ headless pull
     S3 + CloudFront CDN                 CaaS (JSON) + Nav Service
   (only FirstSpirit is backed up ── CaaS needs its own backup)
```

## The five things a Cloud plan must account for

Read the reference that matches; don't guess.

| # | Area | The planning question it answers | Read |
| --- | --- | --- | --- |
| 1 | **Constraints & limits** | "What can't I do / what's different on the Cloud?" | [cloud-constraints.md](references/cloud-constraints.md) |
| 2 | **Environments & workflow** | "How do templates/content move DEV→QA→PROD, and how do we develop with Git?" | [environments-and-workflow.md](references/environments-and-workflow.md) |
| 3 | **Identity & access** | "How do users, groups, SSO and MFA work?" | [identity-and-access.md](references/identity-and-access.md) |
| 4 | **Hosting & delivery** | "How do S3/CloudFront caching, invalidation, deploys and redirects behave?" | [hosting-and-delivery.md](references/hosting-and-delivery.md) |
| 5 | **Operations & maintenance** | "Patch days, backups, logging, incidents, go-live?" | [operations-and-maintenance.md](references/operations-and-maintenance.md) |

For where the official Cloud documentation lives (and the canonical
Governance/status/KB links), see
[documentation-map.md](references/documentation-map.md).

## How to use this skill

- **Signal the limitation, then plan around it.** When a requirement collides
  with a Cloud constraint (file-system access, a custom global web app, a
  server-config change, MFA without an IdP), **name the constraint and the
  Cloud-native way to meet the need** — don't let it surface at go-live. The
  constraints list is [cloud-constraints.md](references/cloud-constraints.md).
- **Say self-service vs. Support request.** For each capability, this skill
  states whether the customer configures it or must **raise a request with the
  Cloud team**. Where the boundary is not documented, it is flagged as **open**,
  not guessed.
- **Frame by project stage.** A pre-launch project can absorb changes cheaply; a
  **production** project carries migration and cutover cost (patch windows,
  cache invalidation, DNS). Lead recommendations with the stage — the
  portfolio's intake rule.
- **Public material only.** This skill contains only **documentation-backed and
  public** facts. It does **not** import internal sales/pricing material. Some
  source docs are drafts or German-only module manuals; items not confirmed in
  customer-facing docs are tagged **(UNVERIFIED)** or carried in
  the skill's review log.
- **Governance is legal's, and canonical.** Certifications, data protection,
  data locations, sub-processors, DPAs, SLAs and DORA live at the **Governance
  Center** (`firstspirit.com/policies/legal`) — the canonical home. **Link it;
  never restate or cache its content here** (it changes and carries legal
  weight).
- **Point, don't paraphrase.** For headless platform internals, template syntax,
  the API model, REST, scripting or module packaging, name the owning skill and
  stop (see the table below). Restating drifts.
- **First pass, version-dependent.** Distilled from the FirstSpirit Cloud docs,
  the Cloud-documentation drafts, and the reference architectures — **not yet
  SME-verified**. Cloud specifics (URLs, caching defaults, group patterns, patch
  cadence) drift with releases; verify against the live docs for a customer
  commitment. See the skill's review log.

## Quick answers

- **What can't I do on the Cloud?** No server **file-system** access, no
  **server-admin** role (Project Admin only), no **custom global web apps**, no
  direct **server-config** changes, no **external-database** integration — the
  server is managed. A defined set of actions (module install/uninstall, WebApp
  components, restarts, project imports, archive access) are **Support tickets**,
  not self-service. → [cloud-constraints.md](references/cloud-constraints.md)
- **How do I move templates DEV→PROD?** Two paths: the manual **Template
  Transport** feature (group-gated), or — recommended — **Git-based distributed
  development**, where each Git branch is a FirstSpirit branch project and design
  promotes DEV→QA→PROD via **ContentTransport** driven by **Bamboo** plans
  (Bitbucket + local **FS-CLI**, `fs-project.yaml`). →
  [environments-and-workflow.md](references/environments-and-workflow.md)
- **How does caching work?** CloudFront caches static assets ~**30 days**;
  **HTML/JSON/XML/TXT/PDF are no-cache** by default. Invalidation is
  file/folder/global — and a **15-path wildcard limit** forces a **global**
  invalidation past that. →
  [hosting-and-delivery.md](references/hosting-and-delivery.md)
- **How do I set up SSO?** Keycloak, **one realm per customer**, permissions by
  **group** only (map names **exactly**, case-sensitive). External **IdP via OIDC
  (preferred) or SAML** by Support request — **SAML-in-Azure setup isn't
  supported**, **MFA comes from your own IdP**, and **group assignment stays
  manual**. → [identity-and-access.md](references/identity-and-access.md)
- **When are the patch days?** Roughly every **4 weeks**, **07:00–09:00 CET**;
  **none in December** or near **Black Friday / Cyber Monday**. →
  [operations-and-maintenance.md](references/operations-and-maintenance.md)
- **Is my content backed up?** **FirstSpirit is** backed up by the platform. If you
  deliver headless, **CaaS is not — plan a separate backup.** →
  [operations-and-maintenance.md](references/operations-and-maintenance.md)

## What this skill is *not* (point at these, don't restate)

| If the question is really about… | Use |
| --- | --- |
| **Whether** to use Cloud vs. self-hosted, static vs. headless, which module, which edition | **the FirstSpirit product documentation (hosting choice, modules, licensing)** |
| Headless platform internals — CaaS REST/GraphQL, `toJson`, Navigation Service JSON, OCM/TPP/SNAP | **firstspirit-headless** |
| Designing/structuring templates (incl. for headless) | **firstspirit-template-design** |
| Template-language & GOM syntax / datatypes / rules | **firstspirit-templating-reference** |
| BeanShell scripting, workflows, generators | **firstspirit-scripting** |
| The Java Access API object model | **firstspirit-api-reference** |
| Packaging a module (FSM) — descriptor, components, resource scopes | **firstspirit-module-development** |
| The FirstSpirit REST API (`/rest/v1/`) | **firstspirit-rest-api** |
| Certifications, DPAs, data locations, SLAs, security posture | **Governance Center** (link, never restate) |
| Sales/marketing positioning, editions/pricing, objection handling | **produktwissen-firstspirit** (separate, non-public; not a source here) |
| Step-by-step install/config/admin procedures | a future **configuration/admin** skill (parked) |

## References

Loaded on demand — read the file that matches the question.

| File | Covers | Read when |
| --- | --- | --- |
| [cloud-constraints.md](references/cloud-constraints.md) | The limitations/specifics to plan around — managed server, no file-system/admin, self-service vs. Support request, headless caveats | You need to signal what the Cloud can't or won't do |
| [environments-and-workflow.md](references/environments-and-workflow.md) | DEV/QA/PROD stages, Template Transport, Git-based development, deploy & generation options, dev best practice | You're planning the build/promotion workflow |
| [identity-and-access.md](references/identity-and-access.md) | Keycloak realms, group-based permissions, default groups, external IdP/SSO, MFA | You're planning users, permissions or SSO |
| [hosting-and-delivery.md](references/hosting-and-delivery.md) | S3 + CloudFront caching defaults, invalidation modes, redirects, allowed characters, the own-webserver alternative | You're planning static delivery, caching or redirects |
| [operations-and-maintenance.md](references/operations-and-maintenance.md) | Patch days, backup & recovery, logging/monitoring, incidents/status, go-live checklist, support hours | You're planning operations, maintenance or launch |
| [documentation-map.md](references/documentation-map.md) | Cloud topic → official doc / KB / Governance / status link + owning skill | You need to send someone to the right doc |

---

*First pass, distilled 2026-07-31 from the FirstSpirit Cloud documentation
(docs.crownpeak.com / docs.e-spirit.com — First Steps, User Management,
**Cloud-vs-Self-Hosted: hosting-model-differences + cloud-specific-processes**,
Cloud Logging, the AWS S3 deployment module doc), the FirstSpirit Cloud
documentation-home drafts, the FirstSpirit reference architectures, and the
FirstSpirit Cloud support knowledge base. The managed-server constraints,
support-ticket action list, custom-module pipeline, and logging/backup specifics
are **verified against the two Cloud-vs-Self-Hosted docs**; other items remain
first-pass and version-dependent. Not yet SME-verified. See
the skill's review log.*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
