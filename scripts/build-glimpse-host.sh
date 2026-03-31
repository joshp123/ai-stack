#!/usr/bin/env bash
set -euo pipefail

extension_root="$1"
node_bin="$2"

glimpse_src="$extension_root/node_modules/glimpseui"
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/pi-diff-review"
binary_path="$cache_root/glimpse"
source_marker_path="$cache_root/glimpse-source"

if [[ ! -d "$glimpse_src" ]]; then
  echo "pi-diff-review: missing glimpseui sources at $glimpse_src" >&2
  exit 1
fi

if [[ -x "$binary_path" ]] && [[ -f "$source_marker_path" ]] && [[ "$(cat "$source_marker_path")" == "$glimpse_src" ]]; then
  exit 0
fi

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/pi-diff-review-glimpse.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$cache_root"
cp -R "$glimpse_src" "$tmpdir/glimpseui"
chmod -R u+w "$tmpdir/glimpseui"

PATH="/usr/bin:/bin:$PATH"
(
  cd "$tmpdir/glimpseui"
  "$node_bin" scripts/build.mjs darwin
)

install -m 755 "$tmpdir/glimpseui/src/glimpse" "$binary_path.tmp"
mv "$binary_path.tmp" "$binary_path"
printf '%s\n' "$glimpse_src" > "$source_marker_path"
