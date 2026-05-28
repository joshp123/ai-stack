set -euo pipefail

# Wrapper run by launchd/systemd to keep cass indexed for agent-session search.
# First run builds the index if the DB/index is missing; steady state watches
# for new session data. CODING_AGENT_SEARCH_NO_UPDATE_PROMPT prevents TUI hangs.
cass_bin="${CASS_BIN:-cass}"
jq_bin="${JQ_BIN:-jq}"

export CODING_AGENT_SEARCH_NO_UPDATE_PROMPT=1

status_json="$("$cass_bin" status --json 2>/dev/null || true)"
needs_full_index="$(
  echo "$status_json" | "$jq_bin" -r '
    ( (.database.exists // false) and (.index.exists // false) ) | not
  ' 2>/dev/null || echo true
)"

if [[ "$needs_full_index" == "true" ]]; then
  "$cass_bin" index --full
fi

exec "$cass_bin" index --watch
