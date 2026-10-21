# Editions & licensing — decision reference

Decision 4 of the four: **what a project needs to be licensed for.** This is a
scoping aid, not a price list.

## Scope of this reference (read first)

- **Documentation only.** This file states what the official documentation says
  about licensing. Edition names, packaging and prices are not part of it.
- **No prices.** Cost varies by licensing option, implementation size, modules,
  and support. Ask Sales for a quote.

## What the docs establish (safe to state)

The official documentation frames FirstSpirit as **core CMS + independently
licensed modules**, not public tiers. Reliable to say:

- The Cloud first-steps page lists AI Suite, CaaS Connect, Navigation Service,
  SmartSearch, DQM, TranslationStudio, Formcentric Webforms and Connect for Commerce
  as services that need a **valid licence** (CaaS Connect and the Navigation Service
  also need a CaaS licence). How a service is metered or priced is not restated
  here: confirm it with the customer's CSM, Sales or Support, and see the
  Governance Center for binding terms. The AI Suite is licensed **as a suite**: all
  assistants and the API are covered by that one licence, including later
  enhancements. **BasicWorkflows** is
  **open source** (Apache-2.0); its documentation ties creating and running
  workflows to `license.WORKFLOW=1`. (See
  [extensions-and-modules.md](extensions-and-modules.md).)
- **Governance Center** (`firstspirit.com/policies/legal`) publishes licensing
  terms, SLAs, product addenda, and compliance statements. It is the reference for
  binding terms; this file does not restate them.

**Use this framing in customer-facing scoping:** "the core CMS plus the specific
licensed modules your requirements need" — scope by *requirements → modules*, not
by tier.

## Cloud vs. self-hosted licensing

Licensing is handled differently for Cloud and self-hosted. Read the environment
first.

- **FirstSpirit Cloud:** Cloud customers have **no server-admin access** (see
  [hosting-and-deployment.md](hosting-and-deployment.md)), so there is no licence
  file to manage. "What's licensed" is agreed with Sales, not edited by the
  customer.
- **Self-hosted:** an **`fs-license.conf`** file (server `conf/` directory) carries
  **feature flags** that gate features and modules; it is **hot-reloadable** via
  ServerMonitoring (no restart), is **IP-locked**, and the server **stops at the
  expiry date**.

**What the feature flags gate** (self-hosted `fs-license.conf` — orientation only;
never quote a customer's actual entitlements from here):
- **Limits / type:** `EXPDATE` (expiry — server terminates), `MAXUSER`,
  `MAXPROJECTS`, `MAXSESSIONS`, `IP` (authorised servers), `SCOPE` (single vs.
  corporate), `TYPE` (Production / Development / Demo / Staging / Training),
  `USER` (licensee).
- **Feature toggles:** `WEBEDIT` (ContentCreator editing), `WORKFLOW` (custom
  workflows), `ARCHIVE`, `DOCUMENTGROUP`, `APPTAB_SLOTS` (AppCenter apps).
- **Modules:** `license.MODULES` (comma-separated — the doc example lists
  personalisation, search, integration, newsletter, portal, form_edit,
  enterprise_search), plus specific gates such as **`license.PACKAGEPOOL=1`**
  (Multisite Management — ContentTransport / Corporate Content) and the
  **API-Access** feature (External Synchronization / external API clients).

> **A flag gates a *feature*, not always a specific module.** `WORKFLOW` enables
> the **general** custom-workflow capability (needed for *any* custom workflow,
> e.g. the free **BasicWorkflows** module) — it is **not** a licence for that
> module. On Cloud there is no licence file, so these flags do not apply.

**Decision takeaway:** *whether* a requirement needs a licence is answered the same
way (requirements → modules); *how it's provisioned* differs — **Cloud:** the
no licence file to manage; **self-hosted:** an `fs-license.conf`. Binding
scope and terms are with Sales and the Governance Center.

## How to reason about a licensing decision

1. **Start from requirements, not tiers.** List the capabilities the project
   actually needs (from decisions 1–3).
2. **Map each to a module** via [extensions-and-modules.md](extensions-and-modules.md);
   mark which are licensed add-ons.
3. **Take anything binding to Sales or the Governance Center.** Prices, exact scope
   per deal, and SLAs are set there.

## Worked example

> "Multi-brand corporate site, three languages, AI copy help, accessibility
> compliance, no commerce."
>
> Needs: **Core CMS** + **Multisite Management** + **TranslationStudio** +
> **DQM** (accessibility) + **AI Suite** (a licensed add-on). Scope it as "core CMS
> plus the Multisite, TranslationStudio, DQM and AI Suite licenses your
> requirements need". Pricing is a Sales matter.

---

*Sources: docs.crownpeak.com/firstspirit/first-steps (per-module licensing);
firstspirit.com/policies/legal (Governance Center); the self-hosted licence-
configuration admin doc (`docs.e-spirit.com/odfs/edocs/admi/.../licence-configu/`).*
