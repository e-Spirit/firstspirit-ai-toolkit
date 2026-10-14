# Operations — running SmartSearch on-prem

For self-hosted installations; in the cloud service the provider runs this layer. Sources:
admin manual and migration guide 5.12.1, release notes, documentation chapter *Logging*
`[odfs]`, unless a line says otherwise. Paths assume the documented default `/opt/…`.

## Requirements and install order

- **Java 21, ZooKeeper 3.9, Solr 9.7 in cloud mode**, SmartSearch latest. ZooKeeper and Solr
  are not delivered; download them in these versions.
- Install in this order: **ZooKeeper → Solr → SmartSearch**. Not as root; use a technical user.
- Reference topology: two nodes, each with ZooKeeper, Solr and SmartSearch ("simple
  redundancy"); a single node is allowed when failover does not matter.

| Port | Use |
|---|---|
| 8181 | SmartSearch cockpit and REST API |
| 8983 | Solr UI and API |
| 2181 | ZooKeeper clients |
| 2888, 3888 | ZooKeeper instance traffic |

### ZooKeeper

- `conf/zoo.cfg`: `4lw.commands.whitelist=*` (from the admin manual; restrict the list in production).
- Optional separate Solr node: `zkCli.sh` → `create /solr ""`; then `ZK_HOST=host1:2181,host2:2181/solr`
  in `solr.in.sh`. The SmartSearch node is created automatically.
- Cluster: list all instances in every `zoo.cfg`; single node: omit.

### Solr

- Cloud mode against ZooKeeper (`ZK_HOST`); single node:
  `sed -i 's/#ZK_HOST=.*/ZK_HOST=localhost:2181\/solr/' /etc/default/solr.in.sh`.
- **Basic authentication is required** (Solr UI → *Security*); the credentials go into
  `application.yml`. They are stored in ZooKeeper and propagate to all Solr nodes.
- Cluster only: after the first start, add a replica (Solr UI → *Collections* → the client's
  collection → *Add replica*), and again for the `_signals` collection.

### SmartSearch server

`application.yml` next to `server.jar` (Spring Boot; any Spring Boot key applies):

| Key | Meaning |
|---|---|
| `server.port` | Default 8181 |
| `server.address` | Host name of **this** node, no protocol, no port. Needed for cockpit forwarding to the leader; without it the cockpit is unusable |
| ZooKeeper `connection` | Address of the node's ZooKeeper |
| `haupia.root` | Installation root, e.g. `/opt/smartsearch` |
| `haupia.licence.path` | License text file, e.g. `./licence/licence.txt` (license from Technical Support) |
| `solr.auth.username`, `solr.auth.password` | Solr Basic auth |
| `solr.url.scheme` | `http` or `https`; default from the Solr cluster property `urlScheme`, else `http` |
| `solr.connection.http_2` | `false` (default, HTTP/1.1) or `true` (5.0.1+) |
| `haupia.zookeeper.users.cache.await` | Seconds to wait for the user cache (default 1) |
| `haupia.connect.datagenerator.pool.size` | Max FirstSpirit projects served by SmartSearch Connect (default cores × 500) |
| `server.servlet.session.timeout` | Cockpit logout, e.g. `60s`, `1h`; default 15 min |
| `spring.main.allow-circular-references: true` | Mandatory since 4.0.0 (on-prem) |

- The **master admin** comes from `application.yml` on the first start and must be identical
  on all instances. Start with `resetAdminPassword` to reset its password to the yml value.
- `server.conf` holds `JAVA_OPTS` with the **mandatory** `-Dhaupia.master.profile=STANDALONE`,
  encoding and JVM options.
- Start the first node, wait for `Started Server in … seconds` in
  `/opt/SmartSearch/logs/SmartSearch.log`, then start the next node.
- Leader election decides which node serves the cockpit; REST works on all nodes.

### Running as a service (5.11+)

Since 5.11 (Spring Boot 4) `server.jar` is **not** self-executable: `./server.jar start|stop`,
`MODE=service …` and units calling `ExecStart=…/server.jar start` stop working. Use:

```ini
[Service]
User=haupia
WorkingDirectory=/opt/haupia
EnvironmentFile=/opt/haupia/server.conf
ExecStart=/path/to/java21/bin/java $JAVA_OPTS -jar /opt/haupia/server.jar
SuccessExitStatus=143
```

- **`WorkingDirectory=` is required**: `application.yml` and `licence.txt` are read relative to
  it; without it systemd starts in `/`.
- `EnvironmentFile=` replaces the old launch script that sourced `server.conf`. Other variables
  in `server.conf` must be referenced explicitly in `ExecStart=`.
- No `ExecStop=`/`ExecReload=` needed; SIGTERM shuts down gracefully.
- `sudo systemctl daemon-reload && sudo systemctl restart smart-search`.
- Embedded container: **Tomcat 11** (Undertow before 5.11). `server.undertow.*` tuning is
  silently ignored; use `server.tomcat.*`.
- SSL keys must be **kebab-case**: `key-store-type`, `key-alias`. camelCase (`keyStoreType`,
  `keyAlias`) is silently dropped and the connector falls back to plain HTTP.
- The admin manual's SSL chapter still speaks of Jetty; the 5.11 migration guide is current.

### HTTP(S) proxy for crawlers

`JAVA_OPTS` (or the `java` command in the systemd unit): `-Dhttp.proxyHost`, `-Dhttp.proxyPort`,
`-Dhttps.proxyHost`, `-Dhttps.proxyPort`, `-Dhttp.nonProxyHosts=localhost|127.0.0.1`.

## SSL

A self-signed certificate ships for local development only. SSL configuration may be changed,
**not removed**.

```bash
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -name server -CAfile ca.crt -caname root
```

```yaml
server:
  ssl:
    key-store: server.p12
    key-store-password: <keystore password>
    key-store-type: PKCS12
    key-alias: server
```

- Wrong keystore password → `Could not load key store …` / `BadPaddingException` at start.
- Restrict ciphers or protocols with `server.ssl.ciphers` / `server.ssl.enabled-protocols`.
- Crawling an HTTPS site with an unknown CA fails with `PKIX path building failed`: import the
  site's certificate into the JRE truststore (`keytool -import -alias … -keystore
  <jre>/lib/security/cacerts -file …`).

## Users: local, LDAP or OIDC

| Mode | Identities | Cockpit user admin | Configure |
|---|---|---|---|
| Local (default) | ZooKeeper | Yes | — |
| **LDAP** | LDAP, read-only | No (groups read-only too; permissions still in the cockpit) | `haupia.ldap.*`, `spring.ldap.*` |
| **OIDC** (5.12+) | Identity provider | No (groups and permissions still in the cockpit) | `haupia.auth.*`, `spring.security.oauth2.*` |

### LDAP

- Mandatory: `haupia.ldap.enable: true`, `spring.ldap.username` / `password` (technical user
  DN), `haupia.ldap.user-search-base`, `haupia.ldap.group-search-base` (one level, no subtrees).
- Optional with defaults: `spring.ldap.urls` (`ldap://localhost:389`), `spring.ldap.base`,
  `haupia.ldap.user-filter` (`uid={0}`), `group-filter` (`(member={0})`),
  `default-password-encoder` (`bcrypt`), `user-attributes.uid/password` (`uid`,
  `userPassword`), `user-attributes.language/default-language` (`en`),
  `group-attributes.name/user` (`cn`, `member`).
- Passwords in LDAP as `{id}hash` with id bcrypt, sha, md4, md5, noop, pbkdf2 or SHA-256.
- A master admin must exist in LDAP in the group `ADMIN`. Every admin-group member can edit
  all permissions. Group names show in upper case.
- LDAP covers authentication only, not ACLs.

### OIDC

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          keycloak:
            client-id: smartsearch
            scope: [openid, email]
            authorization-grant-type: authorization_code
            client-authentication-method: none
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"
        provider:
          keycloak:
            issuer-uri: https://<idp>/realms/smartsearch
      resourceserver:
        jwt:
          issuer-uri: https://<idp>/realms/smartsearch
haupia:
  auth:
    backend: OIDC
    oidc:
      group:
        prefix: smartsearch-
```

- `haupia.auth.oidc.group.prefix` is **required**, no default; the server does not start without it.
- Tokens need an **`email`** claim (the principal; missing → `401`) and a **`groups`** claim.
  `smartsearch-admin` → `ROLE_ADMIN` → cockpit group `ADMIN`; values with another prefix are
  ignored; a prefixed group with no cockpit counterpart grants nothing.
- The first admin is **not** seeded locally: it must exist at the provider in `<prefix>admin`.
- A user needs at least one existing cockpit group, otherwise an access-denied page.
- Issuer URI must be exact, including legacy `/auth` paths on old Keycloak.
- Tested against Keycloak; other standard providers "expected to work" but unverified by the
  vendor. Cloud (SaaS) customers ask Support to enable OIDC.
- The gateway can validate the same provider's bearer tokens (`search-api.md`); SmartSearch
  Connect then authenticates with `OAUTH` (`smartsearch-connect.md`).

## Updates

1. Unpack the new archive into an empty folder (`application.yml`, `server.conf`, `server.jar`).
2. Stop one node (cluster: one at a time).
3. Read the release notes and the migration guide; apply update notices to `application.yml`
   or `server.conf`.
4. Replace `server.jar` **and** the `shared_resources` directory; `documentation` is optional.
5. Start. If configuration or ZooKeeper/Solr structures need changes, the server exits with
   **exit code 1** and logs what is missing: fix it, then start with `java -jar server.jar update`
   (only when the notes ask for it).
6. Repeat per node. Updates never upgrade ZooKeeper or Solr.

| Target | What is special |
|---|---|
| **5.12** | OIDC opt-in; nothing changes for ZooKeeper/LDAP installations |
| **5.11** | systemd unit, Tomcat, kebab-case SSL keys (above); no data migration |
| **5.9 / 5.8** | Configuration Management API / Import-Export (`indexing.md`) |
| **5.6** | Spring Boot 3.5; malformed canonical links ignored by the crawler |
| **5.5** | Mandatory stop-over when coming from before **2.0.66** (start it once: migrates users from MySQL to ZooKeeper); gateway Basic auth |
| **5.0** | Java 21, ZooKeeper 3.9, Solr 9.7: **new environment** plus the **migration tool** (`tools/`, `migration-from.properties`, `migration-to.properties`, `java -jar migration-tool.jar`) before starting 5.0; keep the old system until verified. JSP taglib removed |
| **4.0** | Java 21 compatible; `spring.main.allow-circular-references: true` mandatory |

Older steps (Solr 8 upgrades, reindex tool, 1.9 → 2.0 with taglib and Java API) are in the
migration guide.

## Monitoring and logging

- **Prometheus:** `management.prometheus.metrics.export.enabled: true`, scrape
  `/actuator/prometheus` over HTTPS with Basic auth. Solr has its own Prometheus exporter.
- **Actuators** are on by default and need an admin user. Recommended: expose `*` but exclude
  `heapdump` (GB-sized download).
- **Log levels at runtime** (lost on restart):
  ```bash
  curl -u '<admin>' -X POST 'https://<server>:8181/actuator/loggers/de.arithnea.haupia.Server' \
    -H 'Content-Type: application/json' -d '{"configuredLevel":"DEBUG"}'   # 204 = done
  ```
  (curl prompts for the password; keep it out of the command line)
  `GET /actuator/loggers` lists all loggers (`configuredLevel` vs inherited `effectiveLevel`).
- Persistent levels in `logback-spring.xml` in the root folder (SLF4J). Logs go to `logs/`,
  rotated at 100 MB, nine archives kept.
- Useful logger: `de.arithnea.haupia.datageneration.crawler.api.reactive` (API DG and Connect
  input). The admin manual's SSL debug logger `org.eclipse.jetty.util.ssl` predates the Tomcat
  switch.

## Troubleshooting

| Symptom | Check |
|---|---|
| Cockpit unreachable on one node | `server.address` set on every node? Only the leader serves the cockpit |
| HTTPS gone after 5.11 update | camelCase SSL keys; rename to kebab-case |
| Service does not start after 5.11 | Unit still calls `./server.jar start`; missing `WorkingDirectory=` or `EnvironmentFile=` |
| Start exits with code 1 | Log lists missing adjustments; then `java -jar server.jar update` |
| OIDC: server will not start | `haupia.auth.oidc.group.prefix` missing |
| OIDC: 401 on login | Token lacks the `email` claim |
| OIDC: access denied page | User in no group that exists in the cockpit |
| Crawl fails on HTTPS | Certificate not in the JRE truststore (PKIX) |
| New data not searchable | Commit intervals (30 s Connect, minutes generic API, ≤ 15 min crawls); admin *Reload Collection* |
| Locked out of the cockpit | Restart with `resetAdminPassword` (local mode) |

## Privacy (GDPR)

The customer must check indexed content for personal data. SmartSearch itself stores user
e-mails (LDAP: user names), audit "last changed by" data (anonymised on user deletion), log
files with IP addresses and logins, and session/XSRF cookies in the cockpit.
