#!/usr/bin/env bash
# The session-end feedback hook and scripts/submit-feedback.sh. Run: ./scripts/test-feedback.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK="$REPO_ROOT/hooks/session-end"
SUBMIT="$REPO_ROOT/scripts/submit-feedback.sh"
SESSION_START="$REPO_ROOT/hooks/session-start"
# shellcheck source=lib/test-lib.sh
. "$SCRIPT_DIR/lib/test-lib.sh"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- fixtures ---------------------------------------------------------------

# A transcript with the shapes the hook reads: Read and Skill tool calls on toolkit
# files, a Read on a file outside the toolkit, and prompt text that must never reach the note.
make_transcript() {
  local f="$TMPROOT/$1.jsonl"
  cat > "$f" <<'JSONL'
{"type":"user","message":{"role":"user","content":"PROMPT-SENTINEL-7731 please build the section template for customer ACME-SENTINEL"}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Skill","input":{"skill":"firstspirit-ai-toolkit:firstspirit-rest-api"}}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t2","name":"Read","input":{"file_path":"/home/dev/.claude/plugins/firstspirit-ai-toolkit/skills/templating/firstspirit-templating-reference/references/gom/references-links.md"}}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t3","name":"Read","input":{"file_path":"/home/dev/projects/acme/src/main/Secret-Sentinel.java"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t3","content":"FILE-CONTENT-SENTINEL-5520"}]}}
JSONL
  echo "$f"
}

make_empty_transcript() {
  local f="$TMPROOT/$1.jsonl"
  cat > "$f" <<'JSONL'
{"type":"user","message":{"role":"user","content":"how do I cook rice"}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Rinse it first."}]}}
JSONL
  echo "$f"
}

make_workdir() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  echo "$d"
}

# Fake toolkit root so the version line is deterministic.
FAKEROOT="$TMPROOT/toolkit"
mkdir -p "$FAKEROOT/hooks" "$FAKEROOT/scripts"
cp "$HOOK" "$FAKEROOT/hooks/session-end"
printf '{ "name": "x", "version": "9.8.7" }\n' > "$FAKEROOT/package.json"

run_hook() {  # workdir transcript [env...]
  local dir="$1" tr="$2"
  shift 2
  printf '{"session_id":"abc","transcript_path":"%s","cwd":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$tr" "$dir" \
    | env -i PATH="$PATH" HOME="$HOME" "$@" "$FAKEROOT/hooks/session-end" 2>/dev/null
}

note_of() {
  find "$1/.firstspirit-feedback" -name 'firstspirit-feedback-*.md' 2>/dev/null | head -1
}

# --- the hook ---------------------------------------------------------------

echo "== off by default =="
W="$(make_workdir off)"; T="$(make_transcript off)"
run_hook "$W" "$T"
assert_eq "no note without FIRSTSPIRIT_FEEDBACK" "" "$(note_of "$W")"
run_hook "$W" "$T" FIRSTSPIRIT_FEEDBACK=0
assert_eq "FIRSTSPIRIT_FEEDBACK=0 writes nothing" "" "$(note_of "$W")"

echo "== opt-in writes one note =="
W="$(make_workdir on)"; T="$(make_transcript on)"
run_hook "$W" "$T" FIRSTSPIRIT_FEEDBACK=1 CLAUDE_PLUGIN_ROOT=/plugin
N="$(note_of "$W")"
if [ -n "$N" ]; then pass "a note exists under .firstspirit-feedback/"; else fail "a note exists under .firstspirit-feedback/" "none written"; fi
body="$(cat "$N" 2>/dev/null)"
assert_contains "toolkit version from package.json" "$body" "| Toolkit version | 9.8.7 |"
assert_contains "assistant from the environment"    "$body" "| Assistant | Claude Code |"
assert_contains "session end reason"                "$body" "| Session ended | other |"
assert_contains "skill from a Skill call"           "$body" "- firstspirit-rest-api"
assert_contains "skill from a Read"                 "$body" "- firstspirit-templating-reference"
assert_contains "reference file by name"            "$body" "skills/templating/firstspirit-templating-reference/references/gom/references-links.md"
assert_contains "placeholder for the person"        "$body" "_(Write here what was wrong"
assert_contains "end-of-report marker"              "$body" "end of report"

echo "== privacy by construction =="
assert_not_contains "prompt text is not in the note"        "$body" "PROMPT-SENTINEL-7731"
assert_not_contains "customer name is not in the note"      "$body" "ACME-SENTINEL"
assert_not_contains "file content is not in the note"       "$body" "FILE-CONTENT-SENTINEL-5520"
assert_not_contains "non-toolkit file is not in the note"   "$body" "Secret-Sentinel"
assert_not_contains "no home path of the project"           "$body" "/home/dev/projects"

echo "== the folder ignores itself =="
assert_eq ".gitignore holds *" "*" "$(cat "$W/.firstspirit-feedback/.gitignore" 2>/dev/null)"

echo "== the folder does not switch on FirstSpirit detection =="
out="$( ( cd "$W" && env -i PATH="$PATH" HOME="$HOME" "$SESSION_START" 2>/dev/null ) )"
assert_not_contains "session-start still treats the project as plain" "$out" "Available Skills"

echo "== no toolkit skill touched, no note =="
W="$(make_workdir none)"; T="$(make_empty_transcript none)"
run_hook "$W" "$T" FIRSTSPIRIT_FEEDBACK=1
assert_eq "no note for an unrelated session" "" "$(note_of "$W")"

echo "== the hook never fails a session =="
W="$(make_workdir bad)"
printf 'not json at all' | env -i PATH="$PATH" HOME="$HOME" FIRSTSPIRIT_FEEDBACK=1 "$FAKEROOT/hooks/session-end" >/dev/null 2>&1
assert_eq "garbage stdin exits 0" "0" "$?"
printf '{"transcript_path":"/nonexistent/x.jsonl","cwd":"%s"}' "$W" | env -i PATH="$PATH" HOME="$HOME" FIRSTSPIRIT_FEEDBACK=1 "$FAKEROOT/hooks/session-end" >/dev/null 2>&1
assert_eq "missing transcript exits 0" "0" "$?"
env -i PATH="$PATH" HOME="$HOME" FIRSTSPIRIT_FEEDBACK=1 "$FAKEROOT/hooks/session-end" </dev/null >/dev/null 2>&1
assert_eq "empty stdin exits 0" "0" "$?"

echo "== the hook survives without jq =="
NOJQ="$TMPROOT/nojq-bin"
mkdir -p "$NOJQ"
for t in bash cat dirname grep sed head tr date mkdir sort find; do
  ln -sf "$(command -v "$t")" "$NOJQ/$t" 2>/dev/null || true
done
W="$(make_workdir nojq)"; T="$(make_transcript nojq)"
run_hook "$W" "$T" FIRSTSPIRIT_FEEDBACK=1 PATH="$NOJQ"
if [ -n "$(note_of "$W")" ]; then pass "note written with jq absent"; else fail "note written with jq absent" "none written"; fi

# --- submit-feedback.sh -----------------------------------------------------

# A fake gh that records its arguments. FAKE_GH_AUTH=0 makes 'gh auth status' fail;
# FAKE_GH_CREATE=0 makes 'gh issue create' fail.
FAKEGH="$TMPROOT/gh-bin"
mkdir -p "$FAKEGH"
cat > "$FAKEGH/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_GH_LOG"
case "$1 $2" in
  "auth status") [ "${FAKE_GH_AUTH:-1}" = 1 ]; exit $? ;;
  "issue create") [ "${FAKE_GH_CREATE:-1}" = 1 ] || exit 1
                  echo "https://github.com/e-Spirit/firstspirit-ai-toolkit/issues/999"; exit 0 ;;
esac
exit 0
GH
chmod +x "$FAKEGH/gh"
BASEBIN="$TMPROOT/base-bin"
mkdir -p "$BASEBIN"
for t in bash cat dirname grep sed head tr cut mktemp rm cp; do
  ln -sf "$(command -v "$t")" "$BASEBIN/$t" 2>/dev/null || true
done

filled_note() {
  local W T N
  W="$(make_workdir "$1")"; T="$(make_transcript "$1")"
  run_hook "$W" "$T" FIRSTSPIRIT_FEEDBACK=1 CLAUDE_PLUGIN_ROOT=/plugin
  N="$(note_of "$W")"
  python3 - "$N" "$2" <<'PY'
import sys
p, text = sys.argv[1], sys.argv[2]
s = open(p).read()
s = s.replace("_(Write here what was wrong, unclear or missing, in your own words. One sentence is enough. Do not paste project content, customer names, addresses or credentials.)_", text)
s = s.replace("_(Write here what you expected instead.)_", "The reference should say how to do it.")
open(p, "w").write(s)
PY
  echo "$N"
}

run_submit() {  # note [args...]; extra environment comes from the SUBMIT_ENV array
  env -i PATH="$GHPATH" HOME="$HOME" FAKE_GH_LOG="$TMPROOT/gh.log" "${SUBMIT_ENV[@]}" "$SUBMIT" "$@" 2>&1
}

GHPATH="$FAKEGH:$BASEBIN"
SUBMIT_ENV=(NOOP=1)
: > "$TMPROOT/gh.log"

echo "== submit: preview posts nothing =="
N="$(filled_note sub1 "The REST reference misses the PATCH status.")"
out="$(run_submit "$N")"; rc=$?
assert_eq "preview exits 0" "0" "$rc"
assert_contains "preview says nothing was sent" "$out" "PREVIEW. Nothing has been sent."
assert_contains "preview shows the person's text" "$out" "The REST reference misses the PATCH status."
assert_contains "preview shows the repository" "$out" "e-Spirit/firstspirit-ai-toolkit"
assert_contains "title names the skills" "$out" "Title:      Skill feedback: firstspirit-rest-api, firstspirit-templating-reference"
assert_not_contains "the local hand-in section is not in the preview" "$out" "For an AI assistant"
assert_eq "gh was not called by the preview" "" "$(cat "$TMPROOT/gh.log")"

echo "== submit: --yes posts through gh =="
out="$(run_submit "$N" --yes)"; rc=$?
assert_eq "--yes exits 0" "0" "$rc"
assert_contains "prints the issue URL" "$out" "issues/999"
assert_contains "gh issue create got the repo" "$(cat "$TMPROOT/gh.log")" "issue create --repo e-Spirit/firstspirit-ai-toolkit"
assert_contains "gh issue create got a body file" "$(cat "$TMPROOT/gh.log")" "--body-file"

echo "== submit: a custom title and repository =="
: > "$TMPROOT/gh.log"
SUBMIT_ENV=(FIRSTSPIRIT_FEEDBACK_REPO=someone/fork)
run_submit "$N" --yes --title "My title" >/dev/null
assert_contains "custom repository used" "$(cat "$TMPROOT/gh.log")" "--repo someone/fork"
assert_contains "custom title used" "$(cat "$TMPROOT/gh.log")" "--title My title"
SUBMIT_ENV=(NOOP=1)

echo "== submit: refusals =="
: > "$TMPROOT/gh.log"
W="$(make_workdir sub2)"; T="$(make_transcript sub2)"
run_hook "$W" "$T" FIRSTSPIRIT_FEEDBACK=1 CLAUDE_PLUGIN_ROOT=/plugin
UNF="$(note_of "$W")"
out="$(run_submit "$UNF" --yes)"; rc=$?
assert_eq "unfilled note exits 2" "2" "$rc"
assert_contains "unfilled note is explained" "$out" "still has its placeholders"

SEC="$(filled_note sub3 "It failed with password=hunter2hunter2 in the header.")"
out="$(run_submit "$SEC" --yes)"; rc=$?
assert_eq "credential pattern exits 2" "2" "$rc"
assert_contains "credential refusal names a line" "$out" "look like a credential"
assert_not_contains "credential refusal does not echo the secret" "$out" "hunter2"

PTH="$(filled_note sub4 "The file /Users/someone/project/x.xml was rejected.")"
out="$(run_submit "$PTH" --yes)"; rc=$?
assert_eq "local path exits 2" "2" "$rc"
assert_contains "path refusal is explained" "$out" "local file path"
EOR="$(filled_note sub5 "The text says end of report in the middle of a sentence. This part must survive.")"
out="$("$SUBMIT" "$EOR" 2>&1)"; rc=$?
assert_eq "words 'end of report' in the person's text exit 0" "0" "$rc"
assert_contains "text after those words is kept" "$out" "This part must survive."
assert_eq "gh never called for refused notes" "" "$(cat "$TMPROOT/gh.log")"

out="$(run_submit "$TMPROOT/does-not-exist.md")"; rc=$?
assert_eq "missing note exits 2" "2" "$rc"

echo "== submit: gh missing or not signed in =="
GHPATH="$BASEBIN"
out="$(run_submit "$N" --yes)"; rc=$?
assert_eq "gh missing exits 3" "3" "$rc"
assert_contains "gh missing prints the manual route" "$out" "Manual route"
REPORT="${N%.md}-report.md"
if [ -f "$REPORT" ]; then pass "manual route writes a report-only copy"; else fail "manual route writes a report-only copy" "not found"; fi
assert_not_contains "report-only copy has no hand-in section" "$(cat "$REPORT" 2>/dev/null)" "For an AI assistant"

GHPATH="$FAKEGH:$BASEBIN"
SUBMIT_ENV=(FAKE_GH_AUTH=0)
out="$(run_submit "$N" --yes)"; rc=$?
assert_eq "not signed in exits 3" "3" "$rc"
assert_contains "not signed in never asks for a token" "$out" "never paste a token"

SUBMIT_ENV=(FAKE_GH_CREATE=0)
out="$(run_submit "$N" --yes)"; rc=$?
assert_eq "gh failure exits 4" "4" "$rc"
SUBMIT_ENV=(NOOP=1)

finish
