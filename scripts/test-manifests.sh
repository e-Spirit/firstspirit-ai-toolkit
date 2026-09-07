#!/usr/bin/env bash
# Structural invariants of the platform manifests. Run: ./scripts/test-manifests.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=lib/test-lib.sh
. "$SCRIPT_DIR/lib/test-lib.sh"

MANIFESTS="
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
.agents/plugins/marketplace.json
.codex-plugin/plugin.json
.cursor-plugin/plugin.json
gemini-extension.json
.github/hooks/firstspirit-ai-toolkit.json
hooks/hooks.json
hooks/hooks-cursor.json
.version-bump.json
package.json
"

echo "== every manifest exists and is valid JSON =="
for m in $MANIFESTS; do
  if [ ! -f "$REPO_ROOT/$m" ]; then
    fail "$m exists" "file not found"
    continue
  fi
  if jq empty "$REPO_ROOT/$m" >/dev/null 2>&1; then
    pass "$m is valid JSON"
  else
    fail "$m is valid JSON" "jq failed to parse it"
  fi
done

echo "== the marketplace is named separately from the plugin =="
# Installs read PLUGIN-NAME@MARKETPLACE-NAME, so the two names must differ or the
# command reads as firstspirit-ai-toolkit@firstspirit-ai-toolkit.
assert_json_field "claude marketplace is named firstspirit" \
  "$REPO_ROOT/.claude-plugin/marketplace.json" '.name' "firstspirit"
assert_json_field "codex marketplace is named firstspirit" \
  "$REPO_ROOT/.agents/plugins/marketplace.json" '.name' "firstspirit"
assert_json_field "claude marketplace still lists the plugin under its own name" \
  "$REPO_ROOT/.claude-plugin/marketplace.json" '.plugins[0].name' "firstspirit-ai-toolkit"

echo "== plugin identity is consistent =="
assert_json_field "claude plugin name"  "$REPO_ROOT/.claude-plugin/plugin.json"      '.name' "firstspirit-ai-toolkit"
assert_json_field "codex plugin name"   "$REPO_ROOT/.codex-plugin/plugin.json"       '.name' "firstspirit-ai-toolkit"
assert_json_field "cursor plugin name"  "$REPO_ROOT/.cursor-plugin/plugin.json"      '.name' "firstspirit-ai-toolkit"
assert_json_field "gemini ext name"     "$REPO_ROOT/gemini-extension.json"           '.name' "firstspirit-ai-toolkit"
assert_json_field "codex marketplace name" "$REPO_ROOT/.agents/plugins/marketplace.json" '.plugins[0].name' "firstspirit-ai-toolkit"

echo "== every version-carrying manifest is tracked in .version-bump.json =="
PKG_VER="$(jq -r '.version' "$REPO_ROOT/package.json")"
while IFS= read -r entry; do
  f="$(echo "$entry" | jq -r '.path')"
  fld="$(echo "$entry" | jq -r '.field')"
  jqp=".$(echo "$fld" | sed 's/\.\([0-9][0-9]*\)/[\1]/g' | sed 's/^\.//')"
  assert_json_field "$f ($fld) matches package.json" "$REPO_ROOT/$f" "$jqp" "$PKG_VER"
done < <(jq -c '.files[]' "$REPO_ROOT/.version-bump.json")

echo "== every skill directory is reachable by the harnesses =="
# Harness skill auto-discovery only descends ONE level: it finds
# skills/<name>/SKILL.md but not skills/<category>/<name>/SKILL.md. Verified
# against `claude plugin details`, which reported 1 of 6 skills before the
# category directories were declared explicitly. So every directory that holds a
# nested SKILL.md must appear in the manifest's `skills` list.
while IFS= read -r cat_dir; do
  [ -n "$cat_dir" ] || continue
  rel="./skills/$cat_dir"
  for m in .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json; do
    if jq -e --arg p "$rel" '(.skills // []) | index($p)' \
         "$REPO_ROOT/$m" >/dev/null 2>&1; then
      pass "$m declares $rel"
    else
      fail "$m declares $rel" \
        "nested skills there may be invisible to that harness — add it to .skills"
    fi
  done
# depth 3 is skills/<category>/<name>/SKILL.md; depth 2 is the top-level
# bootstrap skill, which plain auto-discovery already finds.
done < <(cd "$REPO_ROOT/skills" && find . -mindepth 3 -maxdepth 3 -name SKILL.md -print \
           | sed -e 's|/[^/]*/SKILL\.md$||' -e 's|^\./||' | sort -u)

echo "== the bootstrap skill exists where manifests point =="
if [ -f "$REPO_ROOT/skills/using-firstspirit-toolkit/SKILL.md" ]; then
  pass "bootstrap SKILL.md exists"
else
  fail "bootstrap SKILL.md exists" "skills/using-firstspirit-toolkit/SKILL.md not found"
fi
assert_json_field "codex sessionStart points at the bootstrap skill" \
  "$REPO_ROOT/.codex-plugin/plugin.json" '.sessionStart.skill' "using-firstspirit-toolkit"

echo "== no hook command uses a relative path =="
# Hooks run with cwd set by the host (usually the workspace root), never the
# plugin root — so every command must go through the harness's root variable.
check_hook_command() {
  local label="$1" cmd="$2"
  case "$cmd" in
    ./*|hooks/*)
      fail "$label uses a plugin-root variable" "relative command: $cmd" ;;
    *'${'*PLUGIN_ROOT*)
      pass "$label uses a plugin-root variable" ;;
    *)
      fail "$label uses a plugin-root variable" "no PLUGIN_ROOT variable in: $cmd" ;;
  esac
}

check_hook_command "claude hook" \
  "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$REPO_ROOT/hooks/hooks.json")"
check_hook_command "cursor hook" \
  "$(jq -r '.hooks.sessionStart[0].command' "$REPO_ROOT/hooks/hooks-cursor.json")"
check_hook_command "copilot hook" \
  "$(jq -r '.hooks.SessionStart[0].bash' "$REPO_ROOT/.github/hooks/firstspirit-ai-toolkit.json")"

echo "== the hook entry points are executable =="
for h in hooks/run-hook.cmd hooks/session-start; do
  if [ -x "$REPO_ROOT/$h" ]; then
    pass "$h is executable"
  else
    fail "$h is executable" "missing the executable bit"
  fi
done

echo "== manifest metadata is complete =="
assert_json_field "claude plugin has a displayName" \
  "$REPO_ROOT/.claude-plugin/plugin.json" '.displayName' "FirstSpirit AI Toolkit"
# The marketplace entry's displayName is what the install list shows; without it
# the UI falls back to the kebab-case name.
assert_json_field "marketplace entry has a displayName" \
  "$REPO_ROOT/.claude-plugin/marketplace.json" '.plugins[0].displayName' "FirstSpirit AI Toolkit"
assert_json_field "marketplace entry has a description" \
  "$REPO_ROOT/.claude-plugin/marketplace.json" \
  'if (.plugins[0].description | length) > 0 then "yes" else "no" end' "yes"
assert_json_field "claude hook declares a timeout" \
  "$REPO_ROOT/hooks/hooks.json" '.hooks.SessionStart[0].hooks[0].timeout' "10"

echo "== the codex default prompt does not presume FirstSpirit =="
assert_not_contains "defaultPrompt is not an unconditional assertion" \
  "$(jq -r '.defaultPrompt' "$REPO_ROOT/.codex-plugin/plugin.json")" \
  "You are working in a FirstSpirit CMS project"
assert_contains "defaultPrompt is conditional" \
  "$(jq -r '.defaultPrompt' "$REPO_ROOT/.codex-plugin/plugin.json")" \
  "If this project involves FirstSpirit"

echo "== the codex marketplace registry is version-tracked =="
# .agents/plugins/marketplace.json — read by Codex / the ChatGPT desktop app.
assert_json_field "codex marketplace registry is in .version-bump.json" \
  "$REPO_ROOT/.version-bump.json" \
  '[.files[].path] | if index(".agents/plugins/marketplace.json") then "yes" else "no" end' "yes"
assert_json_field "codex marketplace registry has a description" \
  "$REPO_ROOT/.agents/plugins/marketplace.json" \
  'if (.description | length) > 0 then "yes" else "no" end' "yes"
assert_json_field "codex marketplace registry uses a local source" \
  "$REPO_ROOT/.agents/plugins/marketplace.json" '.plugins[0].source.source' "local"

echo "== v1 ships no MCP servers =="
# The toolkit is a skills-and-manifests distribution. Nothing may advertise an
# MCP server until one actually ships. docs/ is excluded: the plans and specs
# there are historical records, not claims about the current release.
if [ -d "$REPO_ROOT/mcp-servers" ]; then
  fail "no mcp-servers directory" "mcp-servers/ still exists"
else
  pass "no mcp-servers directory"
fi

# Assert the tracked tree makes no claim about a capability v1 does not have.
# docs/ is excluded: the plans and specs there are historical records, not
# claims about the current release. This script excludes itself, since the
# patterns appear here as literals.
claims_nothing_about() {
  local pattern="$1" hits
  hits="$(cd "$REPO_ROOT" && git grep -liI -e "$pattern" -- \
    ':!docs/' ':!scripts/test-manifests.sh' 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    fail "no reference to '$pattern'" "found in: $(echo "$hits" | tr '\n' ' ')"
  else
    pass "no reference to '$pattern'"
  fi
}

claims_nothing_about "mcpServers"
claims_nothing_about "mcp-servers"
claims_nothing_about "@firstspirit-ai-toolkit/mcp"
claims_nothing_about "FS_API_KEY"
claims_nothing_about "claude mcp add"

echo "== v1 claims no Antigravity support =="
# Antigravity needs a root plugin.json marker we do not ship, and its earliest
# hook (PreInvocation) fires per model call rather than per session, so neither
# install nor gating works today. Claiming support would be claiming something
# nobody has run. Reinstating it means a plan, not a doc line — see
# docs/porting-to-a-new-harness.md.
claims_nothing_about "antigravity"
claims_nothing_about "agy plugin install"

echo "== install docs do not claim a public marketplace we are not in =="
# Distribution is this repository, imported as a private marketplace. Do not
# advertise a third-party registry until the plugin is actually published there.
claims_nothing_about "awesome-copilot"

echo "== the codex marketplace registry is labelled as Codex's =="
# .agents/plugins/marketplace.json is read by Codex / the ChatGPT desktop app.
# It was previously documented as Antigravity's; keep the attribution honest.
if grep -q 'Codex.*\.agents/plugins/marketplace\.json\|\.agents/plugins/marketplace\.json.*Codex' \
     "$REPO_ROOT/docs/porting-to-a-new-harness.md"; then
  pass "porting guide attributes .agents/plugins/marketplace.json to Codex"
else
  fail "porting guide attributes .agents/plugins/marketplace.json to Codex" \
    "the manifest table does not tie that file to Codex"
fi

echo "== the version audit finds undeclared versions and honours its excludes =="
# Run against a throwaway git repo rather than this one, so the probe files
# never touch the real tree. A git work tree is required because --audit scopes
# itself to tracked files.
AUDIT_TMP="$(mktemp -d)"
trap 'rm -rf "$AUDIT_TMP"' EXIT
(
  cd "$AUDIT_TMP" || exit 1
  git init -q .
  mkdir -p scripts/lib docs
  cp "$REPO_ROOT/scripts/bump-version.sh" scripts/
  printf '{"version":"9.9.9"}\n' > package.json
  printf '{"files":[{"path":"package.json","field":"version"}],"audit":{"exclude":["docs"]}}\n' \
    > .version-bump.json
  printf 'stray 9.9.9\n'   > stray.md          # undeclared: must be reported
  printf 'excluded 9.9.9\n' > docs/note.md     # under an excluded path
  git add -A
) >/dev/null 2>&1

AUDIT_OUT="$(cd "$AUDIT_TMP" && ./scripts/bump-version.sh --audit 2>&1)"
assert_contains "reports an undeclared version in a tracked file" "$AUDIT_OUT" "stray.md"
# This is the assertion the old implementation failed: package.json is a
# declared path, but its exclusion was overridden by a later --include filter.
assert_not_contains "does not report a declared path" "$AUDIT_OUT" "package.json"
assert_not_contains "does not report an excluded path" "$AUDIT_OUT" "docs/note.md"

AUDIT_CLEAN="$(cd "$AUDIT_TMP" && rm -f stray.md && git add -A >/dev/null 2>&1; \
  cd "$AUDIT_TMP" && ./scripts/bump-version.sh --audit 2>&1)"
assert_contains "says so when nothing is undeclared" "$AUDIT_CLEAN" "No undeclared occurrences found."

finish
