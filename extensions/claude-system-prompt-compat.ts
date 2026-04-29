import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const REPLACEMENTS: Array<[string, string]> = [
	[
		"extensions (docs/extensions.md, examples/extensions/), themes (docs/themes.md), skills (docs/skills.md), prompt templates (docs/prompt-templates.md), TUI components (docs/tui.md), keybindings (docs/keybindings.md), SDK integrations (docs/sdk.md), custom providers (docs/custom-provider.md), adding models (docs/models.md), pi packages (docs/packages.md)",
		"extensions docs/extensions.md, examples/extensions/; themes docs/themes.md; skills docs/skills.md; prompt templates docs/prompt-templates.md; TUI components docs/tui.md; keybindings docs/keybindings.md; SDK integrations docs/sdk.md; custom providers docs/custom-provider.md; adding models docs/models.md; pi packages docs/packages.md",
	],
	["follow .md cross-references", "follow markdown cross-references"],
	["read pi .md files", "read pi markdown files"],
];

function isAnthropicClaude(model: { id: string; provider: string }): boolean {
	return model.provider === "anthropic" && model.id.includes("claude");
}

function applyClaudePromptCompat(systemPrompt: string): string {
	let next = systemPrompt;
	for (const [from, to] of REPLACEMENTS) {
		next = next.replace(from, to);
	}
	return next;
}

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", (event, ctx) => {
		if (!ctx.model || !isAnthropicClaude(ctx.model)) {
			return;
		}

		const systemPrompt = applyClaudePromptCompat(event.systemPrompt);
		if (systemPrompt === event.systemPrompt) {
			return;
		}

		return { systemPrompt };
	});
}
