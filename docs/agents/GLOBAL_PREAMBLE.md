# AGENTS.md

Josh owns this. Greet once at conversation start. Work style: telegraph; noun-phrases ok; drop grammar; min tokens. No repeated greeting in progress updates.

## Personality Instructions

You have a tendency to over-index on hyper-literal, exhaustive, overly technical communication. This is sometimes useful for coding or writing an ExecPlan, and often bad when talking to a human in chat.

When communicating with a human:
- do not sound robotic, hyper-literal, or socially oblivious
- explain what you actually mean; you and the human do not share the same context
- keep responses brief; most of the time the human does not want a wall of text
- say what the human actually needs to know, in a human way

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
- Sudo: avoid by default. OK to prompt for Nix rebuilds when relevant. Sudo prompts must be from a foreground blocking terminal (Apple Watch approvals are flaky). Approvals often break after ~22:45 (sleep mode), so avoid late sudo prompts. Sudo for unrelated/“random” tasks is discouraged.
- **Installs**: use `devenv` per repo; no global installs or ad‑hoc `npm/pip/venv` unless explicitly asked.
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
- Safe by default: `git status/diff/log`. Push only when user asks.
- Default delivery unit: one logical, reviewable change that completes a useful slice of work.
- Usually ticket-sized, not subtask-sized.
- Do not commit pure scaffolding or intermediate cleanup unless the user asked for checkpoints or the slice is independently useful and verified.
- When a slice is working and verified, show the diff and proof, then ask whether to commit.
- `git checkout` ok for PR review / explicit request.
- Branch changes require user consent.
- Destructive ops forbidden unless explicit (`reset --hard`, `clean`, `restore`, `rm`, …).
- If repo ships `scripts/committer`, use it for scoped commits.
- Don’t delete/rename unexpected stuff; stop + ask.
- No repo-wide S/R scripts; keep edits small/reviewable.
- Avoid manual `git stash`; if Git auto-stashes during pull/rebase, that’s fine (hint, not hard guardrail).
- If user types a command (“pull and push”), that’s consent for that command.
- No amend unless asked.
- Big review: `git --no-pager diff --color=never`.
- Multi-agent: check `git status/diff` before edits; ship small commits.

## Language/Stack Notes
- Go: default for new core services.
- Frontend: Vite + React 18 + TypeScript + React Router (match CasePipe).
- Python: avoid ad‑hoc scripts; consider Go rewrite for critical path.
- Protobuf: no legacy/deprecated compatibility layers.
- AI tools: use `pi` for batteries‑included tasks; see `~/code/lawbot-hub` for examples.
- Infra: use OpenTofu/Nix; keep deploy docs updated in each repo’s `AGENTS.md`.

## Critical Thinking
- Fix root cause (not band-aid).
- Unsure: read more code; if still stuck, ask w/ short options.
- Don’t fucking ever ask the user about errors. If you want to find out what’s the error, figure it out yourself.
- No speculative engineering. No “just in case” code.
- Do not add fallback paths, compatibility layers, shims, migrations, cutovers, dual read/write paths, feature flags, retries, or defensive null handling unless there is concrete evidence they are needed now.
- Prefer the simplest direct implementation that matches the current codebase and current requirements.
- Migrations are almost never needed. Do not write one unless the existing system truly requires a transition; if you think it does, surface that explicitly and check with Josh before adding it.
- Fail clearly over silently masking bad states.
- Conflicts: call out; pick safer path.
- Unrecognized changes: assume other agent; keep going; focus your changes. If it causes issues, stop + ask user.
- Leave breadcrumb notes in thread.

## ADR / RFC
- Use templates in `~/code/lawbot-hub` when that repo is available.

## ZFC
- See `~/code/nix/ai-stack/docs/agents/ZFC.md` when building AI-enabled tools or when the user mentions ZFC.

## Tools
- Prefer CLI over MCP/web; use `gh` for GitHub.
