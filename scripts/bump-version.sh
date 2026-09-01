#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG="$REPO_ROOT/.version-bump.json"

usage() {
  echo "Usage:"
  echo "  $0 <new-version>  — bump all tracked manifest versions"
  echo "  $0 --check        — report all versions; exit 1 on drift"
  echo "  $0 --audit        — grep repo for undeclared version strings"
}

# Convert dot-path like "plugins.0.version" to jq path ".plugins[0].version"
to_jq_path() {
  echo ".$1" | sed 's/\.\([0-9][0-9]*\)/[\1]/g'
}

get_version() {
  local file="$1" field="$2"
  local jq_path
  jq_path="$(to_jq_path "$field")"
  jq -r "$jq_path" "$REPO_ROOT/$file" 2>/dev/null || echo "NOT_FOUND"
}

set_version() {
  local file="$1" field="$2" new_ver="$3"
  local jq_path tmp
  jq_path="$(to_jq_path "$field")"
  tmp="$(mktemp)"
  jq "$jq_path = \"$new_ver\"" "$REPO_ROOT/$file" > "$tmp"
  mv "$tmp" "$REPO_ROOT/$file"
}

CMD="${1:-}"

case "$CMD" in
  --check)
    echo "Checking version consistency..."
    first_ver=""
    drift=0
    while IFS= read -r entry; do
      file="$(echo "$entry" | jq -r '.path')"
      field="$(echo "$entry" | jq -r '.field')"
      ver="$(get_version "$file" "$field")"
      printf "  %-45s %s\n" "$file ($field)" "$ver"
      if [ -z "$first_ver" ]; then
        first_ver="$ver"
      elif [ "$ver" != "$first_ver" ]; then
        echo "  ERROR: drift in $file — expected $first_ver, got $ver"
        drift=1
      fi
    done < <(jq -c '.files[]' "$CONFIG")
    if [ "$drift" -eq 0 ]; then
      echo "All versions consistent: $first_ver"
    else
      exit 1
    fi
    ;;

  --audit)
    current_ver="$(jq -r '.version' "$REPO_ROOT/package.json")"
    echo "Auditing for undeclared occurrences of $current_ver..."
    mapfile -t excludes < <(jq -r '.audit.exclude[]' "$CONFIG")
    exclude_args=()
    for exc in "${excludes[@]}"; do
      exclude_args+=(--exclude-dir="$exc" --exclude="$exc")
    done
    grep -r "$current_ver" "$REPO_ROOT" \
      "${exclude_args[@]}" \
      --include="*.json" --include="*.yaml" --include="*.yml" \
      --include="*.md" \
      -l 2>/dev/null || echo "No undeclared occurrences found."
    ;;

  ""|--*)
    usage
    exit 1
    ;;

  *)
    NEW_VER="$CMD"
    echo "Bumping all versions to $NEW_VER..."
    while IFS= read -r entry; do
      file="$(echo "$entry" | jq -r '.path')"
      field="$(echo "$entry" | jq -r '.field')"
      set_version "$file" "$field" "$NEW_VER"
      echo "  Updated $file ($field) → $NEW_VER"
    done < <(jq -c '.files[]' "$CONFIG")
    echo "Done. Verify with: ./scripts/bump-version.sh --check"
    ;;
esac
