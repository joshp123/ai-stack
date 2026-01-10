# PR Workflow

## Preconditions
- Read `~/code/nix/ai-stack/docs/agents/PROCESS.md`.
- If the repo has `AGENTS.md`, read it for repo-specific rules.

## Mandatory Human Intent Capture
- Prompt the user for a human-written intent section.
- Do not draft, rewrite, summarize, or paraphrase the intent.
- Paste the intent verbatim at the very top of the PR body.
- If intent is missing, stop and request it.

## Steps
- Ensure branch is clean and only includes the intended commits.
- Check for other open PRs that may conflict.
- Build PR body using `references/pr-human-template.md`.
- Fill non-human sections with factual, testable info.
- Use `/tmp` + `gh pr edit --body-file` for updates.
- Create PR with `gh pr create` if not already open.

## Prompt History Requirements
- Include ISO-8601 timestamps with timezone.
- Prefer `cm`/`cass` history search; if unavailable, fall back to agent logs and note the fallback.
- Always include Environment metadata under Prompt History:
  - Harness
  - Model
  - Thinking level
  - Terminal
  - System
- Use `scripts/build_pr_body.sh` to collect environment fields when possible.
- If any field is unknown, ask the user to fill it.

## Review Comment Checks
- Always check both:
  - `gh pr view <id> --comments`
  - `gh api /repos/<org>/<repo>/pulls/<id>/comments --paginate`
- Summarize inline feedback with file + line + fix status.
