---
name: firstspirit-verify-api-contracts
description: >-
  How to find out what a FirstSpirit API actually returns, by measuring it
  against a running server instead of recalling it: reading signatures out of
  the API jar with `javap`, letting the compiler reject your assumptions,
  connecting the Access API from inside the server's container, and running
  BeanShell in the server JVM through a throwaway schedule task. Use this skill
  before writing a module or a script against an API you have not verified — for
  example "what does `ServerEnvironment.getDataDir()` hand back", "which
  services can a connection reach and as which user", "is this method on the
  interface or only on the implementation", or "why did my probe report success
  without running". Covers the four routes and what each one can and cannot
  prove, the traps that make a probe pass silently while doing nothing, and the
  sandbox boundary that decides when only a deployed module will answer.
---

# Verifying FirstSpirit API contracts against a running server

Use this before you write a module, not after it fails. It applies whenever a
design decision depends on what the API returns rather than on what its name
suggests: an unfamiliar signature, an interface whose implementation you need,
a service you assume is reachable, or a half-remembered method steering the
design.

The point is to replace recall with measurement. Everything below was measured
on FirstSpirit 5.2.260911 (isolated, Tomcat, Java 21). The mechanisms are
version-independent; the exact signatures are not.

For the script language itself — context objects, logging, lock/save/unlock —
use `firstspirit-scripting`. For which interface a store element has, use
`firstspirit-api-reference`. This skill is about proving what the server does,
not about looking up what it should do.

## Pick the cheapest route that can answer the question

Three of the four cannot settle a question about server internals. Choosing
wrong costs an afternoon before it tells you so.

| Route | Proves | Cannot prove |
|---|---|---|
| `javap` against the API jar | Signatures, return types, constants, enum members | Runtime behaviour, which implementation you get |
| Compile a probe against the jar | The same, mechanically, at build time | Anything off your classpath |
| Access API from a JVM that reaches the server | Live values, reachable services, effective user | Anything the public API does not expose |
| BeanShell in a schedule task | Live values *inside* the server JVM | Server internals — a signature check refuses them |

## Route 1 — read the contract out of the jar

Fastest correct answer, and it needs no server.

```bash
JAR=~/.firstspirit/FSLauncher/jar/<version>_isolated/fs-isolated-client-*.jar
javap -cp "$JAR" de.espirit.firstspirit.access.Connection
javap -cp "$JAR" 'de.espirit.firstspirit.access.schedule.ScriptTask$Type'
```

Quote inner classes so the shell does not eat the `$`. Add `-p` for private
members, `-c` to disassemble a body when you need to see which implementation a
getter reaches for.

Server-side interfaces live in the server jar, not the client one. Copy it out
first — the server container may have no `unzip`, and an in-container scan then
produces empty output that reads like a negative result:

```bash
docker cp <container>:/opt/firstspirit5/server/lib-isolated/fs-isolated-server-*.jar ./fs-server.jar
javap -p -cp ./fs-server.jar de.espirit.firstspirit.module.ServerEnvironmentImpl
```

When `javap` reports `class not found` for a class you saw named in the server
log, it is loaded from elsewhere and this route has run out.

## Route 2 — let the compiler reject your assumptions

Write the calls you intend to make, compile them against the real jar, read the
errors. Highest value per minute of anything here, because it fails on exactly
the assumptions you did not know you were making.

```bash
javac -cp "$JAR" -d out Probe.java
```

Treat each error as a finding and write it down. A probe of half a dozen calls
typically catches several: a method that is not on the interface you assumed, a
service not reachable the way you expected, a mutator named unlike its accessor.

## Route 3 — talk to the live server

### Find the ports instead of guessing them

Published container ports are not service ports. Read the server's own config:

```bash
docker exec <container> grep -E "^(HTTP_PORT|SOCKET_PORT)" \
  /opt/firstspirit5/conf/fs-server.conf
```

A port published as `4711` is commonly the **JDWP debug port**, not a
FirstSpirit service. Pointing the Access API at it fails with a handshake
timeout, which reads like a protocol problem and is not one. Confirm what is
really listening:

```bash
docker exec <container> sh -c 'netstat -tln 2>/dev/null || cat /proc/net/tcp'
```

If the socket port is not published to your host, run the probe **inside** the
container rather than publishing it. The container has a JVM:

```bash
docker cp "$JAR" <container>:/tmp/probe/client.jar
docker cp out/Probe.class <container>:/tmp/probe/
docker exec <container> sh -c 'cd /tmp/probe && java -cp client.jar:. Probe'
```

### Reach services through the right broker

Not every service is reachable by class from the connection.
`connection.getService(ScheduleStorage.class)` throws
`ServiceNotFoundException`; the schedule storage hangs off the admin service:

```java
ScheduleStorage storage = connection
    .getService(AdminService.class)
    .getScheduleStorage();
```

When a service is not found, look for an owning service before concluding it is
unavailable.

### If a module exposes an HTTP API, get its real shape from the log

Take the port and the endpoint list from the startup log, not from
documentation:

```bash
docker exec <container> sh -c \
  'grep -a "Registering endpoint" /opt/firstspirit5/log/fs-server.log' \
  | sed -E 's/.*endpoint \{ (.*) \}.*/\1/' | sort -u
```

Check which port it bound (often not the one the reverse proxy serves), whether
it demands authentication, and whether your expected paths exist. An API of this
kind is typically read-only server administration — version, run level, module
inventory, user lookups. **It will not execute code**, so it cannot answer a
question about a return type.

Beware the reverse proxy: a path such as `/rest` on the public host may be
rewritten to something unrelated to FirstSpirit and answer `200` while proving
nothing. Read the live rules before trusting a reachability check.

## Route 4 — run code inside the server JVM

A BeanShell script in a schedule task runs in the server's own JVM, needs no
module, no deployment and no restart, and can be created, executed, read back
and deleted from one command-line program.

```java
ScheduleStorage storage = connection
    .getService(AdminService.class).getScheduleStorage();
ScheduleEntry entry = storage.createScheduleEntry("probe-" + System.currentTimeMillis());
entry.lock();
ScriptTask task = entry.createTask(ScriptTask.class);
task.setName("probe");
task.setType(ScriptTask.Type.FIRSTspirit);   // BeanShell
task.setActive(true);
task.setSource(scriptSource);
task.setUseSystemConnection();
entry.addUnifiedTask(task);                  // required — see below
entry.setActive(true);
entry.save();
entry.unlock();

ScheduleEntryControl control = entry.execute();
control.awaitTermination();
```

### Four traps that make a probe pass while doing nothing

Each produces a **silent** false pass: the entry reports `SUCCESS` and your
script never ran.

1. **`createTask` does not attach the task.** You must also call
   `addUnifiedTask(task)`. Without it `entry.getTasks()` is empty and the run
   succeeds having done nothing. Assert `entry.getTasks().size() == 1` before
   executing.
2. **The task needs `setActive(true)` and an explicit `setType`.** An inactive
   task is skipped, again silently.
3. **A sub-second duration in the entry log means nothing ran.** Read it as a
   sanity check.
4. **`Lockable` is `lock()` / `unlock()` / `save()`.** There is no
   `setLock(boolean)`.

### The error text is not where you expect

The entry log reports only a count (`1 error(s)`). The exception, with the
offending line of script, is on the **task result**:

```java
for (TaskResult r : control.getState().getTaskResults()) {
    try (InputStream in = r.getLogfile()) {
        System.out.println(new String(in.readAllBytes()));
    }
}
```

Do this from the first attempt. Without it a failing probe is indistinguishable
from a passing one.

### Getting values back out

`context.logInfo(...)` does not reliably reach the retrievable log. Write to a
file and read it afterwards. The server JVM runs as a non-root user, so a
directory created by `docker exec` as root is not writable by it; the failure
surfaces as `FileNotFoundException: … (Permission denied)` inside the task log.

Wrap the script body in `try { … } catch (Throwable t) { … }` and record the
exception into the same file.

### The boundary that decides your approach

Scripts run under a signature-checking engine. Measured, in one script:

| Attempted from a script | Result |
|---|---|
| Public Access API (`connection.getService(AdminService.class)`) | Allowed |
| Documented context methods (`context.getConfigDir()`) | Allowed — real `java.io.File` |
| Plain JDK classes, including file I/O | Allowed |
| `Class.forName` on a server-internal class | Allowed |
| **Invoking** a method on a server-internal object | **Blocked** |

```
java.lang.SecurityException: Access denied to
de.espirit.firstspirit.server.io.AbstractServerConnection!
Class bsh.Reflect has missing or invalid signature!
```

Loading the class is permitted; calling into it is not. Two consequences:

- **"What does this internal implementation hand back?" is not answerable by
  script.** Build a minimal module that logs the answer and deploy it once.
  Accept this rather than working around it — the workaround does not exist,
  because BeanShell routes every invocation through its own reflection class.
- **A question about your module's own bundled dependency is also not
  answerable by script**, because a script sees the server classloader, not your
  module's. `Class.forName` on a driver you intend to ship returns
  `ClassNotFoundException` from a script even when the module would resolve it
  correctly. That is not evidence of a packaging fault.

### Clean up, always

A probe that leaves schedule entries behind has changed the server it was meant
only to observe. Delete them in the same program and verify:

```java
for (ScheduleEntry e : storage.getScheduleEntries(true)) {
    if (e.getName().startsWith("probe-")) { e.lock(); e.delete(); e.save(); }
}
```

Pass `true` to include inactive entries, then list again and assert nothing
matching remains. Remove any scratch directory you created in the container.

## Read the server log for design constraints

Module resource conflicts are reported explicitly at startup:

```bash
docker exec <container> sh -c \
  'grep -a "ModuleResourceIssue" /opt/firstspirit5/log/fs-server.log' | tail
```

A resource another module declares with `scope="server"` is flagged against
every module declaring its own copy with `scope="module"`. Read these before
choosing dependency versions — they tell you which libraries are already
contested on the servers you will be installed on.

A line such as `ConfigurationService is currently unavailable` means a module is
installed but not functioning. Installed is not running, and running is not
configured.

## Order of work

1. `javap` the signature. If that answers it, stop.
2. Compile a probe. Fix what the compiler rejects; record each rejection.
3. Run it against the live server — inside the container if the port is not
   published.
4. For a live value the public API exposes, use a schedule-task script, with
   task-result logging and cleanup from the first attempt.
5. For server internals or your own bundled dependencies, stop and record the
   finding as one that requires a deployed module. Do not report it as answered.
6. Write every measured contract into the project's notes with the server
   version you measured it on. A signature is a fact about a version.

---

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
