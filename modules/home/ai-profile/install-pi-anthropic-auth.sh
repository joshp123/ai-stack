#!/usr/bin/env bash
# Sets pi's Anthropic credential to the long-lived Claude setup token from the
# agenix anthropic-api-key secret; every other provider entry in auth.json is
# preserved. pi never rewrites api_key entries, so this is idempotent.
#
# The write is atomic: the result goes to a temporary file in the same
# directory, which is renamed over auth.json only when the entry changes.
set -euo pipefail

auth_path="$1"
jq_bin="$2"
key_file="$3"

dir="$(dirname "$auth_path")"
mkdir -p "$dir"

if [ -s "$auth_path" ] && ! "$jq_bin" -e . "$auth_path" >/dev/null 2>&1; then
  # Never replace a file pi may be mid-write on; the next switch retries.
  printf 'warning: %s is not valid JSON; left untouched\n' "$auth_path" >&2
  exit 0
fi

next="$(mktemp "$auth_path.XXXXXX")"
trap 'rm -f "$next"' EXIT

entry='{type: "api_key", key: ($key | rtrimstr("\n"))}'
if [ -s "$auth_path" ]; then
  if "$jq_bin" -e --rawfile key "$key_file" ".anthropic == $entry" "$auth_path" >/dev/null; then
    exit 0
  fi
  cp -p "$auth_path" "$next"   # keeps the file mode; jq's redirect keeps it too
  "$jq_bin" --rawfile key "$key_file" ".anthropic = $entry" "$auth_path" > "$next"
else
  "$jq_bin" -n --rawfile key "$key_file" "{anthropic: $entry}" > "$next"
  chmod 600 "$next"
fi

mv -f "$next" "$auth_path"
