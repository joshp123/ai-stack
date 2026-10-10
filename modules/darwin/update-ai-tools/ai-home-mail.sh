# Emails when the AI tools update has been failing for three days or
# nix-ai-tools' hourly auto-bump has had no green run for three days. Silent
# otherwise; at most one mail per day while a problem lasts. Gmail SMTP via
# curl with an app password from a file; nothing else. Recipient, sender and
# password file come from the launchd agent's environment.
state="${AI_HOME_STATE:-$HOME/.local/state/ai-home}"
to="${AI_HOME_MAIL_TO:?set by the update-ai-tools launchd agent}"
from="${AI_HOME_MAIL_FROM:?set by the update-ai-tools launchd agent}"
smtp_url="${SMTP_URL:-smtps://smtp.gmail.com:465}"
# Empty means no authentication (the local sink used by tests).
password_file="${AI_HOME_MAIL_PASSWORD_FILE?set by the update-ai-tools launchd agent}"
host=$(hostname -s)
now=$(date +%s)
day=86400
threshold=$((3 * day))
resend_after=$((20 * 3600))   # once a day, with slack for the 05:00 timer

age_of() { echo $(( now - $(stat -c %Y "$1") )); }

conditions=()
# Before the first success, measure from the first attempt, so one transient
# failure on a new machine does not mail immediately.
reference="$state/last-ok"
[ -f "$reference" ] || reference="$state/first-attempt"
if [ -f "$reference" ] && [ "$(age_of "$reference")" -ge "$threshold" ]; then
  conditions+=("The nightly AI tools update has not succeeded for $(( $(age_of "$reference") / day )) days.
Last error: $(head -c 400 "$state/last-error" 2>/dev/null || echo unknown)")
fi
if [ -f "$state/upstream-stale" ]; then
  conditions+=("nix-ai-tools auto-bump has had no green run since $(cat "$state/upstream-stale").
https://github.com/joshp123/nix-ai-tools/actions/workflows/auto-bump.yml")
fi
[ "${#conditions[@]}" -gt 0 ] || exit 0

if [ -f "$state/last-mail" ] && [ "$(age_of "$state/last-mail")" -lt "$resend_after" ]; then
  echo "alert already mailed today; not resending"
  exit 0
fi

message=$(mktemp)
trap 'rm -f "$message"' EXIT
{
  printf 'From: AI tools update <%s>\r\n' "$from"
  printf 'To: %s\r\n' "$to"
  printf 'Subject: [%s] AI tools update needs attention\r\n' "$host"
  printf 'Date: %s\r\n' "$(date -R)"
  printf 'Message-ID: <ai-home-%s@%s>\r\n' "$now" "$host"
  printf 'Content-Type: text/plain; charset=utf-8\r\n'
  printf '\r\n'
  printf 'AI tools updates are broken.\r\n\r\n'
  for c in "${conditions[@]}"; do printf '%s\r\n\r\n' "$c"; done
  printf 'Put a local agent on it (it can start at ~/Library/Logs/update-ai-tools.log).\r\n'
} > "$message"

# The credential reaches curl through a config read from stdin, never argv.
curl_config() {
  if [ -n "$password_file" ]; then
    printf 'ssl-reqd\nuser = "%s:%s"\n' "$from" "$(cat "$password_file")"
  fi
}
curl_config | curl --silent --show-error --config - \
  --connect-timeout 15 --max-time 60 \
  --url "$smtp_url" --mail-from "$from" --mail-rcpt "$to" --upload-file "$message"
touch "$state/last-mail"
echo "alert mailed to $to"
