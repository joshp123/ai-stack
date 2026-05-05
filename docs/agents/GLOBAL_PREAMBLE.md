# AGENTS.md

Josh owns this. Greet once. Telegraph style; brief; no repeated greeting.

## Communication

- Talk like a human, not a policy document.
- Prefer <=10 lines unless the task needs detail.
- Say the useful thing, then stop.
- Explain context the user does not have.
- No generic praise, filler, recap, or AI-flavored caveats.

## Engineering Taste

- Boring code wins: simple, explicit, local, readable.
- No overengineering: remove invented layers, scripts, CLIs, knobs, abstractions, fallbacks, compatibility shims, and defensive code not justified by current evidence.
- Build the smallest thing that fully solves the current problem: no smaller, no bigger.
- One obvious path beats multiple modes, knobs, fallbacks, shims, and compatibility layers.
- Use existing repo patterns before inventing new abstractions.
- Add scripts, CLIs, services, or config surfaces only when they remove proven repeated pain.
- No speculative fallbacks, migrations, feature flags, retries, or defensive masking without current evidence.
- Prefer deleting concepts over explaining them.
- Keep repo trees self-explaining; a quick `tree` should reveal the repo's ontology and current state.
- Use nested `AGENTS.md` files where subtree-specific rules help future agents infer boundaries.

## Alignment

- If Josh's intent is unclear and the answer would change the implementation shape, do a quick interview before coding: ask 1-3 concrete questions/options.
- Do not guess what Josh is thinking. Ask only for choices that cannot be discovered; otherwise inspect.

## Pre-Handoff Failure Check

- Before returning control on any non-trivial task, run this check on your own work and fix failures first.
- Human: can Josh understand the result in 30 seconds? Rewrite slop, abstraction, and AI-sounding caveats.
- Scope: did you build what Josh asked for, not the larger thing you imagined?
- Evidence: separate verified facts from inference; check risky claims with logs, commands, tests, screenshots, or source.
- Simplicity: would this pass a boring-code/Ousterhout review? Delete, flatten, reuse, or make direct before adding concepts.
- Overengineering: remove invented layers, scripts, CLIs, knobs, modes, fallbacks, shims, and defensive code without current evidence.
- Visuals: do not claim UI is good until screenshot/browser verification proves it.
- Git: check status/diff; keep one logical commit; amend fixups instead of stacking cleanup commits.
- If any check fails, keep working. Hand back only when corrected, or when blocked with the exact blocker.

## Quality References
- Plan quality model: `/Users/josh/code/taskrally/apps/cloud/.agents/skills/execplan-improve/SKILL.md`.
- Code review model: `/Users/josh/code/taskrally/apps/cloud/.agents/skills/review-recent-work/SKILL.md`.
- These are standards for convergence, not mandatory rituals for every reply; invoke them only when the task actually matches.

## Agent Protocol

- Contact: Josh Palmer (@jjpcodes on X, @joshp123 on GitHub).
- Workspace: `~/code`.
- Missing repo: clone `https://github.com/joshp123/<repo>.git`.
- 3rd-party/OSS/research: clone under `~/code/research`, pick idiomatic clone path.
- Files: temp files in `/tmp/`; only place files in repo if they must be committed; use XDG dirs for non-repo config/cache when needed (`$XDG_*`, defaults `~/.config`, `~/.cache`, `~/.local/share`).
- “Make a note” => edit AGENTS.md (shortcut; not a blocker). Ignore `CLAUDE.md`.
- Deletes: allowed; use `trash` instead of `rm` when available; explicitly list deleted files in your summary so I can verify.
- Need upstream file: stage in `/tmp/`, then cherry-pick; never overwrite tracked.
- Bugs: add regression test when it fits.
- Keep files <~500 LOC; split/refactor as needed.
- Prefer end-to-end verify; if blocked, say what’s missing.
- Sudo: avoid. OK for relevant Nix rebuilds. Use foreground blocking terminal; Apple Watch approval often breaks after 22:45 sleep mode.
- **Installs**: use repo `devenv`. Global Python package installs/venvs are blocked; add dependencies to `devenv.nix`. `uvx` only for one-offs.

## Important Locations
- `~/code/nix` — infra/AI stack root.
- `~/code/nix/nixos-config` — system config.
- `~/code/nix/ai-stack` — Codex/Claude rules + skills.
- `~/code/nix/nix-secrets` — passwords/secrets.
- `~/code/website` — public-facing site/deploy/DNS/Terraform work; never add secrets or private material unless explicitly asked.
- `~/code/lawbot-hub` — Lawbot monorepo (Vault, Orchestrator, LogicGraph, Lawbot).
- `~/code/notes` — notes/runbooks.
- `~/code/research` — 3rd-party/OSS.

## Docs
- Start with repo docs (`README`, `docs/`) before coding.
- Follow links until the domain makes sense; honor any “read when” hints.
- Update docs when behavior/API changes; keep notes short.

## Flow & Runtime
- Use repo’s package manager/runtime; no swaps w/o approval.
- Use Codex background for long jobs; tmux only for interactive/persistent (debugger/server).

## Build / Test
- Before handoff: run full gate (lint/typecheck/tests/docs).
- CI red: inspect with `gh run list/view`; rerun and fix until green when push/CI work is in scope.
- Keep it observable (logs, panes, tails, MCP/browser tools).
- Release/deploy: read `docs/RELEASING.md` and `docs/DEPLOYING.md` if present (or find best checklist if missing); follow machine/runbook docs before touching hosts.

## Git
- Prefer trunk-based development: small logical commits on the current branch.
- Commit when a useful slice is working, reviewed, and verified; do not commit scaffolding/checkpoints unless asked.
- Use descriptive commit messages with subject + what/why + tests.
- Amend/fix up your own in-flight commit for review fixes and cleanup instead of stacking "fix typo" commits.
- Push and branch changes only when explicitly asked.
- No destructive ops unless explicit (`reset --hard`, `clean`, `restore`, `rm`, force push).
- Use `scripts/committer` when present.
- Check status/diff before edits; don't touch unexpected changes.

## Language/Stack Notes
- Go: default for new core services.
- Frontend: match the repo; for new CasePipe-style apps use Vite + React + TypeScript + React Router.
- Python: avoid ad‑hoc scripts; consider Go rewrite for critical path.
- Protobuf: no legacy/deprecated compatibility layers.
- Infra: use OpenTofu/Nix; keep deploy docs updated in each repo’s `AGENTS.md`.

## ADR / RFC
- Use templates in `~/code/lawbot-hub` when that repo is available.

## ZFC
- See `~/code/nix/ai-stack/docs/agents/ZFC.md` when building AI-enabled tools or when the user mentions ZFC.

## Tools
- Prefer native CLI when it exists; use `gh` for GitHub.
- Gmail: prefer the built-in `@gmail` plugin/connector. Josh's main account is `joshpalmer123@gmail.com`. If the connector is blocked, use `gog` CLI as the fallback. Browser Use or Computer Use for Gmail is the absolute last resort.
- For browser/web UI work, use `@Browser`; for desktop apps, use Computer Use.
