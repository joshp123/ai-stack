#!/usr/bin/env bash
# Copies OpenAI's build-macos-apps skills and removes the instructions that only
# apply inside the Codex app (Run button, environment.toml, forced git init).
set -euo pipefail

cp_bin="$1"
mkdir_bin="$2"
find_bin="$3"
unlink_bin="$4"
sed_bin="$5"
official_skills="$6"
build_run_rules="$7"
swiftui_rules="$8"
manifest="$9"

"$mkdir_bin" -p "$out"
"$cp_bin" -R --no-preserve=mode "$official_skills/." "$out/"

"$sed_bin" -E -i -f "$build_run_rules" "$out/build-run-debug/SKILL.md"
"$sed_bin" -E -i -f "$swiftui_rules" "$out/swiftui-patterns/SKILL.md"

"$find_bin" "$out" -type f -path '*/agents/openai.yaml' -exec "$unlink_bin" {} \;
"$unlink_bin" "$out/build-run-debug/references/run-button-bootstrap.md"

"$cp_bin" "$manifest" "$out/MANIFEST.json"
