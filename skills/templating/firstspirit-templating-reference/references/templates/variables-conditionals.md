# Templates: Output, Variables, and Conditionals

Correct, tested FirstSpirit template-syntax patterns.
**Use these as the primary reference when writing output templates.**

---

## Output and Variables

### Output variable

```
$CMS_VALUE(st_headline)$
```

### Output with default value

```
$CMS_VALUE(st_headline, default:"Untitled")$
```

### Null check before output

```
$CMS_IF(!st_headline.isNull)$
  $CMS_VALUE(st_headline)$
$CMS_END_IF$
```

### Empty check before output

```
$CMS_IF(!st_text.isEmpty)$
  $CMS_VALUE(st_text)$
$CMS_END_IF$
```

### Set variable

```
$CMS_SET(myVar, "value")$
$CMS_SET(myVar, otherVar)$
$CMS_SET(myVar, otherVar.toString)$
```

### Set template fragment (block)

```
$CMS_SET(myBlock)$
  <div>Content: $CMS_VALUE(st_headline)$</div>
$CMS_END_SET$
```

### Create empty list and add items

```
$CMS_SET(myList, [])$
$CMS_SET(void, myList.add("item1"))$
$CMS_SET(void, myList.add("item2"))$
```

### Create filled list

```
$CMS_SET(myList, [1, 2, 3])$
```

### Create empty set

```
$CMS_SET(mySet, { })$
$CMS_SET(void, mySet.add("entry"))$
```

### Create empty map (key → value)

```
$CMS_SET(myMap, {:})$                     $-- {:} is an empty MAP; { } is an empty SET --$
$CMS_SET(void, myMap.put("key", value))$
$CMS_VALUE(myMap["key"])$
$CMS_VALUE(myMap.toJSON)$                  $-- serialise the whole map to JSON --$
```

A map/list graph plus `.toJSON` is the idiom for building custom JSON output — see
`composition.md` → Building structured output.

### Language-dependent dictionary

```
$CMS_SET(labels, {
  "DE" : { "title" : "Titel" },
  "EN" : { "title" : "Title" }
})$
$CMS_VALUE(labels[#global.language.abbreviation]["title"])$
```

---

## Conditionals

### Simple if

```
$CMS_IF(condition)$
  Output
$CMS_END_IF$
```

### If-else

```
$CMS_IF(condition)$
  True output
$CMS_ELSE$
  False output
$CMS_END_IF$
```

### If-elsif-else

```
$CMS_IF(condition1)$
  Output 1
$CMS_ELSIF(condition2)$
  Output 2
$CMS_ELSE$
  Default output
$CMS_END_IF$
```

### Preview vs. deployment

```
$CMS_IF(#global.isPreview())$
  <div class="debug">Preview mode</div>
$CMS_END_IF$
```

### Value comparison

```
$CMS_IF(st_layout == "left")$
  Left layout
$CMS_END_IF$
```

### Even/odd check (modulo)

```
$CMS_IF((#for.index % 2) == 0)$
  even
$CMS_ELSE$
  odd
$CMS_END_IF$
```

---

## Logical and Comparison Operators

```
$CMS_IF(a && b)$        $-- AND --$
$CMS_IF(a || b)$        $-- OR --$
$CMS_IF(!a)$            $-- NOT --$
$CMS_IF(a == b)$        $-- equal --$
$CMS_IF(a != b)$        $-- not equal --$
$CMS_IF(a < b)$         $-- less than --$
$CMS_IF(a > b)$         $-- greater than --$
$CMS_IF(a <= b)$        $-- less or equal --$
$CMS_IF(a >= b)$        $-- greater or equal --$
```

### Complex example

```
$CMS_IF(a != null && a.charAt(0).toString.lowerCase == "b")$
  Starts with B
$CMS_END_IF$
```

---

## Inline conditional expressions & helpers

Besides the `$CMS_IF$` **statement**, FirstSpirit has an `if()` **expression** for use inside a
value — indispensable when building maps/lists (see `composition.md`):

```
$CMS_VALUE(if(st_a == "x", "yes", "no"))$   $-- ternary: if(cond, then, else) --$
$CMS_VALUE(if(st_a.empty, null))$           $-- two-arg: yields null when false --$
```

`isSet(var)` tests whether a variable is defined (safe guard for an optional context/set variable):

```
$CMS_IF(isSet(myVar) && !myVar.empty)$ … $CMS_END_IF$
```

Lists support lambda/stream expressions:

```
$CMS_VALUE(myList.filter(x -> x.get("type") == "teaser").size)$
```

> `.empty` and `.isEmpty` / `.isEmpty()` are interchangeable; real projects use all three forms.

---

## Comments

```
$-- This is a comment and will not appear in the output --$
```

---

## Preventing Endless Loops

When a variable references itself, force evaluation with `.toString`:

```
$CMS_SET(myVar, "PREFIX" + myVar.toString + "SUFFIX")$
```
