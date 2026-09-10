#!/bin/sh
# fs-cli-export.sh — run FS-CLI (fsdevtools) with the settings that actually work
# against a modern FirstSpirit server, without rediscovering the launcher's traps.
#
# It encodes three things this skill documents:
#   1. a JRE/JDK >= the Access API jar's Java version (default: FirstSpirit's bundled JRE 21),
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
#                the FirstSpirit FSLauncher bundled JRE 21, then /usr/libexec/java_home.
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

if [ -n "$PWD_VAL" ]; then
  # Redact the password from output while preserving fs-cli's exit code
  # (a pipe would surface sed's status, and PIPESTATUS is not POSIX sh).
  esc=$(printf '%s' "$PWD_VAL" | sed 's/[.[\*^$/]/\\&/g')
  tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
  run "$@" >"$tmp" 2>&1; status=$?
  sed -E "s/${esc}/***/g" "$tmp"
  exit "$status"
else
  run "$@"
fi
