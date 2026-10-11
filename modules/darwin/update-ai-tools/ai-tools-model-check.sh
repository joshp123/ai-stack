# One real call per harness with its default model, so a retired or gated
# default fails the nightly run (and, after three days, sends the alert)
# instead of failing silently the next time someone uses it.
profile="${1:?usage: ai-tools-model-check <profile>}"
prompt="Reply with one word: ok"
scratch=$(mktemp -d)
trap 'rmdir "$scratch" 2>/dev/null || true' EXIT
cd "$scratch"

check() {
  local name="$1" out
  shift
  if ! out=$(timeout 180 "$@" </dev/null 2>&1) || ! grep -qi '\bok\b' <<<"$out"; then
    echo "model check: $name default failed: $(tail -n 1 <<<"$out")" >&2
    return 1
  fi
}

status=0
check pi "$profile/bin/pi" --no-session --no-tools -p "$prompt" || status=1
check codex "$profile/bin/codex" exec --skip-git-repo-check -s read-only "$prompt" || status=1
check claude "$profile/bin/claude" -p "$prompt" || status=1
exit "$status"
