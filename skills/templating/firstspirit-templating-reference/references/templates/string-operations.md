# Templates: String operations & output escaping

String methods applied in the output channel via `$CMS_VALUE(myString.method)$`. Method names are
Java and **case-sensitive**. The last section covers output escaping (XSS safety), which is what
several of the encoding methods are for.

---

## Case conversion

```
$CMS_VALUE(myString.toLowerCase)$
$CMS_VALUE(myString.toUpperCase)$
```

## Search and check

```
$CMS_VALUE(myString.contains("search"))$          $-- boolean --$
$CMS_VALUE(myString.equals("compare"))$           $-- case-sensitive --$
$CMS_VALUE(myString.equalsIgnoreCase("compare"))$
$CMS_VALUE(myString.startsWith("prefix"))$
$CMS_VALUE(myString.indexOf("sub"))$              $-- -1 if not found --$
$CMS_VALUE(myString.length)$
```

## Manipulation

```
$CMS_VALUE(myString.substring(5))$          $-- from index --$
$CMS_VALUE(myString.substring(5, 12))$      $-- range --$
$CMS_VALUE(myString.trim)$                  $-- strip whitespace --$
$CMS_VALUE(myString.replace("old", "new"))$
$CMS_VALUE(myString.split(","))$            $-- returns array --$
$CMS_VALUE(myString.charAt(0))$
```

## Encoding

```
$CMS_VALUE(myString.convert)$    $-- HTML entities --$
$CMS_VALUE(myString.convert2)$   $-- HTML entities + quotes --$
$CMS_VALUE(myString.urlEncode)$  $-- URL encoding (UTF-8) --$
$CMS_VALUE(myString.xmlEscape)$  $-- XML entities --$
$CMS_VALUE(myString.quoteJS)$    $-- JavaScript escaping --$
$CMS_VALUE(myString.toJSON)$     $-- JSON string --$
$CMS_VALUE(myString.encode)$     $-- HTML id-attribute safe --$
```

## Conversion

```
$CMS_VALUE("5".toNumber())$        $-- string to number --$
$CMS_VALUE(filename.getExtension)$ $-- file extension --$
```

---

## Output escaping (XSS safety)

Editor-entered values that reach the HTML output **unfiltered** are an XSS weak point — page and
menu names are the classic case, since they surface through navigation functions
(`$CMS_VALUE(#nav.label)$`). An editor could enter `<script>alert('XSS');</script>` into a name
field and have it run in the browser.

Escape such values with **`.convert2`**, which replaces non-HTML-compliant characters (and quotes
`<`, `>`, `'`, `"`) using the template set's conversion rules:

```
⚠️  $CMS_VALUE(#nav.label)$          $-- unescaped: script runs --$
✅  $CMS_VALUE(#nav.label.convert2)$ $-- <script>… becomes &lt;script&gt;… --$
```

Apply the same principle to any user-supplied string rendered into markup; pick the encoder that
matches the sink (`convert2`/`xmlEscape` for HTML/XML, `urlEncode` for URLs, `quoteJS` for inline
JavaScript). This is a guideline, not a full security review.

### JSON sink — use `.toJSON`, not `.convert2`

For a **JSON** output channel the correct escaper is **`.toJSON`**, which returns a complete,
quoted, JSON-escaped string. `.convert2` is HTML escaping and does **not** make a value safe for
JSON. When you build JSON as a map/list graph, `.toJSON` on the whole graph handles every value;
when you hand-write JSON text, call `.toJSON` on each scalar:

```
✅ $CMS_VALUE(#nav.label.convert2.toJSON)$   $-- HTML-escape the text, then emit a valid JSON string --$
⚠️ "$CMS_VALUE(#nav.label.convert2)$"         $-- manual quotes + convert2 only: breaks on a literal " or \ --$
```

(`.convert2` before `.toJSON` is a deliberate choice when HTML entities must survive into the
frontend — it is not a substitute for JSON escaping.) See `composition.md` → Building structured
output.
