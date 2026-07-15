import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import { getMarkdownTheme, type Theme } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import {
	formatToolCall,
	formatUsageStats,
	getDisplayItems,
	getFinalOutput,
} from "./format.js";
import type {
	DisplayItem,
	SubagentDetails,
	TaskResult,
	WorkItem,
} from "./types.js";

const COLLAPSED_ITEM_COUNT = 5;

function failed(result: TaskResult): boolean {
	return (
		result.exitCode > 0 ||
		result.stopReason === "error" ||
		result.stopReason === "aborted"
	);
}

export function renderCall(args: { tasks?: WorkItem[] }, theme: Theme) {
	const tasks = Array.isArray(args.tasks) ? args.tasks : [];
	let text =
		theme.fg("toolTitle", theme.bold("subagent ")) +
		theme.fg(
			"accent",
			`${tasks.length} disposable task${tasks.length === 1 ? "" : "s"}`,
		);
	for (let index = 0; index < tasks.length; index++) {
		const task = tasks[index];
		const preview =
			task.task.length > 48 ? `${task.task.slice(0, 48)}...` : task.task;
		text +=
			`\n  ${theme.fg("muted", `${index + 1}.`)}` +
			` ${theme.fg("accent", task.model)}` +
			` ${theme.fg("muted", `[${task.thinking}]`)}` +
			` ${theme.fg("dim", preview)}`;
	}
	return new Text(text, 0, 0);
}

function aggregateUsage(results: TaskResult[]) {
	const total = {
		input: 0,
		output: 0,
		cacheRead: 0,
		cacheWrite: 0,
		cost: 0,
		turns: 0,
	};
	for (const result of results) {
		total.input += result.usage.input;
		total.output += result.usage.output;
		total.cacheRead += result.usage.cacheRead;
		total.cacheWrite += result.usage.cacheWrite;
		total.cost += result.usage.cost;
		total.turns += result.usage.turns;
	}
	return total;
}

function renderItems(items: DisplayItem[], theme: Theme): string {
	const shown = items.slice(-COLLAPSED_ITEM_COUNT);
	let text =
		items.length > shown.length
			? theme.fg("muted", `... ${items.length - shown.length} earlier items\n`)
			: "";
	for (const item of shown) {
		if (item.type === "text")
			text += `${theme.fg("toolOutput", item.text.split("\n").slice(0, 3).join("\n"))}\n`;
		else
			text += `${theme.fg("muted", "→ ")}${formatToolCall(item.name, item.args, theme.fg.bind(theme))}\n`;
	}
	return text.trimEnd();
}

export function renderResult(
	result: AgentToolResult<SubagentDetails>,
	{ expanded }: { expanded: boolean },
	theme: Theme,
) {
	const details = result.details as SubagentDetails | undefined;
	if (!details?.results.length) {
		const content = result.content[0];
		return new Text(
			content?.type === "text" ? content.text : "(no output)",
			0,
			0,
		);
	}

	const running = details.results.filter((task) => task.exitCode === -1).length;
	const failures = details.results.filter(failed).length;
	const complete = details.results.length - running;
	const icon =
		running > 0
			? theme.fg("warning", "⏳")
			: failures > 0
				? theme.fg("warning", "◐")
				: theme.fg("success", "✓");
	const status =
		running > 0
			? `${complete}/${details.results.length} complete`
			: `${details.results.length - failures}/${details.results.length} succeeded`;

	if (expanded && running === 0) {
		const container = new Container();
		container.addChild(
			new Text(
				`${icon} ${theme.fg("toolTitle", theme.bold("subagent "))}${theme.fg("accent", status)}`,
				0,
				0,
			),
		);
		const markdownTheme = getMarkdownTheme();
		for (const task of details.results) {
			const taskIcon = failed(task)
				? theme.fg("error", "✗")
				: theme.fg("success", "✓");
			container.addChild(new Spacer(1));
			container.addChild(
				new Text(
					`${theme.fg("muted", `─── Task ${task.index + 1}`)} ${taskIcon} ${theme.fg("accent", task.model)} ${theme.fg("muted", `[${task.thinking}]`)}`,
					0,
					0,
				),
			);
			container.addChild(new Text(theme.fg("dim", task.task), 0, 0));
			for (const item of getDisplayItems(task.messages)) {
				if (item.type === "toolCall")
					container.addChild(
						new Text(
							`${theme.fg("muted", "→ ")}${formatToolCall(item.name, item.args, theme.fg.bind(theme))}`,
							0,
							0,
						),
					);
			}
			const output = getFinalOutput(task.messages).trim();
			if (output) {
				container.addChild(new Spacer(1));
				container.addChild(new Markdown(output, 0, 0, markdownTheme));
			} else if (task.errorMessage || task.stderr) {
				container.addChild(
					new Text(
						theme.fg("error", task.errorMessage || task.stderr.trim()),
						0,
						0,
					),
				);
			}
			const usage = formatUsageStats(task.usage, task.model);
			if (usage) container.addChild(new Text(theme.fg("dim", usage), 0, 0));
		}
		const usage = formatUsageStats(aggregateUsage(details.results));
		if (usage) {
			container.addChild(new Spacer(1));
			container.addChild(new Text(theme.fg("dim", `Total: ${usage}`), 0, 0));
		}
		return container;
	}

	let text = `${icon} ${theme.fg("toolTitle", theme.bold("subagent "))}${theme.fg("accent", status)}`;
	for (const task of details.results) {
		const taskIcon =
			task.exitCode === -1
				? theme.fg("warning", "⏳")
				: failed(task)
					? theme.fg("error", "✗")
					: theme.fg("success", "✓");
		text += `\n\n${theme.fg("muted", `─── Task ${task.index + 1}`)} ${taskIcon} ${theme.fg("accent", task.model)} ${theme.fg("muted", `[${task.thinking}]`)}`;
		const items = getDisplayItems(task.messages);
		if (items.length) text += `\n${renderItems(items, theme)}`;
		else
			text += `\n${theme.fg("muted", task.exitCode === -1 ? "(running...)" : "(no output)")}`;
	}
	if (running === 0) {
		const usage = formatUsageStats(aggregateUsage(details.results));
		if (usage) text += `\n\n${theme.fg("dim", `Total: ${usage}`)}`;
	}
	if (!expanded) text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
	return new Text(text, 0, 0);
}
