#!/bin/sh
# fs-cli-export.sh — run FS-CLI (fsdevtools) with the settings that actually work
# against a modern FirstSpirit server, without rediscovering the launcher's traps.
#
# It encodes three things this skill documents:
#   1. a JRE/JDK >= the Access API jar's Java version (default: the FirstSpirit launcher's bundled JRE — 21 or 25 depending on the launcher build),
#   2. the --add-opens flags the shipped launcher drops on a JRE (missing javap),
#   3. HTTPS on 443 as the default connection mode (correct for FirstSpirit Cloud).
#
# It is a thin wrapper around `com.espirit.moddev.cli.Main` — every argument after
# the options below is passed straight through, so it runs ANY fs-cli command, e.g.:
#     FS_HOST=my.host FS_PROJECT="My Project" FS_SYNC_DIR=./out \
#     FS_USER=login FS_PWD=secret  fs-cli-export.sh \
#       export projectproperty:ALL templatestore pagestore sitestore mediastore globalstore contentstore
# or just:  FS_HOST=my.host FS_USER=login FS_PWD=secret  fs-cli-export.sh -p "My Project" test
#
# Configuration via environment (all optional except where noted):
#   FS_CLI_HOME  path to the extracted fs-cli dir (contains bin/ lib/ conf/).
#                Default: $FS_CLI_HOME, else ./fsdevtools/fs-cli, else ./fs-cli.
#   JAVA_HOME    a JDK/JRE >= the Access API jar's Java version. If unset, tries
#                the FirstSpirit FSLauncher bundled JRE (21+), then /usr/libexec/java_home.
#   FS_HOST      server host (no scheme).                      [required for connecting commands]
#   FS_PORT      port. Default 443.
#   FS_CONN      connection mode HTTP|HTTPS|SOCKET. Default HTTPS.
#   FS_USER  / FS_USERNAME   FirstSpirit login.
#   FS_PWD   / FS_PASSWORD   password. Prefer sourcing from a chmod-600 env file.
#   FS_PROJECT   project NAME (not id). Passed as -p when set.
#   FS_SYNC_DIR  sync directory. Passed as -sd when set.
#   FS_RESULT    result JSON path. Passed as -rf when set.
#
# The password is passed to fs-cli but redacted from this script's own stdout/stderr.
#
# Every run keeps its (redacted) fs-cli output in results/firstspirit-external-sync-export/<run>/fs-cli.log
# and appends one summary line to logs/firstspirit-external-sync-export.log — the portfolio's
# shared output layout. Both live under the output root: $FS_OUT_ROOT if set, else the nearest
# parent directory holding tracked-skills.tsv (the skills monorepo), else the working directory.
# The directories are git-ignored; the exported project itself goes where FS_SYNC_DIR says.
#
# Note: we deliberately do NOT use `set -e`. This is a wrapper around a tool that
# is expected to fail sometimes (bad identifier, auth, connection); `set -e` would
# abort before the run's own output could be surfaced/redacted, hiding the very
# diagnostics the operator needs. We capture and propagate fs-cli's exit code
# explicitly instead.
set -u

FS_CLI_HOME="${FS_CLI_HOME:-}"
if [ -z "$FS_CLI_HOME" ]; then
  if [ -d "./fsdevtools/fs-cli" ]; then FS_CLI_HOME="./fsdevtools/fs-cli"
  elif [ -d "./fs-cli" ]; then FS_CLI_HOME="./fs-cli"
  else echo "fs-cli-export: set FS_CLI_HOME to the extracted fs-cli directory" >&2; exit 2; fi
fi
[ -d "$FS_CLI_HOME/lib" ] || { echo "fs-cli-export: no lib/ under FS_CLI_HOME=$FS_CLI_HOME" >&2; exit 2; }

# --- resolve a Java >= 21 ----------------------------------------------------
if [ -z "${JAVA_HOME:-}" ]; then
  for c in "$HOME"/.firstspirit/FSLauncher/jre/*/jre-mac-arm/*/Contents/Home \
           "$HOME"/.firstspirit/FSLauncher/jre/*/jre-mac/*/Contents/Home; do
    [ -x "$c/bin/java" ] && { JAVA_HOME="$c"; break; }
  done
fi
if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
  JAVA_HOME="$(/usr/libexec/java_home -v 21+ 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
fi
[ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ] || {
  echo "fs-cli-export: no usable JAVA_HOME (need a JDK/JRE >= the Access API jar's version, normally 21)" >&2; exit 2; }
export JAVA_HOME

# --- assemble connection options from env ------------------------------------
USER_VAL="${FS_USER:-${FS_USERNAME:-}}"
PWD_VAL="${FS_PWD:-${FS_PASSWORD:-}}"

# fs-cli wants: <global options> <command> [args]. The caller's command+args are
# in "$@"; we append the env-derived global options after them, then rotate the
# caller args to the end so the globals lead. (Doing this without clobbering the
# caller args, and preserving values that contain spaces, e.g. FS_SYNC_DIR.)
orig_count=$#
# the caller's command word (for the run log) = first argument that is not an option or its value
CMD=""; skip=0
for a in "$@"; do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  case "$a" in
    -p|-sd|-rf|-h|-port|-c|-u|-pwd|-e) skip=1 ;;
    -*) ;;
    *) [ -n "$CMD" ] || CMD="$a" ;;
  esac
done
[ -n "${FS_HOST:-}" ]    && set -- "$@" -h "$FS_HOST"
set -- "$@" -port "${FS_PORT:-443}" -c "${FS_CONN:-HTTPS}"
[ -n "$USER_VAL" ]       && set -- "$@" -u "$USER_VAL"
[ -n "$PWD_VAL" ]        && set -- "$@" -pwd "$PWD_VAL"
[ -n "${FS_PROJECT:-}" ] && set -- "$@" -p "$FS_PROJECT"
[ -n "${FS_SYNC_DIR:-}" ]&& set -- "$@" -sd "$FS_SYNC_DIR"
[ -n "${FS_RESULT:-}" ]  && set -- "$@" -rf "$FS_RESULT"
i=0
while [ "$i" -lt "$orig_count" ]; do
  a="$1"; shift; set -- "$@" "$a"; i=$((i + 1))
done

# --- shared results/ + logs/ layout (see header) ------------------------------
out_root() {
  if [ -n "${FS_OUT_ROOT:-}" ]; then printf '%s' "$FS_OUT_ROOT"; return; fi
  d="$PWD"
  while [ "$d" != / ]; do
    if [ -f "$d/tracked-skills.tsv" ]; then printf '%s' "$d"; return; fi
    d="$(dirname "$d")"
  done
  printf '%s' "$PWD"
}
ROOT_OUT="$(out_root)"
RUN="$(date +%Y-%m-%d-%H%M%S)"
OUT="$ROOT_OUT/results/firstspirit-external-sync-export/$RUN"
[ -e "$OUT" ] && OUT="$OUT-$$"          # two runs in the same second keep separate dirs
RUNLOG="$ROOT_OUT/logs/firstspirit-external-sync-export.log"
mkdir -p "$OUT" "$ROOT_OUT/logs" 2>/dev/null || { OUT="$(mktemp -d)"; RUNLOG=/dev/null; }
STARTED="$(date +%s)"
logrun() {
  st="$1"; res=ok; [ "$st" = 0 ] || res="fail($st)"
  printf '%s %s host=%s project="%s" sync_dir="%s" result=%s took=%ss log=%s\n' \
    "$(date +%Y-%m-%dT%H:%M:%S%z)" "${CMD:-fs-cli}" "${FS_HOST:-}" "${FS_PROJECT:-}" "${FS_SYNC_DIR:-}" \
    "$res" "$(( $(date +%s) - STARTED ))" "${OUT#"$ROOT_OUT"/}/fs-cli.log" >> "$RUNLOG" 2>/dev/null || true
}

# --- run, redacting the password from our own output -------------------------
run() {
  "$JAVA_HOME/bin/java" \
    --add-opens=java.base/sun.reflect.annotation=ALL-UNNAMED \
    --add-opens=java.base/java.util=ALL-UNNAMED \
    --add-opens=java.base/java.lang=ALL-UNNAMED \
    -Xmx512m \
    -Dlog4j.configurationFile="$FS_CLI_HOME/conf/log4j2.xml" \
    -cp "$FS_CLI_HOME/lib/*" com.espirit.moddev.cli.Main "$@"
}

# fs-cli's output is captured, redacted, kept as the run's fs-cli.log and echoed. The
# capture (instead of a pipe) preserves fs-cli's exit code — PIPESTATUS is not POSIX sh.
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
run "$@" >"$tmp" 2>&1; status=$?
if [ -n "$PWD_VAL" ]; then
  esc=$(printf '%s' "$PWD_VAL" | sed 's/[.[\*^$/]/\\&/g')
  sed -E "s/${esc}/***/g" "$tmp" > "$OUT/fs-cli.log"
else
  cp "$tmp" "$OUT/fs-cli.log"
fi
cat "$OUT/fs-cli.log"
logrun "$status"
exit "$status"
