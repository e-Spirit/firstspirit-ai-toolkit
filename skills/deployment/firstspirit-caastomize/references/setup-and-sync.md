# Setup, activation, the full sync and eventing

Caastomize 0.0.21, a pre-release that is not generally available. `[core]` applies to every
line unless it says otherwise; `[observed]` lines were seen on projects running 0.0.21 on
2026-10-28 and 2026-10-29. Module
installation and server configuration directories in general are `firstspirit-operations`.

## Requirements and components

- FirstSpirit **5.2.260507** or later (the module's minimum).
- A CaaS backend and tenant with an **administration API key** (it creates collections and
  API keys).
- Optional: an S3 bucket (or an S3-compatible store) for media binaries, with or without a
  CloudFront distribution in front of it.
- One FSM, module name `Caastomize`, with four components:

| Component | Type | Role |
|---|---|---|
| *Caastomize Service* | Service (server) | Holds the CaaS connection, the media target and the eventing settings for the whole server; runs the eventing |
| *Caastomize Project App* | Project app | Activates Caastomize for one project; installing it is the switch |
| *Caastomize Full Sync Executable* | Public component (executable) | Runs the full sync as a schedule task |
| *Lean JSON Content Processor* | Public component (content processor) | Post-processing of the `CaaS` presentation channel; makes the lean JSON visible in the preview (`lean-json-and-channel.md`) |

There is no other switch: a project is a Caastomize project exactly while the project app
is installed and active there.

## Service configuration

File `conf/modules/Caastomize.CaastomizeService/caastomize.json`, edited in the ServerManager
(*Caastomize Service* configuration: *CaaS base URL*, *Tenant ID*, *Tenant API key*, and
under *S3 media target*: *Endpoint URI*, *Region*, *Bucket*, *Folder*, *CloudFront base
URL*, *Access key ID*, *Secret access key*):

```json
{
  "baseUrl": "https://<caas-host>",
  "apiKey": "<tenant administration key>",
  "tenantId": "<tenant>",
  "eventing": { "poolSize": 3, "maxQueueSize": 50000 },
  "s3": {
    "endpointUri": "<only for an S3-compatible store; leave out for AWS>",
    "clientRegion": "<region>",
    "bucketName": "<bucket>",
    "folderName": "caas-media",
    "credentials": { "accessKeyId": "<key>", "secretAccessKey": "<secret>" },
    "cloudFront": { "baseUrl": "https://<distribution>" }
  }
}
```

- **The three CaaS fields are required.** The service **does not start** with one missing
  or a base URL that is not a URL; the log names what is wrong ("does not start: … is not a
  valid configuration"). Fix it in the ServerManager, then start the service.
- **No CaaS Connect fallback.** Caastomize reads nothing from CaaS Connect's
  configuration.
- **Saving while running:** a valid configuration applies at once (connection, media
  target, eventing sizes); an invalid one is rejected and the service keeps the one it
  runs with.
- **`eventing`** (optional): `poolSize` workers per project (default 3) and `maxQueueSize`
  queued operations per project (default 50 000); a value that is not a positive whole
  number falls back to the default with a warning. A `poolSize` below 2 logs a warning:
  page references and datasets each need a worker. Tune both to the project's size.
- **`s3`** (optional; the shape of CaaS Connect's S3 media configuration): without the
  block, media binaries are not uploaded and `_included` assets get no `url`. `bucketName`
  and `clientRegion` are required inside the block; `folderName` defaults to `caas-media`;
  `endpointUri` only for an S3-compatible store; without `credentials` the S3 client uses
  its default credential chain (instance role, environment); of `cloudFront` only `baseUrl`
  is read. **Caastomize does not invalidate CloudFront.** A block that is present but
  unusable lets the service start with a warning, and every full sync then fails its media
  pass (*The full sync*).
- **Treat that file as a secret:** it holds the admin key and, with static credentials,
  the S3 secret. Restrict it to the server user.
- All CaaS calls send `Authorization: Bearer <apiKey>` and time out after **10 s**.

## What activation creates

Installing or updating the project app runs the following, idempotent steps. Steps 1 and 2
also run for every active project on each service start:

1. **Two CaaS collections**: `<project-uuid>.caastomize.preview` and
   `<project-uuid>.caastomize.release`.
2. **Four API keys**, created only after the collections exist and only if missing
   (`delivery-in-caas.md` → *API keys*).
3. **The `CaastomizeJSON` output channel** and the default body on empty page templates
   (the project-properties template included) and table templates
   (`lean-json-and-channel.md`). This step can fail when FirstSpirit holds the
   project lock during installation; the log then says so. Run it from the project app
   configuration: *General → Create output channel* (*Recreate output channel* once it
   exists). The button works in the background and shows "Output channel provisioned." or
   "Provisioning failed — see the FirstSpirit server log."
4. **Two schedule entries** (deleted and recreated on every install or update):
   - `Caastomize - Full Sync (slow, sends all data) - PREVIEW`
   - `Caastomize - Full Sync (slow, sends all data) - RELEASE`
5. **Eventing for the project** starts last, so its first render finds the channel.

**After activation the collections are empty** `[observed]`: nothing is sent until the
first full sync or the first change that eventing picks up. Run the PREVIEW full sync
first; an empty preview collection with no summary line in the log means it has not run.

Nothing is created twice. The project app configuration has five tabs: *General* (the
output channel button), *Eventing*, *Error handling* and *JSON output* (**prototypes**: a
banner says the settings have no effect and may be dropped) and *API keys* (the four keys,
masked, each with a copy button that copies the full key, plus the preview and release
collection URLs with copy buttons). Opening it never creates anything in CaaS.

## The full sync

Each schedule entry runs one script task with the executable
`com.firstspirit.caastomize.executable.CaastomizeFullSyncExecutable`
(public component *Caastomize Full Sync Executable*):

| Parameter | Value | Effect |
|---|---|---|
| `useRelease` | `true` (default when absent or unreadable) | Released state → release collection |
| | `false` | Current (preview) state → preview collection |

It runs only as a schedule task (it needs the schedule context) and only while the
service runs. Two passes:

1. **Media pass** (only with an `s3` block): uploads the **original binary** of every
   medium of that state, one medium after the other, under the key the medium's URL path
   yields (`delivery-in-caas.md` → *Media*). A medium without a binary is skipped and does
   not fail the run; a failed upload is counted and the pass goes on; after a number of
   consecutive store failures, or when the store cannot be initialised, the pass **aborts
   and the document pass is skipped** ("document pass skipped because the media pass
   aborted"), so documents never point at binaries that are not there. Other resolutions
   are not uploaded.
2. **Document pass**: sends **every** page reference and **every** dataset of that state,
   and the project settings, once per language marked for generation. It never deletes: a
   document whose element is gone stays until eventing removes it or you do.

- A preview run never writes to the release collection, and the other way round.
- Plan run times: the schedule name says "slow"; a project with many datasets sends one
  document per dataset and language, and the media pass uploads every binary every time.
  The log reports the duration.
- Trigger it by running the schedule entry (ServerManager or a schedule API). The entries
  are created without a timing: they run when started, until you give them your own
  times.

### Project settings

The full sync sends one project settings document per language marked for generation into
the collection of the run:

- Document id `projectsettings.<locale>` (for example `projectsettings.de_DE`), the same key
  CaaS Connect uses; a frontend reads it by id, without a query. `_type` is
  `projectSettings`.
- Caastomize always sets `_id` to that key, also when the body writes another one.
- Rendered through the project-properties template's `CaastomizeJSON` body
  (`lean-json-and-channel.md` → *The project-properties body*).
- Sent only when the project properties have a template in the store of the run. Project
  properties never released have none in the release store: the release full sync then
  sends no project settings document, and that is not an error. When the full sync cannot
  check for the template, the run fails.
- No eventing: a change reaches CaaS with the next full sync.

### Reading the result

The run ends with one log line: `Caastomize full sync finished in <duration>: <n>
document(s) sent, <n> render failure(s), <n> send failure(s)`, plus `, <n> element(s)
skipped because their template has no CaastomizeJSON body` when that happened, plus
`, media: <n> media binary(ies) uploaded, <n> skipped without binary, <n> upload
failure(s)` when an S3 target is configured (with `, aborted: …` or the configuration
error when the pass did not finish).

- Any render failure, send failure, skipped element or media failure makes the **schedule
  fail** ("finished … with failures"), so monitoring sees missing documents.
- Send failures log the HTTP status and up to 500 characters of CaaS's explanation.
- There is **no retry** of a failed PUT or upload; run the sync again.

## Eventing

Eventing runs inside the service for every project whose project app is active, from the
moment the app is installed or updated and on every service start.

| | |
|---|---|
| Listens to | page references and pages: inserted, changed, deleted, released, moved; datasets: created, changed, deleted, released |
| Sends | the document of the **page reference**: on a page event, the page references of that page and of every page that includes one of its sections through a section reference (always deployed again); the document of the **dataset** on a dataset event |
| Not covered | sections, media, global pages and the project settings: **full sync only** |
| Languages | release and delete: every language marked for generation; any other change: the changed languages among them (none named means all) |
| Delete | removes the document (`DELETE`; a missing document counts as removed), for page references and datasets |
| State | preview store events go to the preview collection, release store events to the release collection; a dataset's state is read per change, so a release writes both |
| Queue | one per project; changes to the same element and language merge into one entry; `poolSize` workers render and send, page references and datasets each with a worker of their own; the listener waits only while the queue is full |
| Log | `Caastomize eventing DEPLOY|DELETE of <document>: <summary>` with the entry id, the revision and how many events merged; a warning when nothing was sent |

In 0.0.21 a change to a section starts no eventing: there is no listener for sections. The
change reaches CaaS when its page reference is sent again, at the latest with the next full
sync. Caastomize is a pre-release; check the eventing scope against the version you run.

- A render or send failure of one operation is logged and not retried; the next change or
  a full sync sends the element again.
- Saving a page sends its page reference's document again, also when no value changed
  `[observed]`; that is a way to push one page without a full sync.
- Stopping the service **discards** the queued changes; the log says a full sync brings
  CaaS up to date. The same when FirstSpirit removes the listener (project deactivated or
  deleted): a warning names the project, and for an active project an update of the
  project app or a service restart starts eventing again.
- Uninstalling the project app stops the project's eventing.
- Media: a changed medium's binary is uploaded by the next full sync only; a document sent
  by eventing points at the binary under the key the medium has, uploaded or not. A new
  picture's `url` therefore answers 404 until the next full sync `[observed]`: a frontend
  should expect that and fall back (no image, or a placeholder).

## Limits in 0.0.21

Caastomize 0.0.21 is a pre-release and not generally available; further features follow
until the release.

| Limit | Consequence |
|---|---|
| No eventing for sections, media and the project settings | A change reaches CaaS with the next full sync (for a section also when its page reference is sent again) |
| Full sync never deletes | After a full sync, documents of elements deleted while eventing was off stay. Run the delete yourself (`delivery-in-caas.md` → *Collections and documents*) |
| Media binaries only in the full sync; original resolution only | A new medium is addressable after the next full sync; Caastomize produces no other sizes |
| No CloudFront invalidation | A replaced binary under the same key is served stale until the cache expires or you invalidate |
| Page references, datasets and the project settings only | Global pages are not documents; whatever a document needs from them must be in its own JSON |
| No reference resolving | `$ref` is joined with `_included` (media) or the target document by the consumer (`lean-json-format.md`) |
| Advanced URLs set in the module, no routes in the JSON | See `lean-json-and-channel.md` → *URLs and routes* |
| Admin key and S3 secret in the service configuration | See *Service configuration*: restrict the file |
| Prototype tabs | *Eventing*, *Error handling* and *JSON output* in the project app have no effect |

## Uninstalling

Removing the project app stops the project's eventing and deletes the two schedule entries,
nothing else: the CaaS collections, the API keys, the uploaded binaries and the
`CaastomizeJSON` channel stay. Delete them by hand if the project leaves Caastomize for good.
