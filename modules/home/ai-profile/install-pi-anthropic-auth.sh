#!/usr/bin/env bash
# Sets pi's Anthropic credential to the long-lived Claude setup token from the
# agenix anthropic-api-key secret. pi never rewrites api_key entries, so this
# is idempotent; every other provider entry in auth.json is preserved.
set -euo pipefail

auth_path="$1"
jq_bin="$2"
key_file="$3"

mkdir -p "$(dirname "$auth_path")"

current="$(mktemp)"
next="$(mktemp)"
trap 'rm -f "$current" "$next"' EXIT

if [ -s "$auth_path" ] && "$jq_bin" -e . "$auth_path" >/dev/null 2>&1; then
  cp "$auth_path" "$current"
else
  printf '{}\n' > "$current"
fi

"$jq_bin" --rawfile key "$key_file" \
  '.anthropic = {type: "api_key", key: ($key | rtrimstr("\n"))}' \
  "$current" > "$next"

if ! cmp -s "$next" "$auth_path" 2>/dev/null; then
  install -m 600 "$next" "$auth_path"
fi
