# Checks one AI bundle (a build output or the installed profile): the three
# CLIs run, pi lists models, and every path the system points at exists.
# Exit non-zero on the first problem; update-ai-tools gates on this.
# CuaDriver.app is only checked for presence: running the store copy taints it.
root="${1:?usage: ai-home-smoke <bundle-root>}"

"$root/bin/pi" --version >/dev/null || { echo "smoke: pi --version failed" >&2; exit 1; }
"$root/bin/codex" --version >/dev/null || { echo "smoke: codex --version failed" >&2; exit 1; }
"$root/bin/claude" --version >/dev/null || { echo "smoke: claude --version failed" >&2; exit 1; }
"$root/bin/pi" --list-models >/dev/null || { echo "smoke: pi --list-models failed" >&2; exit 1; }

for path in \
  share/pi/packages/pi-web-search \
  share/pi/packages/pi-agent-browser-native \
  share/pi/extensions/progressive-resources.ts \
  share/pi/extensions/responses-v2-compaction \
  share/pi/skills/shared/ai-stack/COLLECTION.md \
  share/pi/skills/openai/build-macos-apps/COLLECTION.md \
  bin/dash-mcp-server \
  share/pi/skills/tools/cua-driver/cua-driver/SKILL.md \
  Applications/CuaDriver.app/Contents/Info.plist \
  share/pi/extensions/claude-system-prompt-compat.ts \
  share/pi/extensions/subagent \
  share/pi/skills \
  share/claude/skills \
  share/claude/CLAUDE.md \
  share/codex/skills \
  share/ai/rules.md \
  share/ai/models.md \
  share/ai/rev; do
  [ -e "$root/$path" ] || { echo "smoke: missing $root/$path" >&2; exit 1; }
done
