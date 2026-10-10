#!/usr/bin/env bash
# Merges a few Nix-owned keys (the policy file) into an app-owned JSON file:
# pi's settings.json, Claude Code's ~/.claude.json. The app owns every other key
# and writes the file itself; both sides merge, so neither clobbers the other.
set -euo pipefail

settings_path="$1"
jq_bin="$2"
policy_file="$3"

mkdir -p "$(dirname "$settings_path")"

current="$(mktemp)"
next="$(mktemp)"
trap 'rm -f "$current" "$next"' EXIT

if [ -s "$settings_path" ]; then
  if ! "$jq_bin" -e . "$settings_path" >/dev/null 2>&1; then
    # Never replace a file the app may be mid-write on; the next switch retries.
    printf 'warning: %s is not valid JSON; left untouched\n' "$settings_path" >&2
    exit 0
  fi
  cp "$settings_path" "$current"
else
  printf '{}\n' > "$current"
fi

"$jq_bin" --slurpfile policy "$policy_file" '. * $policy[0]' "$current" > "$next"

if ! cmp -s "$next" "$settings_path" 2>/dev/null; then
  install -m 600 "$next" "$settings_path"
fi
