# Logging and debugging

## Log through `context`, not `print()`

`print()` writes to the BeanShell console only — fine while exploring, wrong in a
finished script. In production, use the context's four log levels so output lands
in the FirstSpirit log files and can be filtered/switched on demand.

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
> [script-contexts.md](script-contexts.md)). In a generation script the context
> is bound as `gc`, so use `gc.logInfo(...)`.

## Extended logging (SiteArchitect)

Editors/developers can switch **extended logging** on in SiteArchitect
(*Extras* menu). While active, `logDebug` output becomes visible — the reason to
route debug detail through `logDebug` rather than `print()`: you can turn it on to
trace a problem, then off again without touching the script.

## Debugging workflow

1. **Prototype in the BeanShell console** (context menu → *DeveloperScripts →
   BeanShellConsole*) against a real node. A live `context` and the convenience
   methods (`print`, `getMethods`, `javap` — see
   [beanshell-language.md](beanshell-language.md)) let you inspect objects before
   committing code.
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

- **HTTP `200` does not mean the script succeeded.** The status describes the *request*; a script
  that threw, stopped halfway, or never reached the point that mattered still answers `200`. The
  outcome exists only in what the script **logged**.
- **The response body is the log-listener output — nothing else.** Each record is appended as
  `[LEVEL] message` with **no separator between records**; `print(...)` and the return value never
  appear. So emit a sentinel and believe the log — `context.logInfo("=== DONE")` on success,
  `context.logError("=== FAILED: " + e.getMessage())` on failure — then search for the marker, and
  do not split the output on newlines.
- **The uploaded source is wrapped server-side in `__execute() { … }`** (a method body): a bare
  trailing expression without its `;` is a parse error → HTTP `500`, not a returned value.
  `context` (the `ScriptContext`) is in scope.

### Access-API create defaults worth spelling out

- `setLock(boolean)` / `save(String)` are **recursive** (whole subtree); the two-argument forms
  `setLock(boolean, boolean)` / `save(String, boolean)` are not — use those to lock/save a single
  element (already the safe pattern in [common-patterns.md](common-patterns.md)).
- **`unifyUid` defaults oppositely between stores:** `GlobalContentArea.createGCAPage(uid, template)`
  defaults it `true` and silently **renames** on a collision, while the SiteStore create throws.
  Spell the flag out on every create rather than relying on the default.
