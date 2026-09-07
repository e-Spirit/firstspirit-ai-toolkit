#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"
BOOTSTRAP="$SKILLS_DIR/using-firstspirit-toolkit/SKILL.md"
REFS_DIR="$SKILLS_DIR/using-firstspirit-toolkit/references"

errors=0
checked=0

err() {
  echo "ERROR [$1]: $2"
  errors=$((errors + 1))
}

# Read one frontmatter field. Takes only the block between the FIRST two '---'
# lines, so a horizontal rule in the body cannot be mistaken for frontmatter,
# and strips one layer of matching quotes rather than every quote in the value.
frontmatter_field() {
  local file="$1" key="$2" raw
  raw="$(awk -v k="^$key:" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---"    { exit }
    infm && $0 ~ k         { sub(k "[[:space:]]*", ""); print; exit }
  ' "$file")"
  # strip a trailing CR (CRLF checkouts), then one matching quote pair
  raw="${raw%$'\r'}"
  case "$raw" in
    \"*\") raw="${raw#\"}"; raw="${raw%\"}" ;;
    \'*\') raw="${raw#\'}"; raw="${raw%\'}" ;;
  esac
  printf '%s' "$raw"
}

while IFS= read -r skill_file; do
  checked=$((checked + 1))
  rel_path="${skill_file#"$REPO_ROOT/"}"
  skill_dir="$(basename "$(dirname "$skill_file")")"

  name="$(frontmatter_field "$skill_file" name)"
  description="$(frontmatter_field "$skill_file" description)"

  if [ -z "$name" ]; then
    err "$rel_path" "missing 'name' field in frontmatter"
  else
    if [ "$name" != "$skill_dir" ]; then
      err "$rel_path" "name '$name' does not match its directory '$skill_dir'"
    fi
    case "$name" in
      *[!a-z0-9-]*) err "$rel_path" "name '$name' must be lowercase kebab-case" ;;
    esac
  fi

  if [ -z "$description" ]; then
    err "$rel_path" "missing 'description' field in frontmatter"
  elif [ "${description#Use when}" = "$description" ]; then
    err "$rel_path" "description must start with 'Use when', got: $description"
  fi

  # Every domain skill must be reachable from the bootstrap index.
  if [ "$name" != "using-firstspirit-toolkit" ] && [ -n "$name" ]; then
    if ! grep -q -- "$name" "$BOOTSTRAP"; then
      err "$rel_path" "skill '$name' is not listed in the bootstrap index (skills/using-firstspirit-toolkit/SKILL.md)"
    fi
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" | sort)

# Every reference the bootstrap links must exist, and every reference that
# exists must be linked — an unlinked mapping file is one no harness will read.
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  if [ ! -f "$REPO_ROOT/$ref" ]; then
    err "bootstrap index" "links a missing reference file: $ref"
  fi
done < <(grep -o 'skills/using-firstspirit-toolkit/references/[a-z0-9-]*\.md' "$BOOTSTRAP" | sort -u)

if [ -d "$REFS_DIR" ]; then
  while IFS= read -r ref_file; do
    [ -n "$ref_file" ] || continue
    base="$(basename "$ref_file")"
    if ! grep -q "references/$base" "$BOOTSTRAP"; then
      err "$base" "reference file exists but the bootstrap index does not link it"
    fi
  done < <(find "$REFS_DIR" -name '*.md' | sort)
fi

echo "Checked $checked skill(s). Errors: $errors"
[ "$errors" -eq 0 ] || exit 1
