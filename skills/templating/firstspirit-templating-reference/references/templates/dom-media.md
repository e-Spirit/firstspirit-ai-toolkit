# Templates: DOM Content and Media References

---

## DOM Content (Rich Text)

### Output DOM

```
$CMS_VALUE(st_text)$
```

### DOM normalized (avoids extra wrapper tags)

```
$CMS_VALUE(st_text.normalize)$
```

### DOM as plain text (HTML stripped)

```
$CMS_VALUE(st_text.toText(false))$
```

### DOM as HTML

```
$CMS_VALUE(st_text.toText(true))$
$CMS_VALUE(st_text.normalize.toText(true))$   $-- normalise nesting first --$
$CMS_VALUE(st_text.renderToString())$         $-- render via format templates, capture as a string --$
```

`.renderToString()` runs the DOM through its assigned format templates (as normal rendering would)
but returns the result as a string — useful when the HTML has to go into a variable or a JSON field
rather than straight to the output.

### Check DOM empty

```
$CMS_IF(!st_text.isEmpty)$
  $CMS_VALUE(st_text)$
$CMS_END_IF$
```

---

## Media and References

### Image from Media Store

```
<img src="$CMS_REF(media:"image_uid")$" alt="description">
```

### Image with resolution

```
<img src="$CMS_REF(media:"image_uid", res:"SCALED")$" alt="description">
```

### Image with language

```
<img src="$CMS_REF(media:"image_uid", lang:"EN")$" alt="description">
```

### Page reference link

```
<a href="$CMS_REF(pageref:"detail_page")$">More</a>
```

### Page folder link (start page of folder)

```
<a href="$CMS_REF(pagefolder:"root")$">Home</a>
```

### Absolute URL

```
$CMS_REF(pageref:"detail_page", abs:1)$
```

### Content projection (dataset in multiple pages)

```
$CMS_REF(pageref:"data_source", contentId:374)$
```

### Remote project reference

```
$CMS_REF(pageref:"page_uid", remote:"remoteproject")$
```

### Alternate template set (e.g. print)

```
$CMS_REF(#global.node, templateSet:"print")$
```

### Set URL prefix for absolute links

```
$CMS_SET(#global.urlCreator.urlPrefix, "https://www.example.com")$
```
