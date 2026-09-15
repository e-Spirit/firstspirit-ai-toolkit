# fs-cli setup — install, Access API jar, JRE

Gate 1: **fs-cli can start.** Three things have to line up — the tool, the
FirstSpirit Access API jar, and a compatible Java runtime with the right flags.

## 1. Install fsdevtools

FS-CLI is the open-source **fsdevtools** tool, released by e-Spirit/Crownpeak on
GitHub. It is a Java application distributed as a `.tar.gz` / `.zip` with a
`bin/fs-cli.sh` (and `bin/fs-cli.cmd` on Windows).

```bash
# latest release metadata
curl -sS https://api.github.com/repos/e-Spirit/fsdevtools/releases/latest \
  | grep -E '"(tag_name|browser_download_url)"'

# download + extract (adjust the version)
curl -sSL -o fs-cli.tar.gz \
  https://github.com/e-Spirit/FSDevTools/releases/download/<VERSION>/fs-cli-<VERSION>.tar.gz
mkdir -p fsdevtools && tar -xzf fs-cli.tar.gz -C fsdevtools
```

The extracted `fs-cli/lib/` contains only `fsdevtools-cli-<VERSION>.jar`. The
classpath is `lib/*`, so **adding a jar to `lib/` is how you supply the API**
(next step).

> Verified with **fsdevtools 4.8.9** (2026-08). The tool's own "Build for
> FirstSpirit version" line (e.g. `5.2.231105`) is the version it was compiled
> against, **not** the version you must connect to — the Access API jar governs
> that.

## 2. Supply the FirstSpirit Access API jar (the part that isn't bundled)

fsdevtools ships **without** FirstSpirit classes for licensing reasons. On first
run it reports:

```
ERROR Couldn't find FirstSpirit classes - have you placed your FirstSpirit
api jar (fs-isolated-runtime) into the fs-cli lib folder?
```

Put a FirstSpirit Access API jar into `fs-cli/lib/`:

- **Canonical:** `fs-isolated-runtime.jar` for the target server version. On a
  self-hosted server it lives under the server's `data/fslib/`; it is also a
  published Maven artifact (`de.espirit.firstspirit:fs-isolated-runtime`). On a
  **Cloud** instance you cannot reach the server file system — obtain the jar
  matching the Cloud build from Maven/Support.
- **What worked in practice:** the **`fs-isolated-client-*.jar`** from a
  FirstSpirit SiteArchitect/FSLauncher install of the **same build** as the
  server. On macOS the FSLauncher keeps version-stamped isolated jars, e.g.
  `~/.firstspirit/FSLauncher/jar/<build>_isolated/fs-isolated-client-*.jar`.
  Copied into `lib/`, fs-cli started and connected and exported successfully.
  *(Whether `fs-isolated-client` is fully equivalent to `fs-isolated-runtime`
  for every fs-cli command is an open verification item.
  For `export` it works.)*

**Match the version.** The jar must match the server's build. Confirm the
server build first (any of): the SiteArchitect/ContentCreator "about" dialog,
the FSLauncher's stamped jar directory name, or fs-cli's own
`INFO Connected to FirstSpirit server … of version <build>` once it connects.
The example instance reported `5.2.260815`, so the `5.2.260815` isolated jar was
used. A mismatched-version jar is the second most common startup failure after a
missing one.

fs-cli confirms which jar it loaded:

```
INFO Using FirstSpirit Access API version 5.2.260815.… (fs-isolated-client-….jar)
```

## 3. Run on a compatible JRE — and force the VM flags

Two related traps, both from the launcher script.

### 3a. Java version must be ≥ the jar's compiled version

Recent FirstSpirit builds are compiled for **Java 21** (class file major version
**65**). Running on Java 17 (major 61) fails immediately:

```
java.lang.UnsupportedClassVersionError: de/espirit/firstspirit/logging/ServiceProvider
has been compiled by a more recent version of the Java Runtime (class file version 65.0),
this version of the Java Runtime only recognizes class file versions up to 61.0
```

Use a JDK/JRE whose major version is at least the jar's. A FirstSpirit client
install already bundles a matching runtime — on macOS,
`~/.firstspirit/FSLauncher/jre/<ver>/jre-mac-arm/<jdk>/Contents/Home` (or
`jre-mac` on Intel). Point `JAVA_HOME` at it. The bundled version moves with the
server line: 5.2.2608xx launchers shipped Java 21, the 5.2.2610xx launcher ships
**Java 25** (`jre/25.0.3/`) — newer is fine, it only adds the benign warnings listed in
`troubleshooting.md`.

### 3b. The launcher's `--add-opens` flags get silently dropped on a JRE

`bin/fs-cli.sh` decides whether to add JPMS `--add-opens` flags by shelling out
to **`javap`**:

```sh
BYTECODE_VERSION=$("${JAVA_HOME}"/bin/javap -verbose java.lang.Object | grep major | cut -d " " -f5)
if [ "${BYTECODE_VERSION}" -gt 52 ]; then
  VM_ARGS="--add-opens=java.base/sun.reflect.annotation=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED"
fi
```

A **JRE has no `javap`**, so the command errors, `BYTECODE_VERSION` is empty, the
`-gt` test fails, and `VM_ARGS` stays unset. fs-cli then starts on a modern JVM
*without* the flags and dies during command initialisation:

```
java.lang.reflect.InaccessibleObjectException: Unable to make field ...
sun.reflect.annotation.AnnotationInvocationHandler.memberValues accessible:
module java.base does not "opens sun.reflect.annotation" to unnamed module
```

Two fixes:

- **Use a full JDK 21** (has `javap`) as `JAVA_HOME` → the script adds the flags
  itself. Simplest when a JDK is available.
- **Invoke java directly with the flags**, bypassing the script's check — what
  the `scripts/fs-cli-export.sh` wrapper does, so it works on a bundled JRE:

  ```sh
  "$JAVA_HOME/bin/java" \
    --add-opens=java.base/sun.reflect.annotation=ALL-UNNAMED \
    --add-opens=java.base/java.util=ALL-UNNAMED \
    --add-opens=java.base/java.lang=ALL-UNNAMED \
    -Dlog4j.configurationFile="$FS_CLI_DIR/conf/log4j2.xml" \
    -cp "$FS_CLI_DIR/lib/*" com.espirit.moddev.cli.Main "$@"
  ```

## 4. Verify

With jar and JRE in place, a no-connection command must run clean:

```bash
JAVA_HOME=<jdk-or-jre-21> fs-cli/bin/fs-cli.sh --version
JAVA_HOME=<jdk-or-jre-21> fs-cli/bin/fs-cli.sh help export
```

Expected: version banner + `INFO Using FirstSpirit Access API version <build>`
and no `UnsupportedClassVersionError` / `InaccessibleObjectException`. Now move
to `connection-and-auth.md`.

---
*Sources: the official e-Spirit/FSDevTools GitHub releases; a verified fs-cli
4.8.9 setup against a FirstSpirit 5.2.260815 Cloud instance (2026-08-03).*
