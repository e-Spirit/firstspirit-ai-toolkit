# Logging and debugging

## Log through `context`, not `print()`

`print()` writes to the BeanShell console — or, outside the console, to standard out — never
to the FirstSpirit script log (over REST `/execute` it does not show up in the response; live
2026-10-09). Fine while exploring, wrong in a finished script. In production, use the
context's four log levels so output lands in the FirstSpirit log files and can be
filtered/switched on demand.

| Level | Method | Use for |
| --- | --- | --- |
| DEBUG | `context.logDebug(msg)` | Troubleshooting detail (off by default) |
| INFO | `context.logInfo(msg)` | General progress information |
| WARN | `context.logWarning(msg)` | Critical warning, script can continue |
| ERROR | `context.logError(msg)` / `context.logError(msg, throwable)` | Fatal error |

```
//!BeanShell
context.logInfo("Starting import");
context.logDebug("Resolved element: " + context.getElement());
try {
    // ...
} catch (Exception e) {
    context.logError("Import failed", e);   // pass the Throwable — keeps the stack trace
}
```

> The log methods live on the script `context` (see
> [script-contexts.md](script-contexts.md)). In a generation script the same
> `GenerationContext` is bound as `gc` *and* as `context` `[core]`, so `gc.logInfo(...)` and
> `context.logInfo(...)` are the same call.

## Extended logging (SiteArchitect)

Editors/developers can switch **extended logging** on in SiteArchitect
(*Extras* menu). While active, `logDebug` output becomes visible — the reason to
route debug detail through `logDebug` rather than `print()`: you can turn it on to
trace a problem, then off again without touching the script.

## Debugging workflow

1. **Prototype in the BeanShell console** (if the *Developer-Scripts* package is imported
   into the project: context menu → *DeveloperScripts → BeanShellConsole*) against a real
   node. A live `context`, the commands `print` and `javap`, and plain reflection
   (`obj.getClass().getMethods()` — see [beanshell-language.md](beanshell-language.md)) let
   you inspect objects before committing code.
2. **Log at boundaries** — before/after locks, saves, and external calls — so a
   failure narrows quickly.
3. **Always log the `Throwable`**, not just a message: `logError(msg, e)` retains
   the stack trace; `logError(e.getMessage())` throws it away.
4. **Check the right log.** Client-context scripts log to the client / server log
   depending on where they run; server-context scripts (generation, schedule) log
   to the server / schedule logs.

## Running a script over REST — output capture (live)

When a script is executed **over the REST API** (`POST …/scripts/{name}/execute`) rather than in
a client, capturing its outcome needs care. These were proven live against a real project
(source: PS website-migration tool, `knowledge/fs-facts.md` §2):

- **HTTP `200` does not mean the script succeeded.** It only means the script ran to its end
  without an *unhandled* exception. A script that caught its error, stopped halfway, or never
  reached the point that mattered still answers `200`. The outcome exists only in what the
  script **logged**.
- **An uncaught exception or a syntax error answers `500`**, with a JSON body whose `error` field
  carries the BeanShell message (`bsh.ParseException: Parse error at line 1, column 90.
  Encountered: |`, or `TargetError … Target exception: java.lang.IllegalStateException: boom`).
  The engine turns both into an unchecked `ExecutionException` that the REST module does not
  catch `[core]`; the log records written *before* the throw are lost from the response (live
  2026-10-09, REST module 0.0.25-beta).
- **The response body is the log-listener output — nothing else.** Each record is appended as
  `[LEVEL] message` with **no separator between records** (`[INFO] LOGGED[WARN] WARNED`);
  `print(...)`, the `return` value and `result.setValue(...)` never appear (a script that only
  returns answers `200` with an empty body; live 2026-10-09). So emit a sentinel and believe the
  log — `context.logInfo("=== DONE")` on success, `context.logError("=== FAILED: " +
  e.getMessage())` on failure — then search for the marker, and do not split the output on
  newlines.
- **The uploaded source is wrapped in `__execute() { … }`** (a method body — the wrapper shows
  in every error message, `Called from method: __execute`): a bare trailing expression without
  its `;` is a parse error → HTTP `500`, not a returned value. `context` is in scope; over REST it
  is a `ProjectScriptContext` (concrete class `ProjectScriptContextImpl`; `is(Env.HEADLESS)` and
  `is(Env.PREVIEW)` are both `false`; live 2026-10-09).

### Access-API create defaults worth spelling out

- `setLock(boolean)` / `save(String)` are **recursive** (whole subtree); the two-argument forms
  `setLock(boolean, boolean)` / `save(String, boolean)` are not — use those to lock/save a single
  element (already the safe pattern in [common-patterns.md](common-patterns.md)).
- **`unifyUid` defaults to `false`:** `GlobalContentArea.createGCAPage(uid, template)` delegates to
  the three-argument form with `false` `[core]` and throws `DuplicateReferenceNameException` on a
  collision, like the SiteStore create. The silent rename exists only in the SiteArchitect
  *create* action, which passes `true` explicitly `[core]`. Spell the flag out on every create
  rather than relying on the default. (An earlier version of this bullet said the opposite; the
  claim came from a migration tool's notes and was not checked against the source.)
