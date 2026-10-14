# Rules: Visibility Patterns

Correct, tested patterns for FirstSpirit visibility rules.

---

## Show/hide by selection (radio/combobox)

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY source="selection" name="ENTRY"/>
            <TEXT>1</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY source="st_A" name="VISIBLE"/>
    </DO>
</RULE>
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY source="selection" name="ENTRY"/>
            <TEXT>2</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY source="st_B" name="VISIBLE"/>
    </DO>
</RULE>
```

## Show/hide by input state

```xml
<RULE>
    <WITH>
        <PROPERTY name="EMPTY" source="st_text_1"/>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="st_text_2"/>
        <NOT>
            <PROPERTY name="VISIBLE" source="st_text_3"/>
        </NOT>
    </DO>
</RULE>
```

Logic: IF text_1 empty -> show text_2, hide text_3.

## Gate on a toggle — compare, never test the bare value

A `CMS_INPUT_TOGGLE` has **three** states: `true`, `false` and `null` before the editor has touched
it (ODFS: *"The initial state (no option has been selected yet) returns the value `null`. This
should be taken into account when defining rules, especially when using the property VISIBLE."*).
A rule whose whole condition is the toggle's bare `VALUE` therefore passes `null` to `VISIBLE` on
a fresh section, and the rule does nothing useful until the editor first flips the toggle. What
the editor sees meanwhile **differs by client** (live 2026-10-09, FirstSpirit 5.2.261116, template
form preview): in **SiteArchitect** the gadget cannot apply `null` and keeps the field's initial
state, so the field is **visible** `[core]`; in **ContentCreator** the field is **hidden** on the
fresh section. Once the toggle has been flipped both clients show the field on `true` and hide it
on `false`. The same form therefore behaves differently in the two clients until the first click —
compare against the constant and the rule is unambiguous from the start.

```xml
<!-- ✗ passes null on a new section; the toggle has no effect until first flipped -->
<RULE>
    <WITH><PROPERTY name="VALUE" source="st_show_cta"/></WITH>
    <DO><PROPERTY name="VISIBLE" source="st_cta_label"/></DO>
</RULE>

<!-- ✓ compare against the boolean constant -->
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="VALUE" source="st_show_cta"/>
            <TRUE/>
        </EQUAL>
    </WITH>
    <DO><PROPERTY name="VISIBLE" source="st_cta_label"/></DO>
</RULE>
```

`<TRUE/>` and `<FALSE/>` are the rule constants for booleans (`<TEXT/>`, `<NUMBER/>` and
`<DATE/>` are the others `[core]`); do not write `<TEXT>true</TEXT>`. `<NOT_NULL/>` answers a
different question ("has any value") and cannot tell `true` from `false`. The `null` initial
state is documented for the toggle only `[odfs]`. For `CMS_INPUT_CHECKBOX`,
`CMS_INPUT_RADIOBUTTON`, `CMS_INPUT_COMBOBOX` and `CMS_INPUT_LIST` the `VALUE` is an option or a
set of options, never a boolean — a bare `VALUE` in `<WITH>` fails on its type ("is not of type
boolean", rule evaluates to false `[core]`) and `<TRUE/>` never matches it. Gate on `EMPTY` or
compare `ENTRY` with a `<TEXT>` key instead.

## Address a group, not each of its fields

When one condition governs every member of a `CMS_GROUP`, write **one** rule against the group.
`source` reaches a design component through `#form.<name>`:

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="VALUE" source="st_show_cta"/>
            <TRUE/>
        </EQUAL>
    </WITH>
    <DO><PROPERTY name="VISIBLE" source="#form.cg_cta"/></DO>
</RULE>
```

Five identical `VISIBLE` rules for the five fields of one group is the shape a generator produces;
one rule on the group is the shape hand-written projects use. Per-field rules are right only when
the members are governed differently. `[odfs]` (`<PROPERTY source="#form.gadget"/>` for design
components)

## Store-based visibility (page store only)

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY source="#global" name="STORETYPE"/>
            <TEXT>pagestore</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY source="#form.st_pagestore" name="VISIBLE"/>
    </DO>
</RULE>
```

## Multi-store visibility

```xml
<RULE>
    <WITH>
        <OR>
            <EQUAL>
                <PROPERTY source="#global" name="STORETYPE"/>
                <TEXT>pagestore</TEXT>
            </EQUAL>
            <EQUAL>
                <PROPERTY source="#global" name="STORETYPE"/>
                <TEXT>mediastore</TEXT>
            </EQUAL>
        </OR>
    </WITH>
    <DO>
        <PROPERTY source="st_keywords" name="VISIBLE"/>
    </DO>
</RULE>
```

## Language-based visibility

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY source="#global" name="LANG"/>
            <TEXT>DE</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY source="#form.st_german" name="VISIBLE"/>
    </DO>
</RULE>
```

## ContentCreator only (WEB)

```xml
<RULE>
    <WITH>
        <PROPERTY source="#global" name="WEB"/>
    </WITH>
    <DO>
        <PROPERTY source="#form.st_WebClient_only" name="VISIBLE"/>
    </DO>
</RULE>
```

## SiteArchitect only (NOT WEB)

```xml
<RULE>
    <WITH>
        <NOT>
            <PROPERTY source="#global" name="WEB"/>
        </NOT>
    </WITH>
    <DO>
        <PROPERTY source="#form.st_JavaClient_only" name="VISIBLE"/>
    </DO>
</RULE>
```

## Permission-based visibility (user group)

`<IN_GROUP name="…"/>` tests whether the current editor belongs to a **project** group (the
project's groups plus the user's external groups, e.g. LDAP), and is resolved to a fixed
true/false once, when the ruleset is parsed for the form `[core]` — used to show a field only to
certain editors:

```xml
<RULE>
    <WITH>
        <IN_GROUP name="Administrators"/>
    </WITH>
    <DO>
        <PROPERTY source="#form.st_advanced" name="VISIBLE"/>
    </DO>
</RULE>
```

## Legacy restriction-level blocks (`<ON_EVENT>`, `<ON_SAVE>`, `<ON_RELEASE>`)

Before FirstSpirit 5.2 a rule's restriction level was expressed by its wrapping tag instead of
`<RULE>` + `<VALIDATION scope="…">` `[odfs]` (*New in version 5.2*: the old syntax "will cease to
be supported"). The blocks wrap the same `<IF>`/`<WITH>`/`<DO>` and run at the same time as
`<RULE>` — the tag does **not** change *when* a rule runs, only `when="ONSAVE|ONLOCK"` does; it
only pre-sets the scope `[core]`. `<ON_EVENT>` is therefore identical to a plain `<RULE>`. You
will meet them in exported rulesets; read them like `<RULE>`.

The rule parser accepts exactly these three blocks directly under `<RULES>`, one per scope
`[core]`; any other tag name at that level is a parsing error. A block pre-sets the default scope
for the `<VALIDATION>`s inside it, so a `<VALIDATION>` without `scope` inside `<ON_SAVE>` blocks on
save (inside `<ON_RELEASE>`: on release). An explicit `scope` on the `<VALIDATION>` always wins,
in either direction `[core]`: `scope="INFO"` inside `<ON_SAVE>` blocks nothing, `scope="SAVE"`
inside `<ON_RELEASE>` blocks saving. (What the block cannot do is lower the *rule's* own scope,
which only decides whether the rule is included in a SAVE or RELEASE check run.)

In new rulesets write a plain `<RULE>` with `<VALIDATION scope="SAVE">` / `scope="RELEASE">`
instead of the blocks — and do **not** add `when="ONSAVE"` as a substitute: that changes when the
rule runs, and ONSAVE rules are skipped by every release check, so they never block a release
(`validation.md`, *Execution time*; confirmed live 2026-10-09).

## Section inclusion visibility

```xml
<RULE>
    <WITH>
        <AND>
            <EQUAL>
                <PROPERTY source="#global" name="STORETYPE"/>
                <TEXT>pagestore</TEXT>
            </EQUAL>
            <PROPERTY source="#global" name="INCLUDED"/>
        </AND>
    </WITH>
    <DO>
        <PROPERTY source="#form.A" name="VISIBLE"/>
    </DO>
</RULE>
```
