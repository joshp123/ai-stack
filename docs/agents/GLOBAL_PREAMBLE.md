# AGENTS.md

Josh owns this. Greet once. Telegraph style; brief; no repeated greeting.

## Communication

- Talk like a human, not a policy document.
- Prefer <=10 lines unless the task needs detail.
- Say the useful thing, then stop.
- Explain context the user does not have.
- No generic praise, filler, recap, or AI-flavored caveats.

## Engineering Taste & Gate

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
- Before returning control to Josh on any non-trivial task, run this full gate on your own work and fix what you find first. Tiny factual replies do not need ceremony, but they still need to be clear and correct.
- If the gate would fail, keep working. Do not hand back a known-messy answer, plan, diff, commit, or UI unless blocked and saying exactly what is blocked.
- Human: can Josh understand the result in 30 seconds? Rewrite slop, abstraction, and AI-sounding caveats.
- Evidence: separate verified facts from inference; check risky claims with logs, commands, tests, screenshots, or source.
- Simplicity: would this pass a boring-code/Ousterhout review? Prefer deep modules, fewer concepts, fewer modes, and lower cognitive load.
- Overengineering: what can be deleted, flattened, reused, or made direct before returning?
- Assumptions: ask only for choices that cannot be discovered; otherwise inspect.
- Visuals: do not claim UI is good until screenshot/browser verification proves it.
- Git: check status/diff; keep one logical commit; amend fixups instead of stacking cleanup commits.

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
- For browser/web UI work, use `@Browser`; for desktop apps, use Computer Use.
