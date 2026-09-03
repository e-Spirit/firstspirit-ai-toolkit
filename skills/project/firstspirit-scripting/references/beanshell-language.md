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

FirstSpirit embeds **BeanShell 2**, at roughly **JDK 1.5 language level**. Known
limits to code around (per the DTA training):

- **Generics are limited:** no nested generics, no wildcards (`<?>`), and no casts
  to parameterised types. Use raw types / `Object` and cast to the concrete type.
- **A scripted class can't `implements` an interface** the Java way. To supply an
  interface implementation (e.g. a callback), use the BeanShell idiom of a scripted
  object coerced to the interface (`new SomeInterface() { method(args) { … } }`),
  or move the logic into a module `Executable`.
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

A graphical shell for running BeanShell interactively against a live project.

- Open it from the context menu on **any** store node:
  *Execute Script → DeveloperScripts → BeanShellConsole*.
- A `context` object and all convenience methods are available, exactly as in a
  real script — ideal for exploring the API before committing to a script.

```
bsh % e = context.getElement();
bsh % print(e);
```

## Convenience methods

Available in scripts and in the console. Use them to inspect objects while
developing; replace `print()` with proper logging in finished scripts.

### `print(Object)`
String-prints any object.

```
bsh % e = context.getElement();
bsh % print(e);
<SECTION editor="833847" id="835469" name="Text/Bild" ...>
```

### `show()`
Toggles automatic printing of return values in the console. Call once to turn the
automatic echo off, again to turn it back on.

```
bsh % show();          // auto-echo off
bsh % e = context.getElement();   // (no output now)
```

### `getMethods()`
Lists all methods of a class, including inherited ones — handy when you don't know
what an object offers:

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
class (a narrower, more readable view than `getMethods()`).

---

## When *not* to use BeanShell

- Behaviour needed long-term / under load → build a **module** (executable or
  plugin) instead of a script.
- Output logic that belongs in a template → use template syntax / a format
  template, not a generation script, unless you genuinely need programmatic logic.
