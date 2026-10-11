/^description:/a written_by: ai
/^Use this skill to set up one project-local/,/^then use that script as the default build\/run path\.$/c\
Use this skill to set up or reuse one project-local `script/build_and_run.sh`\
entrypoint, then use that script as the default build/run path.
/If no git repo is present, run `git init`/d
/Use `references\/run-button-bootstrap.md`/,/authoritative snippet in another skill or command\./d
/^4\. Write `\.codex\/environments\/environment\.toml`/,/^5\. Build and run through the script\.$/c\
4. Build and run through the script.
/^6\. Summarize failures correctly\.$/s/^6/5/
/^7\. Debug the right way\.$/s/^7/6/
/^8\. Use Xcode-aware MCP tooling only when it helps\.$/s/^8/7/
/^## References$/,/^## Guardrails$/ {
  /^## Guardrails$/!d
}
/Do not write `\.codex\/environments\/environment\.toml`/c\
- Do not create project infrastructure that the user did not request.
/script path and Codex environment action/s/the script path and Codex environment action/the script path/
