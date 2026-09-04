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

`<IN_GROUP name="…"/>` tests whether the current editor belongs to a server user group — used to
show a field only to certain editors:

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

## Event-triggered rules (`<ON_EVENT>`)

Besides `<RULE>`, a ruleset can carry an `<ON_EVENT>` block that fires on a form event (rather than
continuously). It wraps the same `<WITH>`/`<DO>` and is used, for example, to toggle `VISIBLE` when
a field changes. You will encounter it in exported rulesets alongside `<RULE>`; read it the same way
(the `<DO>` acts when `<WITH>` holds).

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
