#!/usr/bin/env bash
#
# Preview, or with --yes post, a feedback note as a GitHub issue.
#
#   scripts/submit-feedback.sh <note.md>          preview only: prints what would be posted
#   scripts/submit-feedback.sh <note.md> --yes    post it with the GitHub CLI
#
# The note comes from hooks/session-end. Only the part above the line
# "end of report" is posted; the hand-in instructions below it stay local.
#
# Posting needs the GitHub CLI (gh), signed in, and --yes. Issues on the toolkit's
# repository are public, so the script refuses a note that still has the placeholders,
# or that looks like it holds a credential or a local file path. It never asks for
# a token.
#
# Exit codes: 0 preview printed or issue created; 2 the note cannot be posted (usage,
# placeholders, credential or path pattern); 3 gh is missing or not signed in (the manual
# route is printed); 4 gh failed to create the issue.
#
# FIRSTSPIRIT_FEEDBACK_REPO overrides the target repository (owner/name).
#
set -uo pipefail

REPO="${FIRSTSPIRIT_FEEDBACK_REPO:-e-Spirit/firstspirit-ai-toolkit}"
NOTE=""
YES=0
TITLE=""

usage() {
  echo "usage: submit-feedback.sh <note.md> [--yes] [--title \"text\"]" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --yes) YES=1 ;;
    --title) shift; TITLE="${1:-}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $1" >&2; usage; exit 2 ;;
    *) NOTE="$1" ;;
  esac
  shift
done

if [ -z "$NOTE" ] || [ ! -f "$NOTE" ]; then
  usage
  echo "note not found: ${NOTE:-<none>}" >&2
  exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BODY="$TMP/body.md"

# The report is everything above the end-of-report marker (the whole file if absent).
if grep -q 'end of report' "$NOTE"; then
  sed '/end of report/,$d' "$NOTE" > "$BODY"
else
  cp "$NOTE" "$BODY"
fi

if grep -q '_(Write here' "$BODY"; then
  echo "Not posted: the note still has its placeholders. Fill in 'What happened' first." >&2
  exit 2
fi

# A public issue must not carry credentials or local paths. Report line numbers, never the text.
SECRET_RE='-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|authorization:[[:space:]]*(bearer|basic)|(password|passwd|secret|api[_-]?key|token)[[:space:]]*[=:][[:space:]]*[^[:space:]]{6,}'
PATH_RE='/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|[A-Za-z]:\\Users\\'

hits="$(grep -nEi -e "$SECRET_RE" "$BODY" | cut -d: -f1 | tr '\n' ' ')"
if [ -n "$hits" ]; then
  echo "Not posted: line(s) $hits look like a credential. Remove it and try again." >&2
  exit 2
fi
hits="$(grep -nE -e "$PATH_RE" "$BODY" | cut -d: -f1 | tr '\n' ' ')"
if [ -n "$hits" ]; then
  echo "Not posted: line(s) $hits contain a local file path. Remove it and try again." >&2
  exit 2
fi

if [ -z "$TITLE" ]; then
  names="$(sed -n '/^## Skills this session used/,/^## /p' "$BODY" | sed -n 's/^- \(firstspirit-[a-z0-9-]*\)$/\1/p' | head -3 | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
  TITLE="Skill feedback: ${names:-toolkit}"
fi

manual_route() {
  # A copy of just the report, so the local hand-in section never goes out by accident.
  report="${NOTE%.md}-report.md"
  cp "$BODY" "$report" 2>/dev/null || report=""
  echo "Manual route: open an issue at https://github.com/$REPO/issues and paste the report." >&2
  if [ -n "$report" ]; then
    echo "The report text alone is in $report" >&2
    echo "With gh: gh issue create --repo $REPO --title \"$TITLE\" --body-file $report" >&2
  fi
}

if [ "$YES" -eq 0 ]; then
  echo "PREVIEW. Nothing has been sent."
  echo "Repository: $REPO (public)"
  echo "Title:      $TITLE"
  echo "----------------------------------------"
  cat "$BODY"
  echo "----------------------------------------"
  echo "To post this text, run the same command again with --yes."
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Not posted: the GitHub CLI (gh) is not installed." >&2
  manual_route
  exit 3
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Not posted: gh is not signed in (run 'gh auth login' yourself, never paste a token into a chat)." >&2
  manual_route
  exit 3
fi

if url="$(gh issue create --repo "$REPO" --title "$TITLE" --body-file "$BODY")"; then
  echo "Issue created: $url"
  exit 0
fi
echo "Not posted: gh could not create the issue." >&2
manual_route
exit 4
