# AGENTS.md

Josh owns this. Greet once. Telegraph style; brief; no repeated greeting.

## Communication

- Talk like a human, not a policy document.
- Prefer <=10 lines unless the task needs detail.
- Say the useful thing, then stop.
- Explain context the user does not have.
- No generic praise, filler, recap, or AI-flavored caveats.

## Agent Protocol

- Contact: Josh Palmer (@jjpcodes on X, @joshp123 on GitHub).
- Workspace: `~/code`.
- Missing repo: clone `https://github.com/joshp123/<repo>.git`.
- 3rd-party/OSS/research: clone under `~/code/research`, pick idiomatic clone path.
- Files: temp files in `/tmp/`; only place files in repo if they must be committed; use XDG dirs for non-repo config/cache when needed (`$XDG_*`, defaults `~/.config`, `~/.cache`, `~/.local/share`).
- PRs: use `gh pr view/diff` (no URLs).
- “Make a note” => edit AGENTS.md (shortcut; not a blocker). Ignore `CLAUDE.md`.
- Deletes: allowed; use `trash` instead of `rm` when available; explicitly list deleted files in your summary so I can verify.
- Need upstream file: stage in `/tmp/`, then cherry-pick; never overwrite tracked.
- Bugs: add regression test when it fits.
- Keep files <~500 LOC; split/refactor as needed.
- Commits: descriptive messages; multi-line heredoc (subject + what/why + tests).
- Editor: `code <path>`; use `open <url>` for webpages.
- CI: `gh run list/view` (rerun/fix til green).
- Prefer end-to-end verify; if blocked, say what’s missing.
- Web: prefer native commands (e.g., `gh` for GitHub links), `curl`/`wget` for links, cloning repos, over web search.
- Sudo: avoid. OK for relevant Nix rebuilds. Use foreground blocking terminal; avoid late-night prompts.
- **Installs**: use repo `devenv`. Global Python package installs/venvs are blocked; add dependencies to `devenv.nix`. `uvx` only for one-offs.
- **Simplicity**: one obvious way > many; explicit > implicit; simple > complex; flat > nested; readability counts; refuse to guess in code/docs (ask if ambiguous); if hard to explain, it’s a bad idea; avoid premature optimization.

## Screenshots (“use a screenshot”)
- If user pasted screenshot URL or path, use that first.
- Use newest PNG in `~/Desktop` or `~/Downloads`; verify it’s the right UI (ignore filename).
- Size: `sips -g pixelWidth -g pixelHeight <file>` (prefer 2×); optimize with `imageoptim <file>` if shipping.

## Important Locations
- `~/code/nix` — infra/AI stack root.
- `~/code/nix/nixos-config` — system config.
- `~/code/nix/ai-stack` — Codex/Claude rules + skills.
- `~/code/lawbot-hub` — Lawbot monorepo (Vault, Orchestrator, LogicGraph, Lawbot).
- `~/code/notes` — notes/runbooks.
- `~/code/research` — 3rd-party/OSS.

## Docs
- Start with repo docs (`README`, `docs/`) before coding.
- Follow links until the domain makes sense; honor any “read when” hints.
- Update docs when behavior/API changes; keep notes short.

## PR Feedback
- Active PR: `gh pr view --json number,title,url --jq '"PR #\\(.number): \\(.title)\\n\\(.url)"'`.
- PR comments: `gh pr view …` + `gh api …/comments --paginate`.
- Replies: cite fix + file/line; resolve threads only after fix lands.
- When merging a PR: thank the contributor in `CHANGELOG.md`.

## Flow & Runtime
- Use repo’s package manager/runtime; no swaps w/o approval.
- Use Codex background for long jobs; tmux only for interactive/persistent (debugger/server).

## Build / Test
- Before handoff: run full gate (lint/typecheck/tests/docs).
- CI red: `gh run list/view`, rerun, fix, push, repeat til green.
- Keep it observable (logs, panes, tails, MCP/browser tools).
- Release/deploy: read `docs/RELEASING.md` and `docs/DEPLOYING.md` if present (or find best checklist if missing); follow machine/runbook docs before touching hosts.

## Git
- Safe reads: `git status/diff/log`. Push, branch, amend only when asked.
- Ship one logical, reviewable slice with proof.
- No destructive ops unless explicit (`reset --hard`, `clean`, `restore`, `rm`, force push).
- Use `scripts/committer` when present.
- Check status/diff before edits; don't touch unexpected changes.

## Language/Stack Notes
- Go: default for new core services.
- Frontend: Vite + React 18 + TypeScript + React Router (match CasePipe).
- Python: avoid ad‑hoc scripts; consider Go rewrite for critical path.
- Protobuf: no legacy/deprecated compatibility layers.
- AI tools: use `pi` for batteries‑included tasks; see `~/code/lawbot-hub` for examples.
- Infra: use OpenTofu/Nix; keep deploy docs updated in each repo’s `AGENTS.md`.

## Critical Thinking
- Fix root cause.
- If unsure, inspect; if still ambiguous, ask short options.
- Investigate errors yourself.
- No speculative fallbacks, shims, migrations, feature flags, retries, or defensive masking without current evidence.
- Prefer the simplest direct implementation that matches the current codebase and requirements.
- Fail clearly. Call out conflicts. Leave breadcrumbs.

## ADR / RFC
- Use templates in `~/code/lawbot-hub` when that repo is available.

## ZFC
- See `~/code/nix/ai-stack/docs/agents/ZFC.md` when building AI-enabled tools or when the user mentions ZFC.

## Tools
- Prefer CLI over MCP/web; use `gh` for GitHub.
