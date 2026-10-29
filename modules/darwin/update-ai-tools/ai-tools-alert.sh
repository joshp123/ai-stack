# Alerts when the AI tools update has been failing for three days or
# nix-ai-tools' hourly auto-bump has had no green run for three days. Silent
# otherwise; at most one alert per day while a problem lasts. POSTs JSON to a
# webhook (for example a Grok Bot routine) with plain curl. The webhook file
# path comes from the launchd agent's environment; the file holds
# ALERT_WEBHOOK_URL=... and ALERT_WEBHOOK_KEY=... (sent as a bearer token).
state="${AI_TOOLS_STATE:-$HOME/.local/state/ai-tools}"
webhook_file="${AI_TOOLS_ALERT_WEBHOOK_FILE:?set by the update-ai-tools launchd agent}"
host=$(hostname -s)
now=$(date +%s)
day=86400
threshold=$((3 * day))
resend_after=$((20 * 3600))   # once a day, with slack for the 05:00 timer

age_of() { echo $(( now - $(stat -c %Y "$1") )); }

conditions=()
# Before the first success, measure from the first attempt, so one transient
# failure on a new machine does not alert immediately.
reference="$state/last-ok"
[ -f "$reference" ] || reference="$state/first-attempt"
if [ -f "$reference" ] && [ "$(age_of "$reference")" -ge "$threshold" ]; then
  conditions+=("The nightly AI tools update has not succeeded for $(( $(age_of "$reference") / day )) days. Last error: $(head -c 400 "$state/last-error" 2>/dev/null || echo unknown)")
fi
if [ -f "$state/upstream-stale" ]; then
  conditions+=("nix-ai-tools auto-bump has had no green run since $(cat "$state/upstream-stale"). https://github.com/joshp123/nix-ai-tools/actions/workflows/auto-bump.yml")
fi
[ "${#conditions[@]}" -gt 0 ] || exit 0

if [ -f "$state/last-alert" ] && [ "$(age_of "$state/last-alert")" -lt "$resend_after" ]; then
  echo "alert already sent today; not resending"
  exit 0
fi

# shellcheck disable=SC1090
. "$webhook_file"
body=$(jq -n --arg host "$host" '{
  source: "update-ai-tools on \($host)",
  problem: "AI tools updates are broken.",
  conditions: $ARGS.positional,
  next_step: "Put a local agent on it; it can start at ~/Library/Logs/update-ai-tools.log."
}' --args "${conditions[@]}")

# The key reaches curl through a config read from stdin, never argv.
printf 'header = "Authorization: Bearer %s"\n' "$ALERT_WEBHOOK_KEY" \
  | curl --silent --show-error --fail-with-body --config - \
      --connect-timeout 15 --max-time 60 \
      --header 'Content-Type: application/json' --data "$body" "$ALERT_WEBHOOK_URL"
touch "$state/last-alert"
echo "alert sent"
