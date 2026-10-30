# SmartSearch (server) and SmartSearch Connect

Sources `[odfs]`, read 2026-10-13: *SmartSearch Admin Manual* 5.13.0 (05.10.2026), *Migration Guide* 5.13.0, *Release Notes* (5.13.0 first), *SmartSearch Connect Server Administrator* 1.15.2 (02.10.2026), *SmartSearch Connect* module documentation 1.15.2, the smartsearch.js developer page.
`firstspirit-smartsearch` owns the detail (5.12.x); its `firstspirit-smartsearch/references/operations.md` (server) and `firstspirit-smartsearch/references/smartsearch-connect.md` (module) have the full parameter tables. This page gives the order, and what is **new in 5.13**.

## Cloud or on-prem

Running the SmartSearch server (ZooKeeper, Solr, the application) is **on-prem**; in the cloud service the provider runs it. The FirstSpirit-side steps (module, service, project app) are the customer's on both; the service endpoint differs `[odfs]`.

## Requirements `[odfs]`

Java 21; ZooKeeper 3.9; Solr 9.7 in cloud mode (ZooKeeper and Solr are **not** in the delivery); the SmartSearch server in the current version; a SmartSearch licence file from Technical Support. Ports: 8181 (cockpit and REST), 8983 (Solr), 2181, 2888, 3888 (ZooKeeper). For FirstSpirit: SmartSearch Connect module `smartsearch-connect-<version>.fsm`; it works only with projects that do not use fragments.

## Steps, in order `[odfs]`

| # | Step | Where | Check |
|---|---|---|---|
| 1 | Install **ZooKeeper** (at least two instances for redundancy; `4lw.commands.whitelist=*`) | server hosts | `zkCli.sh` answers |
| 2 | Install **Solr** in cloud mode against ZooKeeper (at least two instances); enable **basic authentication** and keep the credentials | `solr.in.sh` | dashboard on 8983 asks for a login |
| 3 | Install **SmartSearch** on each node (not as root): edit `application.yml` (`server.address` = this node's host name, ZooKeeper connection, `haupia.root`, Solr credentials, a real SSL certificate for production, licence path); start the first node with `java -jar server.jar`, start the second only after the log shows *Started Server in …* | `/opt/...` | cockpit on 8181 (reached via the leader) |
| 4 | Since **5.11**: no `./server.jar start`; run it as a **systemd** unit with `WorkingDirectory=`, `EnvironmentFile=…/server.conf` and `ExecStart=java $JAVA_OPTS -jar server.jar` (`-Dhaupia.master.profile=STANDALONE` stays in `server.conf`) | systemd | `systemctl restart` works |
| 5 | FirstSpirit: install `smartsearch-connect-*.fsm` (ServerManager, Server Properties, Modules) | | module listed |
| 6 | Configure the **SmartSearch ConnectConfigurationService**: endpoint URL **with port**; *Authentication* `BASIC` (default; a SmartSearch user with the rights to create data generators and prepared searches) or `OAUTH` (client credentials: token endpoint, client id, secret; the identity-provider client needs a service account with an e-mail address in the right group). *Ignore missing SSL certificate* is for tests only. The service restarts itself after a change | the service's dialog | |
| 7 | Per project: add the project component *SmartSearch Connect ProjectApp*; set the **URL creator** (the one the site generation uses); press **Initialize in SmartSearch!** | Project components | the response dialog shows no error: that is the connection test; the data generator `FS_<project>` and a prepared search appear |
| 8 | First fill: a job with the action **SmartSearch Connect push** (full generation); for partial generation add the executable `com.espirit.smartsearch.initialdeployment.PushPreviousGenerationExecutable` as a script action after it | Job administration | documents in the index; data arrives after about 30 s |

Plus `[odfs]`:
- Eventing sends changes after **release**; dependent objects must be released with them, which is what BasicWorkflows' release workflow does (`basicworkflows.md`).
- Several FirstSpirit projects need `haupia.connect.datagenerator.pool.size` at least as large as the project count, or data is not received.
- Do **not rename** a project or give it a name with spaces: the data generator and prepared search names follow it.
- Files (PDF, DOCX) are fetched by SmartSearch from their URL: they must be reachable; re-run a full generation regularly.

## Updates and what changed lately `[odfs]`

- General update: unpack the new archive, read the release notes first, replace `server.jar` and `shared_resources` on a stopped node, start with `java -jar server.jar update`; ZooKeeper and Solr are **never** upgraded by it.
- **5.11:** Spring Boot 4, Tomcat 11 replaces Undertow, systemd required, SSL keys in kebab-case (`key-store-type`, `key-alias`): the camelCase forms are no longer read, the keystore is not loaded and the connector falls back to plain HTTP (Migration Guide).
- **5.12:** optional **OIDC** login (`haupia.auth.backend: OIDC`, required group prefix, an admin group at the provider before first use); off by default.
- **5.13 (05.10.2026):** search and autocomplete can be sent as **POST** with form-encoded parameters (gateway and server REST), for very long filter lists; Spring Boot 4.1.1.
- Coming from before 2.0.66: install 5.5.0 once first (migrates users from MySQL). 5.0.0 needs a **new environment** and the migration tool.
