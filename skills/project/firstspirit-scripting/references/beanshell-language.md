# BeanShell language essentials

FirstSpirit's script language is **[BeanShell](http://www.beanshell.org)** — a
Java source interpreter. It runs normal Java, plus script conveniences:

- **Dynamic typing** for global variables and functions (no `String s =` needed).
- **Full access** to the FirstSpirit Access API and the Java API.
- **Standard Java syntax** for everything else.
- **Convenience methods** (below) for quick inspection and debugging.

Because it *is* Java under the hood, prefer explicit, typed, imported code for
anything non-trivial — the dynamic features are a convenience, not a licence for
sloppiness.

## Version and restrictions

FirstSpirit embeds **BeanShell** at roughly **JDK 1.5 language level**. Limits, each confirmed on a live FirstSpirit 5.2.261116 server
(scripts run over the REST `/execute` endpoint, 2026-10-09):

- **Generics: one type parameter only.** `List<String> l = new ArrayList<String>();` parses;
  **two** type parameters (`Map<String,String>`), nested generics (`List<List<String>>`),
  wildcards (`List<?>`) and the diamond `new ArrayList<>()` are all `bsh.ParseException`s.
  Casts to parameterised types do not exist either. Use raw types (`Map m = new HashMap();`)
  and cast to the concrete type.
- **No multi-catch.** `catch (LockException | ElementDeletedException e)` is a parse error
  (`Encountered: |`); write one `catch` block per exception.
- **Scripted classes work, `implements` included:** `class Foo implements Runnable { public
  void run() { … } }` ran as written. For a one-off callback the anonymous-object idiom
  (`new SomeInterface() { method(args) { … } }`) is shorter and also works; long-lived logic
  still belongs in a module `Executable`.
- **No default imports.** Every class you name needs an `import` (or its fully qualified
  name); a bare `Page` fails with `Class: Page not found in namespace` (typed declaration) or
  `Class or variable not found: Page.UID_TYPE` (expression) — not with a
  `ClassNotFoundException`.
- **No compile-time help:** no code completion, no `@Deprecated`/`@ApiStatus`
  warnings, reduced syntax checking; slower than native Java.

Because of these, BeanShell is best for **small, one-off, or test scripts**. For
anything long-lived or load-bearing, prefer a FirstSpirit **Executable / module**
(see the script-vs-module note in [conventions.md](conventions.md)). Tip: develop
against the API in a real IDE, then paste into the script — see the
"IDE-to-script workflow" in [real-world.md](real-world.md).

---

## Script header

The first line marks the script as BeanShell (case-insensitive):

```
//!BeanShell
```

Put **all imports directly under the header** (see
[conventions.md](conventions.md) — importing in the header is required for
performance, not just style):

```
//!BeanShell
import de.espirit.firstspirit.access.store.LockException;
import de.espirit.firstspirit.access.store.pagestore.Page;
import java.util.List;
```

## Typing

```
//!BeanShell
// Dynamic (global) — allowed, BeanShell infers the type
foo = "bar";
count = 0;

// Explicit typing works exactly like Java and is preferred for clarity
String label = "bar";
int count = 0;
```

## Methods (functions)

BeanShell functions may omit the return type:

```
//!BeanShell
greet(name) {
    return "Hello " + name;
}
print(greet("world"));
```

## The BeanShell console

A graphical shell for running BeanShell interactively against a live project. It is **not part
of every project**: it comes as the separate *Developer-Scripts* package of context-menu
scripts, which has to be imported into the project first `[core]`.

- Once imported, open it from the context menu of a store node:
  *Execute Script → DeveloperScripts → BeanShellConsole*.
- The console presets `context` (the script context) `[core]`, and the convenience commands
  are available exactly as in a real script — ideal for exploring the API before committing
  to a script.

```
bsh % e = context.getElement();
bsh % print(e);
```

## Convenience commands

BeanShell *commands* (`print`, `show`, `javap`, …) are available in scripts and in the
console. Use them to inspect objects while developing; replace `print()` with proper logging
in finished scripts. `getMethods` is **not** one of them — see below.

### `print(Object)`
String-prints any object to the interpreter's output: the console when you are in it,
otherwise standard out — never the FirstSpirit script log, and over REST `/execute` it does
not appear in the response (live 2026-10-09).

```
bsh % e = context.getElement();
bsh % print(e);
<SECTION editor="100042" id="100043" name="text_image" ...>
```

### `show()`
Toggles automatic printing of return values in the console. Call once to turn the
automatic echo off, again to turn it back on.

```
bsh % show();          // auto-echo off
bsh % e = context.getElement();   // (no output now)
```

### `obj.getClass().getMethods()` — reflection, not a command
There is **no `getMethods(...)` command**: `getMethods("x")` fails with
`Command not found: getMethods(java.lang.String)` (live 2026-10-09). What works is plain Java
reflection on the object, which lists all public methods including inherited ones — handy
when you don't know what an object offers:

```
bsh % print(e.getClass().getMethods());
java.lang.reflect.Method []: {
  public java.util.Set ...SectionImpl.getReferences() throws java.io.IOException,
  public ...Template ...SectionImpl.getTemplate(),
  ...
}
```

### `javap(Object)`
Shows only the methods and fields **declared/overridden directly** on the concrete
class (a narrower, more readable view than `getClass().getMethods()`).

---

## When *not* to use BeanShell

- Behaviour needed long-term / under load → build a **module** (executable or
  plugin) instead of a script.
- Output logic that belongs in a template → use template syntax / a format
  template, not a generation script, unless you genuinely need programmatic logic.
