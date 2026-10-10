# Lays out the contract of the AI bundle: every path here is a fixed pointer
# target for the system (modules/home/ai-profile.nix, modules/darwin/*). Add a
# path here only together with its pointer and its line in ai-home-smoke.sh.
# share/pi/packages/<name> comes from the pi packages themselves (symlinkJoin).
mkdir -p "$out/share/pi" "$out/share/claude" "$out/share/codex" "$out/share/ai" \
  "$out/Applications" "$out/bin"

ln -s "$piExtensions" "$out/share/pi/extensions"
ln -s "$piSkills" "$out/share/pi/skills"

ln -s "$claudeSkills" "$out/share/claude/skills"
ln -s "$claudeAgents" "$out/share/claude/CLAUDE.md"

ln -s "$codexSkills" "$out/share/codex/skills"

ln -s "$rulesMd" "$out/share/ai/rules.md"
ln -s "$modelsMd" "$out/share/ai/models.md"
printf '%s\n' "$rev" > "$out/share/ai/rev"

# CuaDriver.app hard-codes /Applications/CuaDriver.app, so update-ai-tools
# copies this bundle there; bin/cua-driver points at that installed copy, never
# at the store copy (running the store copy taints it with com.apple.macl).
ln -s "$cuaApp" "$out/Applications/CuaDriver.app"
ln -s /Applications/CuaDriver.app/Contents/MacOS/cua-driver "$out/bin/cua-driver"
