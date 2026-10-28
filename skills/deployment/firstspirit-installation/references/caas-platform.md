# CaaS Platform (operating it yourself)

Sources `[odfs]`, read 2026-10-13: *CaaS Platform: Operations Guide* 21.4.3 (05.10.2026), read whole; *Content as a Service: Product documentation* 21.4.3 (components, migration); the *REST Interface* document for the authentication model.
The module that fills the platform: `caas-connect.md`. Reading it from a front end: `firstspirit-headless`.

## Cloud or on-prem

Running the platform is **on-prem** work. The Operations Guide advises against on-premises operation without the ability to operate, monitor and repair a Kubernetes cluster, and points to the SaaS offering `[odfs]`. In SaaS none of this applies; some settings below (database management, paging limits, reference resolution) are on-prem only (REST Interface documentation) `[odfs]`.

## Requirements `[odfs]`

- **Kubernetes** and the **Helm** client; delivered as a Helm chart (`caas-<version>.tgz`) and an image archive (`caas-docker-images-<version>.zip`). System requirements and sizing: *Sizing and support* below.
- A central Docker registry the cluster can pull from.
- NGINX Ingress Controller for the shipped ingress definitions (otherwise adjust annotations and `ingressClassName`, or create the ingress yourself).
- Prometheus Operator and a central logging system are **essential**, not optional: without them analysis and support are hard. No Prometheus Operator: switch the service monitors and alerts off.
- MongoDB file system: XFS recommended. Two components, both containers: `caas-rest-api` and `caas-mongo` (not reachable from outside the cluster).

## Steps, in order `[odfs]`

| # | Step | Detail | Check |
|---|---|---|---|
| 1 | Import the images into your registry | from `caas-docker-images-<version>.zip` | images present |
| 2 | Write a `custom-values.yaml` over the chart's `values.yaml` | `credentials` block: passwords, **Master API key**, Mongo cluster key. Change the defaults. Passwords **alphanumeric only**. Generate the cluster key (`openssl rand -base64 756`) **before the first install**: changing it later can make the database permanently unavailable. Registry under `image.registry` and `image.credentials`. Ingress via `restApi.ingress.enabled` and `restApi.ingressPreview.enabled` with hosts | |
| 3 | Create a namespace and install the chart: `helm install <release> . --namespace=caas --values <file>` | takes up to about five minutes | `kubectl get pods`: all `Running` (three `caas-mongo`, REST pods) |
| 4 | TLS: create a secret with `tls.key` and `tls.crt` | not encrypted by default | |
| 5 | Monitoring and scaling (below) | | `/_logic/healthcheck` returns 200 |
| 6 | Hand the URL, tenant and **Master API key** to the FirstSpirit administrator | `caas-connect.md` step 2 | the CaaS Connect Service starts without a connection error |

The **Master API key** is created at install, so the REST Interface can be used at once `[odfs]`.

## Scaling and monitoring `[odfs]`

- At least **three** Mongo instances (a primary needs a majority; below 50 percent available, no primary can be elected and the REST pods turn not-ready). Scale Mongo only through the Helm `mongo.replicas` value, never the StatefulSet directly; scaling down needs manual work and is not recommended.
- The REST Interface scales with a Horizontal Pod Autoscaler (defaults: off; 3 to 9 replicas; 50 percent CPU). Switching it on once drops the pods to one for a moment during the rollout.
- Health: `/_logic/healthcheck` (HTTP 500 if a check fails). Mongo metrics come on a separate port without authentication, reachable only inside the cluster.

## Configuration worth knowing (`restApi.applicationConfig`) `[odfs]`

Page size default 20, maximum 100 (`/mongo/default-pagesize`, `/mongo/max-pagesize`); reference resolution depth, count and switch (`/refResolvingInterceptor/...`); filter operator blacklist; collection metadata in filtered queries (off); GraphQL on or off with its limits (`/graphql/enabled`, `default-limit`, `max-limit`); SRV connection format for the bundled Mongo.

## Update, backup, trouble `[odfs]`

- **Update:** keep the `custom-values.yaml` (and any changed config files), take a **backup first**, then `helm upgrade <release> caas-<version>.tgz --values <file>`; no downtime is promised.
- **Backup:** MongoDB's own means (file copy or `mongodump`); nothing else holds data.
- **Trouble:** `kubectl get pods`, then the logs; logs only cover the running container, so a central logging system is needed after a restart. A file upload by PUT that fails with a duplicate-key error on `chunks` means orphaned chunks; the guide gives a mongo shell script to delete them.
- **Development:** use a separate namespace on a real cluster; local clusters (k3d, kind, Minikube) work but are unsupported.

## Migration from the old CaaS module (v2) `[odfs]`

CaaS Connect replaced it in July 2020. The platform stays compatible and both modules can run on one FirstSpirit server against the same platform, even in one project; URL schemes differ so data does not collide. Install and configure Connect, do the first deployment, move consumers step by step, then uninstall v2 and remove its databases or collections. HTML generated inside the JSON is not possible with Connect.

## Updating the platform: the MongoDB chain and the notices `[odfs]`

*CaaS Platform release notes* (21.4.3, 05.10.2026), read 2026-10-13: about 290 entries, 71 update notices; the fixes are not summarised. Read every notice between your version and the target.

**Do not skip the MongoDB steps.** A new MongoDB comes with a platform release that needs a minimum installed version, and the compatibility switch (`featureCompatibilityVersion`) is raised in a **later** release on purpose, so the update runs without downtime:

| Target | MongoDB | You must already run |
|---|---|---|
| 16.8.0 (04.2023) | 6.0 (compat raised) | 16.4.2 or later |
| 19.2.0 (06.2024) | 7.0 | 16.8.0 or later; the notes advise waiting for a release that sets the compat version to 7.0 |
| 19.6.0 (07.2024) | compat 7.0 | 19.2.0 or later |
| 20.2.0 (01.2025) | 8.0 (compat still 7.0) | 20.1.0 or later |
| 20.8.0 (03.2025) | compat 8.0 (triggers a replica-set reconfiguration) | 20.2.0 or later |

Check that every application reading the platform copes with the MongoDB compatibility changes, and take a backup first.

Notices that change an installation:
- **21.0.0 (04.2026):** the Helm `values.yaml` was restructured and **legacy values are no longer supported**: RESTHeart settings now sit under `restApi.applicationConfig` in the flat `/plugin/property` form (page sizes, GraphQL limits, filter-operator blacklist, binary-upload switch and the others moved there), resources under `restApi.resources` and `mongo.resources`, service settings under `restApi.service` and `mongo.service`, image settings under `image`; the chart-name override and the built-in **cert-manager / Let's Encrypt integration were removed** (use `restApi.ingress.annotations` and `restApi.ingress.tls`). Migrate `custom-values.yaml` with the table in the notes before the upgrade.
- **21.1.1 (04.2026):** restores defaults missing in 21.0.0 (with 21.0.x, documents over **2 MB are rejected with 400**). Go to 21.1.1 or later, not 21.0.x.
- **20.15.0 (02.2026):** RESTHeart 9.1.1 reduced the default **CORS headers** to the minimum; re-check front-end CORS. GraphQL index creation is now `restApi.additionalConfigOverrides./createIndexesOnGqlApps/enabled`; the older `graphQLIndexInitializer` switch is obsolete.
- **20.7.0 (03.2025):** with the REST API's horizontal pod autoscaler on, the pods **drop to one** during the rollout; the documentation says how to avoid it.
- **20.0.0 (12.2024):** collection metadata is no longer returned with filtered collection requests.
- **19.0.0 (06.2024):** the basic-auth admin user is removed; **API keys are the only authorization**.
- **18.4.0 (05.2024):** can break installations that set `restApi.tenantSubdomainCheckEnabled: true` (meant for the SaaS offering).
- **18.0.0 (02.2024):** metrics URL moved from `/_metrics` to `/_logic/metrics` when read directly (not through the ServiceMonitor).
- **17.0.0 (08.2023):** Helm 2 support removed (Helm 3 only).
- **16.3.0 (03.2023):** `credentials.caasRepoAdditions` must no longer carry escaped special characters.
- **15.4.0 (01.2023):** the `Bearer <key>` authorization header is supported; the older `apikey="<key>"` form still is. The CaaS Connect module needs this version from its 3.28.0.

## Sizing and support `[odfs]`

*Technical Data Sheet* 21.4.3, 05.10.2026 (valid for CaaS Platform 2.0 and above), read 2026-10-13.

- **Kubernetes:** reference and actively tested **1.19.6 with Helm 3**; passively supported 1.19.0 and above; **below 1.19.0 and Helm 2 are not supported**. The release notes set a higher floor: since platform **15.0.0** the Helm chart is not compatible with Kubernetes **below 1.21** unless `restApi.podDisruptionBudget.apiVersionOverride` and `mongo.podDisruptionBudget.apiVersionOverride` are set. Treat 1.21 as the floor and ask the vendor for the tested version you plan `[verify]`.
- **MongoDB storage:** at least three `mongo` pods, each with storage of **at least five times the deployed project size**, plus the transaction **journal**, which depends on write load, not project size (a 500 MB project showed 300 MB to 1500 MB). A Mongo instance that runs out of space **crashes** and can destabilise the cluster.
- **Scaling:** writes go through the single primary, so write-heavy loads need larger nodes (vertical); reads scale linearly with the number of REST API instances until the database is the limit. The measured example: one REST API instance (250 millicores, 350 MB limit) on an EC2 t2.medium handled about 350 mixed requests per second, 99 percent under 200 ms, mean 21 ms; load tests simulated up to 100 000 users.
- **Support for on-premises:** the vendor's support covers the product (bugs, compatibility), not customer-specific operating problems; a bug report needs a description, logs and reproduction steps; regular updates are recommended.
