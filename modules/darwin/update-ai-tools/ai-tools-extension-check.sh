# Loads the written pi extensions (the ones the current system generation
# links) into the pi of a new AI tools bundle, the way pi does at startup.
# update-ai-tools runs this before pushing or installing a bundle: the
# extensions change only on a switch, so a pi that cannot load them must not
# reach the profile. Same approach as nix-ai-tools' pi-package install check:
# RPC mode loads extensions, needs no model or key, and exits when stdin
# closes. A load failure exits non-zero; an error an extension throws during
# session start is reported on stdout as an extension_error event.
bundle="${1:?usage: ai-tools-extension-check <bundle-root> <extensions-dir>}"
extensions="${2:?usage: ai-tools-extension-check <bundle-root> <extensions-dir>}"

args=()
for entry in "$extensions"/*; do
  args+=(--extension "$entry")
done
[ "${#args[@]}" -gt 0 ] || { echo "extension check: no extensions in $extensions" >&2; exit 1; }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
if ! HOME="$scratch" "$bundle/bin/pi" --offline --no-session \
  --no-extensions --no-skills --no-prompt-templates --no-themes --no-context-files \
  "${args[@]}" --mode rpc </dev/null >"$scratch/events"; then
  echo "extension check: pi failed to load the extensions in $extensions" >&2
  exit 1
fi
errors=$(jq -R -c 'fromjson? | select(.type == "extension_error")' "$scratch/events")
if [ -n "$errors" ]; then
  echo "extension check: an extension failed in pi: $errors" >&2
  exit 1
fi
echo "extension check: $((${#args[@]} / 2)) extensions load in $(readlink -f "$bundle/bin/pi")"
