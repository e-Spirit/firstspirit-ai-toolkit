# Conventions: code style and Dos & Don'ts

Scripts are read and maintained by other developers. A consistent style and a few
hard rules keep them safe and legible.

---

## Code style

### Group code into blocks
Keep imports, global variables, methods, and the script body in clearly separated
blocks:

```
//!BeanShell

// Imports
import java.util.List;

// Global variables
foo = "bar";
count = 0;

// Methods
myMethod() {
    print("this is my method!");
}

// Script start
// ...
```

### Indentation
Indent consistently. Prefer **tabs** so the layout survives editors with different
tab widths.

### Documentation
Comment anything non-obvious — future extension and debugging depend on it:

```
//!BeanShell
// Single-line comment

/* Multi-line
   comment */
```

---

## Dos & Don'ts

### DO import classes in the header
For performance, import FirstSpirit/Java classes at the top — never use
fully-qualified names inline in hot paths.

```
//!BeanShell
// Bad
if (myVar instanceof java.lang.String) { print("its a string!"); }

// Good
import java.lang.String;
if (myVar instanceof String) { print("its a string!"); }
```

### DO lock with the correct try/finally schema
The only reliable way to guarantee the lock is released (full pattern in
[common-patterns.md](common-patterns.md)):

```
//!BeanShell
import de.espirit.firstspirit.access.store.LockException;
try {
    elm.setLock(true, false);
    try {
        elm.save("comment", false);
    } catch (Exception e) {
        // handle
    } finally {
        elm.setLock(false, false);
    }
} catch (LockException e) {
    // element already locked
}
```

### DO iterate with iterators, not full lists/arrays
Child collections can be very large (especially recursive). Use the iterator and
filter by class:

```
//!BeanShell
for (elem : folder.getChildren(MyClass.class, true).iterator()) {
    print(elem.getSomeValue());
}
```

### DO log, don't `print()`
Replace `print()` with the differentiated log methods
(`logInfo` / `logDebug` / `logWarning` / `logError`) so output goes to the log
files and can be switched via extended logging (see
[logging-and-debugging.md](logging-and-debugging.md)):

```
//!BeanShell
// Bad
print("done");

// Good
context.logDebug("done");
```

### DON'T script what already exists
Check for a standard FirstSpirit feature or existing template function before
writing a script. A script is only justified when nothing built-in fits.

### DON'T ship long-term logic as a script
Scripts are lightweight glue. For behaviour that is required and used
long-term / under load, implement a **module** (executable or plugin) — it is more
stable and maintainable. Scripts suit automation of editorial steps, migrations,
and one-off integrations.
