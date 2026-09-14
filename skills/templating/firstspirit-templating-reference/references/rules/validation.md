# Rules: Validation Patterns

Correct, tested patterns for FirstSpirit validation rules.
**Use these as the primary reference when writing rules. Do NOT use anti-patterns from the full documentation.**

> **Key principle:** `<VALIDATION>` executes when `<WITH>` returns **FALSE**. For "must not be empty" checks, always negate with `<NOT>`.
>
> **Second principle:** `<IF>` is safe only for preconditions that cannot flip back within an
> editing session (language, store context). A precondition on another **editable field**
> belongs in `<WITH>` — in `<IF>` it produces a [one-way rule](#anti-pattern-the-one-way-rule).

### Validation scopes

`<VALIDATION scope="…">` sets when the check blocks:

- **`SAVE`** — blocks on save (the strictest; most common).
- **`RELEASE`** — blocks only at release, so editors can save work in progress.
- **`INFO`** — non-blocking; shows the message as information without preventing save or release.

Scope tokens are case-insensitive (`SAVE`/`Save`/`save` all occur in real projects), but write
them uppercase.

---

## Required field (must not be empty)

```xml
<RULE>
    <WITH>
        <NOT>
            <PROPERTY source="st_text" name="EMPTY"/>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_text" name="VALID"/>
            <MESSAGE lang="*" text="The editor must not be empty!"/>
            <MESSAGE lang="DE" text="Der Editor darf nicht leer sein!"/>
        </VALIDATION>
    </DO>
</RULE>
```

Logic: EMPTY=TRUE -> NOT=FALSE -> VALIDATION executes -> error shown.

## At least one of multiple fields must be filled

```xml
<RULE>
    <WITH>
        <NOT>
            <AND>
                <PROPERTY source="st_headline" name="EMPTY"/>
                <PROPERTY source="st_text" name="EMPTY"/>
                <PROPERTY source="st_picture" name="EMPTY"/>
            </AND>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_headline" name="VALID"/>
            <MESSAGE lang="*" text="At least one field must be filled!"/>
            <MESSAGE lang="DE" text="Es wurde kein Inhalt erfasst!"/>
        </VALIDATION>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_text" name="VALID"/>
            <MESSAGE lang="*" text="At least one field must be filled!"/>
            <MESSAGE lang="DE" text="Es wurde kein Inhalt erfasst!"/>
        </VALIDATION>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_picture" name="VALID"/>
            <MESSAGE lang="*" text="At least one field must be filled!"/>
            <MESSAGE lang="DE" text="Es wurde kein Inhalt erfasst!"/>
        </VALIDATION>
    </DO>
</RULE>
```

Logic: NOT(ALL empty) = at least one filled. All three fields get marked invalid if all are empty.

## Conditional required field (only when another field is filled)

> **Trap — the "one-way rule".** The obvious `<IF>`-based form of this rule can mark a field
> invalid but never valid again. Use the version below; see
> [Anti-pattern](#anti-pattern-the-one-way-rule) for why.

```xml
<RULE>
    <WITH>
        <OR>
            <PROPERTY source="cs_picture" name="EMPTY"/>
            <NOT>
                <PROPERTY source="cs_description" name="EMPTY"/>
            </NOT>
        </OR>
    </WITH>
    <DO>
        <VALIDATION scope="RELEASE">
            <PROPERTY source="cs_description" name="VALID"/>
            <MESSAGE lang="*" text="Description required when image is set!"/>
            <MESSAGE lang="DE" text="Beschreibung erforderlich, wenn ein Bild gesetzt ist!"/>
        </VALIDATION>
    </DO>
</RULE>
```

Logic: "picture set => description required", written as its equivalent "picture empty **OR**
description filled". No `<IF>`, so the rule runs on every change and re-evaluates in both
directions. `scope="RELEASE"` lets editors save work in progress.

### Anti-pattern: the one-way rule

**One-way rule** — practitioner term (used in FirstSpirit trainings and community posts; not
official FirstSpirit terminology) for a rule that can move a field to invalid but never back,
because its `<IF>` precondition stops the rule from running.

```xml
<RULE>
    <IF>                                       <!-- WRONG: one-way rule -->
        <NOT>                                  <!-- gates the whole rule, not the requirement -->
            <PROPERTY source="cs_picture" name="EMPTY"/>
        </NOT>
    </IF>
    <WITH>
        <NOT>
            <PROPERTY source="cs_description" name="EMPTY"/>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="RELEASE">
            <PROPERTY source="cs_description" name="VALID"/>
            <MESSAGE lang="*" text="Description required when image is set!"/>
        </VALIDATION>
    </DO>
</RULE>
```

**What `<IF>` actually means.** It reads as *"if a picture is set, then a description is
required."* It does not say that. `<IF>` gates **whether the rule executes at all**:

> if a picture is set, evaluate this rule — otherwise leave this rule's verdict exactly as it is.

`<IF>` is not the antecedent of an implication. It is an on/off switch for the rule, and when it
switches off, the last verdict the rule left behind stays.

**The failure.** In an open form:

1. Set `cs_picture`, leave `cs_description` empty -> the rule runs and marks the description
   invalid. Correct so far.
2. Remove `cs_picture` again. The `<IF>` is now false, the rule no longer runs, and the invalid
   verdict is never revisited — the field stays invalid although nothing requires it any more.
3. Now type a description. **It stays invalid.** The rule that would clear the verdict is
   switched off.

Step 3 is the signature: the field cannot be repaired by any input. (SME observation; no known
change in this behaviour.)

**Why it survives development.** The failure depends on the order of actions, and the order that
gets tested is the intended one — "a description is missing, so add a description." The path that
breaks it is the editor's other reasonable choice: remove the picture instead, or having added it
by accident to begin with. That path is rarely on the test list, so the rule ships looking correct.

**How far the damage goes.** The stale verdict is session-local — it lives in the rule engine's
state for the open form, not in the stored element. Saving, releasing and re-opening all
re-evaluate the rules from scratch, so a release is not blocked and a re-opened form shows no
phantom warning. The cost is editor confusion within one editing session, not corrupted content
or a blocked workflow. Report it as a usability defect, not a broken release.

**Detect.** In `Ruleset.xml`: a `<RULE>` whose `<IF>` tests a `PROPERTY source=` naming an
**input component** and whose `<DO>` contains `<VALIDATION>`, with no complementary rule covering
the inverse precondition.
Not a hit: `<IF>` over `#global` (`LANG`, `MASTER`, store context) — those cannot leave a verdict
that contradicts the current state. Not a hit: `<IF>` without `<VALIDATION>` (value-setting rules;
see `value-manipulation.md`).

**Repair.** Move the precondition into the value determination:
`IF(A) + WITH(B)` -> `WITH(OR(NOT(A), B))`. The rule then always runs and recovers in both
directions.

## Master language only validation

```xml
<RULE>
    <IF>
        <EQUAL>
            <PROPERTY source="#global" name="LANG"/>
            <PROPERTY source="#global" name="MASTER"/>
        </EQUAL>
    </IF>
    <WITH>
        <NOT>
            <PROPERTY source="st_headline" name="EMPTY"/>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_headline" name="VALID"/>
            <MESSAGE lang="*" text="Headline required in master language!"/>
        </VALIDATION>
    </DO>
</RULE>
```

Logic: Precondition limits rule to master language only.

## Maximum character length

```xml
<RULE>
    <WITH>
        <NOT>
            <GREATER_THAN>
                <PROPERTY source="cs_description" name="LENGTH"/>
                <NUMBER>1024</NUMBER>
            </GREATER_THAN>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="cs_description" name="VALID"/>
            <MESSAGE lang="*" text="Only 1,024 characters allowed!"/>
            <MESSAGE lang="DE" text="Es sind nur 1.024 Zeichen zugelassen!"/>
        </VALIDATION>
    </DO>
</RULE>
```

Logic: NOT(length > 1024) = length must be <= 1024.

## Multiple validations on same field (length + format)

```xml
<RULES>
  <RULE>
   <WITH>
    <LESS_THAN>
     <PROPERTY name="LENGTH" source="st_text"/>
     <NUMBER>6</NUMBER>
    </LESS_THAN>
   </WITH>
   <DO>
    <VALIDATION scope="SAVE">
     <PROPERTY name="VALID" source="st_text"/>
     <MESSAGE lang="*" text="Maximum 5 characters permitted"/>
    </VALIDATION>
   </DO>
  </RULE>
  <RULE>
   <WITH>
    <NOT>
     <MATCHES regex=".*[0-9].*">
      <PROPERTY name="VALUE" source="st_text"/>
     </MATCHES>
    </NOT>
   </WITH>
   <DO>
    <VALIDATION scope="SAVE">
     <PROPERTY name="VALID" source="st_text"/>
     <MESSAGE lang="*" text="No number permitted"/>
    </VALIDATION>
   </DO>
  </RULE>
</RULES>
```

Logic: Two separate rules = separate error messages per violation.

## Prevent negative numbers

```xml
<RULE>
    <WITH>
        <NOT>
            <LESS_THAN>
                <PROPERTY source="st_budget" name="VALUE"/>
                <NUMBER>0</NUMBER>
            </LESS_THAN>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_budget" name="VALID"/>
            <MESSAGE lang="*" text="Value must not be negative."/>
            <MESSAGE lang="DE" text="Wert darf nicht negativ sein."/>
        </VALIDATION>
    </DO>
</RULE>
```

## Value range validation

```xml
<RULE>
    <WITH>
        <OR>
            <EQUAL>
                <PROPERTY source="st_value" name="VALUE"/>
                <PROPERTY source="st_lowerLimit" name="VALUE"/>
            </EQUAL>
            <AND>
                <GREATER_THAN>
                    <PROPERTY source="st_value" name="VALUE"/>
                    <PROPERTY source="st_lowerLimit" name="VALUE"/>
                </GREATER_THAN>
                <LESS_THAN>
                    <PROPERTY source="st_value" name="VALUE"/>
                    <PROPERTY source="st_upperLimit" name="VALUE"/>
                </LESS_THAN>
            </AND>
            <EQUAL>
                <PROPERTY source="st_value" name="VALUE"/>
                <PROPERTY source="st_upperLimit" name="VALUE"/>
            </EQUAL>
        </OR>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_value" name="VALID"/>
            <MESSAGE lang="*" text="Value is out of range"/>
            <MESSAGE lang="DE" text="Wert ist nicht im Wertebereich"/>
        </VALIDATION>
    </DO>
</RULE>
```

## Regex format validation

```xml
<RULE>
    <WITH>
        <MATCHES regex="^DIN\ \d\d*$">
            <PROPERTY source="st_standard" name="VALUE"/>
        </MATCHES>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_standard" name="VALID"/>
            <MESSAGE lang="*" text="No DIN standard given"/>
            <MESSAGE lang="DE" text="Keine DIN-Norm angegeben"/>
        </VALIDATION>
    </DO>
</RULE>
```

## Prevent whitespace-only input

```xml
<RULE>
    <WITH>
        <NOT>
            <MATCHES regex="^\s*$">
                <PROPERTY name="VALUE" source="st_headline"/>
            </MATCHES>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY name="VALID" source="st_headline"/>
            <MESSAGE lang="*" text="Field must contain actual content!"/>
            <MESSAGE lang="DE" text="Es wurde kein Inhalt erfasst!"/>
        </VALIDATION>
    </DO>
</RULE>
```

## Language-dependent validation (different rules per language)

```xml
<RULE>
    <IF>
        <EQUAL>
            <PROPERTY source="#global" name="LANG"/>
            <TEXT>DE</TEXT>
        </EQUAL>
    </IF>
    <WITH>
        <MATCHES regex="^DIN\ \d\d*$">
            <PROPERTY source="st_standard" name="VALUE"/>
        </MATCHES>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_standard" name="VALID"/>
            <MESSAGE lang="DE" text="Keine DIN-Norm angegeben"/>
        </VALIDATION>
    </DO>
</RULE>
<RULE>
    <IF>
        <NOT>
            <EQUAL>
                <PROPERTY source="#global" name="LANG"/>
                <TEXT>DE</TEXT>
            </EQUAL>
        </NOT>
    </IF>
    <WITH>
        <MATCHES regex="^ISO\ \d\d*$">
            <PROPERTY source="st_standard" name="VALUE"/>
        </MATCHES>
    </WITH>
    <DO>
        <VALIDATION scope="SAVE">
            <PROPERTY source="st_standard" name="VALID"/>
            <MESSAGE lang="*" text="No ISO standard given"/>
        </VALIDATION>
    </DO>
</RULE>
```
