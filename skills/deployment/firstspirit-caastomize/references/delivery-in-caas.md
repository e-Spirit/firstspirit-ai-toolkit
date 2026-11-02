# What lands in CaaS and S3

Caastomize 0.0.21, a pre-release that is not generally available, read in the module source
`[core]` unless a line says otherwise; `[observed]` lines were seen on projects running 0.0.21 on
2026-10-28 and 2026-10-29. How to
read CaaS (filters, paging, secure tokens, CORS, change streams) is
`firstspirit-headless/references/caas-platform.md`; this page covers only what Caastomize
puts there.

## Collections and documents

| | Value |
|---|---|
| Preview collection | `<project-uuid>.caastomize.preview` |
| Release collection | `<project-uuid>.caastomize.release` |
| Database | the configured tenant (`tenantId`) |
| Document id | `<gid>.<locale>`, the element's GID and the locale with underscore (`de_DE`); the project settings: `projectsettings.<locale>` |
| Write | `PUT <baseUrl>/<tenant>/<collection>/<document-id>`, body = the rendered JSON |
| Delete | `DELETE <baseUrl>/<tenant>/<collection>/<document-id>` (eventing, page references and datasets) |

- `<project-uuid>` is the FirstSpirit project's UUID. The `caastomize` segment keeps the
  names apart from CaaS Connect's collections for the same project, so both modules can
  write into one tenant. The project app's *API keys* tab lists both collection URLs with
  a copy button.
- One document per page reference or dataset, per language marked for generation, per
  state, plus one project settings document per language (`setup-and-sync.md` → *Project
  settings*). A page reference and its page are **one** document (the page's GID is in
  `_pageId`); sections are part of the page's document, shaped by the page body and by the
  section templates' own bodies (`lean-json-and-channel.md`).
- `_id` in the body equals the document id (`lean-json-format.md` → *The envelope*).
- A deleted page reference or dataset loses its document through eventing. The full sync
  never deletes (`setup-and-sync.md` → *Limits*): a document of an element deleted while
  eventing was off stays. Remove it with the same `DELETE` and a read-write key.

Reading a document is a normal CaaS read, for example
`GET <baseUrl>/<tenant>/<project-uuid>.caastomize.preview/<gid>.de_DE` with a read key; the
query parameters are in `firstspirit-headless/references/caas-platform.md`.

## Media

With an `s3` block in the service configuration (`setup-and-sync.md`), the full sync
uploads the **original binary** of every medium of the synced state, and every asset in a
document's `_included` carries its public `url`:

| | Value |
|---|---|
| Key in the bucket | `<folder>/<path>`, where `<path>` is the medium's Advanced URLs path under a project prefix: `<project-uuid>-caastomize/<medium path>` for release, `<project-uuid>-caastomize/preview/<medium path>` for preview (without the leading slash and without the store folder); pictures with the project's original resolution |
| `url` without CloudFront | `https://<bucket>.s3.<region>.amazonaws.com/<folder>/<path>` (or the endpoint's host for an S3-compatible store) |
| `url` with CloudFront | `<cloudFront.baseUrl>/<path>`: the folder is left out, as CaaS Connect does, because the distribution's origin path points at the folder |
| Object metadata | the medium's GID (`fs-gid`) and its content type |

- Preview and release documents point at the binaries of their own state. A medium that
  is the same in both is uploaded twice, under its preview and its release key. The
  `-caastomize` suffix keeps the keys apart from CaaS Connect's when both share a bucket.
- A medium that is no medium of the project and state, or whose key cannot be computed,
  gets no `url`; a warning names the document and the asset.
- Only the original resolution is uploaded; Caastomize produces no other sizes.
- Nothing is invalidated in CloudFront, and nothing is deleted from the bucket.

## Editing in ContentCreator (OCM)

A frontend that reads the preview collection can be the external preview of
ContentCreator. The bridge (`TPP_SNAP`, `live.js`, preview ids) is
`firstspirit-headless/references/preview-and-editing.md`. What Caastomize adds:

- The preview id of a page reference is its CaaS document id (`lean-json-format.md` → *The
  envelope*); for a section append `.<locale>` to its `_id`, which has none. Seen once with
  OCM 3 on 2026-10-28, 0.0.21 `[observed]`; whether `TPP_SNAP.renderElement` works when the
  preview renders the `CaastomizeJSON` channel is `[verify]`.
- A saved change to the page reference, the page or a dataset reaches the preview collection
  through eventing, a little later; the frontend notices the rewrite by `_etag` (*Reading
  it*). A section edit starts no eventing in 0.0.21 and shows after the next send of its page
  reference or a full sync (`setup-and-sync.md` → *Eventing*).

## Reading it: what the pushed JSON means for queries

How to read CaaS is platform behaviour and does not change with Caastomize: paging
(`pagesize` default 20, max 100), filter syntax and key rules are in
`firstspirit-headless/references/caas-platform.md` (*Pagination*, *Filtering*,
*API keys*). What Caastomize decides is the JSON that goes in, and that shapes the queries
`[observed]`:

- **References are not resolved by CaaS.** A `$ref` to a medium is joined with the same
  document's `_included` by the consumer; a `$ref` to a page reference or a dataset is read
  as its own document (`<gid>.<locale>`).
- **`_etag` tells that a document was rewritten**, eventing and full sync alike (a full sync
  rewrites unchanged documents too `[observed]`); compare it to refresh a cache or a preview.
  What `_etag` is and how to compare it is platform behaviour:
  `firstspirit-headless/references/caas-platform.md` → *Response envelope*. `_revision` does
  not serve for this (`lean-json-format.md` → *`_revision`*).
- **A field in the JSON can be read, whatever the key's scope.** A key scope selects
  collections, not fields; shape the JSON to leave out internal fields
  (`lean-json-and-channel.md` → *Reshaping it*).

## API keys

Provisioning creates four keys per project, each scoped to one collection:

| Key name in CaaS | Collection | Mode | Tag `usecase=` |
|---|---|---|---|
| `Caastomize Project <uuid> Read (Preview)` | preview | `read` | `PREVIEW_READ` |
| `Caastomize Project <uuid> Read/Write (Preview)` | preview | `read-write` | `PREVIEW_READWRITE` |
| `Caastomize Project <uuid> Read (Release)` | release | `read` | `RELEASE_READ` |
| `Caastomize Project <uuid> Read/Write (Release)` | release | `read-write` | `RELEASE_READWRITE` |

- Every key carries the tags `automated-by=caastomize` and `project=<uuid>`; the description
  reads "Automated api key (…), generated by Caastomize."
- Missing keys are created on provisioning; existing ones are kept. Uninstalling the
  project app does not revoke them: revoke the four keys in CaaS yourself when the project
  leaves Caastomize.
- **Getting the value for a consumer:** the project app's *API keys* tab shows each key
  masked and has a **copy button** that copies the full key (a working bearer credential;
  treat it as a secret). Without the client, a CaaS administrator finds the keys in the
  platform's key management (`firstspirit-headless/references/caas-platform.md` → *API keys*)
  by their tags `automated-by=caastomize` and `project=<uuid>`.
- Each key works only on its own collection `[observed]`: the preview read key gets 403
  on the release collection and on the tenant listing. A frontend that reads both states
  needs both read keys.
- Give a browser frontend the **read** key only, and through a secure token rather than the
  raw key (`firstspirit-headless/references/caas-platform.md` → *Secure tokens*).

## Next to CaaS Connect

- Separate collections, separate key names, a separate custom-properties bucket in the
  project, separate service and project app names: installing Caastomize changes nothing in
  CaaS Connect's delivery.
- Caastomize reads nothing from CaaS Connect's configuration. Its `s3` block has the shape
  of CaaS Connect's S3 media configuration, so the same values can be copied over; the
  CloudFront invalidation settings are ignored.
- A frontend that reads both must know which collection it reads: CaaS Connect documents
  have the toJson shape (`firstspirit-headless/references/caas-connect.md`), Caastomize
  documents have the shape your `CaastomizeJSON` body produces.

## If you saw the proof of concept

Earlier demos ran a proof-of-concept module with the same name; it is not developed
further. The product differs:

| Topic | Proof of concept | Product 0.0.21 |
|---|---|---|
| Collection names | `<uuid>-caastomize.preview` | `<uuid>.caastomize.preview` |
| Service configuration directory | `conf/modules/CaastomizeService/` | `conf/modules/Caastomize.CaastomizeService/` |
| JSON | Hand-written default bodies for page, section and table templates | `leanJSON` default body on page and table templates; section and link bodies optional |
| Updates | Eventing with a per-project event matrix, plus *Total Sync* schedules | Eventing for page references and datasets, plus *Full Sync* schedules |
| Delivered elements | Page references (media and datasets only inside them) | Page references and datasets as their own documents; media binaries in S3, linked from `_included` |

Do not apply proof-of-concept instructions to the product.
