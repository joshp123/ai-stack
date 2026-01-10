#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: build-clawdbot-documents.sh <src_docs_dir> <upstream_agents> <josh_agents> <out_dir>" >&2
  exit 1
fi

src_dir="$1"
upstream_agents="$2"
josh_agents="$3"
out_dir="$4"

if [ ! -d "$src_dir" ]; then
  echo "documents dir not found: $src_dir" >&2
  exit 1
fi
if [ ! -f "$upstream_agents" ]; then
  echo "upstream AGENTS.md not found: $upstream_agents" >&2
  exit 1
fi
if [ ! -f "$josh_agents" ]; then
  echo "Josh AGENTS block not found: $josh_agents" >&2
  exit 1
fi

mkdir -p "$out_dir"
cp -R "$src_dir"/. "$out_dir"/
chmod -R u+w "$out_dir"

if [ "$(head -n 1 "$upstream_agents")" = "---" ]; then
  end_line="$(awk 'NR>1 && $0=="---" {print NR; exit}' "$upstream_agents")"
  if [ -n "$end_line" ]; then
    head -n "$end_line" "$upstream_agents" > "$out_dir/AGENTS.md"
    printf '\n' >> "$out_dir/AGENTS.md"
    cat "$josh_agents" >> "$out_dir/AGENTS.md"
    printf '\n' >> "$out_dir/AGENTS.md"
    tail -n +"$((end_line + 1))" "$upstream_agents" >> "$out_dir/AGENTS.md"
  else
    cat "$upstream_agents" > "$out_dir/AGENTS.md"
    printf '\n' >> "$out_dir/AGENTS.md"
    cat "$josh_agents" >> "$out_dir/AGENTS.md"
  fi
else
  cat "$josh_agents" > "$out_dir/AGENTS.md"
  printf '\n' >> "$out_dir/AGENTS.md"
  cat "$upstream_agents" >> "$out_dir/AGENTS.md"
fi

rm -f "$out_dir/TOOLS_INSTALLED.md"
