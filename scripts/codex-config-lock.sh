#!/usr/bin/env bash
set -euo pipefail

config_path="$HOME/.codex/config.toml"
if [ -e "$config_path" ]; then
  /usr/bin/chflags uchg "$config_path" 2>/dev/null || true
fi
