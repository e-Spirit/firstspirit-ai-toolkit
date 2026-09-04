# FS_CATALOG — Cards via REST API

FS_CATALOG is the most complex editor type. It stores an ordered list of "cards", each based on a section template with its own nested form.

## The One Rule: GET → jq → PATCH

**NEVER manually construct an FS_CATALOG PATCH payload.** The API requires the **complete FormEditorDTO** structure for every nested editor — including `configuration` (with all sub-fields), `description`, `language`, and for FS_REFERENCE the full `content` object with `language`, `storeType`, `medium`, etc. Omitting any of these causes 500 "Unknown error" or JSON parse errors.

The only reliable method:
1. **GET** the full editor response
2. **Mutate** with `jq` (change only the fields you need)
3. **PATCH** the modified GET response back

This works because the API accepts its own GET output as valid PATCH input.

## Language Handling

- Project languages use **UPPERCASE** abbreviations: `EN`, `FR`, `DE` (not `en`, `fr`, `de`)
- If the FS_CATALOG has `usesLanguages: true`, append `/{LANG}` to **both** GET and PATCH URLs
- Check `GET .../form/{editor}` — if the response contains `"language": "EN"`, the catalog is language-dependent
- Always check project languages first: `GET /projects/{id}/languages/`

## Read FS_CATALOG

```bash
# Language-independent catalog
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/{catalogEditor}"

# Language-dependent catalog (usesLanguages: true)
curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/{catalogEditor}/EN"
```

## Write FS_CATALOG

### Update a card's text field

```bash
# 1. GET current state (use /EN suffix if language-dependent)
CURRENT=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN")

# 2. Mutate with jq — change only the content of specific editors
# Example: update st_headline and st_text of the 2nd card (index 1)
UPDATED=$(echo "$CURRENT" | jq '
  .content[1].item.editors[] |= (
    if .name == "st_headline" then .content = "New Headline"
    elif .name == "st_text" then .content = "New description text."
    else . end
  )
')

# 3. PATCH back (same URL suffix as GET)
echo "$UPDATED" | curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d @- \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN"
```

### Add a new card

```bash
CURRENT=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN")

NEW_ID=$(uuidgen)

# Copy structure from an existing card, then modify content
UPDATED=$(echo "$CURRENT" | jq --arg id "$NEW_ID" '
  # Clone the first card as template for the new one
  .content += [.content[0] | .id = $id |
    .item.editors[] |= (
      if .name == "st_headline" then .content = "New Card Title"
      elif .name == "st_text" then .content = "New card description."
      elif .type == "FS_REFERENCE" then .content.empty = true | del(.content.uid, .content.uidType, .content.medium, .content.language, .content.storeType)
      else . end
    )
  ]
')

echo "$UPDATED" | curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d @- \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN"
```

### Remove a card

```bash
CURRENT=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN")

# Remove card by id
UPDATED=$(echo "$CURRENT" | jq '
  .content |= map(select(.id != "the-uuid-to-remove"))
')

echo "$UPDATED" | curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d @- \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN"
```

### Reorder cards

```bash
CURRENT=$(curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN")

# Reverse order as example
UPDATED=$(echo "$CURRENT" | jq '.content |= reverse')

echo "$UPDATED" | curl -s -u "$FS_USERNAME:$FS_PASSWORD" \
  -X PATCH -H "Content-Type: application/json" \
  -d @- \
  "$FS_REST_BASE_URL/projects/$FS_PROJECT_ID/pages/{pageUid}/bodies/{body}/sections/{section}/form/st_cards/EN"
```

## Why Manual Construction Fails

The API's `FormEditorDTO` requires **non-null** fields that the GET response includes but are tedious to reconstruct:

| Field | Required | What happens if missing |
|-------|----------|------------------------|
| `name` (top-level) | Yes | 500: "Missing required creator property 'name'" |
| `configuration` (on every nested editor) | Yes, **non-null** | 500: "parameter configuration specified as non-null is null" |
| `configuration.templates` (on catalog itself) | Yes | 400 error |
| `empty` (in FS_REFERENCE content) | Yes | 500: "Missing required creator property 'empty'" |
| `language`, `storeType`, `medium` (in FS_REFERENCE) | Needed for non-empty refs | 400: "Reference DTO is not empty but does not define a reference" or 500 "Unknown error" |

Using the GET → jq → PATCH pattern avoids all of these issues because the GET response already contains every required field with correct values.

## Common Mistakes

| Mistake | Result | Fix |
|---------|--------|-----|
| Manually constructing PATCH JSON | Various 500/400 errors | Always use GET → jq → PATCH |
| Lowercase language codes (`en`) | 404 "Unable to find language" | Use UPPERCASE: `EN`, `FR`, `DE` |
| Omitting `/{LANG}` suffix for language-dependent catalog | Returns/writes wrong data | Check `usesLanguages` in configuration |
| Missing card `id` | 400 error | Existing cards: keep ID from GET. New cards: `uuidgen` |
| PATCH with empty `content: []` | Deletes all cards | Always GET first to preserve existing cards |
| Sending only changed cards | Unchanged cards are deleted | Always send ALL cards in `content` array |
| Using `configuration: {}` on inner editors | 500 error | Use GET → jq → PATCH (full configuration is preserved) |
