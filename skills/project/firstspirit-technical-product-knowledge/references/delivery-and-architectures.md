# Delivery strategy & reference architectures — decision reference

Decision 2 of the four: **how content reaches the audience.** This drives the
whole solution shape. The *platform internals* (CaaS REST/GraphQL, `toJson`,
Navigation Service JSON, OCM/TPP) are owned by **firstspirit-headless** — this
file is for *choosing the model and the architecture*, then routing there.

## The two delivery strategies (and the hybrid)

| Strategy | Mechanism | Best for | Trade-offs |
| --- | --- | --- | --- |
| **Push — static** | Server **pre-generates** output, then deploys files to **S3 + CloudFront** (or SFTP → webserver) | A website (or a few), best raw performance, small/no frontend team, strong security isolation | Output is materialised per generation run; multi-channel means re-templating; less suited to app/JS frontends |
| **Pull — headless (CaaS)** | **CaaS Connect** serialises content to JSON and syncs it to **CaaS**; a decoupled frontend reads it over **REST/GraphQL**, routes via the **Navigation Service** | Many channels/frontends, JS apps (React/Angular/Vue/Next), app/IoT/voice, content reuse across touchpoints | You build/operate the frontend; API keys and caching are your concern; **CaaS needs its own backup** |
| **Hybrid** | Both at once against the same project | Mixed estate — a static marketing site *and* an app/portal off one repository | Two delivery paths to reason about |

> **The choice is about delivery mechanics, not editorial capability.** Static vs.
> headless changes *who renders, who caches, and who backs up* — **not what editors
> can do.** In-context editing (including OCM on an external frontend) works for
> both; content is authored once and delivery is a separate concern, as the
> reference architectures show.

**Intake questions that decide it:**
1. **How many channels/frontends?** One website → static is simplest. Many, or a
   JS app → headless.
2. **Who owns the frontend?** No frontend team → static. A frontend team that
   wants framework freedom → headless.
3. **Editing on the live frontend?** Headless editors keep in-context editing via
   **OCM/TPP** (click-to-edit in ContentCreator against the external app).
4. **Project stage?** Pre-launch changes are cheap; a production project has
   migration cost — frame recommendations accordingly.

## The three documented reference architectures

The reference architectures are published at
`docs.crownpeak.com/reference-architectures/firstspirit/`. Point customers at the
matching one.

### 1. Static content delivery
```
FirstSpirit ──generation (pre-render)──▶ S3 ──▶ CloudFront CDN ──▶ website
                                     └──(or)──▶ SFTP ──▶ customer webserver
```
- Server-side **pre-generation** keeps rendering load off the live system.
- CMS and delivery layers are **decoupled** — the live site keeps serving even if
  the CMS is down; the CMS is not exposed to public traffic.
- **Deployment targets:** S3 + CloudFront, or a customer webserver via **SFTP** or
  **rsync** (SSH, delta sync — available for Cloud and self-hosted). See
  [hosting-and-deployment.md](hosting-and-deployment.md).
- Doc: `.../reference-architectures/firstspirit/static-deployment/`

### 2. Headless content delivery
```
FirstSpirit ──CaaS Connect──▶ CaaS (REST/GraphQL JSON) ─┐
            └─media──▶ S3                                ├─▶ frontend app
            └─Navigation Service (routing JSON) ─────────┘
                    OCM/TPP ──▶ in-context editing of the frontend
```
- Content + media sync to CaaS/S3; the frontend reads JSON and resolves routes
  via the Navigation Service; **OCM** gives editors WYSIWYG on the external app.
- **Decoupling isolates failures:** a CaaS outage doesn't hit the CMS; CMS issues
  affect only editors, not the live frontend.
- Docs recommend **frontend caching** and **hiding API keys behind middleware**
  (never ship a CaaS key to the browser un-proxied).
- **Backup scope:** the reference architecture names a backup strategy for FirstSpirit only; CaaS in the SaaS environment is backed up periodically, so confirm scope and restore with the CSM or Support.
- Doc: `.../reference-architectures/firstspirit/headless/index.html`
- **Depth:** `firstspirit-headless` (CaaS Platform, CaaS Connect, Navigation
  Service, OCM/TPP/SNAP). For reading it from JavaScript, the `fsxa-api` client is covered there too.

### 3. Connect for Commerce
```
Commerce backend (SAP Commerce Cloud / Salesforce / …)
        │  Bridge API  ▲
        ▼              │  Frontend API
FirstSpirit content ───┴──▶ shopper journey (content around the catalogue)
```
- Content-led commerce: FirstSpirit orchestrates content **around** the shop;
  the shop still owns the catalogue and transactions.
- Integration via a **Bridge** + **Frontend API**: the **Bridge** is a swappable
  microservice (reference implementation *or* your own) that adapts a backend to a
  fixed API scheme; the **Frontend API backend** hides API keys and validates the
  request source; editors preview the storefront in ContentCreator and edit via
  **OCM**. Documented connectors include SAP Commerce Cloud, SAP Commerce Cloud
  (Headless), and Salesforce.
- **Two storefront variants, same content chain.** The CMS → **Bridge** →
  CaaS / Navigation Service → **Frontend API** chain is identical; only the
  rendering side differs:
  - **Headless storefront** — a PWA / client-side app via the Frontend API
    *client*.
  - **Static storefront** — **server-side rendered** (e.g. PHP / JSP / ASPX) via
    `static.js`.
- **Transferable pattern (reusable beyond commerce):** *decouple-via-Bridge +
  Frontend-API-hides-keys + OCM-on-an-embedded-preview* applies to any external
  frontend, not just a shop.
- Docs: `.../connect-for-commerce/` (+ `headless-storefront/`,
  `static-storefront/`, `headless-storefront/salesforce/`).
- **Depth/module:** building with Connect for Commerce (module, Bridge API, Frontend
  API, reference implementations) → the Connect for Commerce documentation. Product
  overview: [extensions-and-modules.md](extensions-and-modules.md).

## External preview & on-page editing (OCM)

ContentCreator can surround an **external frontend** instead of a
FirstSpirit-rendered preview — typically an **e-commerce storefront or a PWA** —
**embedded via an iframe** for WYSIWYG preview. To let the editor actually **edit
FirstSpirit content** from that external preview, **OCM** (Omnichannel Manager /
TPP) must be used.

- **Works over both delivery styles.** The reference architectures show OCM
  on-page editing over **both** a headless PWA storefront (Frontend API *client*)
  **and** a static / server-side-rendered storefront (`static.js`). So **headless
  delivery is not a prerequisite for OCM editing.**
- **Not the same as headless.** Content is authored once in FirstSpirit; delivery
  is a separate concern deliverable by *different* techniques. Anything beyond the
  documented storefront patterns is a **custom solution, not out-of-the-box**.
  Keep "editor edits via OCM on an external preview" separate from "the site is
  delivered headless."
- **Browser security.** Because the external site runs inside the preview (an
  iframe), cross-site and browser protections may apply. The reference-architecture
  pages do not describe such limits; check the OCM documentation when scoping.
- **Depth:** OCM / TPP / SNAP internals → `firstspirit-headless`.

## Cross-cutting architectural principles (reusable beyond commerce)

Patterns the reference architectures repeat — apply them in any FirstSpirit
solution, not only the documented ones:

- **Decoupling / failure isolation.** Delivery is separated from the CMS: an
  attack or outage on the delivery layer **doesn't take the CMS down**, and a CMS
  outage **only disrupts editors**, not the live touchpoint.
- **Pre-generation offloads rendering.** For static, FirstSpirit renders ahead of
  time so rendering load and time-sensitivity stay off the live system.
- **Caching is owned differently.** Static → **CloudFront caches automatically**;
  headless → **you implement frontend caching** to your needs.
- **Hide API keys behind middleware.** Never expose a CaaS/API key to the browser;
  a backend / Frontend-API layer holds the key and validates the request source.
- **Check the CaaS backup.** The reference architecture names a backup strategy for
  FirstSpirit only; CaaS in the SaaS environment is backed up periodically (confirm
  scope and restore), and a CaaS you operate yourself needs its **own backup**.
- **API-first, composable, swappable.** The delivery stack is modular — components
  (e.g. a **Bridge** adapter) can be replaced or self-implemented against a fixed
  API scheme; deployable to Kubernetes / hosting services / existing infra.

## Common project shapes (how the pieces combine)

| Project shape | Delivery | Key modules |
| --- | --- | --- |
| Classic corporate website | Static push | Core CMS (+ SmartSearch, DQM optional) |
| Multi-brand / multi-market estate | Static or hybrid | **Multisite Management**, TranslationStudio |
| Headless app / portal (single frontend) | Headless pull | CaaS + CaaS Connect, Navigation Service, OCM/TPP |
| Content-led commerce storefront | Headless (usually) | Connect for Commerce (+ CaaS, Nav Service) |
| Omnichannel (web + app + more) | Hybrid | CaaS + static, Navigation Service, OCM/TPP |

Module details, dependencies and license flags are in
[extensions-and-modules.md](extensions-and-modules.md).

---

*Sources: docs.crownpeak.com/reference-architectures/firstspirit — index, static,
headless, and connect-for-commerce incl. the headless-storefront / static-storefront
/ salesforce variants (read 2026-07-31); docs.crownpeak.com/firstspirit/first-steps.*
