---
written_by: ai
---

# Claude guidance

## Picking the right models for workflows and subagents

Rankings, higher = better. Cost reflects effective local limits, not list price.
Intelligence is how hard a problem you can hand the model unsupervised. Taste
covers UI/UX, code quality, API design, and copy.

| model | cost | intelligence | taste |
|-------|------|--------------|-------|
| gpt-5.5 | 9 | 8 | 5 |
| sonnet-5 | 5 | 5 | 7 |
| opus-4.8 | 4 | 7 | 8 |
| fable-5 | 2 | 9 | 9 |

How to apply:
- These are defaults, not limits. You have standing permission to override
  them: if a cheaper model's output does not meet the bar, rerun or redo the
  work with a smarter model without asking. Judge the output, not the price tag.
  Escalating costs less than shipping mediocre work.
- Cost is a tie-breaker only; when axes conflict for anything that ships,
  intelligence > taste > cost.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations):
  gpt-5.5 - it's effectively free.
- Anything user-facing (UI, copy, API design) needs taste >= 7.
- Reviews of plans/implementations: fable-5 or opus-4.8, optionally gpt-5.5 as
  an extra independent perspective.
- Never use Haiku.
- Mechanics: gpt-5.5 is only reachable through the Codex CLI - `codex exec` /
  `codex review` (this setup's ~/.codex/config.toml defaults to gpt-5.5). Use
  `codex exec`, `codex review`, and direct browser/computer-use verification;
  for work they don't cover (investigation, data analysis), run
  `codex exec -s read-only` directly with a self-contained prompt.
- Claude models (sonnet-5, opus-4.8, fable-5) run via the Agent/Workflow model
  parameter.
- Local syntax note: use `sonnet` or `claude-sonnet-5`, `opus` or
  `claude-opus-4-8`, and `fable` or `claude-fable-5` when the workflow needs an
  executable model parameter.

Using gpt-5.5 inside workflows and subagents:
- The model parameter only takes Claude models, so use a wrapper.
- Spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose
  prompt instructs it to write a self-contained codex prompt, run `codex exec`
  via Bash, and return the Codex result.

Do self-review wherever possible using code-review subagents.
