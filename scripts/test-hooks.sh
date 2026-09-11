#!/usr/bin/env bash
# Behaviour of hooks/session-start under each harness. Run: ./scripts/test-hooks.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK="$REPO_ROOT/hooks/session-start"
# shellcheck source=lib/test-lib.sh
. "$SCRIPT_DIR/lib/test-lib.sh"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- fixtures ---------------------------------------------------------------

make_fs_fixture() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  : > "$d/.firstspirit"
  echo "$d"
}

make_plain_fixture() {
  local d="$TMPROOT/$1"
  mkdir -p "$d/src"
  echo 'console.log("hello")' > "$d/src/index.js"
  echo "$d"
}

make_minimal_bin() {
  local b="$TMPROOT/$1"
  local t
  mkdir -p "$b"
  for t in bash cat dirname find grep git head sed; do
    ln -sf "$(command -v "$t")" "$b/$t" 2>/dev/null || true
  done
  echo "$b"
}

# --- runners ----------------------------------------------------------------
# env -i scrubs the inherited harness variables so each case is deterministic.
# PATH and HOME are re-supplied; overrides are appended by the caller.

run_hook() {
  local dir="$1"
  shift
  ( cd "$dir" && env -i PATH="$PATH" HOME="$HOME" "$@" "$HOOK" 2>/dev/null )
}

hook_exit() {
  local dir="$1"
  shift
  ( cd "$dir" && env -i PATH="$PATH" HOME="$HOME" "$@" "$HOOK" >/dev/null 2>&1 )
  echo $?
}

FS="$(make_fs_fixture fsproj)"
PLAIN="$(make_plain_fixture plain)"

out="$(run_hook "$FS")"
# A string that appears in the bootstrap index itself rather than in any one
# skill, so these tests keep testing the gate when the skill set changes. A
# skill name does not survive that: once it is gone from the index, the
# positive assertions fail and — worse — the negative ones pass vacuously.
INDEX_MARKER="Available Skills"

echo "== the gating marker is a real string in the index =="
# Both assert_contains and assert_not_contains pass when the needle is absent
# from the haystack for the wrong reason — the positive loudly, the negative
# silently. That is how the manage-content assertions rotted: four tests meant to
# prove the index is NOT loaded stayed green through a fully sabotaged gate. Tie
# the marker to the file it is supposed to come from, so a rewrite of the index
# fails here instead of quietly disarming every gating assertion.
if grep -qF "$INDEX_MARKER" "$REPO_ROOT/skills/using-firstspirit-toolkit/SKILL.md"; then
  pass "INDEX_MARKER appears in the bootstrap index"
else
  fail "INDEX_MARKER appears in the bootstrap index" \
    "gating assertions can no longer fail — update INDEX_MARKER to a string the index contains"
fi

echo "== gating: FirstSpirit project loads the full index =="
assert_contains "marker dir injects the bootstrap skill" "$out" "name: using-firstspirit-toolkit"
assert_contains "marker dir injects the skill index"     "$out" "$INDEX_MARKER"

echo "== gating: plain project stays quiet =="
out="$(run_hook "$PLAIN")"
assert_contains     "plain dir injects the quiet line" "$out" "FirstSpirit AI Toolkit is available"
assert_not_contains "plain dir omits the skill index"  "$out" "$INDEX_MARKER"

echo "== gating: env override wins in both directions =="
out="$(run_hook "$PLAIN" FIRSTSPIRIT_PROJECT=1)"
assert_contains "FIRSTSPIRIT_PROJECT=1 forces the index on" "$out" "$INDEX_MARKER"
out="$(run_hook "$FS" FIRSTSPIRIT_PROJECT=0)"
assert_not_contains "FIRSTSPIRIT_PROJECT=0 forces the index off" "$out" "$INDEX_MARKER"

echo "== envelope: one shape per harness =="
out="$(run_hook "$FS" CLAUDE_PLUGIN_ROOT=/plugin)"
assert_eq "claude envelope" "SessionStart" \
  "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName')"
assert_eq "claude payload is non-empty" "yes" \
  "$(printf '%s' "$out" | jq -r 'if (.hookSpecificOutput.additionalContext | length) > 0 then "yes" else "no" end')"

out="$(run_hook "$FS" CURSOR_PLUGIN_ROOT=/plugin)"
assert_eq "cursor envelope key" "additional_context" \
  "$(printf '%s' "$out" | jq -r 'keys[0]')"

# Cursor sets CLAUDE_PLUGIN_ROOT alongside CURSOR_PLUGIN_ROOT, with the same
# value, so the real Cursor environment has both. Test what Cursor actually
# does, not the single variable in isolation.
out="$(run_hook "$FS" CURSOR_PLUGIN_ROOT=/plugin CLAUDE_PLUGIN_ROOT=/plugin)"
assert_eq "cursor envelope key wins over claude" "additional_context" \
  "$(printf '%s' "$out" | jq -r 'keys[0]')"

out="$(run_hook "$FS" COPILOT_AGENT_SESSION_ID=abc123 CLAUDE_PLUGIN_ROOT=/plugin)"
assert_eq "copilot envelope key wins over claude" "additionalContext" \
  "$(printf '%s' "$out" | jq -r 'keys[0]')"

out="$(run_hook "$FS")"
assert_eq "default envelope key" "additionalContext" \
  "$(printf '%s' "$out" | jq -r 'keys[0]')"

echo "== the hook always succeeds and always says something =="
assert_eq "exit 0 in a FirstSpirit project" "0" "$(hook_exit "$FS")"
assert_eq "exit 0 in a plain project"       "0" "$(hook_exit "$PLAIN")"
out="$(run_hook "$PLAIN")"
assert_eq "plain-dir output is valid JSON" "0" \
  "$(printf '%s' "$out" | jq empty >/dev/null 2>&1; echo $?)"

echo "== injected paths are absolute =="
out="$(run_hook "$PLAIN")"
assert_contains "quiet line names the absolute SKILL.md path" "$out" \
  "$REPO_ROOT/skills/using-firstspirit-toolkit/SKILL.md"
out="$(run_hook "$FS")"
assert_contains "index injection names the toolkit root" "$out" \
  "Toolkit root: $REPO_ROOT"

echo "== explicit opt-out gets its own message =="
out="$(run_hook "$FS" FIRSTSPIRIT_PROJECT=0)"
assert_contains     "opt-out message is distinct" "$out" "disabled for this session"
assert_not_contains "opt-out does not re-suggest the env var" "$out" "set FIRSTSPIRIT_PROJECT=1"

echo "== the hook survives without jq =="
NOJQ="$(make_minimal_bin nojq-bin)"
assert_eq "exit 0 with jq absent" "0" "$(hook_exit "$FS" PATH="$NOJQ")"
out="$( ( cd "$FS" && env -i PATH="$NOJQ" HOME="$HOME" "$HOOK" 2>/dev/null ) )"
assert_contains "still injects the index with jq absent" "$out" "using-firstspirit-toolkit"
assert_eq "output is still a parseable envelope with jq absent" "additionalContext" \
  "$(printf '%s' "$out" | jq -r 'keys[0]' 2>/dev/null)"

echo "== escaping survives the characters the skill file actually contains =="
ESCFIX="$(make_fs_fixture escfix)"
out="$(run_hook "$ESCFIX")"
assert_eq "round-trips through jq to the original text" "0" \
  "$(printf '%s' "$out" | jq -e '.additionalContext | test("using-firstspirit-toolkit")' >/dev/null 2>&1; echo $?)"

echo "== copilot is detected by either of its variables =="
out="$(run_hook "$FS" COPILOT_PLUGIN_ROOT=/plugin CLAUDE_PLUGIN_ROOT=/plugin)"
assert_eq "COPILOT_PLUGIN_ROOT alone selects the copilot shape" "additionalContext" \
  "$(printf '%s' "$out" | jq -r 'keys[0]')"
out="$(run_hook "$FS" COPILOT_AGENT_SESSION_ID=abc123 CLAUDE_PLUGIN_ROOT=/plugin)"
assert_eq "COPILOT_AGENT_SESSION_ID alone still selects the copilot shape" "additionalContext" \
  "$(printf '%s' "$out" | jq -r 'keys[0]')"

echo "== FSXA frontends are recognised =="
FSXA="$TMPROOT/fsxa-app"
mkdir -p "$FSXA"
cat > "$FSXA/package.json" <<'JSON'
{
  "name": "my-site",
  "dependencies": {
    "next": "^14.0.0",
    "fsxa-api": "^10.19.0"
  }
}
JSON
out="$(run_hook "$FSXA")"
assert_contains "an fsxa-api dependency counts as FirstSpirit" "$out" "$INDEX_MARKER"

echo "== a plain JS project is still not FirstSpirit =="
PLAINJS="$TMPROOT/plain-js"
mkdir -p "$PLAINJS"
cat > "$PLAINJS/package.json" <<'JSON'
{
  "name": "unrelated",
  "dependencies": {
    "express": "^4.18.0"
  }
}
JSON
out="$(run_hook "$PLAINJS")"
assert_not_contains "an unrelated package.json is not FirstSpirit" "$out" "$INDEX_MARKER"

echo "== the detector does not descend into dependency trees =="
NOISY="$TMPROOT/noisy"
mkdir -p "$NOISY/node_modules/some-pkg/test/fixtures"
: > "$NOISY/node_modules/some-pkg/test/fixtures/.firstspirit"
out="$(run_hook "$NOISY")"
assert_not_contains "a marker inside node_modules is ignored" "$out" "$INDEX_MARKER"

echo "== a module descriptor must name FirstSpirit to count =="
# Deliberate: module.xml is a generic filename, so the detector requires
# de.espirit / firstspirit inside it. Asserted here so the README bullet and the
# code cannot drift apart again.
BAREMOD="$TMPROOT/bare-module"
mkdir -p "$BAREMOD"
cat > "$BAREMOD/module.xml" <<'XML'
<module>
  <name>unrelated-plugin</name>
  <version>1.0.0</version>
</module>
XML
out="$(run_hook "$BAREMOD")"
assert_not_contains "a module.xml that never names FirstSpirit is not detected" "$out" "$INDEX_MARKER"

NAMEDMOD="$TMPROOT/named-module"
mkdir -p "$NAMEDMOD"
cat > "$NAMEDMOD/module.xml" <<'XML'
<module>
  <name>my-fs-module</name>
  <class>de.espirit.firstspirit.module.ModuleImpl</class>
</module>
XML
out="$(run_hook "$NAMEDMOD")"
assert_contains "a module.xml naming de.espirit is detected" "$out" "$INDEX_MARKER"

finish
