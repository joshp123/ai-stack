/**
 * Handoff extension (patched)
 *
 * Fixes common flakiness in the upstream example:
 * - avoids silent failures (shows real error instead of "Cancelled")
 * - truncates long conversation history to stay within model limits
 */

import { complete, type Message } from "@mariozechner/pi-ai";
import type { ExtensionAPI, SessionEntry } from "@mariozechner/pi-coding-agent";
import { BorderedLoader, convertToLlm, serializeConversation } from "@mariozechner/pi-coding-agent";

const SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes relevant context from the conversation (decisions made, approaches taken, key findings)
2. Lists any relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained - the new thread should be able to proceed without the old conversation

Format your response as a prompt the user can send to start the new thread. Be concise but include all necessary context. Do not include any preamble like "Here's the prompt" - just output the prompt itself.

Example output format:
## Context
We've been working on X. Key decisions:
- Decision 1
- Decision 2

Files involved:
- path/to/file1.ts
- path/to/file2.ts

## Task
[Clear description of what to do next based on user's goal]`;

const MAX_CONVERSATION_CHARS = 140_000;
const KEEP_HEAD_CHARS = 6_000;

function truncateConversation(text: string): { text: string; wasTruncated: boolean } {
	if (text.length <= MAX_CONVERSATION_CHARS) return { text, wasTruncated: false };
	const head = text.slice(0, KEEP_HEAD_CHARS);
	const tailBudget = Math.max(10_000, MAX_CONVERSATION_CHARS - KEEP_HEAD_CHARS - 500);
	const tail = text.slice(-tailBudget);
	const omitted = text.length - head.length - tail.length;
	return {
		text: `${head}\n\n…(omitted ${omitted.toLocaleString()} chars)…\n\n${tail}`,
		wasTruncated: true,
	};
}

function formatError(err: unknown): string {
	if (err instanceof Error) return err.message || err.name;
	try {
		return JSON.stringify(err);
	} catch {
		return String(err);
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("handoff", {
		description: "Transfer context to a new focused session",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("handoff requires interactive mode", "error");
				return;
			}

			if (!ctx.model) {
				ctx.ui.notify("No model selected", "error");
				return;
			}

			const goal = args.trim();
			if (!goal) {
				ctx.ui.notify("Usage: /handoff <goal for new thread>", "error");
				return;
			}

			const branch = ctx.sessionManager.getBranch();
			const messages = branch
				.filter((entry): entry is SessionEntry & { type: "message" } => entry.type === "message")
				.map((entry) => entry.message);

			if (messages.length === 0) {
				ctx.ui.notify("No conversation to hand off", "error");
				return;
			}

			const llmMessages = convertToLlm(messages);
			const conversationRaw = serializeConversation(llmMessages);
			const { text: conversationText, wasTruncated } = truncateConversation(conversationRaw);
			const currentSessionFile = ctx.sessionManager.getSessionFile();

			let lastError: string | null = null;

			const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const loader = new BorderedLoader(
					tui,
					theme,
					wasTruncated ? "Generating handoff prompt… (history truncated)" : "Generating handoff prompt…",
				);
				loader.onAbort = () => done(null);

				const doGenerate = async () => {
					let apiKey: string;
					try {
						apiKey = await ctx.modelRegistry.getApiKey(ctx.model!);
					} catch (e) {
						lastError = `Handoff failed (missing/invalid auth?): ${formatError(e)}`;
						return null;
					}

					const userMessage: Message = {
						role: "user",
						content: [
							{
								type: "text",
								text: `## Conversation History\n\n${conversationText}\n\n## User's Goal for New Thread\n\n${goal}`,
							},
						],
						timestamp: Date.now(),
					};

					const response = await complete(
						ctx.model!,
						{ systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
						{ apiKey, signal: loader.signal },
					);

					if (response.stopReason === "aborted") {
						return null;
					}

					const text = response.content
						.filter((c): c is { type: "text"; text: string } => c.type === "text")
						.map((c) => c.text)
						.join("\n")
						.trim();

					if (!text) {
						lastError = `Handoff failed: model returned no text (stopReason=${response.stopReason ?? "unknown"}).`;
						return null;
					}

					return text;
				};

				doGenerate()
					.then(done)
					.catch((err) => {
						lastError = `Handoff generation failed: ${formatError(err)}`;
						done(null);
					});

				return loader;
			});

			if (result === null) {
				if (lastError) ctx.ui.notify(lastError, "error");
				else ctx.ui.notify("Cancelled", "info");
				return;
			}

			const editedPrompt = await ctx.ui.editor(
				"Edit handoff prompt (ctrl+enter to submit, esc to cancel)",
				result,
			);
			if (editedPrompt === undefined) {
				ctx.ui.notify("Cancelled", "info");
				return;
			}

			const newSessionResult = await ctx.newSession({ parentSession: currentSessionFile });
			if (newSessionResult.cancelled) {
				ctx.ui.notify("New session cancelled", "info");
				return;
			}

			ctx.ui.setEditorText(editedPrompt);
			ctx.ui.notify("Handoff ready. Submit when ready.", "info");
		},
	});
}
