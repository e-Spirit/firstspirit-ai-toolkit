#!/usr/bin/env bash
# smoke-test.sh — verify this skill's claims against a live FirstSpirit REST API.
#
# Every probe corresponds to a statement in SKILL.md or references/ (the "claim"
# column). A FAIL means the server behaves differently from what the skill says —
# either the skill is wrong for your FirstSpirit version, or the server is. Both are
# worth reporting (see the Feedback section of SKILL.md).
#
# Usage:
#   scripts/smoke-test.sh                 read-only probes (safe on any project)
#   scripts/smoke-test.sh --write         + creates a throwaway page, patches it, deletes it
#   scripts/smoke-test.sh --scripts       + creates a throwaway script, exercises /execute, deletes it
#   scripts/smoke-test.sh --all           everything
#   scripts/smoke-test.sh --env path/.env use another env file (default ./.env)
#
# Needs: curl, jq. Reads FS_USERNAME, FS_PASSWORD, FS_REST_BASE_URL, FS_PROJECT_ID
# from .env. Optional overrides (else auto-discovered from the project):
#   FS_TEST_PAGE            uid of an existing page with at least one section
#   FS_TEST_PAGE_TEMPLATE   uid of a page template the throwaway page is created from
#   FS_TEST_SECTION_TEMPLATE uid of a section template for the throwaway section
#
# Raw responses land in ./tmp/smoke/<run>/ (numbered) with requests.log — attach
# the folder when you report a FAIL. Exit code 1 if anything failed.
#
# O1 keeps a normalised copy of the server's OpenAPI spec per host under
# ./internal/openapi/<host>/ (override: FS_OPENAPI_SNAPSHOTS) and WARNs with a
# diff (<run>.diff.md) when the surface changed since the last run — the early
# warning that a skill section may be stale. dev/claim-coverage.md maps probes
# and OpenAPI paths to skill sections.

set -u

DO_WRITE=0; DO_SCRIPTS=0; ENV_FILE=".env"
while [ $# -gt 0 ]; do
  case "$1" in
    --write)   DO_WRITE=1 ;;
    --scripts) DO_SCRIPTS=1 ;;
    --all)     DO_WRITE=1; DO_SCRIPTS=1 ;;
    --env)     shift; ENV_FILE="${1:?--env needs a path}" ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

for tool in curl jq; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 2; }
done

# ---- result bookkeeping ------------------------------------------------------
PASS=0; FAIL=0; SKIP=0; WARN=0
pass() { PASS=$((PASS+1)); printf '  PASS  %-5s %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL+1)); printf '  FAIL  %-5s %s\n            -> %s\n' "$1" "$2" "$3"; }
skip() { SKIP=$((SKIP+1)); printf '  SKIP  %-5s %s\n            -> %s\n' "$1" "$2" "$3"; }
warn() { WARN=$((WARN+1)); printf '  WARN  %-5s %s\n            -> %s\n' "$1" "$2" "$3"; }   # server changed, skill may be stale; not a failure
say()  { printf '\n%s\n' "$1"; }

# ---- .env: the §4.8 check happens BEFORE sourcing ----------------------------
say "Environment ($ENV_FILE)"
[ -f "$ENV_FILE" ] || { echo "no $ENV_FILE — see SKILL.md → Setup" >&2; exit 2; }

# Rule (SKILL.md Setup): a value starting with `$` must be single-quoted, or `source`
# expands it to empty and every call 401s with a misleading message.
if grep -qE '^[[:space:]]*(export[[:space:]]+)?FS_[A-Z_]+=("?\$|[^'"'"'"][^=]*\$)' "$ENV_FILE"; then
  fail E1 "values containing \$ are single-quoted in .env" \
       "$(grep -nE '^[[:space:]]*(export[[:space:]]+)?FS_[A-Z_]+=' "$ENV_FILE" | grep -E '\$' | sed -E 's/=.*/=…/' | tr '\n' ' ')— wrap the value in single quotes"
else
  pass E1 "no unquoted \$ in .env values"
fi

# shellcheck disable=SC1090
set -a; set +u; . "$ENV_FILE"; set -u; set +a   # +u: a mis-quoted $ must not abort, E1 already said why
for v in FS_USERNAME FS_PASSWORD FS_REST_BASE_URL FS_PROJECT_ID; do
  [ -n "${!v:-}" ] || { echo "$v is empty after sourcing $ENV_FILE" >&2; exit 2; }
done
FS_REST_BASE_URL="${FS_REST_BASE_URL%/}"

RUN="$(date +%Y%m%d-%H%M%S)"
OUT="./tmp/smoke/$RUN"; mkdir -p "$OUT"
LOG="$OUT/requests.log"; : > "$LOG"
N=0
P="$FS_REST_BASE_URL/projects/$FS_PROJECT_ID"

# req METHOD URL [content-type] [datafile]  -> STATUS, BODY (path of response body)
req() {
  local m="$1" u="$2" ct="${3:-}" data="${4:-}"
  N=$((N+1)); BODY="$OUT/$(printf '%03d' "$N").body"
  local args=(-s -u "$FS_USERNAME:$FS_PASSWORD" -X "$m" -o "$BODY" -w '%{http_code}')
  [ -n "$ct" ]   && args+=(-H "Content-Type: $ct")
  [ -n "$data" ] && args+=(--data-binary "@$data")
  STATUS="$(curl "${args[@]}" "$u" 2>>"$LOG" || echo 000)"
  printf '%03d  %-6s %s  -> %s\n' "$N" "$m" "${u#"$FS_REST_BASE_URL"}" "$STATUS" >> "$LOG"
}
jqr() { jq -r "$1" "$BODY" 2>/dev/null; }          # jq on the last body, empty on error
is2xx() { case "$STATUS" in 2??) return 0 ;; *) return 1 ;; esac; }
keys() { jq -c 'if type=="object" then keys else type end' "$BODY" 2>/dev/null | cut -c1-120; }

# ---- Read-only probes --------------------------------------------------------
say "Read-only probes  (project $FS_PROJECT_ID @ $FS_REST_BASE_URL)"

# R1 — authentication / reachability
req GET "$FS_REST_BASE_URL/projects/"
if is2xx; then pass R1 "GET /projects/ authenticates (HTTP $STATUS)"
elif [ "$STATUS" = 401 ]; then fail R1 "GET /projects/ authenticates" "401 — wrong credentials, or the .env quoting trap (see E1)"
else fail R1 "GET /projects/ reachable" "HTTP $STATUS (000 = no connection)"; fi

# R2 — the /rest/v1 vs /rest/v3/api-docs claim
case "$FS_REST_BASE_URL" in
  */rest/v1) pass R2a "FS_REST_BASE_URL ends in /rest/v1" ;;
  *)         fail R2a "FS_REST_BASE_URL ends in /rest/v1" "is '$FS_REST_BASE_URL' — v3 is only the OpenAPI group name" ;;
esac
req GET "${FS_REST_BASE_URL%/rest/v1}/rest/v3/api-docs"
if is2xx && [ -n "$(jqr '.openapi // .swagger')" ]; then pass R2b "OpenAPI spec served at /rest/v3/api-docs (openapi $(jqr '.openapi // .swagger'))"
else skip R2b "OpenAPI spec at /rest/v3/api-docs" "HTTP $STATUS — spec endpoint may be disabled; not a skill error"; fi

# O1 — OpenAPI snapshot diff. The API is beta and moves between module versions; every other
# probe checks one claim, this one checks whether the SURFACE changed at all since the last run
# against this host. Normalised spec (sorted keys) is kept per host under $SNAP_DIR; a new file
# is written only when it differs from the newest one there. Changes are WARN, not FAIL: the
# server moved, the skill may be stale — re-read the affected sections.
SNAP_DIR="${FS_OPENAPI_SNAPSHOTS:-./internal/openapi}"
if is2xx && [ -n "$(jqr '.openapi // .swagger')" ]; then
  HOST="$(printf '%s' "$FS_REST_BASE_URL" | sed -E 's#^[a-z]+://##; s#[/:].*##')"
  SNAP_HOST="$SNAP_DIR/$HOST"; mkdir -p "$SNAP_HOST"
  NEW="$OUT/openapi.json"; jq -S . "$BODY" > "$NEW"
  API_VERSION="$(jq -r '.info.version // ("openapi " + .openapi)' "$NEW")"   # the spec carries no module version (0.0.23-beta)
  N_PATHS="$(jq '.paths | length' "$NEW")"
  PREV="$(ls -1 "$SNAP_HOST"/*.json 2>/dev/null | sort | tail -1)"
  if [ -z "$PREV" ]; then
    cp "$NEW" "$SNAP_HOST/$RUN.json"
    pass O1 "OpenAPI snapshot recorded for $HOST ($API_VERSION, $N_PATHS paths) → ${SNAP_HOST#./}/$RUN.json"
  elif cmp -s "$PREV" "$NEW"; then
    pass O1 "OpenAPI surface unchanged since $(basename "$PREV" .json) ($API_VERSION, $N_PATHS paths)"
  else
    # operations = "METHOD /path" lines; changed = same path, different definition
    ops() { jq -r '.paths | to_entries[] | .key as $p | .value | keys[] | select(test("^(get|put|post|patch|delete|head|options)$")) | ascii_upcase + " " + $p' "$1" | sort; }
    ops "$PREV" > "$OUT/openapi-prev.ops"; ops "$NEW" > "$OUT/openapi-new.ops"
    ADDED="$(comm -13 "$OUT/openapi-prev.ops" "$OUT/openapi-new.ops")"
    REMOVED="$(comm -23 "$OUT/openapi-prev.ops" "$OUT/openapi-new.ops")"
    CHANGED="$(jq -rn --slurpfile a "$PREV" --slurpfile b "$NEW" \
      '[ ($a[0].paths | keys[]) as $k | select($b[0].paths[$k] != null and $a[0].paths[$k] != $b[0].paths[$k]) | $k ] | .[]')"
    SCHEMAS="$(jq -rn --slurpfile a "$PREV" --slurpfile b "$NEW" \
      '(($a[0].components.schemas // {}) | keys) as $ka | (($b[0].components.schemas // {}) | keys) as $kb
       | [ ($kb - $ka | .[] | "+" + .), ($ka - $kb | .[] | "-" + .),
           ( ($ka - ($ka - $kb))[] | select($a[0].components.schemas[.] != $b[0].components.schemas[.]) | "~" + . ) ] | .[]')"
    cp "$NEW" "$SNAP_HOST/$RUN.json"
    { echo "# OpenAPI diff $HOST: $(basename "$PREV" .json) → $RUN ($API_VERSION)"
      echo "## added operations";   printf '%s\n' "$ADDED"
      echo "## removed operations"; printf '%s\n' "$REMOVED"
      echo "## changed paths";      printf '%s\n' "$CHANGED"
      echo "## schemas (+ new, - gone, ~ changed)"; printf '%s\n' "$SCHEMAS"
    } > "$SNAP_HOST/$RUN.diff.md"
    warn O1 "OpenAPI surface CHANGED since $(basename "$PREV" .json) ($API_VERSION): +$(printf '%s' "$ADDED" | grep -c .) ops, -$(printf '%s' "$REMOVED" | grep -c .) ops, ~$(printf '%s' "$CHANGED" | grep -c .) paths, $(printf '%s' "$SCHEMAS" | grep -c .) schema deltas" \
      "details in ${SNAP_HOST#./}/$RUN.diff.md — check the skill sections for the listed paths (dev/claim-coverage.md maps paths → sections)"
  fi
else
  skip O1 "OpenAPI snapshot diff" "no spec body to snapshot (see R2b)"
fi

# R3 — languages are listed, abbreviations UPPERCASE
req GET "$P/languages/"
LANGS="$(jqr 'if type=="array" then .[] else .content[] end | .abbreviation' | tr '\n' ' ')"
if is2xx && [ -n "$LANGS" ]; then
  if [ "$LANGS" = "$(echo "$LANGS" | tr '[:lower:]' '[:upper:]')" ]; then pass R3 "languages listed, abbreviations uppercase: $LANGS"
  else fail R3 "language abbreviations are UPPERCASE" "got: $LANGS"; fi
else fail R3 "GET /languages/ lists languages" "HTTP $STATUS, keys $(keys)"; fi
MASTER="$(jqr 'if type=="array" then .[] else .content[] end | select(.masterLanguage==true) | .abbreviation' | head -1)"
[ -n "$MASTER" ] || MASTER="$(echo "$LANGS" | awk '{print $1}')"

# R4 — template listings are a bare array (use .[] not .content[])
req GET "$P/templates/section-templates/"
if is2xx && [ "$(jqr type)" = array ]; then pass R4 "GET /templates/section-templates/ is a bare JSON array ($(jqr length) items)"
else fail R4 "template listing is a bare array (Pagination → Exception)" "HTTP $STATUS, shape $(keys)"; fi
# Prefer a standalone text-bearing section (has a top-level CMS_INPUT_TEXT) over a catalog
# `_item` child, so the round-trip probe W4 has a text field to write.
SECTION_TEMPLATE="${FS_TEST_SECTION_TEMPLATE:-$(jqr '
  [.[]?.uid] as $u
  | ( [ $u[] | select(.=="text") ]
      + [ $u[] | select(.=="teaser") ]
      + [ $u[] | select((test("(?i)_item$")|not) and test("(?i)text|teaser|intro|copy|content|headline")) ]
      + [ $u[] | select(test("(?i)_item$")|not) ]
      + $u ) | .[0] // empty')}"
req GET "$P/templates/page-templates/"
# Prefer a standard content page (exact match first); avoid settings/metadata/config shells that
# create a page with no body and no page-form text editor (which strands W3/W4).
PAGE_TEMPLATE="${FS_TEST_PAGE_TEMPLATE:-$(jqr '
  [.[]?.uid] as $u
  | ( [ $u[] | select(.=="standard" or .=="content" or .=="default" or .=="homepage") ]
      + [ $u[] | select(test("(?i)standard|content|default|homepage|basic|article|landing")) ]
      + [ $u[] | select(test("(?i)metadata|setting|config|footer|header|mapping|projection")|not) ]
      + $u ) | .[0] // empty')}"

# R5 — listing endpoints are a bare array (0.0.23-beta); ?page/size ignored
req GET "$P/pages/?page=0&size=5"
if is2xx && [ "$(jqr type)" = array ]; then
  N_ALL="$(jqr length)"
  if [ "$N_ALL" -gt 5 ] 2>/dev/null; then pass R5 "GET /pages/ is a bare array; ?size=5 ignored (returned $N_ALL)"
  else pass R5 "GET /pages/ is a bare array ($N_ALL items)"; fi
elif is2xx && [ -n "$(jqr '.content? // empty')" ]; then
  fail R5 "GET /pages/ is a bare array (0.0.23-beta)" "got PaginatedResponse {content,…} — the server now paginates listings; revert the Pagination section"
else fail R5 "GET /pages/ lists pages" "HTTP $STATUS, shape $(keys)"; fi
PAGE_UIDS="$(jqr 'if type=="array" then .[].uid else .content[].uid end' 2>/dev/null | head -15)"
PAGE="${FS_TEST_PAGE:-$(printf '%s\n' "$PAGE_UIDS" | head -1)}"

# R5b — /search is the one paginated endpoint (PaginatedResponse, honours page/size)
req GET "$P/search?q=e&page=0&size=3"
if is2xx && [ "$(jqr '.content|type')" = array ]; then pass R5b "GET /search returns PaginatedResponse (pageSize $(jqr .pageSize), hasNext $(jqr .hasNext))"
elif is2xx; then fail R5b "GET /search returns PaginatedResponse {content,pageNumber,pageSize,hasNext}" "HTTP $STATUS, shape $(keys) — search pagination changed"
else skip R5b "GET /search pagination" "HTTP $STATUS (query may need different params on this server)"; fi

# R6 — page → bodies → section → form ({editors:[…]}). Scan candidate pages for one that actually
# has a body + section: headless / data / ODFS pages legitimately have empty bodies ([], HTTP 200),
# so "no content page found" is a SKIP, not a FAIL.
BODYNAME=""; SECTION=""; EDITOR=""; EDITOR_LANGDEP=""
CANDIDATES="$PAGE_UIDS"; [ -n "${FS_TEST_PAGE:-}" ] && CANDIDATES="$FS_TEST_PAGE"
FOUND_PAGE=""; N_CAND=0
for cand in $CANDIDATES; do
  [ -n "$cand" ] || continue
  N_CAND=$((N_CAND+1))
  req GET "$P/pages/$cand/bodies/"; is2xx || continue
  bn="$(jqr 'if type=="array" then .[] else (.content[]?) end | .name // .uid // empty' | head -1)"
  [ -n "$bn" ] || continue
  req GET "$P/pages/$cand/bodies/$bn"
  sec="$(jqr '(.sections // .content // .children // [])[0] | .name // .uid // empty')"
  [ -n "$sec" ] || continue
  FOUND_PAGE="$cand"; BODYNAME="$bn"; SECTION="$sec"; break
done
if [ -z "$FOUND_PAGE" ]; then
  skip R6 "page/bodies/section/form chain" "no page with a body+section in $N_CAND candidate(s) (headless/data/ODFS project?) — set FS_TEST_PAGE to a content page"
else
  PAGE="$FOUND_PAGE"
  req GET "$P/pages/$PAGE/bodies/$BODYNAME/sections/$SECTION/form"
  if is2xx && [ "$(jqr '.editors | type')" = array ]; then
    pass R6 "section form is {editors:[…]} ($(jqr '.editors|length') editors on $PAGE/$BODYNAME/$SECTION)"
    EDITOR="$(jqr '[.editors[] | select(.type=="CMS_INPUT_TEXT" or .type=="CMS_INPUT_TEXTAREA")][0].name // .editors[0].name // empty')"
  else
    fail R6 "section form is {editors:[…]}" "HTTP $STATUS, shape $(keys)"
  fi
fi

# R7 — a single editor GET is a flat FormEditorDTO carrying the PATCH prerequisites
if [ -z "$EDITOR" ]; then
  skip R7 "single-editor DTO has configuration/description/language" "no editor discovered (see R6)"
else
  req GET "$P/pages/$PAGE/bodies/$BODYNAME/sections/$SECTION/form/$EDITOR"
  MISSING="$(jqr '[ "name","type","configuration","content","description","language" ] - keys | join(",")')"
  if is2xx && [ -z "$MISSING" ]; then
    pass R7 "GET …/form/$EDITOR is a flat FormEditorDTO with all PATCH-required keys"
  elif is2xx; then
    # A language-dependent editor without /{LANG} may legitimately come back different — R8 tells.
    skip R7 "GET …/form/$EDITOR is a flat FormEditorDTO" "HTTP $STATUS, missing keys: $MISSING (keys $(keys))"
  else fail R7 "GET …/form/$EDITOR" "HTTP $STATUS"; fi
  EDITOR_LANGDEP="$(jqr '.configuration.usesLanguages // empty')"
fi

# R8 — language suffix: UPPERCASE works, lowercase 404s
if [ -z "$EDITOR" ] || [ -z "$MASTER" ]; then
  skip R8 "/{LANG} suffix uppercase vs lowercase" "needs an editor and a language"
else
  req GET "$P/pages/$PAGE/bodies/$BODYNAME/sections/$SECTION/form/$EDITOR/$MASTER"; UP="$STATUS"
  req GET "$P/pages/$PAGE/bodies/$BODYNAME/sections/$SECTION/form/$EDITOR/$(echo "$MASTER" | tr '[:upper:]' '[:lower:]')"; LOW="$STATUS"
  if [ "$UP" = 200 ] && [ "$LOW" = 404 ]; then pass R8 "…/form/$EDITOR/$MASTER → 200, lowercase → 404 (usesLanguages=${EDITOR_LANGDEP:-?})"
  elif [ "$UP" = 200 ] && [ "$LOW" = 200 ]; then fail R8 "lowercase language code returns 404" "both cases returned 200 — the UPPERCASE rule is softer than documented on this server"
  else skip R8 "…/form/$EDITOR/{LANG}" "uppercase → $UP, lowercase → $LOW (usesLanguages=${EDITOR_LANGDEP:-?}); language-independent editors may reject any suffix"; fi
fi

# R9 — search/by-uid resolves the page
if [ -n "$PAGE" ]; then
  req GET "$P/search/by-uid?uid=$PAGE&type=PAGESTORE"
  if is2xx; then pass R9 "GET /search/by-uid?uid=$PAGE&type=PAGESTORE → $STATUS"
  else fail R9 "search/by-uid finds the page" "HTTP $STATUS — check the uidType spelling in search-and-discovery.md"; fi
fi

# R10 — MediaStore enumeration (documented: 200 since 0.0.23-beta, was 405)
req GET "$P/media/?type=PICTURE"
if is2xx && [ "$(jqr type)" = array ]; then pass R10 "GET /media/?type=PICTURE enumerates ($(jqr length) pictures, first location: $(jqr '.[0].location // "-"'))"
elif [ "$STATUS" = 405 ]; then fail R10 "GET /media/ enumerates (≥ 0.0.23-beta)" "405 — REST module older than 0.0.23-beta; the skill documents this as fixed"
else fail R10 "GET /media/?type=PICTURE" "HTTP $STATUS, shape $(keys)"; fi

# R11 — datasets live directly under the data-source; the old /datasets/ segment is gone
req GET "$P/data-sources/"
DS="$(jqr 'if type=="array" then .[0].uid else .content[0].uid end // empty')"
if ! is2xx; then fail R11 "GET /data-sources/ lists data sources" "HTTP $STATUS"
elif [ -z "$DS" ]; then skip R11 "dataset path layout" "project has no data sources"
else
  req GET "$P/data-sources/$DS/"; NEWP="$STATUS"
  req GET "$P/data-sources/$DS/datasets/"; OLDP="$STATUS"
  if [ "$NEWP" = 200 ] && [ "$OLDP" = 404 ]; then pass R11 "datasets at /data-sources/$DS/ (200); legacy /datasets/ → 404"
  else fail R11 "datasets addressed directly under the data-source" "/data-sources/$DS/ → $NEWP, …/datasets/ → $OLDP"; fi
fi

# ---- Write probes (throwaway page) -------------------------------------------
if [ "$DO_WRITE" = 1 ]; then
  say "Write probes  (throwaway page, deleted at the end)"
  TS="$(date +%s)"; TPAGE="smoketest_$TS"; CREATED_PAGE=""
  cleanup_page() {
    [ -n "$CREATED_PAGE" ] || return 0
    req DELETE "$P/pages/$CREATED_PAGE"
    req GET "$P/pages/$CREATED_PAGE"
    if [ "$STATUS" = 404 ]; then pass W9 "DELETE /pages/$CREATED_PAGE, then GET → 404"
    else fail W9 "throwaway page deleted" "GET after DELETE → $STATUS — remove page '$CREATED_PAGE' by hand"; fi
    CREATED_PAGE=""
  }
  trap cleanup_page EXIT

  if [ -z "$PAGE_TEMPLATE" ]; then
    skip W1 "create page" "no page template found — set FS_TEST_PAGE_TEMPLATE"
  else
    printf '{"uid":"%s","templateUid":"%s"}' "$TPAGE" "$PAGE_TEMPLATE" > "$OUT/create-page.json"
    req POST "$P/pages/" application/json "$OUT/create-page.json"
    NEWID="$(jqr '.id // empty')"
    if is2xx && [ -n "$NEWID" ]; then
      CREATED_PAGE="$TPAGE"; pass W1 "POST /pages/ {uid,templateUid:$PAGE_TEMPLATE} → $STATUS, id $NEWID"
    elif is2xx; then CREATED_PAGE="$TPAGE"; fail W1 "create-page response includes numeric id" "HTTP $STATUS but no .id (keys $(keys))"
    else fail W1 "POST /pages/ creates a page" "HTTP $STATUS: $(head -c 200 "$BODY")"; fi
  fi

  if [ -n "$CREATED_PAGE" ]; then
    # W2 — /rename takes RenameRequestDTO {name,language} and sets the DISPLAY NAME, not the uid.
    # {uid} must be rejected; the uid must survive; the display name must change.
    printf '{"name":"Smoke %s","language":"%s"}' "$TS" "$MASTER" > "$OUT/rename-name.json"
    req PATCH "$P/pages/$CREATED_PAGE/rename" application/json "$OUT/rename-name.json"; RN="$STATUS"
    printf '{"uid":"%s_r"}' "$TPAGE" > "$OUT/rename-uid.json"
    req PATCH "$P/pages/$CREATED_PAGE/rename" application/json "$OUT/rename-uid.json"; RU="$STATUS"
    req GET "$P/pages/$CREATED_PAGE"; STILL="$STATUS"
    DN="$(jqr '.displayNames // {} | to_entries[0].value // empty')"
    if [ "${RN:0:1}" = 2 ] && [ "${RU:0:1}" != 2 ] && [ "$STILL" = 200 ]; then
      pass W2 "PATCH /rename: {name,language} → $RN (displayName now \"$DN\"), {uid} → $RU (rejected), uid unchanged"
    elif [ "${RN:0:1}" = 2 ] && [ "${RU:0:1}" = 2 ]; then
      fail W2 "/rename must reject {uid} (wants {name,language})" "{uid} was accepted ($RU) — the DTO is looser than documented on this server"
    else
      fail W2 "/rename {name,language} sets display name, uid unchanged" "{name,language} → $RN, {uid} → $RU, GET by original uid → $STILL"
    fi

    # W3 — add a section
    req GET "$P/pages/$CREATED_PAGE/bodies/"
    TBODY="$(jqr 'if type=="array" then .[0] else .content[0] end | .name // .uid // empty')"
    if [ -z "$TBODY" ] || [ -z "$SECTION_TEMPLATE" ]; then
      skip W3 "PUT …/sections/{name} adds a section" "body '$TBODY' / section template '$SECTION_TEMPLATE' missing"
    else
      printf '{"templateUid":"%s"}' "$SECTION_TEMPLATE" > "$OUT/add-section.json"
      req PUT "$P/pages/$CREATED_PAGE/bodies/$TBODY/sections/smoke" application/json "$OUT/add-section.json"
      if is2xx; then pass W3 "PUT …/bodies/$TBODY/sections/smoke {templateUid:$SECTION_TEMPLATE} → $STATUS"
      else skip W3 "PUT …/sections/smoke" "HTTP $STATUS — template '$SECTION_TEMPLATE' may not be allowed in body '$TBODY'; set FS_TEST_SECTION_TEMPLATE"; fi
    fi

    # W4–W7 — GET → jq → PATCH on a text editor. Look on the page form first, then in the section
    # added in W3, so a page template without page-level text editors doesn't skip the round trip.
    FBASE="$P/pages/$CREATED_PAGE/form"
    req GET "$FBASE"
    TEDITOR="$(jqr '[.editors[]? | select(.type=="CMS_INPUT_TEXT" or .type=="CMS_INPUT_TEXTAREA")][0].name // empty')"
    if [ -z "$TEDITOR" ] && [ -n "${TBODY:-}" ]; then
      SFBASE="$P/pages/$CREATED_PAGE/bodies/$TBODY/sections/smoke/form"
      req GET "$SFBASE"
      TEDITOR="$(jqr '[.editors[]? | select(.type=="CMS_INPUT_TEXT" or .type=="CMS_INPUT_TEXTAREA")][0].name // empty')"
      [ -n "$TEDITOR" ] && FBASE="$SFBASE"
    fi
    if [ -z "$TEDITOR" ]; then
      skip W4 "GET→jq→PATCH round trip" "no CMS_INPUT_TEXT/TEXTAREA on the page form or the added section of $CREATED_PAGE — set FS_TEST_PAGE_TEMPLATE/FS_TEST_SECTION_TEMPLATE to ones with a text field"
    else
      req GET "$FBASE/$TEDITOR"
      SUFFIX=""; [ "$(jqr '.configuration.usesLanguages')" = true ] && SUFFIX="/$MASTER"
      [ -n "$SUFFIX" ] && req GET "$FBASE/$TEDITOR$SUFFIX"
      cp "$BODY" "$OUT/editor.json"
      # Rule 2: apostrophes and a newline must survive the file-based round trip.
      VALUE="smoke $TS — Ma'am's \"quoted\" Straße"$'\n'"second line"
      jq --arg v "$VALUE" '.content = $v' "$OUT/editor.json" > "$OUT/editor.patched.json"
      req PATCH "$FBASE/$TEDITOR$SUFFIX" application/json "$OUT/editor.patched.json"; PS="$STATUS"
      req GET "$FBASE/$TEDITOR$SUFFIX"
      if [ "${PS:0:1}" = 2 ] && [ "$(jqr .content)" = "$VALUE" ]; then
        pass W4 "GET→jq→PATCH on ${FBASE#"$P/"}/$TEDITOR$SUFFIX round-trips (apostrophes, quotes, umlaut, newline intact)"
      else fail W4 "GET→jq→PATCH round trip" "PATCH → $PS, read-back content: $(jqr .content | head -c 80)"; fi

      # Rule 1 (refined): the full DTO is required for FS_CATALOG/FS_REFERENCE, but a plain scalar
      # editor may ACCEPT a minimal {name,type,content} PATCH. This probe hits a scalar editor, so
      # either outcome is consistent with the skill — it records which, and never fails on accept.
      # (GET→jq→PATCH stays the universal advice regardless.)
      jq '{name,type,content}' "$OUT/editor.patched.json" > "$OUT/editor.minimal.json"
      req PATCH "$FBASE/$TEDITOR$SUFFIX" application/json "$OUT/editor.minimal.json"
      case "$STATUS" in
        4??|5??) pass W5 "minimal {name,type,content} PATCH rejected on scalar editor ($STATUS) — full DTO enforced" ;;
        2??)     pass W5 "minimal {name,type,content} PATCH accepted on scalar editor ($STATUS) — Rule 1 is scalar-lenient (still send full DTO; FS_CATALOG/FS_REFERENCE require it)" ;;
        *)       skip W5 "minimal-PATCH behaviour" "unexpected HTTP $STATUS" ;;
      esac

      # Rule 4: wrong Content-Type is rejected — 415 on some endpoints, 500 on /form/{editor}.
      # Either rejection is correct per the skill; a 2xx would mean it silently accepted text/plain.
      req PATCH "$FBASE/$TEDITOR$SUFFIX" text/plain "$OUT/editor.patched.json"
      case "$STATUS" in
        415)     pass W6 "PATCH Content-Type text/plain rejected → 415" ;;
        500)     pass W6 "PATCH Content-Type text/plain rejected → 500 (the /form/{editor} code, documented)" ;;
        4??|5??) pass W6 "PATCH Content-Type text/plain rejected → $STATUS" ;;
        *)       fail W6 "wrong Content-Type is rejected (Rule 4)" "got $STATUS — text/plain was accepted on a JSON editor" ;;
      esac
    fi

    # W7 — release dry-run through /actions
    printf '{"action":"release","options":{"checkOnly":true,"dependentReleaseType":"NO_DEPENDENT_RELEASE","ensureAccessibility":false,"recursive":false}}' > "$OUT/release-check.json"
    req POST "$P/pages/$CREATED_PAGE/actions" application/json "$OUT/release-check.json"
    if is2xx; then pass W7 "POST /actions {release, checkOnly:true} → $STATUS"
    else fail W7 "release dry-run via /actions" "HTTP $STATUS: $(head -c 160 "$BODY")"; fi
  fi
  cleanup_page; trap - EXIT
fi

# ---- Script probes (report §4.6 / §5.5) --------------------------------------
if [ "$DO_SCRIPTS" = 1 ]; then
  say "Script probes  (throwaway script, deleted at the end)"
  TS="${TS:-$(date +%s)}"; TSCRIPT="smoketest_$TS"; CREATED_SCRIPT=""
  cleanup_script() {
    [ -n "$CREATED_SCRIPT" ] || return 0
    req DELETE "$P/scripts/$CREATED_SCRIPT"
    if is2xx; then pass S6 "DELETE /scripts/$CREATED_SCRIPT → $STATUS"
    else fail S6 "throwaway script deleted" "HTTP $STATUS — remove script '$CREATED_SCRIPT' by hand"; fi
    CREATED_SCRIPT=""
  }
  trap cleanup_script EXIT

  req GET "$P/template-sets/"; TSET_STATUS="$STATUS"
  if is2xx; then
    TSET="$(jqr 'if type=="array" then .[0] else .content[0] end | .abbreviation // .uid // .name // empty')"
    pass S0 "GET /template-sets/ → $TSET_STATUS (using template set '${TSET:-none}')"
  else
    TSET=""
    fail S0 "GET /template-sets/ lists template sets" "HTTP $TSET_STATUS: $(head -c 160 "$BODY") — blocks the source-upload/execute probes S3–S5"
  fi

  # S1 — POST /scripts/ does not fully honour the create DTO (documented in SKILL.md → Scripts):
  # stored type comes back MENU regardless of what's sent, and description is dropped. This probe
  # asserts that DOCUMENTED behaviour; it fails only if the server starts honouring the DTO (good
  # news — update the skill) or does something else.
  printf '{"name":"%s","type":"TEMPLATE","location":"/","description":"smoke description","comment":"smoke comment"}' "$TSCRIPT" > "$OUT/create-script.json"
  req POST "$P/scripts/" application/json "$OUT/create-script.json"
  if is2xx; then
    CREATED_SCRIPT="$TSCRIPT"
    req GET "$P/scripts/$TSCRIPT"
    STYPE="$(jqr '.type // "?"')"; SDESC="$(jqr '.description // "null"')"
    if [ "$STYPE" = MENU ] && [ "$SDESC" = "null" ]; then
      pass S1 "POST /scripts/ ignores type/description as documented (stored type=MENU, description=null)"
    elif [ "$STYPE" = TEMPLATE ] && [ "$SDESC" = "smoke description" ]; then
      fail S1 "create-DTO handling changed (now honoured)" "stored type=$STYPE, description set — the server now honours the DTO; update SKILL.md → Scripts and this probe"
    else
      fail S1 "POST /scripts/ create-DTO behaviour" "expected type=MENU/description=null (documented); got type=$STYPE, description=$SDESC"
    fi
  else fail S1 "POST /scripts/ creates a script" "HTTP $STATUS: $(head -c 160 "$BODY")"; fi

  if [ -n "$CREATED_SCRIPT" ]; then
    # S2 — is there a PATCH on /scripts/{name}?
    printf '{"description":"patched"}' > "$OUT/patch-script.json"
    req PATCH "$P/scripts/$TSCRIPT" application/json "$OUT/patch-script.json"
    case "$STATUS" in
      2??) pass S2 "PATCH /scripts/{name} exists ($STATUS) — undocumented in the skill, add it" ;;
      405|404) pass S2 "PATCH /scripts/{name} not available ($STATUS) — consistent with the skill (no PATCH documented)" ;;
      *) skip S2 "PATCH /scripts/{name}" "HTTP $STATUS" ;;
    esac

    if [ -z "$TSET" ]; then
      skip S3 "script source / execute" "no usable template set (see S0 for the GET /template-sets/ status)"
    else
      # S3 — source upload (text/plain) + execute. The skill documents that /execute does NOT echo
      # the return value: a successful run answers 2xx with an EMPTY body (verify by read-back).
      # So the expected result is PUT 2xx + execute 2xx + empty body. If the value ("42") ever comes
      # back, that's a behaviour change — flag it so the skill can be updated.
      printf 'return 6 * 7;\n' > "$OUT/script-ok.bsh"
      req PUT "$P/scripts/$TSCRIPT/template-sets/$TSET" text/plain "$OUT/script-ok.bsh"; PUTS="$STATUS"
      printf '{}' > "$OUT/empty.json"
      req POST "$P/scripts/$TSCRIPT/execute" application/json "$OUT/empty.json"
      BODYSIZE="$(wc -c < "$BODY" | tr -d ' ')"
      if [ "${PUTS:0:1}" = 2 ] && is2xx && grep -q 42 "$BODY"; then
        fail S3 "/execute echoes the return value (behaviour changed)" "execute → $STATUS returned '42' — the empty-body behaviour documented in SKILL.md → Scripts no longer holds; update it"
      elif [ "${PUTS:0:1}" = 2 ] && is2xx; then
        pass S3 "PUT source + POST /execute → $STATUS with empty body ($BODYSIZE bytes) — matches the documented no-echo behaviour"
      else
        fail S3 "PUT …/template-sets/$TSET then POST /execute succeeds" "PUT → $PUTS, execute → $STATUS: $(head -c 120 "$BODY")"; fi

      # S4 — parse-probe: a syntax error surfaces as a parse error
      printf 'return 6 * ;\n' > "$OUT/script-bad.bsh"
      req PUT "$P/scripts/$TSCRIPT/template-sets/$TSET" text/plain "$OUT/script-bad.bsh"
      req POST "$P/scripts/$TSCRIPT/execute" application/json "$OUT/empty.json"
      if grep -qi 'parse' "$BODY"; then pass S4 "/execute surfaces BeanShell parse errors (cheap syntax probe)"
      else fail S4 "/execute reports parse errors (§5.5)" "HTTP $STATUS: $(head -c 120 "$BODY")"; fi

      # S5 — the REST execute context has no getElement()
      printf 'return context.getElement();\n' > "$OUT/script-elm.bsh"
      req PUT "$P/scripts/$TSCRIPT/template-sets/$TSET" text/plain "$OUT/script-elm.bsh"
      req POST "$P/scripts/$TSCRIPT/execute" application/json "$OUT/empty.json"
      if grep -qiE 'getElement|method' "$BODY"; then pass S5 "/execute context has no getElement() (error mentions it) — element-dependent scripts cannot be tested here"
      else skip S5 "/execute context lacks getElement()" "HTTP $STATUS: $(head -c 120 "$BODY") — record the context class if it worked"; fi
    fi
  fi
  cleanup_script; trap - EXIT
fi

# ---- Summary -----------------------------------------------------------------
say "Summary: $PASS passed, $FAIL failed, $SKIP skipped, $WARN warning(s) — responses in $OUT"
[ "$FAIL" -eq 0 ]
