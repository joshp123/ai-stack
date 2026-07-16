import { spawn } from "node:child_process";
import { join } from "node:path";
import type { Message } from "@earendil-works/pi-ai";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import { getFinalOutput } from "./format.js";
import type {
	OnUpdateCallback,
	SubagentDetails,
	TaskResult,
	WorkItem,
} from "./types.js";

interface PiJsonEvent {
	type?: string;
	message?: Message;
}

const claudePromptCompatExtension = join(
	getAgentDir(),
	"extensions",
	"claude-system-prompt-compat.ts",
);

export async function mapWithConcurrencyLimit<TIn, TOut>(
	items: TIn[],
	concurrency: number,
	fn: (item: TIn, index: number) => Promise<TOut>,
): Promise<TOut[]> {
	if (items.length === 0) return [];
	const limit = Math.max(1, Math.min(concurrency, items.length));
	const results: TOut[] = new Array(items.length);
	let nextIndex = 0;
	const workers = new Array(limit).fill(null).map(async () => {
		while (true) {
			const current = nextIndex++;
			if (current >= items.length) return;
			results[current] = await fn(items[current], current);
		}
	});
	await Promise.all(workers);
	return results;
}

function taskPrompt(item: WorkItem): string {
	return `Task:\n${item.task.trim()}\n\nContext:\n${item.context.trim()}`;
}

export async function runTask(
	defaultCwd: string,
	item: WorkItem,
	index: number,
	signal: AbortSignal | undefined,
	onUpdate: OnUpdateCallback | undefined,
	makeDetails: (results: TaskResult[]) => SubagentDetails,
): Promise<TaskResult> {
	const model = item.model.trim();
	const currentResult: TaskResult = {
		...item,
		model,
		index,
		exitCode: 0,
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
	};

	const args = [
		"--mode",
		"json",
		"--no-extensions",
		"--extension",
		claudePromptCompatExtension,
		"--no-skills",
		"--no-prompt-templates",
		"-p",
		"--no-session",
		"--model",
		model,
		"--thinking",
		item.thinking,
		taskPrompt(item),
	];

	const emitUpdate = () => {
		onUpdate?.({
			content: [
				{
					type: "text",
					text: getFinalOutput(currentResult.messages) || "(running...)",
				},
			],
			details: makeDetails([currentResult]),
		});
	};

	let wasAborted = false;
	const exitCode = await new Promise<number>((resolve) => {
		const proc = spawn("pi", args, {
			cwd: item.cwd ?? defaultCwd,
			shell: false,
			stdio: ["ignore", "pipe", "pipe"],
		});
		let buffer = "";

		const processLine = (line: string) => {
			if (!line.trim()) return;
			let event: PiJsonEvent;
			try {
				event = JSON.parse(line) as PiJsonEvent;
			} catch {
				return;
			}

			if (event.type === "message_end" && event.message) {
				const message = event.message;
				currentResult.messages.push(message);
				if (message.role === "assistant") {
					currentResult.usage.turns++;
					const usage = message.usage;
					if (usage) {
						currentResult.usage.input += usage.input || 0;
						currentResult.usage.output += usage.output || 0;
						currentResult.usage.cacheRead += usage.cacheRead || 0;
						currentResult.usage.cacheWrite += usage.cacheWrite || 0;
						currentResult.usage.cost += usage.cost?.total || 0;
						currentResult.usage.contextTokens = usage.totalTokens || 0;
					}
					if (message.stopReason) currentResult.stopReason = message.stopReason;
					if (message.errorMessage)
						currentResult.errorMessage = message.errorMessage;
				}
				emitUpdate();
			}

			if (event.type === "tool_result_end" && event.message) {
				currentResult.messages.push(event.message);
				emitUpdate();
			}
		};

		proc.stdout.on("data", (data) => {
			buffer += data.toString();
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) processLine(line);
		});
		proc.stderr.on("data", (data) => {
			currentResult.stderr += data.toString();
		});
		proc.on("close", (code) => {
			if (buffer.trim()) processLine(buffer);
			resolve(code ?? 0);
		});
		proc.on("error", (error) => {
			currentResult.errorMessage = error.message;
			resolve(1);
		});

		const abort = () => {
			wasAborted = true;
			proc.kill("SIGTERM");
			setTimeout(() => {
				if (proc.exitCode === null) proc.kill("SIGKILL");
			}, 5000);
		};
		if (signal?.aborted) abort();
		else signal?.addEventListener("abort", abort, { once: true });
	});

	currentResult.exitCode = exitCode;
	if (wasAborted) {
		currentResult.stopReason = "aborted";
		currentResult.errorMessage = "Subagent was aborted";
	}
	return currentResult;
}
