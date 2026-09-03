# Identifiers, casing, and notation

Factual rules about how names, casing, and call notation behave in FirstSpirit — language and
client behaviour, **not** house naming conventions. The *convention* for form-variable prefixes
(`st_`, `prm_`, `lt_`, …) is normative ("name it like this") and lives in the
**`firstspirit-template-design`** skill (principle 7), not here. This file only states what the
system enforces, how case is treated, and when parentheses/shorthands are allowed.

## Reference names (store element UIDs)

Every store element (page, section, medium, template, dataset, …) has a **reference name** — its
technical UID — separate from its display name.

**The editor clients (SiteArchitect and ContentCreator) enforce a normalised form:**

- lowercase only
- every punctuation or whitespace character is mapped to underscore `_`
- digits are allowed

So a name entered as `My Teaser-Image 2` is stored as `my_teaser_image_2`.

**The API does not enforce this.** Reference names created or changed through the Access API or
scripts (BeanShell/Java) can bypass the rule, so a project may contain reference names that are
not lowercase / underscore-normalised (mixed case, other characters).

> **Diagnostic signal:** a reference name that does not match the client-enforced form
> (lowercase, punctuation→`_`, digits only) was almost certainly created or altered via API or
> script, not through the editor clients. Scripting and the API are out of scope for this skill
> (they belong to the scripting skill) — but the fact matters when reading an existing project.

### Where the reference name lives in a sync export

The reference name is **not** an attribute called `uid=` (that appears only as `uid="root"` on
store roots). In a sync export it is carried by, depending on element type:

- **`filename=`** — templates, format/link templates, scripts, workflows (e.g. `text_image`, `internal_link`, `wf_release`).
- **`name=`** — pages and sections (e.g. `<PAGE name="main_navigation">`).
- **`uniquedescription=`** — media and page-refs (e.g. `<MEDIUM uniquedescription="female_model">`).

> **Media trap:** on a `<MEDIUM>`, `filename=` is the **physical upload file name** and keeps its
> original casing / resolution suffix (e.g. `FemaleModel`, `picture_ORIGINAL`) — it is *not* the
> reference name. The normalised reference name is **`uniquedescription=`**. Check that one before
> concluding a media UID is "mixed-case".

## Casing in template code

| Where | Case-sensitive? | Rule |
|---|---|---|
| GOM form-XML attribute values | no | SiteArchitect writes `yes` / `no` / `picture` lowercase by default, but enum values are case-**insensitive** — real projects mix them (`store="mediastore"` and `store="PAGESTORE"` coexist; `FILTER type=` is often written lowercase `picture`/`pageref` despite docs showing uppercase). Don't rely on the case of an attribute value. |
| Ruleset.xml (rules) tokens | no | `scope=` and `<PROPERTY name=>` values are case-insensitive — deploying projects mix `SAVE`/`Save`/`save`, `VALID`/`valid`, `INFO`/`info`. Read them case-insensitively. |
| `$CMS_…$` output tags & keywords | no | keyword casing inside CMS tags is irrelevant |
| Java notation (method/object calls, class imports) | **yes** | `getKey`, `getLabel`, `.format`, `.isEmpty`, `.convert2`, class names must be spelled exactly (camelCase throughout the reference projects) |

See `datatypes.md` for the datatype methods these casing rules apply to, and
`firstspirit-template-design` (principle 7) for the variable-prefix convention.

## Notation: parentheses, shorthands, and the template-language vs. Java-API line

A frequent source of confusion: inside the template language you can *often* drop the `()` and use
a short property form — but that relaxation applies **only to the template language's own objects,
methods and functions**. Java Access API that is **not** part of the template language must be
written in full Java notation (complete call with `()`, exact case). The rules:

- **No-argument methods — `()` is optional.** `st_x.isEmpty` = `st_x.isEmpty()`; `x.toString` =
  `x.toString()`. Methods that take arguments always need the parentheses (`.format("dd.MM.yyyy")`,
  `.substring(5)`).
- **Bean syntax — a getter becomes a property.** A no-arg getter `.getX()` may be written as `.x`
  (ODFS calls this "Bean syntax"): `.getClass()` → `.class`, `.getDataset()` → `.dataset`. A
  boolean `is`-getter keeps its name, just drops the parens: `.isNull()` → `.isNull` (not `.null`).
- **Simplified accessor syntax.** A few accessors have documented shortcuts — e.g. FormData:
  `.formData.ID` ≡ `.formData.get("ID")` ≡ `.formData["ID"]` ≡ `.get(#global.language, "ID").get`.
- **Template-language functions** — the built-in set (`if`, `isset`, `ref`, `json`, `class`,
  `editorId`, `fsbutton`, `font`, `dataassociation`, plus header functions `define` / `table` /
  `contentSelect` / `Navigation` / `MenuGroup` / `PageGroup`). These are part of the language and
  called with their own syntax. Distinct from the `$CMS_…$` instructions, and distinct from Java.
- **Java Access API (not part of the template language) — full notation required.** Complete method
  calls with `()`, exact camelCase (see the casing table above: Java notation is case-sensitive).
  The `()`-optional and Bean-syntax relaxations do **not** apply here.

### Running list — equivalent forms

A living list of full-form ↔ shorthand pairs, so the two don't confuse a reader. Add to it as pairs
are confirmed against the docs.

| Full form | Shorthand / equivalent | Kind | Source |
|---|---|---|---|
| `.getClass()` | `.class` | Bean syntax | ODFS `data-types/*` |
| `.isNull()` | `.isNull` | no-arg `()` optional (is-getter) | ODFS `data-types/*` |
| `.isEmpty()` | `.isEmpty` (also `.empty` seen in projects) | no-arg `()` optional | ODFS / reference projects |
| `.getDataset()` | `.dataset` | Bean syntax | ODFS `data-types/datasetcontaine` |
| `.get(#global.language, "ID").get` | `.formData.ID` · `.formData["ID"]` · `.formData.get("ID")` | Simplified FormData syntax | ODFS `data-types/formdata` |
| `.toString()` | `.toString` | no-arg `()` optional | ODFS |
| `.values.iterator.next` | `.values.first` | idiom variants (FS_INDEX record) | reference projects |

> `.empty` vs `.isEmpty`: ODFS documents `.isEmpty()` → `.isEmpty`; the reference projects also use
> `.empty`. Both work in practice; treat them as equivalent when reading a project.

> **Status:** this list is deliberately partial. A complete public enumeration of simplified/
> shorthand accessors and per-function argument-optional behaviour does not appear to exist in the
> ODFS; completing it depends on an internal source (docs or code). Extend the table as pairs are
> confirmed — do not infer pairs into it unverified.
