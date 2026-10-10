import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import {
	formatSkillsForPrompt,
	truncateHead,
	type ExtensionAPI,
	type Skill,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const COLLECTION_FILE = "COLLECTION.md";
const TOOL_GROUPS = {
	web: ["web_search"],
	browser: ["agent_browser"],
} as const;

const DEFERRED_TOOLS = new Set([
	...Object.values(TOOL_GROUPS).flat(),
	"url_context",
	"launch_browser",
	"navigate_browser",
	"evaluate_browser",
]);

type ToolGroup = keyof typeof TOOL_GROUPS;

interface SkillCollection {
	id: string;
	description: string;
	skills: Skill[];
}

interface CollectionFile {
	id: string;
	description: string;
}

const LoadResourcesParams = Type.Union([
	Type.Object(
		{ action: Type.Literal("list_skills") },
		{ additionalProperties: false },
	),
	Type.Object(
		{
			action: Type.Literal("load_skill"),
			name: Type.String({ minLength: 1 }),
		},
		{ additionalProperties: false },
	),
	Type.Object(
		{
			action: Type.Literal("load_tools"),
			capability: Type.Union([Type.Literal("web"), Type.Literal("browser")]),
		},
		{ additionalProperties: false },
	),
]);

function readCollectionFile(path: string): CollectionFile {
	const lines = readFileSync(path, "utf-8").split("\n");
	let heading: string | undefined;
	const paragraph: string[] = [];

	for (const line of lines) {
		const trimmed = line.trim();
		if (!heading && trimmed.startsWith("# ")) {
			heading = trimmed.slice(2).trim();
			continue;
		}
		if (trimmed.length === 0) {
			if (paragraph.length > 0) break;
			continue;
		}
		if (!trimmed.startsWith("#")) paragraph.push(trimmed);
	}

	return {
		id: heading || "uncollected",
		description:
			paragraph.join(" ") || "Collection description missing.",
	};
}

function findCollection(skill: Skill): Omit<SkillCollection, "skills"> {
	if (skill.sourceInfo.scope === "project") {
		return {
			id: "project",
			description: "Trusted skills supplied by the current project.",
		};
	}

	let current = skill.baseDir;
	while (true) {
		const collectionPath = join(current, COLLECTION_FILE);
		if (existsSync(collectionPath)) {
			const collection = readCollectionFile(collectionPath);
			return collection;
		}

		const parent = dirname(current);
		if (parent === current) break;
		current = parent;
	}

	return {
		id: "uncollected",
		description: "Loaded skills without a collection description.",
	};
}

function buildCollections(skills: Skill[]): SkillCollection[] {
	const collections = new Map<string, SkillCollection>();

	for (const skill of skills.filter(
		(candidate) => !candidate.disableModelInvocation,
	)) {
		const found = findCollection(skill);
		const collection = collections.get(found.id) ?? {
			...found,
			skills: [],
		};
		collection.skills.push(skill);
		collections.set(found.id, collection);
	}

	return [...collections.values()]
		.map((collection) => ({
			...collection,
			skills: [...collection.skills].sort((left, right) =>
				left.name.localeCompare(right.name),
			),
		}))
		.sort((left, right) => left.id.localeCompare(right.id));
}

function compactSkillsPrompt(collections: SkillCollection[]): string {
	if (collections.length === 0) return "";

	const lines = ["", "", "Skill collections:"];
	for (const collection of collections) {
		const names = collection.skills.map((skill) => skill.name).join(", ");
		const description = collection.description.endsWith(".")
			? collection.description.slice(0, -1)
			: collection.description;
		lines.push(`- ${collection.id} — ${description}: ${names}`);
	}
	lines.push(
		"Use load_resources to list skill descriptions or load one skill by exact name.",
	);
	return lines.join("\n");
}

function listSkills(collections: SkillCollection[]): string {
	if (collections.length === 0) return "No model-invocable skills are loaded.";

	const lines: string[] = [];
	for (const collection of collections) {
		if (lines.length > 0) lines.push("");
		lines.push(`${collection.id} — ${collection.description}`);
		for (const skill of collection.skills) {
			const description = skill.description
				.split("\n")
				.map((line) => line.trim())
				.filter(Boolean)
				.join(" ");
			lines.push(`- ${skill.name}: ${description}`);
		}
	}

	const output = lines.join("\n");
	const truncation = truncateHead(output);
	if (!truncation.truncated) return output;
	return [
		truncation.content,
		"",
		`[Skill list truncated after ${truncation.outputLines} of ${truncation.totalLines} lines. Load a skill by exact name from the compact collection index.]`,
	].join("\n");
}

function findSkill(
	collections: SkillCollection[],
	name: string,
): { collection: SkillCollection; skill: Skill } | undefined {
	for (const collection of collections) {
		const skill = collection.skills.find((candidate) => candidate.name === name);
		if (skill) return { collection, skill };
	}

	return undefined;
}

function fail(message: string): never {
	throw new Error(message);
}

export default function progressiveResources(pi: ExtensionAPI) {
	let currentCollections: SkillCollection[] = [];
	let promptWarningShown = false;

	pi.registerTool({
		name: "load_resources",
		label: "Load Resources",
		description: [
			"List available skills, load one skill by exact name, or activate an optional tool capability.",
			"Tool capabilities are web and browser.",
		].join(" "),
		promptSnippet:
			"Load specialised skills or optional web and browser tools on demand.",
		promptGuidelines: [
			"Load a listed skill when it matches the task; list skills when uncertain.",
			"Prefer a service's native tools for known URLs and resources, for example git or gh for GitHub.",
			"Load web for public discovery and current information.",
			"Load browser for browsing, rendered-page inspection, authentication, or web UI interaction.",
			"Load the cua-driver skill for native desktop applications and operating-system UI; prefer browser for websites.",
		],
		parameters: LoadResourcesParams,
		executionMode: "sequential",

		async execute(_toolCallId, params) {
			switch (params.action) {
				case "list_skills":
					return {
						content: [{ type: "text", text: listSkills(currentCollections) }],
						details: {
							collections: currentCollections.map((collection) => collection.id),
						},
					};

				case "load_skill": {
					if (params.name !== params.name.trim()) {
						fail("Skill names must match exactly without surrounding whitespace.");
					}
					const found = findSkill(currentCollections, params.name);
					if (!found) {
						fail(`Unknown skill: ${params.name}. Use list_skills to see exact names.`);
					}

					try {
						const content = readFileSync(found.skill.filePath, "utf-8");
						const truncation = truncateHead(content);
						const skillContent = truncation.truncated
							? [
									truncation.content,
									"",
									`[Skill truncated after ${truncation.outputLines} of ${truncation.totalLines} lines. Continue with read on ${found.skill.filePath} at offset ${truncation.outputLines + 1}.]`,
								].join("\n")
							: content;
						return {
							content: [
								{
									type: "text",
									text: [
										`Skill: ${found.skill.name}`,
										`Collection: ${found.collection.id}`,
										`Source directory: ${found.skill.baseDir}`,
										"Resolve relative paths against the source directory.",
										"",
										skillContent,
									].join("\n"),
								},
							],
							details: {
								collection: found.collection.id,
								name: found.skill.name,
								sourceDirectory: found.skill.baseDir,
							},
						};
					} catch (error) {
						const message = error instanceof Error ? error.message : String(error);
						fail(`Could not read skill ${params.name}: ${message}`);
					}
				}

				case "load_tools": {
					const capability = params.capability as ToolGroup;
					const requested = [...TOOL_GROUPS[capability]];
					const requestedNames = new Set<string>(requested);
					const availableTools = pi.getAllTools();
					const available = new Set(availableTools.map((tool) => tool.name));
					const missing = requested.filter((name) => !available.has(name));
					if (missing.length > 0) {
						fail(`Cannot load ${capability}; unavailable tools: ${missing.join(", ")}.`);
					}

					const active = pi.getActiveTools();
					const added = requested.filter((name) => !active.includes(name));
					if (added.length > 0) {
						pi.setActiveTools([...new Set([...active, ...added])]);
					}

					const guidance = [
						...new Set(
							availableTools
								.filter((tool) => requestedNames.has(tool.name))
								.flatMap((tool) => tool.promptGuidelines ?? []),
						),
					];
					const status =
						added.length > 0
							? `Loaded ${capability}: ${added.join(", ")}.`
							: `${capability} tools are already active: ${requested.join(", ")}.`;
					const text =
						guidance.length > 0
							? `${status}\n\nGuidance:\n${guidance.map((line) => `- ${line}`).join("\n")}`
							: status;

					return {
						content: [{ type: "text", text }],
						details: { capability, added, tools: requested },
					};
				}
			}
		},
	});

	pi.on("session_start", (event) => {
		if (event.reason === "reload") return;
		pi.setActiveTools(
			pi.getActiveTools().filter((name) => !DEFERRED_TOOLS.has(name)),
		);
	});

	pi.on("before_agent_start", (event, ctx) => {
		const skills = event.systemPromptOptions.skills ?? [];
		currentCollections = buildCollections(skills);

		const verboseSkillsPrompt = formatSkillsForPrompt(skills);
		if (!verboseSkillsPrompt) return;
		if (!event.systemPrompt.includes(verboseSkillsPrompt)) {
			if (!promptWarningShown) {
				ctx.ui.notify(
					"Could not compact Pi's skill catalogue; using the full catalogue.",
					"warning",
				);
				promptWarningShown = true;
			}
			return;
		}

		return {
			systemPrompt: event.systemPrompt.replace(
				verboseSkillsPrompt,
				compactSkillsPrompt(currentCollections),
			),
		};
	});
}
