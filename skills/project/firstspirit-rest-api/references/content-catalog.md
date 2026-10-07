# FS_CATALOG — Cards via REST API

FS_CATALOG is the most complex editor type. It stores an ordered list of "cards", each based on a section template with its own nested form.

## The One Rule: GET → jq → PATCH

**Build FS_CATALOG PATCH payloads from the GET response, never by hand.** Every card needs `id` and `templateUid`; every nested editor needs `name`, `type` and a `content` of the right shape. `configuration`, `description` and `language` are ignored on write; FS_REFERENCE content needs only `{"uid":"…","uidType":"…"}` (or `{"empty":true}`) `[core]` (module source `0.0.23-beta` to `0.0.25-beta`). A malformed `content` answers `400 Invalid content for editor …`; a `null` value on an option editor (RADIOBUTTON / COMBOBOX) answers `500`. The content shapes are the hard part, and the GET response already has them right.

The only reliable method:
1. **GET** the full editor response
2. **Mutate** with `jq` (change only the fields you need)
3. **PATCH** the modified GET response back

This works because the API accepts its own GET output as valid PATCH input.

> **Link-template cards.** A card of a *link catalogue* (cards based on a link template) answered
> `404 "Section template … not found"` `[observed]`: the catalog endpoints look the card up as
> a section template. Treat link-template cards as not editable over REST in the tested
> version; edit them in the client.

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

Only a few fields are required, and the GET response already has them `[core]` (module source `0.0.23-beta` to `0.0.25-beta`):

| Field | Required | What happens if missing |
|-------|----------|------------------------|
| `name`, `type` (top level and on every nested editor) | Yes | top level: `400 Malformed request body` from `0.0.24-beta` (`500` before); inside a card: `400 Invalid content for editor …` |
| `id`, `templateUid` (on every card) | Yes | `400`; an unknown `templateUid` on a new card → `404 Section template … not found` |
| `uid` + `uidType` (non-empty FS_REFERENCE content) | Yes | `400 … requires a valid 'uidType'` |
| `configuration`, `description`, `language`, `empty`, `storeType`, `medium` | No | ignored on write (`empty` defaults to `false`; `storeType`, `medium`, `language` are output-only) |

What goes wrong by hand is the `content` shape (card list, option objects, reference objects), not missing metadata. Earlier versions of this page quoted a `500 "parameter configuration specified as non-null is null"`; that message came from a build before the module's first tagged release and no tagged source produces it.

## Common Mistakes

| Mistake | Result | Fix |
|---------|--------|-----|
| Manually constructing PATCH JSON | Various 500/400 errors | Always use GET → jq → PATCH |
| Lowercase language codes (`en`) | 404 "Unable to find language" | Use UPPERCASE: `EN`, `FR`, `DE` |
| Omitting `/{LANG}` suffix for language-dependent catalog | Returns/writes wrong data | Check `usesLanguages` in configuration |
| Missing card `id` | 400 error | Existing cards: keep ID from GET. New cards: `uuidgen` |
| PATCH with empty `content: []` | Deletes all cards | Always GET first to preserve existing cards |
| Sending only changed cards | Unchanged cards are deleted | Always send ALL cards in `content` array |
| `null` as `content` of a RADIOBUTTON / COMBOBOX inside a card | 500 error | Send an option `{"key":…,"value":…}` or keep the value from GET `[core]` |
