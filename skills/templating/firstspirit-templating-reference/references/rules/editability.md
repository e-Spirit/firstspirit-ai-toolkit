# Rules: Editability Patterns

Correct, tested patterns for FirstSpirit editability rules. The `EDITABLE` property: ODFS 2026.5 *Rules → Form properties → EDITABLE* `[odfs]` (re-read 2026-10-30).

---

## Editable only when dependency is filled

```xml
<RULE>
    <WITH>
        <NOT>
            <PROPERTY source="st_picture" name="EMPTY"/>
        </NOT>
    </WITH>
    <DO>
        <PROPERTY source="st_description" name="EDITABLE"/>
    </DO>
</RULE>
```

Logic: Description is only editable when picture is set.

## Always locked (script-only field)

```xml
<RULE>
    <WITH>
        <FALSE/>
    </WITH>
    <DO>
        <PROPERTY name="EDITABLE" source="rules_text"/>
    </DO>
</RULE>
```
