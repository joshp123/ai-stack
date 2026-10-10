---
written_by: ai
---

# extensions/

pi coding-agent extension source. `ai-home/default.nix` links the shipped ones
into the bundle's `share/pi/extensions`; the private repo may add its own.

This directory owns extension code only; private agent policy lives in the
consumer repo or the deployed agent docs.

## Sub-agent contract

Read `subagent/API.md` before changing any file in `subagent/`. It is the
locked contract. Do not add a component or change observable behaviour without
an explicit user decision or a demonstrated Pi failure.

## Structure

- `claude-system-prompt-compat.ts`: narrow Anthropic OAuth prompt compatibility.
- `progressive-resources.ts`: compact skill catalogue by collection, `load_resources` tool for skills and the optional web/browser tool groups.
- `responses-v2-compaction/`: compaction for the OpenAI Responses provider.
- `subagent/index.ts`: six public tools and Pi event bridges.
- `subagent/parent-session-admissions.ts`: active-branch admission scan and terminal receipts.
- `subagent/live-children.ts`: in-memory child lifecycle.
- `subagent/child-runner.ts`: the in-process Pi child create and reopen seam.
- `subagent/schemas.ts`: model-facing tool parameter schemas.
- `subagent/tool-support.ts`: validation, typed results and model catalogue.
- `subagent/render.ts`: compact TUI rendering for the six tools and the terminal result message.
- `subagent/reviewer-context.ts`: active-parent user-message snapshot.
- `subagent/roles.ts` and `subagent/agents/`: role loading and role prompts.
- `subagent/types.ts`: shared contract types.

Keep active TypeScript extension files small enough to review. If an extension
needs multiple concerns, split by protocol boundary rather than adding generic
helper layers.
