# Rules: Validation Patterns

Correct, tested patterns for FirstSpirit validation rules.
**Use these as the primary reference when writing rules. Do NOT use anti-patterns from the full documentation.**

> **Key principle:** `<VALIDATION>` executes when `<WITH>` returns **FALSE**. For "must not be empty" checks, always negate with `<NOT>`.

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

```xml
<RULE>
    <IF>
        <NOT>
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
            <MESSAGE lang="DE" text="Der Editor darf nicht leer sein!"/>
        </VALIDATION>
    </DO>
</RULE>
```

Logic: IF picture exists, THEN description is required. Uses `scope="RELEASE"` for release-time validation.

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
