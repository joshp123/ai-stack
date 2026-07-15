import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getFinalOutput } from "./format.js";
import { renderCall, renderResult } from "./render.js";
import { mapWithConcurrencyLimit, runTask } from "./runner.js";
import { SubagentParams } from "./schema.js";
import type { SubagentDetails, TaskResult, WorkItem } from "./types.js";

const MAX_TASKS = 3;
const MAX_CONCURRENCY = 3;
const THINKING_LEVELS = new Set([
	"off",
	"minimal",
	"low",
	"medium",
	"high",
	"xhigh",
	"max",
]);

function validationError(tasks: WorkItem[]): string | null {
	if (tasks.length < 1 || tasks.length > MAX_TASKS)
		return `Provide between 1 and ${MAX_TASKS} tasks.`;
	for (let index = 0; index < tasks.length; index++) {
		const task = tasks[index];
		for (const field of ["task", "context", "model"] as const) {
			if (!task[field]?.trim())
				return `Task ${index + 1} requires a non-empty ${field}.`;
		}
		if (/\s/.test(task.model))
			return `Task ${index + 1} model must be one non-whitespace selector.`;
		if (!THINKING_LEVELS.has(task.thinking))
			return `Task ${index + 1} has an unsupported thinking level.`;
	}
	return null;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "subagent",
		label: "Subagent",
		description: [
			"Run one to three independent disposable Pi tasks with isolated context.",
			"Every task must provide its task, context, model selector, and thinking level.",
			"Runs are flat: they do not share state or receive another task's output.",
		].join(" "),
		parameters: SubagentParams,

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const tasks = params.tasks as WorkItem[];
			const invalid = validationError(tasks);
			const makeDetails = (results: TaskResult[]): SubagentDetails => ({
				results,
			});
			if (invalid) {
				return {
					content: [{ type: "text", text: invalid }],
					details: makeDetails([]),
					isError: true,
				};
			}

			const allResults: TaskResult[] = tasks.map((task, index) => ({
				...task,
				index,
				exitCode: -1,
				messages: [],
				stderr: "",
				usage: {
					input: 0,
					output: 0,
					cacheRead: 0,
					cacheWrite: 0,
					cost: 0,
					contextTokens: 0,
					turns: 0,
				},
			}));

			const emitUpdate = () => {
				const done = allResults.filter(
					(result) => result.exitCode !== -1,
				).length;
				onUpdate?.({
					content: [
						{
							type: "text",
							text: `${done}/${tasks.length} disposable tasks complete`,
						},
					],
					details: makeDetails([...allResults]),
				});
			};

			const results = await mapWithConcurrencyLimit(
				tasks,
				MAX_CONCURRENCY,
				async (task, index) => {
					const result = await runTask(
						ctx.cwd,
						task,
						index,
						signal,
						(partial) => {
							if (partial.details?.results[0]) {
								allResults[index] = partial.details.results[0];
								emitUpdate();
							}
						},
						makeDetails,
					);
					allResults[index] = result;
					emitUpdate();
					return result;
				},
			);

			const failed = results.filter(
				(result) =>
					result.exitCode !== 0 ||
					result.stopReason === "error" ||
					result.stopReason === "aborted",
			);
			if (results.length === 1) {
				const result = results[0];
				const text = failed.length
					? result.errorMessage ||
						result.stderr ||
						getFinalOutput(result.messages) ||
						"Task failed without output."
					: getFinalOutput(result.messages) || "(no output)";
				return {
					content: [{ type: "text", text }],
					details: makeDetails(results),
					isError: failed.length > 0,
				};
			}

			const summaries = results.map((result) => {
				const output = getFinalOutput(result.messages).trim();
				const preview =
					output.length > 120 ? `${output.slice(0, 120)}...` : output;
				return `Task ${result.index + 1} ${result.exitCode === 0 ? "completed" : "failed"}: ${preview || "(no output)"}`;
			});
			return {
				content: [
					{
						type: "text",
						text: `${results.length - failed.length}/${results.length} tasks succeeded\n\n${summaries.join("\n\n")}`,
					},
				],
				details: makeDetails(results),
				isError: failed.length > 0,
			};
		},

		renderCall,
		renderResult,
	});
}
