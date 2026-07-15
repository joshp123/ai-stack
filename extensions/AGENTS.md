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
- `subagent/index.ts`: bounded flat task orchestration.
- `subagent/runner.ts`: disposable child `pi` execution and JSON-event capture.
- `subagent/render.ts`: TUI rendering only.
- `subagent/schema.ts`: tool parameter schema only.
- `subagent/format.ts`: output, usage, and tool-call formatting.
- `subagent/types.ts`: shared types.

Keep active TypeScript extension files small enough to review. If an extension
needs multiple concerns, split by protocol boundary rather than adding generic
helper layers.
