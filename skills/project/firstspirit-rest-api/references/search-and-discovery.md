# Search & Discovery via REST API

## Table of Contents
- [Full-Text Search](#full-text-search)
- [Search by UID](#search-by-uid)
- [Search by ID](#search-by-id)
- [Find References](#find-references)
- [Browse Structure](#browse-structure)

---

## Full-Text Search

```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search?q=Headline&page=0&size=20"
```

Response (paginated):
```json
{
  "content": [
    {
      "id": 12345,
      "uid": "homepage",
      "type": "PAGE",
      "name": "Homepage",
      "storeType": "PAGESTORE"
    }
  ],
  "pageNumber": 0,
  "pageSize": 20,
  "hasNext": false
}
```

Iterate pages:
```bash
PAGE=0
while true; do
  RESULT=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
    "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search?q=text&page=$PAGE&size=50")
  echo "$RESULT" | jq '.content[]'
  HAS_NEXT=$(echo "$RESULT" | jq '.hasNext')
  [ "$HAS_NEXT" = "false" ] && break
  PAGE=$((PAGE + 1))
done
```

---

## Search by UID

Find elements by their unique identifier:
```bash
# Without type filter (returns all matches across stores)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search/by-uid?uid=homepage"

# With type filter
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search/by-uid?uid=homepage&type=PAGESTORE"
```

Valid `type` values: `PAGESTORE`, `SITESTORE`, `MEDIASTORE`, `TEMPLATESTORE`, `GLOBALSTORE`, `CONTENTSTORE`.

---

## Search by ID

Find element by numeric FirstSpirit ID:
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search/by-id/12345"
```

---

## Find References

### Invalid (Broken) References
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search/invalid-references?page=0&size=50"
```

### External References
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/search/external-references?page=0&size=50"
```

### Usages of a Specific Element
```bash
# Where is this page used?
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/homepage/usages"

# Where is this medium used?
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/media/logo/usages"
```

---

## Browse Structure

### Page Folders
```bash
# Root
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-folders/root"

# Subfolder (wildcard path)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-folders/root/subfolder"
```

### SiteStore Folders
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/page-reference-folders/root"
```

### Media Folders
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/medium-folders/root"
```

### List All Pages
```bash
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/"
```

### List All Templates
```bash
# Section templates
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/section-templates/"

# Page templates
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/page-templates/"
```

### Project Info
```bash
# Languages
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/languages/"

# Template sets
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/template-sets/"

# Resolutions (for media)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/resolutions"

# Schemas
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/templates/schemas/"
```

### Global Content
```bash
# GCA areas
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/global-content/"

# Project properties
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/global-content/project-properties"
```
