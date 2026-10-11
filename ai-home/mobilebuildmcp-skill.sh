# Writes MobileBuildMCP's own CLI skill, so the skill always matches the
# packaged binary. `init` also appends a hint to an AGENTS.md in the current
# directory, so it runs from a scratch directory. Telemetry stays off.
export HOME="$TMPDIR" MOBILEBUILDMCP_SENTRY_DISABLED=true XCODEBUILDMCP_SENTRY_DISABLED=true
cd "$TMPDIR"
"$mobilebuildmcp" init --skill cli --dest "$out" --force >/dev/null
test -s "$out/mobilebuildmcp-cli/SKILL.md"
