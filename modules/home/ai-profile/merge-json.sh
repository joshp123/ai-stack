#!/usr/bin/env bash
# Merges a few Nix-owned keys (the policy file) into an app-owned JSON file:
# pi's settings.json, Claude Code's ~/.claude.json. The app owns every other key
# and writes the file itself; both sides merge, so neither clobbers the other.
#
# The write is atomic and idempotent: the merge goes to a temporary file in the
# same directory, which is renamed over the target only when the merge changes
# something, so a reader sees the old file or the new one, never a partial one.
set -euo pipefail

settings_path="$1"
jq_bin="$2"
policy_file="$3"

dir="$(dirname "$settings_path")"
mkdir -p "$dir"

if [ -s "$settings_path" ] && ! "$jq_bin" -e . "$settings_path" >/dev/null 2>&1; then
  # Never replace a file the app may be mid-write on; the next switch retries.
  printf 'warning: %s is not valid JSON; left untouched\n' "$settings_path" >&2
  exit 0
fi

next="$(mktemp "$settings_path.XXXXXX")"
trap 'rm -f "$next"' EXIT

if [ -s "$settings_path" ]; then
  if "$jq_bin" -e --slurpfile policy "$policy_file" '. == (. * $policy[0])' "$settings_path" >/dev/null; then
    exit 0
  fi
  cp -p "$settings_path" "$next"   # keeps the app's file mode; jq's redirect keeps it too
  "$jq_bin" --slurpfile policy "$policy_file" '. * $policy[0]' "$settings_path" > "$next"
else
  "$jq_bin" --slurpfile policy "$policy_file" '$policy[0]' -n > "$next"
  chmod 600 "$next"
fi

mv -f "$next" "$settings_path"
