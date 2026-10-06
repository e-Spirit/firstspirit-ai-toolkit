# Documentation map — Cloud topic → official source

Where the authoritative Cloud documentation lives, per topic, with the owning
portfolio skill. **Point here; don't restate** — especially the Governance
Center and the status page, which are canonical and change.

> **Naming & branding:** follow the rule in
> the FirstSpirit product documentation (hosting choice, modules, licensing) (`product-overview.md` "Naming &
> branding") — **FirstSpirit**-first, "Crownpeak" only as the legal entity. It's
> **mid-transition**, so the docs and URLs below still carry legacy names; the
> hosts (`docs.crownpeak.com` / `docs.e-spirit.com`, being consolidated under
> **docs.firstspirit.com** with 301s) and legacy search terms (**e-Spirit** — the
> legal name until 2021 — and **Crownpeak**) stay **verbatim** as literal
> identifiers. URLs below may move once the consolidation lands.

## Getting started & operations

| Topic | Source | Owner |
| --- | --- | --- |
| First Steps (sign-in, onboarding, patch days) | docs.crownpeak.com/firstspirit/first-steps/ | this skill |
| Patch / Maintenance Window Schedule | support KB (support.rezolve.com — SaaS information section; **reposted yearly, link the section**) + crownpeak.com/patchday-calendar | this skill |
| Status & incidents | firstspiritstatus.crownpeak.com (**noindex — link prominently**) | this skill |
| Maintenance/status notifications (how to subscribe) | support.crownpeak.com KB (Product Status Pages & Maintenance Notifications) | this skill |
| Logging | docs.crownpeak.com/cloud-logging/ + SaaS Customer Logging quick start KB (**being consolidated to one page**) | this skill |
| Backup, recovery & data consistency | support KB (**self-hosted-oriented, DE — concepts only, not a Cloud DIY procedure**) | this skill |

## Hosting & delivery

| Topic | Source | Owner |
| --- | --- | --- |
| Reference architectures (static / headless / commerce) | docs.crownpeak.com/reference-architectures/firstspirit/ | the FirstSpirit product documentation (hosting choice, modules, licensing) (decision) / firstspirit-headless (headless depth) |
| Static hosting, configuration, caching, invalidation | AWS S3 deployment module doc (docs.e-spirit.com, **DE — being reworked to EN/DE**) | this skill (hosting-and-delivery) |
| URL redirects | docs.crownpeak.com/firstspirit/url-redirect-module/ | this skill (points here for detail) |
| Own-webserver delivery (rsync) | docs.crownpeak.com/firstspirit/rsync-deployment/ | this skill (alternative path) |

## Development

| Topic | Source | Owner |
| --- | --- | --- |
| Template Development Guide (root) — Cloud env, developing/distributing templates | docs.crownpeak.com/template-development-guide/ | template *technology* → firstspirit-template-design / firstspirit-templating-reference (the FirstSpirit product documentation (hosting choice, modules, licensing) routes there); the **Cloud Git workflow** sub-page → this skill |
| Git-based / distributed development | docs.crownpeak.com/template-development-guide/distributed-development-of-firstspirit-projects/ (**2026.8; link prominently — findability ticket-driver**) | this skill (environments-and-workflow) |
| Templates (template language, GOM, rules) | ODFS (docs.e-spirit.com/odfs/) + Training | firstspirit-template-design / firstspirit-templating-reference |
| Module development (FSM) | docs.crownpeak.com/module-development-guide/ | firstspirit-module-development |
| FirstSpirit REST API | (REST API docs) | firstspirit-rest-api |

## User & access management

| Topic | Source | Owner |
| --- | --- | --- |
| User management (Keycloak, realms, groups) | docs.crownpeak.com/firstspirit/user-management/ | this skill (identity-and-access) |
| External identity provider / SSO (OIDC, SAML) | new Cloud IdP page (split from user management; **Support-driven setup**) | this skill (identity-and-access) |

## Governance, compliance & legal (canonical — link, never restate)

| Topic | Source |
| --- | --- |
| Certifications (ISO 27001, TISAX), DPA, TOMs, sub-processors, data locations, DORA, MSAs, SLA | **Governance Center** — firstspirit.com/policies/legal (DE: /policies/rechtliches). **Canonical trust hub; owned by legal; never approximate or cache.** |

## Cloud vs. self-hosted

| Topic | Source | Owner |
| --- | --- | --- |
| Hosting model differences, Cloud-specific limits (file-system/roles/config, module availability) | docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/hosting-model-differences/ | this skill (cloud-constraints) — also the hosting *decision* in the FirstSpirit product documentation (hosting choice, modules, licensing) |
| Cloud-specific processes (support-ticket actions, custom-module pipeline, external-DB/staging/archive/logging specifics) | docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/cloud-specific-processes/ | this skill (cloud-constraints, environments-and-workflow, operations) |

## Parked (future configuration/admin skill)

Step-by-step **install / configuration / admin procedures** are **out of scope**
for this skill and parked for a future configuration/admin skill. This skill
covers *deciding, planning, and explaining* Cloud specifics — when it says "raise
a Support request" or "configure the project component", the procedure itself
belongs to that future skill (and to the official docs linked above).

---

*Sources: the FirstSpirit Cloud documentation-home + inventory drafts (the
fold/link register and canonical link set); the docs and KB URLs listed above.
First pass — URLs and the docs.firstspirit.com consolidation are in flux; see
the skill's review log.*
