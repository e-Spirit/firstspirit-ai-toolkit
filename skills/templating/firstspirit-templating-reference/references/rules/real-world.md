# Rules: Real-World Patterns

Patterns extracted from production FirstSpirit projects. Each example includes the business context it solves.

---

## Catalog size limit -- Maximum items (NEW)

Limits catalog entries by disabling the "New" action (`NEW`) when the maximum is reached.

```xml
<RULE>
    <WITH>
        <LESS_THAN>
            <PROPERTY name="SIZE" source="st_cards"/>
            <NUMBER>3</NUMBER>
        </LESS_THAN>
    </WITH>
    <DO>
        <PROPERTY name="NEW" source="st_cards"/>
    </DO>
</RULE>
```

Business context: Design constraint -- highlight cards limited to max 3 items for visual balance. The "New" action stays enabled while SIZE < 3 (0-2 items exist), so a third card can be added and no fourth. (`SIZE < 4` would allow four: with three cards `3 < 4` still holds.)

Equivalent form with an inverted condition (disables "New" once 3 items exist):

```xml
<RULE>
    <WITH>
        <GREATER_THAN>
            <PROPERTY name="SIZE" source="st_features"/>
            <NUMBER>2</NUMBER>
        </GREATER_THAN>
    </WITH>
    <DO>
        <NOT>
            <PROPERTY name="NEW" source="st_features"/>
        </NOT>
    </DO>
</RULE>
```

Key points `[core]` (confirmed live 2026-10-09, FirstSpirit 5.2.261116, SiteArchitect and ContentCreator form preview):
- The action properties switch an **enabled** state; the button stays visible, greyed out — nothing is hidden. With the rule above, "New" was disabled after the third card in both clients
- `FS_CATALOG` knows the actions `NEW`, `REMOVE`, `EDIT` and `COPY` only. **`ADD` does not exist on a catalog**: a rule setting it is logged as a warning and limits nothing — in the live check "New" stayed enabled at any size (`FS_INDEX` has `ADD`, see *FS_INDEX size limit*)
- `NEW` creates a new card (FS_CATALOG, FS_INDEX); `ADD` adds existing records via selection (FS_INDEX only); `COPY` duplicates a card (FS_CATALOG) and follows `NEW` unless set explicitly
- For FS_CATALOG restrict `NEW`; for FS_INDEX restrict both `NEW` and `ADD`
- `SIZE` returns the current number of entries in the catalog/index

---

## Catalog size limit -- Minimum items (RELEASE validation)

Requires a minimum number of catalog entries for release.

```xml
<RULE>
    <WITH>
        <LESS_THAN>
            <PROPERTY name="SIZE" source="st_features"/>
            <NUMBER>2</NUMBER>
        </LESS_THAN>
    </WITH>
    <DO>
        <NOT>
            <VALIDATION scope="RELEASE">
                <PROPERTY name="VALID" source="st_features"/>
                <MESSAGE lang="*" text="At least two features must be added."/>
            </VALIDATION>
        </NOT>
    </DO>
</RULE>
```

Business context: Features section requires at least 2 items (not 1, not 0) for the layout to work visually. Editors can save with fewer, but cannot release.

Logic: SIZE < 2 -> WITH=TRUE -> NOT in DO block inverts the validation -> validation error is shown. When SIZE >= 2 -> WITH=FALSE -> inverted NOT = validation passes -> no error.

---

## Conditional EDITABLE by radio/combobox value

Makes a field editable only when a specific option is selected.

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="ENTRY" source="st_layout"/>
            <TEXT>text</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="EDITABLE" source="st_text_alignment"/>
    </DO>
</RULE>
```

Business context: Text alignment is only configurable when the teaser layout is "text" (text-only). When layout is "text-image" or "image-text", alignment has no effect, so the field is locked.

---

## Conditional visibility by radio value (multiple fields)

Shows different sets of fields depending on a mode selection.

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="ENTRY" source="st_type"/>
            <TEXT>product</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="st_product"/>
    </DO>
</RULE>
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="ENTRY" source="st_type"/>
            <TEXT>manual</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="st_image"/>
        <PROPERTY name="VISIBLE" source="st_image_alt_text"/>
        <PROPERTY name="VISIBLE" source="st_title"/>
        <PROPERTY name="VISIBLE" source="st_text"/>
        <PROPERTY name="VISIBLE" source="st_link"/>
    </DO>
</RULE>
```

Business context: Feature card with dual mode -- "product" shows a dataset picker, "manual" shows individual content fields. Only relevant fields are visible at any time.

Key points:
- Multiple `<PROPERTY name="VISIBLE" .../>` in one `<DO>` block toggles all at once
- There is no "hidden by default": the rule writes the boolean WITH result into VISIBLE, so each field is hidden whenever the condition is false — also while nothing is selected yet — and visible when it is true `[core]`

---

## Conditional validation by radio value

Validates different fields depending on a data source selection.

```xml
<RULE>
    <WITH>
        <OR>
            <NOT>
                <PROPERTY name="EMPTY" source="st_data_page"/>
            </NOT>
            <EQUAL>
                <PROPERTY name="ENTRY" source="st_datasource"/>
                <TEXT>manual</TEXT>
            </EQUAL>
        </OR>
    </WITH>
    <DO>
        <VALIDATION scope="RELEASE">
            <PROPERTY name="VALID" source="st_data_page"/>
            <MESSAGE lang="*" text="Please add a JSON data page"/>
        </VALIDATION>
    </DO>
</RULE>
```

Business context: Google Maps section with "database" or "manual" data source. The JSON data page reference is only required when "database" is selected. When "manual" is active, validation is skipped via the OR condition.

Logic: The OR makes the WITH TRUE when either the field is filled OR the other mode is selected -> VALIDATION passes.

---

## Conditional visibility by radio value with paired validation

Shows a field and validates it only when the right option is selected.

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="ENTRY" source="st_datasource"/>
            <TEXT>database</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="st_data_page"/>
    </DO>
</RULE>
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="ENTRY" source="st_datasource"/>
            <TEXT>manual</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="st_data_list"/>
    </DO>
</RULE>
```

Business context: Google Maps shows either a JSON page reference (database mode) or a manual location catalog (manual mode). Each data source has its own input, only the relevant one is shown.

---

## Element-type-based visibility (ELEMENTTYPE)

Shows form groups based on the type of element being edited.

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="ELEMENTTYPE" source="#global"/>
            <TEXT>picture</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="#form.imageAI"/>
    </DO>
</RULE>
```

Business context: Metadata template -- AI image analysis fields (alt text, object detection, etc.) are only shown when editing a picture element in the media store.

Key points:
- `ELEMENTTYPE` returns: `page`, `section`, `content2`, `picture`, `file`, `pageref`, etc.
- Access via `source="#global"` (system property)

---

## Always-hidden groups (FALSE)

Permanently hides form groups from all editors in all contexts.

```xml
<RULE>
    <WITH>
        <FALSE/>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="#form.translationStudio"/>
        <PROPERTY name="VISIBLE" source="#form.image"/>
    </DO>
</RULE>
```

Business context: Metadata template groups defined in GOM for programmatic access (scripts, modules) but never shown to editors. WITH=FALSE writes `false` into VISIBLE, so the groups are hidden -- nothing is "negated"; negation happens only through `<NOT>` `[core]`.

Key points:
- `<FALSE/>` is always FALSE -> VISIBLE is set to false -> fields are hidden
- Useful for fields that are only accessed by scripts or FirstSpirit modules
- Multiple fields can be hidden in one rule

---

## TemplateStore-only visibility (admin fields)

Shows fields only when editing in the TemplateStore -- hides them from content editors.

```xml
<RULE>
    <WITH>
        <EQUAL>
            <PROPERTY name="STORETYPE" source="#global"/>
            <TEXT>templatestore</TEXT>
        </EQUAL>
    </WITH>
    <DO>
        <PROPERTY name="VISIBLE" source="#form.sectionLifespan"/>
    </DO>
</RULE>
```

Business context: Section lifespan dates (from/to) are configured by template developers, not content editors. The group is only visible when editing the template itself.

Key points:
- `STORETYPE` values: `pagestore`, `contentstore`, `mediastore`, `sitestore`, `templatestore`, `globalstore` (the store type's name in lower case `[core]`)
- `source="#form.groupName"` targets a named `CMS_GROUP` in the GOM

---

## FS_INDEX size limit (single selection)

Restricts an FS_INDEX dataset picker to exactly 1 entry.

```xml
<RULE>
    <WITH>
        <LESS_THAN>
            <PROPERTY name="SIZE" source="st_product"/>
            <NUMBER>1</NUMBER>
        </LESS_THAN>
    </WITH>
    <DO>
        <PROPERTY name="NEW" source="st_product"/>
        <PROPERTY name="ADD" source="st_product"/>
    </DO>
</RULE>
```

Business context: Feature card allows selecting exactly one product from the database. Once a product is picked, the NEW and ADD buttons are disabled (greyed out, not hidden `[core]`).

Logic: SIZE < 1 (= empty) -> buttons enabled. SIZE >= 1 -> buttons disabled.

---

## Multiple required fields with bilingual messages

Multiple parallel validation rules for required fields, each with localized error messages.

```xml
<RULE>
    <WITH>
        <NOT>
            <PROPERTY name="EMPTY" source="st_category"/>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="RELEASE">
            <PROPERTY name="VALID" source="st_category"/>
            <MESSAGE lang="*" text="Please choose a category"/>
            <MESSAGE lang="DE" text="Bitte wählen Sie eine Kategorie aus"/>
        </VALIDATION>
    </DO>
</RULE>
<RULE>
    <WITH>
        <NOT>
            <PROPERTY name="EMPTY" source="st_headline"/>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="RELEASE">
            <PROPERTY name="VALID" source="st_headline"/>
            <MESSAGE lang="*" text="Please choose a headline"/>
            <MESSAGE lang="DE" text="Bitte geben Sie eine Überschrift ein"/>
        </VALIDATION>
    </DO>
</RULE>
<RULE>
    <WITH>
        <NOT>
            <PROPERTY name="EMPTY" source="st_text"/>
        </NOT>
    </WITH>
    <DO>
        <VALIDATION scope="RELEASE">
            <PROPERTY name="VALID" source="st_text"/>
            <MESSAGE lang="*" text="Please enter text"/>
            <MESSAGE lang="DE" text="Bitte pflegen Sie einen Text"/>
        </VALIDATION>
    </DO>
</RULE>
```

Business context: Product category teaser requires category, headline, and text before release. Each field gets its own validation rule with DE and EN error messages.

Key points:
- One rule per field = separate error messages per violation
- `scope="RELEASE"` allows saving drafts without validation
- `lang="*"` is the fallback, `lang="DE"` overrides for German editors
- This pattern scales to any number of required fields
