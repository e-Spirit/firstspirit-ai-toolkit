---
name: firstspirit-technical-product-knowledge
description: >-
  Technical product knowledge and project-decision reference for FirstSpirit: what the
  product is, how it is hosted, which extensions and modules exist, the documented
  reference architectures and where the official documentation lives. Use it to scope
  a project decision or route to the right doc: Cloud SaaS vs. self-hosted, static push
  vs. headless pull via CaaS vs. hybrid, which reference architecture fits, which
  module or extension a requirement needs (AI Suite, CaaS, Navigation Service,
  SmartSearch, DQM, TranslationStudio, Connect for Commerce, OCM/TPP, Multisite
  Management, Formcentric Webforms), what needs a licence or edition, what FirstSpirit
  is and is not, the current version and certifications. Also for questions like
  "which hosting", "do I need CaaS", "is X licensed separately", "where is the doc
  for Z". Depth lives in firstspirit-headless,
  firstspirit-api-reference, firstspirit-template-design, firstspirit-scripting,
  firstspirit-module-development and firstspirit-rest-api.
metadata:
  source-commit: "4a75bd0"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit — technical product knowledge

The **orientation and decision layer** for FirstSpirit. It answers *what to
build, on what, with which modules and licenses, and where the documentation
is* — then hands off to the reference skills and the official docs for depth.

This skill owns the **technical product picture and the project decisions**. It
does **not** re-teach template syntax, the API object model, or the headless
platform internals — those live in dedicated skills it points at. Treat it as
the map, not the territory.

FirstSpirit is an **enterprise, hybrid-headless CMS**. Current release:
**FirstSpirit 2026.8** — calendar versioning `YYYY.N`. It serves content from one repository to any channel two
ways at once: **classic** template-based delivery (the server pre-generates
output) and **headless** delivery (Content as a Service — clean JSON over
REST/GraphQL). A project is organised into **stores** — Page, Media, Site
(structure), Template, and Content/datasources — and every element exists in a
**preview** and a **release** state.

```
                     ┌─────────────────── FirstSpirit server ───────────────────┐
   authoring:        │  ContentCreator (browser)   SiteArchitect (Java desktop)  │
   admin:            │  ServerManager                                            │
   stores:           │  Page · Media · Site · Template · Content/datasources     │
   states:           │  preview  ·  release                                      │
                     └───────────────┬───────────────────────┬──────────────────┘
                        push (static)  │                       │  pull (headless)
                   pre-generate → S3 + CloudFront CDN     CaaS Connect → CaaS
                        (or SFTP → webserver)             (REST/GraphQL JSON)
                                 │                             │  + Navigation Service
                                 ▼                             ▼      (routing JSON)
                            live website                 any frontend / app / channel
```

## The four project decisions

Most FirstSpirit scoping questions reduce to four decisions. Each has a
dedicated reference — read the one that matches, don't guess.

| # | Decision | Options (short) | Read |
| --- | --- | --- | --- |
| 1 | **Hosting model** | Cloud SaaS on AWS · Self-hosted | [hosting-and-deployment.md](references/hosting-and-deployment.md) |
| 2 | **Delivery strategy & architecture** | Static push (S3/CDN) · Headless pull (CaaS) · Hybrid | [delivery-and-architectures.md](references/delivery-and-architectures.md) |
| 3 | **Which modules / extensions** | AI Suite, CaaS, Nav Service, SmartSearch, DQM, TranslationStudio, Connect for Commerce, OCM/TPP, Multisite, Formcentric … | [extensions-and-modules.md](references/extensions-and-modules.md) |
| 4 | **Edition & licensing** | What's included vs. add-on; what needs a valid license | [editions-and-licensing.md](references/editions-and-licensing.md) |

For the technical product model behind all four (server, stores, interfaces,
generation, release vs. preview, versioning, certifications) read
[product-overview.md](references/product-overview.md).

## How to use this skill

- **Decide, then route.** Give the recommendation and the *reason* (the intake
  question that drives it — most often **project stage: in development vs. in
  production**, and **channels: one website vs. many channels/frontends**).
  Then point at the reference skill and the official doc for the build detail.
- **Point, don't paraphrase.** For anything another skill owns (headless
  internals, API model, template syntax, REST, scripting, modules), name the
  skill and stop. Restating drifts. See "What this skill is *not*" below.
- **Public material only.** This skill contains only information backed by the
  **official documentation and other public material**. Where public marketing
  and the documentation disagree (some spellings, a
  "personalisation" module), the text says which source it follows. For product
  names and spellings it follows the live firstspirit.com examples.
- **Packaging and pricing are not covered.** Edition and packaging detail and
  pricing are a Sales / Governance Center topic. See
  [editions-and-licensing.md](references/editions-and-licensing.md).
- **Governance is legal's, and canonical.** Certifications, data protection /
  security posture, licensing terms, SLAs, and product addenda are **owned by
  legal** and published at the **Governance Center**
  (`firstspirit.com/policies/legal`) — the **canonical home**. For any such
  topic, **link the Governance Center; never restate, approximate, or cache its
  content here** (it changes and it carries legal weight). Everything in this
  skill that touches governance points there.
- **Use product names.** **FirstSpirit** is the product name; refer to
  everything by its **product name** (ContentCreator, DQM, CaaS, …). Do **not**
  combine a company name such as "Crownpeak" or "Rezolve" with product
  names; mention a company or legal entity only where genuinely necessary. See
  [product-overview.md](references/product-overview.md#naming--branding).
- **Beta; version-dependent.** Built against **FirstSpirit 2026.8** from the
  official documentation, the first-steps guide and firstspirit.com. Version-dependent
  facts drift: check the current documentation before a customer commitment.

## Quick answers

- **What version?** FirstSpirit **2026.8**, calendar naming `YYYY.N`, released on
  a monthly-ish cadence. → [product-overview.md](references/product-overview.md)
- **Which hosting?** Default is **FirstSpirit Cloud** (managed SaaS on AWS, with
  DEV/QA/PROD stages, Keycloak identity, ~4-week patch days). **Self-hosted**
  (a.k.a. on-prem) exists for strict data-residency/network-isolation needs. (The
  documentation names only **Cloud** and **self-hosted**.) →
  [hosting-and-deployment.md](references/hosting-and-deployment.md)
- **Static or headless?** Need one website, best raw performance, minimal
  frontend team → **static push** (pre-generate → S3 → CloudFront). Need many
  channels/frontends or a JS app → **headless pull** (CaaS + Navigation
  Service). You can do **both** (hybrid). →
  [delivery-and-architectures.md](references/delivery-and-architectures.md)
- **Which reference architecture?** The documentation publishes three:
  **static-deployment**, **headless**, and **connect-for-commerce**. →
  [delivery-and-architectures.md](references/delivery-and-architectures.md)
- **Is <feature> licensed separately?** Almost every extension (AI Suite, CaaS &
  CaaS Connect, Navigation Service, SmartSearch, DQM, TranslationStudio,
  Formcentric, Connect for Commerce, OCM) **requires a valid license** and is
  add-on. → [editions-and-licensing.md](references/editions-and-licensing.md)
- **Where's the doc for X?** →
  [documentation-map.md](references/documentation-map.md) — a topic → official
  doc URL + owning portfolio skill index.

## What this skill is *not* (point at these, don't restate)

| If the question is really about… | Use |
| --- | --- |
| **Operating on FirstSpirit Cloud** once it's chosen — the Cloud's constraints/limits, DEV/QA/PROD workflow, caching/invalidation, SSO, patch days, backups, go-live, dev/maintenance best practice | **firstspirit-cloud** |
| The headless platform internals — CaaS REST/GraphQL, `toJson`, Navigation Service JSON, OCM/TPP/SNAP click-to-edit | **firstspirit-headless** |
| The Java Access API object model — stores, agents, UID types, queries | **firstspirit-api-reference** |
| Designing/structuring templates (incl. for headless) | **firstspirit-template-design** |
| Template-language & GOM syntax / datatypes / rules | **firstspirit-templating-reference** |
| BeanShell scripting, workflows, generators | **firstspirit-scripting** |
| Packaging a module (FSM) — descriptor, components, deployment | **firstspirit-module-development** |
| The FirstSpirit REST API (`/rest/v1/`, editing content) | **firstspirit-rest-api** |
| Delivering findings as editor comments | **firstspirit-collaboration** |
| Auditing a project from a sync export | **downstream analysis** |
| **How** a report/doc should read (technical voice) | **firstspirit-technical-tone-of-voice** |

## References

Loaded on demand — read the file that matches the question.

| File | Covers | Read when |
| --- | --- | --- |
| [product-overview.md](references/product-overview.md) | What FirstSpirit is technically: server, the five stores, generation model, release vs. preview, the three interfaces (ContentCreator/SiteArchitect/ServerManager), APIs, versioning, certifications | You need the technical product model or feature scope |
| [hosting-and-deployment.md](references/hosting-and-deployment.md) | Cloud SaaS on AWS vs. self-hosted; DEV/QA/PROD stages; Keycloak; patch cadence; S3/CloudFront; CI toolchain; how to choose | You're deciding or explaining hosting/operations |
| [delivery-and-architectures.md](references/delivery-and-architectures.md) | Push (static) vs. pull (CaaS) vs. hybrid; the three documented reference architectures; how to choose by need | You're choosing a delivery model or architecture |
| [extensions-and-modules.md](references/extensions-and-modules.md) | The premium-module catalogue — for each: what it is, what problem it solves, what it depends on, license flag, owning skill/doc | You're deciding which module a requirement needs |
| [editions-and-licensing.md](references/editions-and-licensing.md) | Per-module licensing from the public docs (add-on; metering: confirm with CSM); how to scope a licence decision by requirements → modules; why editions/pricing are a Sales topic kept out of scope | You're advising on licensing, scope, or feature cost |
| [documentation-map.md](references/documentation-map.md) | Topic → official doc URL + owning portfolio skill; the master pointer index | You need to send someone to the right doc |
| [naming-and-aliases.md](references/naming-and-aliases.md) | Legacy/internal/alias names → current product name → where each still surfaces (licence flags, class/API names, docs) + why the drift exists | You hit an old/odd name (`WE_API`, `PACKAGEPOOL`, "WebEdit", "CorporateContent") and need the current one |

---

*Sources: the FirstSpirit official documentation (docs.crownpeak.com /
docs.e-spirit.com), the Cloud first-steps guide, and firstspirit.com (used only
for product names, claims and offerings). Built against FirstSpirit 2026.8;
version-dependent.*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
