# Hosting & delivery specifics — S3 + CloudFront

The Cloud-specific behaviour of **static delivery**: how generated output reaches
the audience, how caching and invalidation work, how redirects behave, and the
gotchas to plan around. This is the *how it behaves on the Cloud* reference;
**whether** to go static vs. headless is a the FirstSpirit product documentation (hosting choice, modules, licensing)
decision, and the headless platform internals are `firstspirit-headless`.

## The static delivery path

For static delivery in the Cloud, generated output is pushed to AWS and served
via a CDN:

```
FirstSpirit ──generate──▶ S3 (aws-services-s3deployment) ──▶ CloudFront CDN ──▶ website
                                              └──(alt)──▶ SFTP / rsync ──▶ own webserver
```

- **AWS S3** (the **`aws-services-s3deployment`** module, which requires the shared
  **`aws-services-base`** module) — uploads the generated output from the
  FirstSpirit staging directory to an **S3 bucket**, then optionally triggers a
  **CloudFront cache invalidation**. Supports **full / partial / delta**
  generation.
- **CloudFront CDN** distributes and caches them. Supports custom **CNAME/SSL**,
  **cache invalidation**, **wildcard forwarding to `/index.html`**, **basic
  auth**, **`301`/`302` redirects** (via `aws-services-urlredirect`), and custom
  **`403`/`404`** pages from **`/error-pages/`** in S3.
- **Two config levels:** a **project component** ("AWS Services Configuration"
  ProjectApp — central settings: bucket, region, S3 folder/origin, the CloudFront
  distribution ID) and per-**task/schedule** configuration for a specific deploy.
  In the SaaS Cloud, **AWS credentials are managed by the platform**, not entered
  by the customer.
- **Alternative — own webserver:** the **SFTP** module or **rsync** deployment
  pushes to a **customer-managed webserver** instead of S3/CloudFront (a spoke,
  not the default Cloud path).

> **Cloud-default, not Cloud-only.** This S3/CloudFront deployment stack is
> documented in the **Cloud developer docs** (German source) and is the **default
> delivery path in FirstSpirit Cloud**; the modules are technically installable
> **self-hosted** too (they need Isolated Mode). It's documented here because the
> Cloud is where it's the norm. For the hosting *decision*, see
> the FirstSpirit product documentation (hosting choice, modules, licensing).

## Caching — the defaults that surprise people

CloudFront applies **default `Cache-Control` by file type** (values below are
from the Cloud-docs summary of the S3-deployment module doc; the German module
doc is the primary source — confirm the exact header values there):

| File type | Default caching |
| --- | --- |
| **HTML, JSON, XML, TXT, PDF** | **no-cache** |
| Other static assets (CSS, JS, images, fonts, …) | **~30-day** `max-age` |

**Implications to plan:**
- Don't assume HTML is edge-cached — it isn't by default. If you want HTML
  cached, set it **deliberately** (custom caching is configurable).
- Long-lived static assets (30 days) mean **updated assets need a new path or an
  invalidation** to be seen. Prefer content-hashed/fingerprinted asset filenames
  so a change is a new URL, not a stale cache.

## Invalidation — and the wildcard limit

When you replace files, CloudFront must be told to drop the cached copy.
Invalidation operates at three scopes:

| Scope | Use |
| --- | --- |
| **File** | Invalidate specific paths |
| **Folder** | Invalidate a subtree |
| **Global** | Invalidate everything |

**The limit that bites:** CloudFront caps **wildcard invalidation paths at ~15**.
A deploy that would exceed that is forced into a **global invalidation** — slower,
broader, and it re-fetches everything. **(confirm the exact number against the
live docs.)**

**Best practice:**
- Keep routine deploys **under the wildcard limit** so you invalidate narrowly.
- Fingerprint assets to avoid invalidating them at all.
- Expect (and schedule) the occasional **global** invalidation after a large or
  first-time deploy.
- Watch for **path discrepancies / duplicate-URL warnings** at deploy time — a
  documented failure mode.

## Redirects — CloudFront is not a web server

Because CloudFront isn't a web server, redirect behaviour is **emulated**, and
there are two distinct mechanisms:

| Mechanism | How it runs | Use for |
| --- | --- | --- |
| **Folder redirect** | Through a **Lambda** function (part of the S3 deployment module) | Simple folder-level redirects at the edge |
| **URL Redirect module** (`aws-services-urlredirect`) | Writes rules to a **DynamoDB** table that a **Lambda** consults per request | Managed, **editorially-maintained** redirect rules |

- **Status codes:** the module default is **`302`**; **in the Cloud only `301`
  and `302`** are relevant.
- The two mechanisms behave **differently on invalidation** — factor that into
  cache planning.

### How the URL Redirect module actually works (planning-level)
Verified against the module doc — enough to scope it; link the doc for the setup:

- **Editors maintain redirects as data** — entries in a **data source** backed by
  a **table template** with fields for **source URL, target URL, response code**.
  It needs editor rights **including release/approval**. Plan it as an editorial
  workflow, not a config file.
- **Targets can be a FirstSpirit object, a FirstSpirit dataset, or an external
  URL.** Sources can be **language-specific or universal**. External URLs are
  validated to start with `http(s)://`; internal references resolve through a
  **templateSet** (e.g. HTML) to get the right output-channel URL.
- **Wiring:** configured via the **"AWS Services Configuration" ProjectApp**; the
  target **DynamoDB table ID must match the CloudFront distribution ID** of the
  delivering project; rules are pushed by a **publishing task** in Schedule
  Management, and a **`generate` action is required if URL-Creator paths are
  referenced**.
- **Duplicates:** identical source URLs are **rejected** (a source is unique in
  DynamoDB — the language setting is ignored when comparing); generation emits
  **warnings** and a **report of created / deleted / skipped** entries — watch it.
- **No wildcard/pattern support** is documented — redirects are per-source-URL.
- The module doc references **both Cloud and self-hosted** and documents **no
  licence restriction**, but the mechanism is **CloudFront-bound**, so in practice
  it lands with the Cloud — and the **Cloud-vs-Self-Hosted doc lists URL Redirect
  among the Cloud-exclusive modules** (see [cloud-constraints.md](cloud-constraints.md)).

## Allowed characters (URLs)

The deployment does **not** convert unsafe or reserved characters — it follows
**RFC 1738**. Characters outside the safe set **break URLs**. Ensure generated
paths (from page names, structure, filenames) stay within the allowed character
set; sanitise at the template/structure level, not at deploy time.

## Security at the delivery layer (open ownership)

TLS/certificates, custom domains, **security headers** (CSP, HSTS, …), **WAF**,
and access control exist at the CloudFront layer. **Which of these a customer can
configure directly vs. must request from the FirstSpirit Cloud team is not fully
documented** and is a **known open question (OPEN)**. When a requirement touches
delivery-layer security, treat it as *possibly a Support request* and confirm —
don't promise self-service configuration.

> Governance-level security (certifications, data protection, sub-processors) is
> **not** this — that's the **Governance Center** (link, never restate). See
> [operations-and-maintenance.md](operations-and-maintenance.md) and
> [documentation-map.md](documentation-map.md).

## Delivery planning checklist

- **Set caching intent** per type — HTML no-cache by default; fingerprint static
  assets.
- **Keep deploys under the wildcard-invalidation limit**; plan for occasional
  global invalidations.
- **Choose the redirect mechanism** (folder vs. URL module) and remember only
  `301`/`302`, with different invalidation behaviour.
- **Constrain generated paths** to RFC-1738-safe characters.
- **Confirm delivery-layer security ownership** (self-service vs. Support) before
  committing.
- For **headless** delivery instead, jump to `firstspirit-headless` and remember
  **CaaS needs its own backup** (see operations).

---

*Sources: docs.crownpeak.com/firstspirit/url-redirect-module (**verified
2026-07-31** — DynamoDB+Lambda, data-source/table-template editorial model,
target types, JSON shape, `301`/`302`, duplicate handling + generation report,
DynamoTable=distribution ID); docs.e-spirit.com/.../Cloud_Development_Deployment_DE
(the AWS S3 deployment module doc, **German** — module names `aws-services-s3deployment`
+ `aws-services-base`, project-component vs. task config, full/partial/delta,
folder redirects, allowed-paths section confirmed 2026-07-31; **the exact
Cache-Control values and the ~15 wildcard limit were not surfaced in this pass —
they rest on the Cloud-docs-home summary, still to confirm from the German
source**); the reference architectures (static-deployment); the FirstSpirit Cloud
documentation-home drafts (delivery-layer security open question). Version- and
release-dependent — see the skill's review log.*
