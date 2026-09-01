#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"

errors=0
checked=0

while IFS= read -r skill_file; do
  checked=$((checked + 1))
  rel_path="${skill_file#"$REPO_ROOT/"}"

  # Extract frontmatter block (between the first two --- lines)
  frontmatter="$(awk '/^---/{p=!p; next} p{print}' "$skill_file" | head -20)"

  # Check name field
  name="$(echo "$frontmatter" | grep '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"' | head -1 || true)"
  if [ -z "$name" ]; then
    echo "ERROR [$rel_path]: missing 'name' field in frontmatter"
    errors=$((errors + 1))
  fi

  # Check description field
  description="$(echo "$frontmatter" | grep '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"' | head -1 || true)"
  if [ -z "$description" ]; then
    echo "ERROR [$rel_path]: missing 'description' field in frontmatter"
    errors=$((errors + 1))
  elif [[ "$description" != "Use when"* ]]; then
    echo "ERROR [$rel_path]: description must start with 'Use when', got: $description"
    errors=$((errors + 1))
  fi

done < <(find "$SKILLS_DIR" -name "SKILL.md" | sort)

echo "Checked $checked skill(s). Errors: $errors"
[ "$errors" -eq 0 ] || exit 1
