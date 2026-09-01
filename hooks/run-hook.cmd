#!/usr/bin/env bash
set -euo pipefail
HOOK_NAME="${1:-}"
if [ -z "$HOOK_NAME" ]; then
  echo "Usage: run-hook.cmd <hook-name>" >&2
  exit 1
fi
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$HOOKS_DIR/$HOOK_NAME"
