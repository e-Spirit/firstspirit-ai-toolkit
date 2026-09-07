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
  jq -re "$jq_path" "$REPO_ROOT/$file" 2>/dev/null || echo "NOT_FOUND"
}

set_version() {
  local file="$1" field="$2" new_ver="$3"
  local jq_path tmp
  jq_path="$(to_jq_path "$field")"
  tmp="$(mktemp)"
  jq --arg v "$new_ver" "$jq_path = \$v" "$REPO_ROOT/$file" > "$tmp"
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
    if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Error: --audit needs a git work tree, so it can tell tracked files" >&2
      echo "       from build output and local scratch directories." >&2
      exit 1
    fi
    current_ver="$(jq -r '.version' "$REPO_ROOT/package.json")"
    echo "Auditing for undeclared occurrences of $current_ver..."

    # Exclusions are git pathspecs, and the search runs over tracked files only.
    # The previous implementation used `grep -r` with --exclude/--include, and
    # every file exclusion was silently defeated:
    #
    #   1. BSD grep resolves --include and --exclude in command-line order, last
    #      match winning. The old code appended the --include=*.json / *.md
    #      filters *after* the exclusions, so each --exclude=<file> was undone by
    #      a later --include that also matched it. --exclude-dir=docs survived
    #      only because nothing re-included it. Verified against BSD grep 2.6.0:
    #      moving the excludes last fixes it, which is a trap waiting to be
    #      re-sprung by anyone appending a flag.
    #   2. Exclusions matched on basename, so --exclude=plugin.json hid all three
    #      of our plugin.json files *and* any undeclared file that happened to
    #      share the name. Full repo-relative paths are what we mean.
    #   3. grep has no notion of gitignore, so build output and local scratch
    #      directories were audited as if they shipped.
    pathspecs=()
    while IFS= read -r exc; do
      [ -n "$exc" ] || continue
      pathspecs+=(":!$exc" ":!$exc/**")
    done < <(jq -r '.audit.exclude[]' "$CONFIG")
    while IFS= read -r entry; do
      pathspecs+=(":!$(echo "$entry" | jq -r '.path')")
    done < <(jq -c '.files[]' "$CONFIG")

    # -F: the version is a literal, and its dots are not wildcards.
    if hits="$(git -C "$REPO_ROOT" grep -lIF -e "$current_ver" -- "${pathspecs[@]}")"; then
      echo "$hits"
    else
      echo "No undeclared occurrences found."
    fi
    ;;

  ""|--*)
    usage
    exit 1
    ;;

  *)
    NEW_VER="$CMD"
    if ! echo "$NEW_VER" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
      echo "Error: '$NEW_VER' is not a valid semver (expected X.Y.Z)" >&2
      exit 1
    fi
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
