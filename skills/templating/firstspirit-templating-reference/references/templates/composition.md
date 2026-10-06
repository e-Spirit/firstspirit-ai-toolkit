# Templates: Composition (`$CMS_RENDER$`, `$CMS_TRIM$`)

Calling **another** template from this one, and controlling the shape of the output. For reading
and outputting *this* template's own fields, see `variables-conditionals.md`, `loops-lists.md`
and `dom-media.md`.

---

## `$CMS_RENDER$` — render another template

### Include a format template (render fragment)

```
$CMS_RENDER(template:"LayoutTemplate", style:true, customVar:"value")$
```

A format template pulled in this way is a **reusable render fragment**. (The *same* format
template object has a second, unrelated use — supplying HTML for editor-selected text styling
inside a `CMS_INPUT_DOM` field. That DOM-styling role is documented in `dom-media.md`; do not
conflate the two.)

### Execute a script

```
$CMS_RENDER(script:"ScriptName", param1:"value1")$
```

### Render an alternate output channel

```
$CMS_RENDER(#this, templateSet:"logicChannel")$
```

### Pass parameters to a format template

Calling template:
```
$CMS_RENDER(template:"Card", title:st_headline, text:st_text)$
```

Format template:
```
<div class="card">
  <h2>$CMS_VALUE(title)$</h2>
  <p>$CMS_VALUE(text)$</p>
</div>
```

Always pass **named** arguments; positional arguments do not occur in production templates. A
format template has no form definition, so **nothing declares or checks its parameters**: a
misspelled name is a silently empty value, an extra argument is silently ignored. Document the
contract in a `$-- Parameters: … --$` header at the top of the format template; it is the only
signature the template will ever have.

### `$CMS_RENDER$` is a macro, not a function call

The called template executes **in the caller's scope**. Consequences:

- **An omitted parameter is `null`, not empty.** Normalise on the callee's first lines and test
  `isNull` before `isEmpty`, or the template dies on the first caller who leaves an argument out:
  ```
  $CMS_SET(setElement,    if(!element.isNull, element, ""))$
  $CMS_SET(setResolution, if(!resolution.isNull && !resolution.isEmpty, resolution, "resDesktop"))$
  ```
- **The callee can read the caller's fields without being passed them** (a page head template
  reading `pt_title` directly). That is an undeclared dependency; either pass the value or name
  it in the header comment.
- **`editorId()` without arguments resolves against the caller's section**, which is what lets a
  shared ContentCreator wrapper stamp the edit frame around somebody else's section
  (see `real-world.md`).
- **`$CMS_SET$` does not cross a template boundary in the other direction**: a container cannot
  set a variable for its `FS_CATALOG` item template to read. Only `#global.section.id` and
  `#index` cross.
- **Prefix locals** (`set…`) so a partial does not clobber a caller variable, and **reset** any
  variable you pre-set for a format template invoked implicitly (a `<FORMATS>` entry or a link
  template), or it leaks into the next field:
  ```
  $CMS_SET(setDomAttr, "class=\"lead\"")$
  $CMS_VALUE(st_text)$
  $CMS_SET(setDomAttr, "")$
  ```

### Getting a value back

Almost every render emits its markup where it stands. To capture the output instead, use the
**block form** of `$CMS_SET$`; the expression form `$CMS_SET(x, $CMS_RENDER(…)$)$` does not occur
in production templates:

```
$CMS_SET(set_rendered)$$CMS_RENDER(template:"ft_card", title:st_headline)$$CMS_END_SET$
$CMS_VALUE(set_rendered.toString)$
```

Two other return channels seen in practice: a map passed as a parameter that the callee `.put()`s
into (see *Composing across templates* below), and a write to a page-level context
(`$CMS_SET(#global.context("PAGE")["psFavicon"], set_path)$`) when the result is needed far away.

> Sources: the `$CMS_RENDER$` and format-template ODFS pages, plus a 2026 survey of format-template
> call sites across several live FirstSpirit projects (named arguments, `set*` normalisation, block-form
> capture). `[odfs]` for the mechanics, `[observed]` for the idioms.

---

## `$CMS_TRIM$` — control output whitespace

Controls whitespace in the generated output — essential for XML, JSON, and inline values.

```
$CMS_TRIM(level:4)$
  $CMS_VALUE(someValue)$
$CMS_END_TRIM$
```

Trim levels:
- `level:0` = no change to whitespace
- `level:1` = consecutive whitespace-only rows are grouped into a single row
- `level:2` = all whitespace-only rows are removed
- `level:3` = level 2 + leading and trailing whitespace per row is removed
- `level:4` = all consecutive whitespace grouped into one space, leading/trailing spaces removed.
  ⚠️ **breaks JavaScript** — necessary line breaks are removed.

---

## Building structured output (maps → JSON)

For a **custom JSON** output channel (e.g. a headless project that authors its own document shape
rather than relying on CaaS Connect's auto-serialisation), the robust idiom is **not** to
concatenate JSON strings but to build a map/list graph and serialise it once with `.toJSON`.
`.toJSON` does all the JSON escaping, so you never manage quotes or commas by hand:

```
$CMS_TRIM(level:1)$
  $CMS_SET(json, {:})$                              $-- {:} = empty map (vs { } = empty set) --$
  $CMS_SET(void, json.put("headline", st_headline))$
  $CMS_SET(void, json.put("tags", [st_a, st_b]))$   $-- list literal --$
  $CMS_VALUE(json.toJSON)$                           $-- one serialisation, fully escaped --$
$CMS_END_TRIM$
```

Build maps with `{:}` + `.put(key, value)` and lists with `[]` + `.add`/`.addAll` (see
`variables-conditionals.md`). Wrap the whole channel in `$CMS_TRIM$` so only `.toJSON` reaches the
output.

**Inline-literal style** (cleaner) — write the object as one literal, using the two-arg `if(cond,
value)` (yields `null` when false) for optional fields; `.toJSON` emits real JSON `null`:

```
$CMS_SET(void, items.add({
  "headline": if(st_headline.empty, null, st_headline.convert2),
  "image":    if(st_image.empty, null, ref(st_image, res:"CONTENT", abs:1).url)
}))$
```

**Composing across templates.** A page can `$CMS_SET(blocks, [])$`, render its body, and let each
section append its own object (`blocks.add(block)`); a called render template can even take the
map/list as a parameter and `.put()` into it (render-template-as-mutator):
`$CMS_RENDER(template:"extra_attrs_render", target:block)$`.

**Escaping inside hand-written JSON.** If you must write JSON text by hand, call `.toJSON` on each
**scalar** to get a safely quoted-and-escaped string — do not wrap a value in manual quotes with
only `.convert2`:

```
✅ $CMS_VALUE(#nav.label.convert2.toJSON)$      $-- emits a complete "…" JSON string --$
⚠️ "$CMS_VALUE(#nav.label.convert2)$"           $-- breaks on a literal " or \ in the value --$
```

`.convert2` is **HTML** escaping, not JSON escaping — only `.toJSON` is safe for a JSON sink. See
`string-operations.md` → Output escaping. The deep CaaS/TPP mechanics of custom-JSON headless
delivery (preview vs release, previewId/TPP ids) belong to `firstspirit-headless`; this section is
just the template-language technique for assembling the output.
