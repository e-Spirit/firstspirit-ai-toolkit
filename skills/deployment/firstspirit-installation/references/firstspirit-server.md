# Installing the FirstSpirit server (on-premises only)

Source: "Installation Instructions" of the FirstSpirit documentation (ODFS, 2026.11 footer), `[odfs]`, read 2026-10-09.
Pages: Introduction, Provisioning, Preparing the operating system (Linux), Installing FirstSpirit, Installing the license file,
Troubleshooting, Updating, Uninstalling, Starting applications, Quick guide for test servers.

**Scope.** On-premises only. A Cloud customer does not install, update or uninstall the server; the platform service does,
and module installs are Support requests (see `firstspirit-cloud`). Do not hand these steps to a Cloud customer.

Versions of Java, operating systems, databases and servlet engines are not restated here: the documentation sends you to
*Technical requirements and recommendations* in the Documentation for Administrators, and that page moves with each release.

## What is installed

- The FirstSpirit Server is a Java application, started by the Tanuki Java Service Wrapper (the only platform-dependent part),
  through a shell script (Unix) or a Windows service. A JDK is **not** supplied. The GNU Java of some Linux distributions cannot be used.
- Optional: an external relational database (the built-in Apache Derby is for tests only), an external web server / servlet engine
  (the embedded Tomcat and Jetty modules are for tests only, not productive).
- Clients: ContentCreator, FragmentCreator and ServerMonitoring run in the browser; SiteArchitect and ServerManager start through the FirstSpirit Launcher.
- Ports: HTTP 8000/tcp and SOCKET 1088/tcp by default. If one is taken, the installation picks a free one and writes it to `~FS/conf/fs-server.conf`
  (`HTTP_PORT`, `SOCKET_PORT`; most changes need a restart). A default installation uses Isolated Mode.

## Provisioning (what to ask Support for)

Download access comes from Technical Support. Files: the install archive `fs-install-[version].tar.gz` (the version is the backend/wrapper version,
not the server version), the update archive `fs-update-[version].tar.gz`, the server jar `fs-isolated-server-[version].jar`,
and the licence file (see `licence.md`). Blueprint and demo projects (for example the CXT Blueprint) are requested through Support too;
the FirstSpirit Experience Accelerator is offered in the Cloud only.

## Requirements for 2026.11 `[odfs]`

German page *Technical requirements and recommendations* (2026.11), read 2026-10-13; it states that FirstSpirit works with the current version of a third-party component unless said otherwise. Check the page for the version you install.

| | Recommended (reference) | Also named |
|---|---|---|
| JDK | OpenJDK **21**, Temurin / AdoptOpenJDK HotSpot recommended | Oracle JDK and other vendors' OpenJDK builds as compatible |
| Servlet engine | Apache Tomcat: **9.0.78+ up to FirstSpirit 2023.8**, **10.1.11+ from 2023.9** (Jakarta), **11.0.13+ from 2025.13** | WebSphere Application Server is named with the note that its support will be discontinued, and is also listed under *Not supported* on the same page: plan without it. The embedded Tomcat and Jetty modules are for tests only, **not supported with CXT** |
| Database (external, JDBC) | PostgreSQL **18**; the embedded Derby is for tests only | IBM DB2 (versions up to 9.4 are *not supported*), MariaDB, MySQL, Microsoft SQL Server, Oracle, PostgreSQL in other versions |
| Browser (web apps) | latest Chrome | Chrome-based browsers; Safari with limits |

## The wrapper and its configuration files `[odfs]`

*Java VM and wrapper (fs-wrapper*.conf)*, Administrators' documentation 2026.11 (German page), read 2026-10-13.

| File in `~FS/conf` | Use |
|---|---|
| `fs-wrapper-vendor.conf` | the vendor's recommended JVM options. **Do not edit**; it is replaced by the update archive. Re-define a parameter in the file below instead |
| `fs-wrapper.isolated.conf` | server-specific options for an **isolated** installation (the normal case) |
| `fs-wrapper.conf` | the same for a non-isolated installation |
| `fs-wrapper.slave.conf`, `fs-wrapper.isolated.slave.conf` | JVM options of cluster nodes |
| `fs-wrapper-j1.include.conf`, `fs-wrapper-j2.include.conf` | Java 8 and 9+ specials, obsolete after the switch to the new configuration |

- The start values are tuned for compatibility; **tune them for production** with someone who knows Java (parameters: Tanuki's wrapper property list).
- They can be changed in the ServerMonitoring (invalid keys are refused on save) or directly in the file. **Every change needs a server restart.** Order of lines does not matter; **a comment must not share a line with a value** (`wrapper.startup.timeout=30 # x` breaks it).
- The wrapper version shows in ServerMonitoring, Overview, Status, *Basic information (System)*; an outdated one is shown in red. **Replacing `fs-isolated-server.jar` does not update the wrapper**; that is the separate backend update (`fs-install` archive), with the server stopped and clients logged off.
- `fs-wrapper.log` holds what the JVM would print to the console before the logging starts, and the wrapper's own warnings.

## Preparing Linux

| Item | Rule |
|---|---|
| User | Not created automatically. Create a dedicated system user and group first; do not run as root |
| Open files | `nofile` soft and hard 10000 for that user in `/etc/security/limits.conf` or `/etc/security/limits.d/firstspirit.conf`; on Ubuntu/Debian check `session required pam_limits.so` in `/etc/pam.d/su`. Check with `su - fs -c "ulimit -a"` |
| Why | A project uses up to 200 open files, and about 4 TCP sockets per logged-in editor |
| `flock()` | The file system must offer it; check the vendor for GFS2, OCFS, VxFS, NFS |
| Locale | UTF-8, or documentation roll-out and SEO URLs with umlauts break |
| umask | `wrapper.umask` in `fs-wrapper.isolated.conf` overrides the system umask for files FirstSpirit creates |

## Install steps

1. Unpack the install archive (`tar xzf`).
2. Copy `fs-isolated-server.jar` for the wanted version into `~FS/server/lib-isolated`.
3. Point `FS_JAVA_HOME` at a JDK, or set `wrapper.java.command` in `~FS/conf/fs-wrapper.isolated.conf`.
4. Add the licence file (`licence.md`). Without one the server runs 30 minutes after each start, then warns the users and shuts down.
5. Adjust the Java VM settings (`fs-wrapper*.conf`, File system organisation in the Administrators' documentation).
6. Start the server (Unix script or Windows service). Other port: set `HTTP_PORT` / `SOCKET_PORT` in `~FS/conf/fs-server.conf` **before** the first start.

## First login

Open `http://[host]:[port]`. The documented first login as server administrator is the user name and password
`Admin` / `Admin` (capital A). Change the password straight away (area User, Change password). A "Forbidden request host" 403 means the host name used is
missing from `allowedRedirectHosts` in `fs-server.conf`.

## Starting the clients

SiteArchitect and ServerManager start through the FirstSpirit Launcher (own Java environment, configuration file `.fslnch` downloaded from the start page).
Linux is not officially supported for the Launcher. Proxy settings of the operating system are used only with `java.net.useSystemProxies=true`
(Java 11 or later). Details: Documentation for Administrators, FirstSpirit Launcher.

Installing the Launcher on workstations `[odfs]` (2026.11, German *Anwendungen starten* page, read 2026-10-13):
- The installer `FSLauncher.exe` comes from the start page (*Download FirstSpirit Launcher*). A local install needs **no administrator rights**, but the user must have write and execute rights in `%LOCALAPPDATA%\Programs\FSLauncher` (the launcher) and `~\.firstspirit\FSLauncher` (client jar, JRE, logs); without them it throws and cannot run. Deleted files are rolled out again at the next client start.
- **Group install** (for example by group policy): `FSLauncher.exe -q` (silent), optionally `-dir <folder>`. Pair it with `externalLauncherGroup` in `fs-server.conf` (connection settings for SiteArchitect and ServerManager are set centrally for the users of that external group) and activate the Launcher on the server for those groups.
- **Updates** follow the server update automatically; without write rights in the install folder the update is aborted and only logged, so an administrator must update it.
- **Behind SSO and a reverse proxy or firewall**, declare the session cookie names in `clientCookieNames` in `fs-server.conf`. If the cookies are still intercepted and the clients do not start, release the path `~/fs5root/jnlp/` in the firewall (documented as no security problem).

## Updating

Stop the server (log editors off first; maintenance mode helps), read the release notes, update. An update changes binaries and libraries, not project or user data.
Four parts are updated separately: the server, the backend (wrapper and control files), the modules (update every installed module, rebuild your own),
and the web applications (rolled out again at start by `version.txt`). A cluster group has its own procedure. Within a minor version the
server jar can be replaced on its own. Steps: Documentation for Administrators, Updating FirstSpirit.

### The three update paths and the order `[odfs]`

Administrators' documentation 2026.11 (German pages *FirstSpirit aktualisieren*, automatic, manual and module update), read 2026-10-13. Cloud customers get the server update through the vendor's patch days.

| Path | When | How |
|---|---|---|
| **Replace `fs-isolated-server.jar`** (recommended for 24/7 systems) | planned window | 1. backend current? (else the update archive first) 2. download the jar and the `.fsm` of every installed module (third-party modules from their vendor) 3. clients off (maintenance mode) 4. `~FS/bin/fs-server stop` 5. **modules first**: ServerManager, Server properties, Modules, *Install* each file, then *Update usages* (updates the project and web apps of all projects at once; the option to deactivate the web server restart is fine because modules are updated before the start) 6. put the new jar into `~FS/server/lib-isolated/` and **remove the old one: every `*.jar` there is loaded, so two versions break it** 7. `fs-server start` |
| **ServerMonitoring, local files** | no shell access | Control, Update: variant I picks a target version and *Update modules* (all vendor standard modules); variant II uploads the jar and module files from your machine; then *Start server update*. Can be switched off with `update.pull.enabled` / `update.push.enabled` in `fs-server.conf` |
| **Update service job** | dev or QA that should follow along; needs internet | a job with the action *Server update*. **Default on a new server: it only e-mails the administrators that a version exists** (weekly check); to update, switch off *Notify only*. The restart time is not exactly plannable, so not for tight windows |

The **first start after an update takes longer**: web apps are rolled out again (by `version.txt`). Start order is by run level: core (40), global web apps (60, 80; the root web app up means limited use), project-local and remaining web apps (100, full use). After updating a module that other modules depend on through a **service**, restart those services by hand or they fail. A module that supplies data is unavailable to running processes (generations, clients) until they restart. Modules that connect to the server (for example partner modules) can break on update: ask the module's support first.

## Uninstalling

Remove the system service (`~FS/bin/fs-server remove`, needs administrator rights), optionally remove the system user and group, delete the installation directory.

## Troubleshooting

Logs `~FS/log/fs-server.log` and `fs-wrapper.log`; only `fs-wrapper.log` is written when the JVM cannot start.
"ulimit -n with 1024 too low" means the `nofile` limit above. Login or start page not reachable: check whether the HTTP port is taken.

## Quick guide for a test server (Windows, macOS, Linux) `[odfs]`

German pages under the same installation guide, 2026.11, read 2026-10-13. For demo and test only, not for production or a publicly reachable server.

| # | Step | Check |
|---|---|---|
| 0 | Files from the vendor: `fs-install-<version>.tar.gz` (the version is the **backend's**, not FirstSpirit's), `fs-isolated-server.jar`, the licence file. A JDK: **OpenJDK 21** (Temurin recommended), as on the 2026.11 requirements page; the requirements page sets the version | |
| 1 | Unpack the archive; the folder `firstspirit5` can be renamed and moved, but neither its name nor the path may contain a **space**. That path is `~FS` | |
| 2 | Copy the server jar into `~FS/server/lib-isolated/` | |
| 3 | Copy the licence file into `~FS/conf/` | |
| 4 | Java: `wrapper.java.command=` in `~FS/conf/fs-wrapper.isolated.conf` (full path to the `java` executable) or the environment variable `FS_JAVA_HOME` | |
| 5 | `~FS/bin`: `fs-server installstart` installs and starts the service; without a service, `fs-server console` (Windows, stop with Ctrl-C) or `fs-server start` / `stop` (Linux, macOS). The first start rolls out the files and web apps and takes a while | new folders appear under `~FS` |
| 6 | Browser, **`http://localhost:8000`, not https**; first login as in *First login*; then change the password | the start page |

Problems the guide lists:
- **Windows: "The service already exists (0x431)"**: another instance is installed. Change `wrapper.ntservice.name` in `fs-wrapper.isolated.conf` (for example `FirstSpiritServer5_Instance2`), then `installstart` again. Never rename the service after install without `fs-server remove` first.
- **Not reachable after install:** wait, then read `~FS/log/fs-wrapper.log` for the line `setup ports`. If port 8000 was taken, the installer picked others and **saved them in `~FS/conf/fs-server.conf`**, so they stay even when 8000 is free again; edit the file to change them.
- **An `.fslnch` file downloads and will not open:** the FirstSpirit Launcher is not installed on the workstation; use the download link on the start page. The option to use the Launcher is switched on after install.

The licence file is `fs-license.conf` (`licence.md`).

## Backup, in one table `[odfs]`

Overview page *Backing up and restoring the FirstSpirit server* (2026.11), read 2026-10-13. The steps of each method: Documentation for Administrators.

| Method | Scope | Running server |
|---|---|---|
| Project backup, a standard project action in the job scheduling | one project | yes |
| Full backup through the file system | all projects | **no**, the server must be stopped |
| *FirstSpirit EnterpriseBackup* module | further strategies | licence-dependent |

Choose by: the data loss you can accept (sets the interval), the load on CPU, storage and network, and the downtime you can accept, per project.

## Not covered here

Windows specifics, cluster groups, backup procedures, security hardening: Documentation for Administrators.
