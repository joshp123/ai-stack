# Checks one AI tools bundle (a build output or the installed profile): the
# three CLIs run, pi lists models, and every fixed path that the system
# generation links into the profile exists. Exit non-zero on the first problem;
# update-ai-tools gates on this. CuaDriver.app is only checked for presence:
# running the store copy taints it.
root="${1:?usage: ai-tools-smoke <bundle-root>}"

"$root/bin/pi" --version >/dev/null || { echo "smoke: pi --version failed" >&2; exit 1; }
"$root/bin/codex" --version >/dev/null || { echo "smoke: codex --version failed" >&2; exit 1; }
"$root/bin/claude" --version >/dev/null || { echo "smoke: claude --version failed" >&2; exit 1; }
"$root/bin/pi" --list-models >/dev/null || { echo "smoke: pi --list-models failed" >&2; exit 1; }

# One line per fixed path: modules/home/ai-profile.nix (PATH, pi packages),
# modules/darwin/codex-defaults.nix (dash-mcp-server), content/ (package-owned
# skills and herdr's extension), update-ai-tools (the app).
for path in \
  share/pi/packages/pi-web-search \
  bin/dash-mcp-server \
  share/cua-driver/skills/cua-driver/SKILL.md \
  share/pi-autoresearch/skills/autoresearch-create/SKILL.md \
  share/pi-autoresearch/skills/autoresearch-finalize/SKILL.md \
  share/pi-autoresearch/skills/autoresearch-hooks/SKILL.md \
  share/herdr/integrations/pi/herdr-agent-state.ts \
  Applications/CuaDriver.app/Contents/Info.plist; do
  [ -e "$root/$path" ] || { echo "smoke: missing $root/$path" >&2; exit 1; }
done
