#!/bin/zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: codex-notify '<json-payload>'" >&2
  exit 1
fi

payload="$1"
app_name="CodexNotifier"
app_support="$HOME/Library/Application Support/CodexNotifier"
payload_file="$app_support/payload.json"

mkdir -p "$app_support"
printf '%s' "$payload" > "$payload_file"

open -g -a "$app_name" >/dev/null 2>&1 || true
