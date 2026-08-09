---
written_by: ai
---

# extensions/

pi coding-agent extension source installed by the Home Manager module.

This directory owns extension code only. Packaging and runtime installation live
in `modules/pi-coding-agent.nix`; private agent policy lives in the consumer
repo or deployed agent docs.

## Structure

- `claude-system-prompt-compat.ts`: narrow Anthropic OAuth prompt compatibility.
- `subagent/index.ts`: six public tools and parent-session persistence wiring.
- `subagent/manager.ts`: retained-child lifecycle and recovery.
- `subagent/child-runner.ts`: the in-process Pi child seam.
- `subagent/schemas.ts`: tool parameter schemas.
- `subagent/tool-support.ts`: validation and bounded tool payloads.
- `subagent/reviewer-context.ts`: active-parent user-message snapshot.
- `subagent/roles.ts` and `subagent/agents/`: role loading and role prompts.
- `subagent/types.ts`: shared contract types.

Keep active TypeScript extension files small enough to review. If an extension
needs multiple concerns, split by protocol boundary rather than adding generic
helper layers.
