/**
 * TodoWrite Extension - Plan/progress tracking for Codex compatibility
 *
 * Provides the `todowrite` tool that Codex prompts expect.
 * Tracks steps with status: pending, in_progress, completed
 */

import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

type StepStatus = "pending" | "in_progress" | "completed";

interface Step {
	step: string;
	status: StepStatus;
}

interface TodoWriteDetails {
	steps: Step[];
	explanation?: string;
}

const StepSchema = Type.Object({
	step: Type.String({ description: "Step description (5-7 words)" }),
	status: StringEnum(["pending", "in_progress", "completed"] as const),
});

const TodoWriteParams = Type.Object({
	steps: Type.Array(StepSchema, { description: "List of steps with their status" }),
	explanation: Type.Optional(Type.String({ description: "Rationale for plan changes" })),
});

export default function (pi: ExtensionAPI) {
	let currentSteps: Step[] = [];

	const reconstructState = (ctx: ExtensionContext) => {
		currentSteps = [];
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "message") continue;
			const msg = entry.message;
			if (msg.role !== "toolResult" || msg.toolName !== "todowrite") continue;
			const details = msg.details as TodoWriteDetails | undefined;
			if (details?.steps) {
				currentSteps = details.steps;
			}
		}
	};

	pi.on("session_start", async (_event, ctx) => reconstructState(ctx));
	pi.on("session_switch", async (_event, ctx) => reconstructState(ctx));
	pi.on("session_fork", async (_event, ctx) => reconstructState(ctx));
	pi.on("session_tree", async (_event, ctx) => reconstructState(ctx));

	pi.registerTool({
		name: "todowrite",
		label: "Plan",
		description: "Track task progress with steps. Each step has status: pending, in_progress, or completed. Keep exactly one step in_progress at a time.",
		parameters: TodoWriteParams,

		async execute(_toolCallId, params, _onUpdate, _ctx, _signal) {
			currentSteps = params.steps;
			
			const completed = currentSteps.filter(s => s.status === "completed").length;
			const total = currentSteps.length;
			const inProgress = currentSteps.find(s => s.status === "in_progress");

			let text = `Plan updated: ${completed}/${total} completed`;
			if (inProgress) {
				text += `\nCurrent: ${inProgress.step}`;
			}
			if (params.explanation) {
				text += `\nRationale: ${params.explanation}`;
			}

			return {
				content: [{ type: "text", text }],
				details: { steps: currentSteps, explanation: params.explanation } as TodoWriteDetails,
			};
		},

		renderCall(args, theme) {
			const steps = args.steps as Step[];
			const completed = steps.filter(s => s.status === "completed").length;
			const inProgress = steps.find(s => s.status === "in_progress");
			
			let text = theme.fg("toolTitle", theme.bold("todowrite "));
			text += theme.fg("muted", `${completed}/${steps.length}`);
			if (inProgress) {
				text += theme.fg("dim", ` → ${inProgress.step}`);
			}
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as TodoWriteDetails | undefined;
			if (!details?.steps) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}

			const steps = details.steps;
			const lines: string[] = [];
			
			if (details.explanation) {
				lines.push(theme.fg("dim", `↳ ${details.explanation}`));
				lines.push("");
			}

			const display = expanded ? steps : steps.slice(0, 6);
			for (const s of display) {
				let icon: string;
				let textColor: string;
				switch (s.status) {
					case "completed":
						icon = theme.fg("success", "✓");
						textColor = "dim";
						break;
					case "in_progress":
						icon = theme.fg("accent", "→");
						textColor = "text";
						break;
					default:
						icon = theme.fg("dim", "○");
						textColor = "muted";
				}
				lines.push(`${icon} ${theme.fg(textColor as any, s.step)}`);
			}

			if (!expanded && steps.length > 6) {
				lines.push(theme.fg("dim", `... ${steps.length - 6} more steps`));
			}

			return new Text(lines.join("\n"), 0, 0);
		},
	});

	// Command to view current plan
	pi.registerCommand("plan", {
		description: "Show current plan/progress",
		handler: async (_args, ctx) => {
			if (currentSteps.length === 0) {
				ctx.ui.notify("No plan yet", "info");
				return;
			}

			const completed = currentSteps.filter(s => s.status === "completed").length;
			let msg = `Plan: ${completed}/${currentSteps.length} completed\n\n`;
			for (const s of currentSteps) {
				const icon = s.status === "completed" ? "✓" : s.status === "in_progress" ? "→" : "○";
				msg += `${icon} ${s.step}\n`;
			}
			ctx.ui.notify(msg.trim(), "info");
		},
	});
}
