import type { Api, Context, Model, Tool } from "@earendil-works/pi-ai";
import { complete } from "@earendil-works/pi-ai";
import {
	buildSessionContext,
	convertToLlm,
	type ExtensionAPI,
	type ExtensionContext,
	parseSkillBlock,
	type SessionEntry,
} from "@earendil-works/pi-coding-agent";

const COMPACTION_SUMMARY_MARKER = "[pi:responses-v2-compaction]";
const SERIALIZED_COMPACTION_MARKER = `The conversation history before this point was compacted into the following summary:\n\n<summary>\n${COMPACTION_SUMMARY_MARKER}\n</summary>`;
const NO_RETAINED_SESSION_TAIL_ENTRY_ID = "responses-v2:no-retained-session-tail";
const PROFILE_ENTRY_TYPE = "responses-v2-compaction-profile";
const RETAINED_USER_TOKEN_TARGET = 64_000;
const RESPONSES_V2_FEATURE = "remote_compaction_v2";
const V2_FULL_CONTEXT_WINDOW = 372_000;

type CompactionProfile = "pi" | "v2-current" | "v2-full";

interface ResponsesV2CompactionDetails {
	kind: "responses-v2";
	items: Record<string, unknown>[];
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isResponsesV2Model(model: Model<Api> | undefined): model is Model<"openai-codex-responses"> {
	return model?.provider === "openai-codex" && model.api === "openai-codex-responses";
}

function profile(branch: readonly SessionEntry[]): CompactionProfile {
	const entry = branch.findLast((candidate) =>
		candidate.type === "custom" && candidate.customType === PROFILE_ENTRY_TYPE
	);
	return entry?.type === "custom" &&
		(entry.data === "v2-current" || entry.data === "v2-full" || entry.data === "pi")
		? entry.data
		: "pi";
}

function latestResponsesV2Details(branch: readonly SessionEntry[]): ResponsesV2CompactionDetails | undefined {
	const latestCompaction = branch.findLast((entry) => entry.type === "compaction");
	if (!latestCompaction || !isRecord(latestCompaction.details)) return undefined;
	const { kind, items } = latestCompaction.details;
	return kind === "responses-v2" && Array.isArray(items)
		? latestCompaction.details as unknown as ResponsesV2CompactionDetails
		: undefined;
}

function isSerializedCompactionMarker(item: unknown): boolean {
	if (!isRecord(item) || item.role !== "user" || !Array.isArray(item.content)) return false;
	return item.content.some((part) =>
		isRecord(part) && part.type === "input_text" && part.text === SERIALIZED_COMPACTION_MARKER
	);
}

function replayCompaction(payload: unknown, details: ResponsesV2CompactionDetails): unknown {
	if (!isRecord(payload) || !Array.isArray(payload.input)) return payload;
	const markerIndex = payload.input.findIndex(isSerializedCompactionMarker);
	if (markerIndex !== -1) {
		return {
			...payload,
			input: [
				...payload.input.slice(0, markerIndex),
				...details.items,
				...payload.input.slice(markerIndex + 1),
			],
		};
	}

	let foundEmbeddedMarker = false;
	const input = payload.input.map((item) => {
		if (foundEmbeddedMarker || !isRecord(item) || !Array.isArray(item.content)) return item;
		return {
			...item,
			content: item.content.map((part) => {
				if (foundEmbeddedMarker || !isRecord(part) || part.type !== "input_text" ||
				typeof part.text !== "string" || !part.text.includes(COMPACTION_SUMMARY_MARKER)) return part;
				foundEmbeddedMarker = true;
				return { ...part, text: part.text.replace(COMPACTION_SUMMARY_MARKER, "Earlier context restored above.") };
			}),
		};
	});
	return foundEmbeddedMarker ? { ...payload, input: [...details.items, ...input] } : payload;
}

function serializeGenuineUser(entry: SessionEntry): Record<string, unknown> | undefined {
	if (entry.type !== "message" || entry.message.role !== "user" || !Array.isArray(entry.message.content)) {
		return undefined;
	}
	const content = entry.message.content.flatMap<Record<string, unknown>>((part) => {
		if (part.type === "image") {
			return [{ type: "input_image", detail: "auto", image_url: `data:${part.mimeType};base64,${part.data}` }];
		}
		if (part.type !== "text") return [];
		const skill = parseSkillBlock(part.text);
		const text = skill ? skill.userMessage : part.text;
		return text ? [{ type: "input_text", text }] : [];
	});
	return content.length > 0 ? { role: "user", content } : undefined;
}

function retainedSerializedUsers(branch: readonly SessionEntry[]): Record<string, unknown>[] {
	const users = branch.flatMap((entry) => {
		const user = serializeGenuineUser(entry);
		return user ? [user] : [];
	});
	const retained: Record<string, unknown>[] = [];
	let retainedTokens = 0;
	for (let index = users.length - 1; index >= 0; index--) {
		const user = users[index];
		const estimatedTokens = Math.max(1, Math.ceil(Buffer.byteLength(JSON.stringify(user), "utf8") / 4));
		if (retained.length > 0 && retainedTokens + estimatedTokens > RETAINED_USER_TOKEN_TARGET) break;
		retained.push(user);
		retainedTokens += estimatedTokens;
	}
	return retained.reverse();
}

function activeTools(pi: ExtensionAPI): Tool[] {
	const activeToolNames = new Set(pi.getActiveTools());
	return pi.getAllTools()
		.filter((tool) => activeToolNames.has(tool.name))
		.map(({ name, description, parameters }) => ({ name, description, parameters }));
}

async function applyProfileModel(pi: ExtensionAPI, selected: CompactionProfile, ctx: ExtensionContext): Promise<void> {
	if (!isResponsesV2Model(ctx.model)) return;
	const catalogModel = ctx.modelRegistry.find(ctx.model.provider, ctx.model.id);
	if (!catalogModel || !isResponsesV2Model(catalogModel)) return;
	const contextWindow = selected === "v2-full" ? V2_FULL_CONTEXT_WINDOW : catalogModel.contextWindow;
	const useResponsesV2 = selected !== "pi" || Boolean(latestResponsesV2Details(ctx.sessionManager.getBranch()));
	const model = useResponsesV2
		? { ...catalogModel, contextWindow, headers: { ...catalogModel.headers, "x-codex-beta-features": RESPONSES_V2_FEATURE } }
		: catalogModel;
	if (ctx.model.contextWindow !== model.contextWindow ||
		ctx.model.headers?.["x-codex-beta-features"] !== model.headers?.["x-codex-beta-features"]) {
		await pi.setModel(model);
	}
}

export default function responsesV2Compaction(pi: ExtensionAPI): void {
	pi.registerCommand("compaction", {
		description: "Select pi, v2-current, or v2-full compaction",
		async handler(argument, ctx) {
			const selected = argument.trim() as CompactionProfile;
			if (selected !== "pi" && selected !== "v2-current" && selected !== "v2-full") {
				ctx.ui.notify("Usage: /compaction pi|v2-current|v2-full", "info");
				return;
			}
			if (selected !== "pi" && !isResponsesV2Model(ctx.model)) {
				ctx.ui.notify("Responses v2 compaction requires an OpenAI Codex model", "info");
				return;
			}
			pi.appendEntry(PROFILE_ENTRY_TYPE, selected);
			await applyProfileModel(pi, selected, ctx);
			const model = ctx.model;
			const window = model && isResponsesV2Model(model)
				? selected === "v2-full" ? V2_FULL_CONTEXT_WINDOW : ctx.modelRegistry.find(model.provider, model.id)?.contextWindow
				: undefined;
			ctx.ui.notify(`Compaction: ${selected}${window ? ` (${window.toLocaleString()} tokens)` : ""}`, "info");
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		await applyProfileModel(pi, profile(ctx.sessionManager.getBranch()), ctx);
	});

	pi.on("model_select", async (event, ctx) => {
		if (isResponsesV2Model(event.model)) {
			await applyProfileModel(pi, profile(ctx.sessionManager.getBranch()), ctx);
		}
	});

	pi.on("before_provider_request", (event, ctx) => {
		if (!isResponsesV2Model(ctx.model)) return;
		const details = latestResponsesV2Details(ctx.sessionManager.getBranch());
		if (details) return replayCompaction(event.payload, details);
	});

	pi.on("session_before_compact", async (event, ctx) => {
		if (!isResponsesV2Model(ctx.model) || profile(event.branchEntries) === "pi") return;
		try {
			const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model);
			if (!auth.ok) throw new Error(auth.error);
			const priorDetails = latestResponsesV2Details(event.branchEntries);
			const context: Context = {
				systemPrompt: ctx.getSystemPrompt(),
				messages: convertToLlm(buildSessionContext([...event.branchEntries]).messages),
				tools: activeTools(pi),
			};
			const rawOutputItems: unknown[] = [];
			const response = await complete(ctx.model, context, {
				apiKey: auth.apiKey,
				headers: { ...auth.headers, "x-codex-beta-features": RESPONSES_V2_FEATURE },
				sessionId: ctx.sessionManager.getSessionId(),
				signal: event.signal,
				reasoningEffort: pi.getThinkingLevel() === "off" ? undefined : pi.getThinkingLevel(),
				onOutputItemDone: (item: unknown) => rawOutputItems.push(item),
				onPayload(payload: unknown) {
					const requestPayload = priorDetails ? replayCompaction(payload, priorDetails) : payload;
					if (!isRecord(requestPayload) || !Array.isArray(requestPayload.input)) return requestPayload;
					return { ...requestPayload, input: [...requestPayload.input, { type: "compaction_trigger" }] };
				},
			} as never);
			const compactionItem = rawOutputItems.find((item) =>
				isRecord(item) && item.type === "compaction" && typeof item.encrypted_content === "string"
			);
			if (response.stopReason !== "stop" || event.signal.aborted || !isRecord(compactionItem)) {
				throw new Error(response.errorMessage ?? "Codex did not return a compaction checkpoint");
			}
			return {
				compaction: {
					summary: COMPACTION_SUMMARY_MARKER,
					firstKeptEntryId: NO_RETAINED_SESSION_TAIL_ENTRY_ID,
					tokensBefore: event.preparation.tokensBefore,
					usage: response.usage,
					details: {
						kind: "responses-v2",
						items: [...retainedSerializedUsers(event.branchEntries), compactionItem],
					} satisfies ResponsesV2CompactionDetails,
				},
			};
		} catch (error) {
			ctx.ui.notify(`Responses v2 compaction failed: ${error instanceof Error ? error.message : String(error)}`, "error");
			return { cancel: true };
		}
	});
}
