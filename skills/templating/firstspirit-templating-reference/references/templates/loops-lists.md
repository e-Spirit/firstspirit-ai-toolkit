# Templates: Loops and List Operations

---

## Loops

### Loop through range

```
$CMS_FOR(i, [1 .. 10])$
  Item $CMS_VALUE(i)$
$CMS_END_FOR$
```

### Loop through list

```
$CMS_FOR(item, myList)$
  Index $CMS_VALUE(#for.index)$: $CMS_VALUE(item)$
$CMS_END_FOR$
```

### Loop through map

```
$CMS_FOR(entry, {"key1" : "val1", "key2" : "val2"})$
  $CMS_VALUE(entry.key)$ = $CMS_VALUE(entry.value)$
$CMS_END_FOR$
```

### Loop properties

```
$CMS_VALUE(#for.index)$      $-- zero-based index --$
$CMS_VALUE(#for.isFirst)$    $-- true on first iteration --$
$CMS_VALUE(#for.isLast)$     $-- true on last iteration --$
$CMS_SET(void, #for.BREAK)$     $-- exit loop --$
$CMS_SET(void, #for.CONTINUE)$  $-- skip to next --$
```

### Table with first/last detection

```
$CMS_FOR(item, myList)$
  $CMS_IF(#for.isFirst)$<table>$CMS_END_IF$
  <tr><td>$CMS_VALUE(item)$</td></tr>
  $CMS_IF(#for.isLast)$</table>$CMS_END_IF$
$CMS_END_FOR$
```

---

## List Operations

### Access

```
$CMS_VALUE(myList[0])$          $-- by index --$
$CMS_VALUE(myList.get(2))$      $-- by index --$
$CMS_VALUE(myList.first)$       $-- first element --$
$CMS_VALUE(myList.last)$        $-- last element --$
$CMS_VALUE(myList.size)$        $-- count --$
$CMS_VALUE(myList.isEmpty)$     $-- boolean --$
```

### Transform

```
$CMS_VALUE(myList.sort)$                   $-- ascending --$
$CMS_VALUE(myList.sort.reverse)$           $-- descending --$
$CMS_VALUE(myList.reverse)$                $-- reverse order --$
$CMS_VALUE(myList.filter(x -> x.active))$  $-- filter by lambda --$
$CMS_VALUE(myList.map(x -> x.name))$       $-- transform --$
$CMS_VALUE(myList.distinct(x -> x.cat))$   $-- unique values --$
$CMS_VALUE(myList.subList(1, 4))$          $-- slice --$
$CMS_VALUE(myList.copy)$                   $-- shallow copy --$
```

### Aggregate

```
$CMS_VALUE(myList.max)$
$CMS_VALUE(myList.min)$
$CMS_VALUE(myList.contains("value"))$
$CMS_VALUE(myList.toString("; "))$              $-- join with separator --$
$CMS_VALUE(myList.toString(", ", "name"))$      $-- join attribute --$
```

### Modify

```
$CMS_SET(void, myList.add("new"))$          $-- append --$
$CMS_SET(void, myList.add(0, "first"))$     $-- insert at index --$
```
