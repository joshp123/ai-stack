# Nightly AI tools update, run as the user by launchd (org.nixos.update-ai-tools).
# Run it now with: launchctl kickstart gui/$(id -u)/org.nixos.update-ai-tools
#
# In its own clone of the config repo: move the nix-ai-tools and ai-stack lock
# entries, commit, build the AI bundle and the system configuration from that
# commit (the guard: main must always build), push, then install exactly the
# revision it verified into the AI profile and copy its apps to /Applications.
# Nothing is ever applied to the system. On any failure nothing is pushed or
# installed; ai-home-mail reports failures that persist for three days.

# Site configuration comes from the launchd agent's environment (set by
# modules/darwin/update-ai-tools.nix); a scratch repo, profile and state
# directory can be substituted for tests.
usage="set by the update-ai-tools launchd agent; run it with launchctl kickstart gui/\$(id -u)/org.nixos.update-ai-tools"
repo_url="${UPDATE_AI_TOOLS_REPO:?$usage}"
attr="${UPDATE_AI_TOOLS_ATTR:?$usage}"
system_attr="${UPDATE_AI_TOOLS_SYSTEM_ATTR:?$usage}"
upstream_runs="${UPDATE_AI_TOOLS_UPSTREAM_RUNS:?$usage}"
profile="${UPDATE_AI_TOOLS_PROFILE:-$HOME/.local/state/nix/profiles/ai}"
state="${AI_HOME_STATE:-$HOME/.local/state/ai-home}"
checkout="${UPDATE_AI_TOOLS_CHECKOUT:-$state/checkout}"
applications="${UPDATE_AI_TOOLS_APPLICATIONS:-/Applications}"
ai_inputs=(nix-ai-tools ai-stack)

mkdir -p "$state"
[ -f "$state/first-attempt" ] || touch "$state/first-attempt"
set -o errtrace   # the ERR trap must fire inside functions too
step="start"
on_error() {
  printf '%s: failed (exit %s)\n' "$step" "$1" > "$state/last-error"
  echo "FAILED at $step" >&2
}
trap 'on_error $?' ERR
trap 'ai-home-mail || true' EXIT

echo "==> $(date '+%Y-%m-%d %H:%M')"

# Build the bundle and the system configuration from one committed revision;
# both must succeed before that revision is pushed or installed.
verified_rev=""
verify() {
  local rev="$1"
  [ "$rev" = "$verified_rev" ] && return 0
  step="build ai-home ($rev)"
  local out
  out=$(nix build --no-link --print-out-paths "git+file://$checkout?rev=$rev#$attr")
  step="smoke ai-home ($rev)"
  ai-home-smoke "$out"
  step="system build guard ($rev)"
  nix build --no-link "git+file://$checkout?rev=$rev#$system_attr"
  verified_rev="$rev"
}

# Move the lock entries and commit when they changed; sets lock_changed.
# Called as a plain statement, never as an if condition, so that errexit and
# the ERR trap still apply and a failure is never mistaken for "unchanged".
update_lock() {
  step="nix flake update"
  nix flake update "${ai_inputs[@]}"
  lock_changed=false
  if ! git diff --quiet flake.lock; then
    step="commit"
    git commit --quiet -m "chore: update AI tools" flake.lock
    lock_changed=true
  fi
}

sync_with_origin() {
  if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
    git rebase --abort || true
  fi
  git fetch --quiet origin main
  git reset --quiet --hard origin/main
}

step="git fetch"
if [[ ! -d "$checkout/.git" ]]; then
  git clone --quiet "$repo_url" "$checkout"
fi
cd "$checkout"
sync_with_origin

update_lock
if [ "$lock_changed" = true ]; then
  verify "$(git rev-parse HEAD)"
  step="push"
  if ! git push --quiet origin HEAD:main; then
    # Someone pushed meanwhile. Start over from their main once; never rebase.
    echo "Push rejected; redoing the update on top of origin/main."
    sync_with_origin
    update_lock
    if [ "$lock_changed" = true ]; then
      verify "$(git rev-parse HEAD)"
      step="push (after redo)"
      git push --quiet origin HEAD:main
    else
      echo "Lock already current on origin/main."
    fi
  fi
  echo "Main is at $(git rev-parse --short HEAD)."
else
  echo "Lock file unchanged."
fi

# Install exactly the verified revision of main, changed tonight or not.
rev=$(git rev-parse HEAD)
verify "$rev"
step="install profile"
previous=$(readlink "$profile" 2>/dev/null || true)
nix build --profile "$profile" "git+file://$checkout?rev=$rev#$attr"
step="smoke profile"
if ! ai-home-smoke "$profile"; then
  if [ -n "$previous" ] && [ "$(readlink "$profile" 2>/dev/null || true)" != "$previous" ]; then
    nix profile rollback --profile "$profile"
    echo "Rolled back the AI profile." >&2
  fi
  false
fi
echo "AI profile at $(cat "$profile/share/ai/rev")."

# Apps that must live in /Applications (CuaDriver.app hard-codes that path and
# its daemon is launched by name). /Applications is admin-writable, so this
# runs as the user. Replace a copy only when its version changed, after
# stopping its daemon; running the store copy would taint the store.
step="install apps"
app_version() { /usr/bin/plutil -extract CFBundleShortVersionString raw "$1/Contents/Info.plist"; }
for app in "$profile"/Applications/*.app; do
  [ -e "$app" ] || continue
  name=$(basename "$app")
  target="$applications/$name"
  if [ -d "$target" ] && [ "$(app_version "$target")" = "$(app_version "$app")" ]; then
    continue
  fi
  if [ -x "$target/Contents/MacOS/cua-driver" ]; then
    "$target/Contents/MacOS/cua-driver" stop || true
  fi
  rm -rf "$target"
  /usr/bin/ditto "$(readlink -f "$app")" "$target"
  # ditto keeps the store's read-only modes; the next replacement must be able
  # to delete this copy. Modes are not part of the code signature.
  chmod -R u+w "$target"
  echo "Installed $target $(app_version "$target")."
done

step="upstream health"
if created=$(curl --fail --silent --show-error --max-time 30 "$upstream_runs" | jq -r '.workflow_runs[0].created_at // empty'); then
  if [[ -n "$created" ]] && (( $(date +%s) - $(date -d "$created" +%s) >= 3 * 86400 )); then
    printf '%s\n' "$created" > "$state/upstream-stale"
  else
    rm -f "$state/upstream-stale"
  fi
else
  echo "Could not read nix-ai-tools run history; keeping the previous upstream status." >&2
fi

step="trim"
nix profile wipe-history --profile "$profile" --older-than 7d

touch "$state/last-ok"
rm -f "$state/last-error"
echo "Done."
