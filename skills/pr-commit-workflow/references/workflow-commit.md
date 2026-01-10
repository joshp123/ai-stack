# Commit Workflow

## Preconditions
- Read `~/code/nix/ai-stack/docs/agents/PROCESS.md`.
- If the repo has `AGENTS.md`, read it for repo-specific rules.

## Steps
- Ensure one logical change per commit; avoid unrelated files.
- Stage surgically; never use `git add .` or sweeping adds.
- Use surgical commits only; partials ok, bulk commits not ok.
- Amend HEAD for feedback on the same logical change; new commit only for distinct changes.
- Run the full test suite (or repo gate) before committing.
- Capture evidence of tests (command + outcome).
- Write the commit message using `references/commit-format.md`.
- If a repo has a committer script, use it.

## Evidence Recording
- Record the exact command and outcome for:
  - Smoke test (mandatory when feature behavior changes).
  - Full suite or gate (lint/typecheck/tests/docs).
- If blocked, state why and what is missing.
