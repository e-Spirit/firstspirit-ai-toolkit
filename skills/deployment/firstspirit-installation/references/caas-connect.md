# CaaS Platform and CaaS Connect

Sources `[odfs]`, read 2026-10-13: *CaaS Connect: Documentation for Server Administrators* (3.104.9, 05.10.2026); *CaaS Connect: Module documentation* (3.104.9; chapters 2, 5, 6 read); *CaaS Platform: REST Interface Documentation* (21.4.3; introduction and authentication only).
What the documents look like and how a front end reads them: `firstspirit-headless`. The platform's own installation: `caas-platform.md`.
(The vendor name in these documents reads *Rezolve AI*; the older ones say Crownpeak.)

## Cloud or on-prem

The server-side topics are **on-prem** only; in the SaaS environment the module is installed and configured for you and media sit in an S3 bucket behind a CDN `[odfs]`. The project steps are the customer's on both.

## Requirements `[odfs]`

- FirstSpirit **5.2.260507 or later**.
- A reachable **CaaS platform** (mandatory) and a **Master API key** with read and write access to all CaaS projects. Platform installation: `caas-platform.md`.
- Optional: an S3-compatible bucket, optionally behind CloudFront, for media.
- The module has no dependency on other modules. Licence: an add-on (`firstspirit-technical-product-knowledge`).

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Install the module, then **restart the server** (also after every update). Nothing syncs yet: a project has to be marked | ServerManager, Server, Properties, Modules | module listed |
| 2 | Configure the **CaaS Connect Service**: platform URL, Master API key, Tenant ID (at most 63 characters, not case-sensitive). Fields with a red border are invalid. The same values can be set in `./conf/modules/CaasConnect.CaasConnectService/caasConnect.json` (`baseUrl`, `apiKey`, `tenantId`; S3 under `mediaConnectorConfig`); a **restart of the service** is needed after editing the file | the service's configuration dialog | the service log has no connection error: it tests the platform when it starts |
| 3 | Optional: web component *CaaS Connect Web App* on the ContentCreator web app. It gives the **status report for CaaS documents** (Actions menu, project administrators) and the **CaaS Connect Preview Rendering Plugin** for the OCM | Web applications or Project properties, Web components | report in the Actions menu |
| 4 | Per project: add the project component **CaaS Connect project app**. This creates the collections, some API keys and the sync schedules | Project properties, Project components | Endpoints and API Keys tabs filled in; schedules present |
| 5 | Optional per project: URL factory, remote datasets, resolution tags `CaaS` (see below) | the project app's dialog; project resolution tags | |
| 6 | First fill of the data: run a **Total Sync** schedule | Schedules | documents in the platform, status report ok |

Passwords: with password encryption on, the API key and the S3 secret are encrypted when saved or when the service starts, with a key internal to the module `[odfs]`.

## Project configuration `[odfs]`

- **Keys.** Per project and state (preview, release): one read-only and one read/write key; plus one GraphQL key per state. They are project-specific. With **remote datasets** (references instead of embedded data, recommended by the vendor) these keys cannot read datasets of the other project: create a key by hand, or use the GraphQL keys.
- **URL factory.** Default *Advanced URLs*; the vendor recommends a factory that keeps its URLs in the FirstSpirit Registry. After a change, **overwrite all content** with a Total Sync.
- **Resolutions.** Without a tag, **all** resolutions of every image are sent: slow, especially the first run. Tag the wanted ones `CaaS` in the project; a tag change updates nothing by itself (Total Sync) and removes nothing already sent. When exporting a project keep *Export automatically calculated image resolutions* on.
- **Release function off.** Only the preview state is sent; update the release state with the schedules.

## Media `[odfs]`

Default: binaries in CaaS file buckets. The vendor "strongly recommends" S3 for performance. S3 is configured in the file only (`mediaConnectorConfig.S3`: bucket, region, credentials, CloudFront, cache-control; defaults 300 s and 900 s shared). Changing the hosting invalidates earlier URLs; run a Total Sync.

## Schedules `[odfs]`

Created by the project app: *Smart Sync* (changed data, preview and release) and *Total Sync* (all data, preview and release). Both remove obsolete documents after a run without errors. Edits to them are **reset** when the component is installed or updated: change a copy. For single elements: executable `com.espirit.caasconnect.executable.CaasConnectGidSyncExecutable` (parameters `elements`, `useRelease`, `languages`, `resolutions`).

## Checking and repairing after the install `[odfs]`

Module documentation 3.104.9, 05.10.2026.

- **Status report** (needs the *CaaS Connect Web App* component): *Actions* menu of a page reference, context menu of a dataset or media item, for project administrators. Per language and stage it shows *In Sync*, *Out of Sync*, *Missing in CaaS* (typical right after a project import, before the first fill), *Content unavailable* (rendering failed, for example a deleted page template; fix it in FirstSpirit first) or *Never Released*. A difference is not automatically an error: a missing approval, a missing reference or a change still in flight explains it. Resync from the dialog is per stage, not per language, and runs beside events and schedules. The header shows the pipeline: *Lagging* above 30 s delay, *Critical* above 2 min. The report downloads as JSON for the technical support.
- **GraphQL API:** provisioned by the module through the platform's management API, at service start and after installing or updating the project component, only when it does not exist yet. After a change to the project model, or when a GCAPage template is used for the first time, run the schedule *Deploy FirstSpirit GraphQL API* or the executable `CaasConnectGraphqlSyncExecutable`. A change that breaks the schema still goes out and can break consumers' queries.
- **Documented problems:** `ReferenceNotFoundException: No template defined for project properties` in a full sync means no project settings template is set (fixed in FirstSpirit 2023-04; update or set the template). **External read-only databases are not supported** (no GID, so no sync). Change streams missing on a collection are restored by running a schedule.

## Updating the module: version pairing and notices `[odfs]`

*CaaS Connect release notes* (module 3.104.9, 05.10.2026), read 2026-10-13: of about 300 entries, 21 are *update notices*; the rest are fixes and internal changes and are not summarised. Read the notes of every version between yours and the target before updating.

| From module version | Needs |
|---|---|
| 3.98.0 (06.2026) | FirstSpirit **2026.5 (5.2.260507)** or later |
| 3.74.3 / 3.74.0 (2025) | 5.2.250602 / 5.2.250404 or later |
| 3.49.0 (02.2024) | 5.2.240208 or later |
| 3.41.0 (11.2023) | Java 17 for the server (FirstSpirit requires it from 2023.9) |
| 3.34.1 (07.2023) | 5.2.230812 or later |
| 3.30.0 (06.2023) | **CaaS Platform 16.9.0 or later** before updating the module (setup endpoint changes) |
| 3.28.0 (01.2023) | **CaaS Platform 15.4.0 or later** (new authorization header) |
| 3.25.0 / 3.23.0 (2022) | CaaS Platform 14.9.0 (ready-made API keys) / 14.8.3 (simpler setup) |

Notices that change behaviour after an update:
- **3.104.0 to 3.104.3:** a URL-generation optimisation had errors in special cases; 3.104.4 reverted it. Avoid 3.104.0 to 3.104.3.
- **3.103.0:** the first sync after the update **uploads existing media once more** to attach a version marker.
- **3.85.0:** a project option can switch off processing of **remote datasets**; switching it on means they are no longer processed, and a Smart Sync removes those already in CaaS.
- **3.68.0:** two breaking changes for the standard GraphQL apps (type names now always carry their type suffix, and queries only offer types named in the templates; `FS_INDEX` is the exception). Re-deploy the GraphQL API and test consumers.
- **3.63.0:** metadata inheritance for CaaS (from 3.55.0) became **active by default**, which can change what the CaaS API returns.
- **3.38.0:** the schedules were renamed to *Smart Sync* and new *Total Sync* schedules were added; replication mode *FULL* now deletes obsolete documents after an error-free run.
- **3.29.2:** data is generated only for languages with *Generate language* on; existing CaaS data of other languages is removed by the reconciliation schedules.
- **Sync limits:** the manual sync executable and a single-element sync count against the **schedule limit** like sync jobs, except syncs started from the status dialog (3.100.0, 3.101.4). Where the limit is set is not in the release notes `[verify]`.

## Failure `[odfs]`

Network trouble or overload: the module retries, then logs to the FirstSpirit server log. **The editor is not told**; watch the log. Repair by running a schedule or repeating the change. An API key without write access to all CaaS projects is the other cause listed.
