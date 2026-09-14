# Troubleshooting — failure → fix

Every row below is a message observed on a real run, with the cause and fix.
They are ordered by the gate they occur at (startup → connect → auth → export),
so the first one you hit tells you how far you got.

## Startup (gate 1)

### `Couldn't find FirstSpirit classes … fs-isolated-runtime`
```
ERROR Couldn't find FirstSpirit classes - have you placed your FirstSpirit
api jar (fs-isolated-runtime) into the fs-cli lib folder?
```
**Cause:** no FirstSpirit Access API jar in `fs-cli/lib/` (fsdevtools ships
without it). **Fix:** add a version-matched `fs-isolated-runtime.jar` (or the
`fs-isolated-client-*.jar` from a matching client install) to `lib/`.
→ `fs-cli-setup.md` §2.

### `UnsupportedClassVersionError … class file version 65.0 … up to 61.0`
**Cause:** the Access API jar is compiled for Java 21 (major 65) but you're on
Java 17 (major 61). **Fix:** run under a JDK/JRE ≥ 21; point `JAVA_HOME` at it
(a FirstSpirit client bundles a matching JRE). → `fs-cli-setup.md` §3a.

### `InaccessibleObjectException … does not "opens sun.reflect.annotation"`
```
java.lang.reflect.InaccessibleObjectException: Unable to make field ...
AnnotationInvocationHandler.memberValues accessible ...
```
**Cause:** the JPMS `--add-opens` flags weren't applied. `bin/fs-cli.sh` computes
whether to add them via `javap`, which is absent on a **JRE**, so the flags are
silently skipped. **Fix:** use a full **JDK** (has `javap`) so the script adds
them, or invoke `java` directly with the flags (the `scripts/fs-cli-export.sh`
wrapper does this). → `fs-cli-setup.md` §3b.

### `line 11: …/javap: No such file or directory` (warning, not fatal by itself)
Same root cause as above — the launcher's `javap` probe on a JRE. Harmless on
its own, but it's the tell that the `--add-opens` flags got dropped; expect the
`InaccessibleObjectException` next. Fix as above.

### Benign JVM warnings on Java 24+ (bundled JRE 25 with 5.2.2610xx launchers)
```
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called … classgraph …
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by com.github.luben.zstd.util.Native$2 …
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
```
Printed at startup and after connecting; the run continues and exports normally. Not
errors — ignore, or add `--enable-native-access=ALL-UNNAMED` to the `java` call to silence
the second group. *(Observed 2026-09-14, fs-cli 4.8.9 on the launcher's JRE 25.0.3.)*

## Connect (gate 2)

### `Unexpected HTTP state: (400) … server=awselb/2.0 … http://<host>:443/…`
**Cause:** connecting with `-c HTTP` (plaintext) to a TLS-only front-end — the
AWS load balancer rejects it before FirstSpirit sees it. Typical of a Cloud
instance. **Fix:** use `-c HTTPS`. → `connection-and-auth.md`.

### Websocket handshake fails / connection "not successful"
```
WebSocketHandshakeException … Connection with 'WebsocketFSHttpClient(ws://…:443/…)' not successful
```
**Cause:** wrong scheme/port for the endpoint (e.g. `ws://` on a `wss://`-only
host, or the wrong port). **Fix:** for Cloud use `-c HTTPS -port 443`; for a
self-hosted socket server use `-c SOCKET` with its socket port.
→ `connection-and-auth.md`.

### `Wrong client build number <client>, must be at least <server>!` *after* "successfully connected"
```
INFO  FSHttpClient 'WebsocketFSHttpClient(wss://<host>/websocket/ClientIO/…)' successfully connected.
ERROR Wrong client build number 260911, must be at least 261011! Client-Version: 5.2.260911, Server-Version: 5.2.261011.…
de.espirit.firstspirit.common.ConnectError … Caused by: de.espirit.firstspirit.access.store.VersionMismatchException
```
**Cause:** the Access API jar in `lib/` is **older than the server build** — the websocket
channel connects, then the server's version check refuses the client before authentication.
The message tells you both builds. **Fix:** put the jar of the server's build (or newer) into
`lib/` — on macOS the FSLauncher keeps one per build it has ever connected to,
`~/.firstspirit/FSLauncher/jar/<build>_isolated/fs-isolated-client-*.jar`; the `test` command
then reports `Connected to FirstSpirit server … of version <build>`. Keep exactly one API jar
in `lib/`. → `fs-cli-setup.md` §2. *(Reproduced 2026-09-14: server 5.2.261011 rejected the
5.2.260911 client jar; the 5.2.261011 jar connected.)*

## Authenticate (gate 3)

### `couldn't authenticate!` *after* "successfully connected"
```
INFO  FSHttpClient 'WebsocketFSHttpClient(wss://…)' successfully connected.
ERROR couldn't authenticate!  (AuthenticationException)
```
**Cause:** transport is fine; the **credentials** are wrong, expired, or still
placeholder values. A tell: the config echo shows `User: <the placeholder you
pasted>`. **Fix:** put the real login/password in the creds file; confirm the
account is valid for *this* instance's realm. → `connection-and-auth.md`.

## Export (gate 4)

### Foreground run is killed at ~2 minutes (exit 143 / SIGTERM)
**Cause:** a whole-project export takes much longer than a short foreground
timeout. Not an fs-cli error. **Fix:** run it in the background or with a long
timeout and poll the log / the growing sync dir; check the final
`== SUMMARY ==` and exit code. → `export-command.md`.

### `WARN Error parsing export files in directory '/…' - content files not found`
**Not an error.** fs-cli inspects the target directory before writing; on an
empty/partial destination there's nothing to parse yet. Safe to ignore.
→ `export-command.md`.

### Files unexpectedly deleted from the sync directory
**Cause:** default mirroring — `deleteObsoleteFiles=true` removes files for
elements not in this export. **Fix:** export the full intended set in one run,
use `--keepObsoleteFiles` if you're layering exports, and never point `-sd` at a
directory with unrelated content. → `export-command.md`.

### `[ExternalSync - Export] failed: Entity <table> [<id>] has no gid`
```
de.espirit.firstspirit.store.access.nexport.exceptions.SyncOperationException:
[ExternalSync - Export] failed: Entity translation [9409] has no gid.
```
**This is working as intended, not a defect.** External sync exists to be
**re-imported** (into the same or another project), and import must map each
exported entity back onto the right row by a **stable, cross-project identifier
— the GID**. The older `fs_id` is assigned per project and is *not* stable
across projects, so it cannot serve as the mapping key. An entity **without a
GID therefore cannot be round-tripped**, and external sync correctly refuses to
export it rather than write something that can't be re-imported. **A single
GID-less row aborts the whole export**, so a broad `entities:` batch fails
entirely even though most data sources are fine, and any data source whose query
includes that row fails while others sharing the same table succeed.
**What to do:**
- **Export the healthy data sources and skip the blocked ones.** Run each
  `entities:<uid>` **individually** (with `--keepObsoleteFiles` so they
  accumulate in one dir) to isolate which sources hit the GID-less row; keep the
  successes. This gets you everything that is legitimately exportable, without
  changing the project.
- **If the blocked rows genuinely need to be in a re-importable export, give
  them GIDs first.** That means the entities acquire a stable id on the server
  (re-saving them assigns one) — after which they export normally. This
  **modifies the source project**, so confirm before doing it; it is the
  intended remedy, not a workaround.
- **Only reading the content (not round-tripping)?** Read those datasets over
  the FirstSpirit REST API instead — it returns dataset content and does not
  require a GID, because it isn't producing a re-importable artifact. See
  `firstspirit-rest-api`.
Do **not** silently drop the blocked sources — report exactly which data
sources and which row id were affected, and which of the above applies.

### Project opens over `test` but export finds nothing / wrong state
**Cause:** exporting the wrong revision state, or too narrow an identifier set.
**Fix:** decide `--useReleaseState` vs. current deliberately; widen the
identifiers (a "whole project" is an explicit list). → `export-command.md`.

---
*Every message here was reproduced on fs-cli 4.8.9 against a FirstSpirit
5.2.260815 Cloud instance (2026-08-03); the client-build-number and Java 25
entries against a second, 5.2.261011 Cloud instance (2026-09-14). See `SOURCES.md`.*
