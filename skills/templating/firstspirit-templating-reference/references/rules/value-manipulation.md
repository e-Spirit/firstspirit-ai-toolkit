# Rules: Value Manipulation Patterns

Correct, tested patterns for FirstSpirit value manipulation rules.

---

## Auto-calculate integer

```xml
<RULE>
    <WITH>
        <ADD value="9">
            <PROPERTY source="st_startValue" name="VALUE"/>
        </ADD>
    </WITH>
    <DO>
        <PROPERTY source="st_value" name="VALUE"/>
    </DO>
</RULE>
```

## Auto-calculate date (+ 2 weeks)

```xml
<RULE>
    <WITH>
        <ADD value="2 weeks">
            <PROPERTY source="st_startDate" name="VALUE"/>
        </ADD>
    </WITH>
    <DO>
        <PROPERTY source="st_endDate" name="VALUE"/>
    </DO>
</RULE>
```

## Reset dependent field when source is cleared

```xml
<RULE>
    <IF>
        <PROPERTY name="EMPTY" source="st_supplier"/>
    </IF>
    <WITH>
        <TRUE/>
    </WITH>
    <DO>
        <PROPERTY name="EMPTY" source="st_dish"/>
    </DO>
</RULE>
```

## Toggle clears another field

```xml
<RULE>
    <IF>
        <PROPERTY name="VALUE" source="st_empty"/>
    </IF>
    <WITH>
        <FALSE/>
    </WITH>
    <DO>
        <PROPERTY name="VALUE" source="st_empty"/>
        <PROPERTY name="EMPTY" source="st_checkbox"/>
    </DO>
</RULE>
```

## Sync two toggles oppositely

```xml
<RULE>
    <IF>
        <EQUAL>
            <PROPERTY name="VALUE" source="First"/>
            <TRUE/>
        </EQUAL>
    </IF>
    <WITH>
        <FALSE/>
    </WITH>
    <DO>
        <PROPERTY name="VALUE" source="Second"/>
    </DO>
</RULE>
<RULE>
    <IF>
        <EQUAL>
            <PROPERTY name="VALUE" source="First"/>
            <FALSE/>
        </EQUAL>
    </IF>
    <WITH>
        <TRUE/>
    </WITH>
    <DO>
        <PROPERTY name="VALUE" source="Second"/>
    </DO>
</RULE>
```

## Dynamic query parameter for database-backed selection

```xml
<RULE>
    <WITH>
        <PROPERTY source="st_supplier" name="VALUE"/>
    </WITH>
    <DO>
        <PROPERTY source="st_dish" name="query.supplier_id"/>
    </DO>
</RULE>
```
