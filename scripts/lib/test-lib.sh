#!/usr/bin/env bash
# shellcheck shell=bash
# Shared assertion helpers for the toolkit's bash test scripts.
# Source this; do not execute it. bash 3.2 compatible.
#
# Callers must not invoke assertions inside a subshell or a pipeline —
# the counters live in the current shell.

# shellcheck disable=SC2034  # read by the sourcing script, not here
TESTS_RUN=0
# shellcheck disable=SC2034  # read by the sourcing script, not here
TESTS_FAILED=0

pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  printf '  ok   %s\n' "$1"
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf '  FAIL %s\n       %s\n' "$1" "$2" >&2
}

assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1" "expected [$2], got [$3]"
  fi
}

assert_contains() {
  case "$2" in
    *"$3"*) pass "$1" ;;
    *)      fail "$1" "expected output to contain [$3]" ;;
  esac
}

assert_not_contains() {
  case "$2" in
    *"$3"*) fail "$1" "expected output NOT to contain [$3]" ;;
    *)      pass "$1" ;;
  esac
}

# assert_json_field <name> <file> <jq-path> <expected>
assert_json_field() {
  local actual
  actual="$(jq -r "$3" "$2" 2>/dev/null || echo "JQ_ERROR")"
  assert_eq "$1" "$4" "$actual"
}

finish() {
  printf '\n%s test(s), %s failure(s)\n' "$TESTS_RUN" "$TESTS_FAILED"
  [ "$TESTS_FAILED" -eq 0 ]
}
