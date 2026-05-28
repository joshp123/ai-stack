set -euo pipefail

# Home Manager activation hook for ~/.pi/agent/settings.json.
# pi auto-discovers managed extensions from ~/.pi/agent/extensions, so this only
# removes obsolete upstream example extension paths and preserves valid user JSON.
settings="@settingsPath@"
extensions_json='@extensionsJson@'
jq_bin="@jq@"

mkdir -p "$(dirname "$settings")"

tmp="$(mktemp)"
if [ -f "$settings" ]; then
  if "$jq_bin" -e . "$settings" >/dev/null 2>&1; then
    cp "$settings" "$tmp"
  else
    echo "pi-coding-agent: invalid JSON in $settings, recreating with extensions" >&2
    echo '{}' > "$tmp"
  fi
else
  echo '{}' > "$tmp"
fi

"$jq_bin" --argjson exts "$extensions_json" '
  .extensions = (
    ((.extensions // [])
      | map(select(
          (test("examples/extensions/permission-gate\\.ts$") | not)
          and (test("examples/extensions/handoff\\.ts$") | not)
        ))
    )
    + $exts
  ) |
  .extensions |= unique
' "$tmp" > "$tmp.cfg"
mv "$tmp.cfg" "$tmp"

mv "$tmp" "$settings"
chmod 600 "$settings"
