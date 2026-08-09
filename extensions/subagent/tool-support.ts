import { statSync } from "node:fs";
import { getSupportedThinkingLevels, type Message, type Model, type ToolCall } from "@earendil-works/pi-ai";
import type { AgentMessage, AgentToolResult, ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { ModelRegistry } from "@earendil-works/pi-coding-agent";
import type {
  PiModelSelector,
  SubagentStatus,
  ToolErrorPayload,
} from "./types.js";
import { SubagentToolError } from "./types.js";

const TRANSCRIPT_PAYLOAD_CHARACTER_CAP = 60_000;
const CURRENT_ACTIVITY_CHARACTER_CAP = 6_000;
const MAXIMUM_TRANSCRIPT_CONTENT_BLOCK_COUNT = 12;
const MAXIMUM_RUNNING_TOOL_CALL_COUNT = 16;
const TRUNCATION_MARKER = "…[truncated]";
const MODEL_LABS: Array<{ model_lab: string; provider?: string; id_prefix?: string }> = [
  { model_lab: "openai", provider: "openai-codex" },
  { model_lab: "openai", provider: "openai" },
  { model_lab: "anthropic", provider: "anthropic" },
  { model_lab: "google", provider: "google" },
  { model_lab: "deepseek", provider: "ollama", id_prefix: "deepseek" },
  { model_lab: "zhipu", provider: "ollama", id_prefix: "glm" },
  { model_lab: "moonshot", provider: "ollama", id_prefix: "kimi" },
  { model_lab: "alibaba", provider: "ollama", id_prefix: "qwen" },
];

interface TruncatedValue {
  value: unknown;
  was_truncated: boolean;
}

export interface BoundedTranscriptPayload {
  current_time: string;
  status: SubagentStatus;
  session_file: string;
  transcript_truncated: boolean;
  messages: AgentMessage[];
}

function truncateText(text: string, maximumCharacters: number): TruncatedValue {
  if (text.length <= maximumCharacters) return { value: text, was_truncated: false };
  const prefixLength = Math.max(0, maximumCharacters - TRUNCATION_MARKER.length);
  return { value: `${text.slice(0, prefixLength)}${TRUNCATION_MARKER}`, was_truncated: true };
}

function truncateToolCallArguments(value: unknown, depth = 0): TruncatedValue {
  if (typeof value === "string") return truncateText(value, 1_000);
  if (value === null || typeof value !== "object") return { value, was_truncated: false };
  if (depth >= 5) return { value: TRUNCATION_MARKER, was_truncated: true };
  if (Array.isArray(value)) {
    const retainedItems = value.slice(-8);
    let wasTruncated = retainedItems.length !== value.length;
    const items = retainedItems.map((item) => {
      const truncatedItem = truncateToolCallArguments(item, depth + 1);
      wasTruncated ||= truncatedItem.was_truncated;
      return truncatedItem.value;
    });
    return { value: items, was_truncated: wasTruncated };
  }
  const retainedEntries = Object.entries(value).slice(0, 16);
  let wasTruncated = retainedEntries.length !== Object.keys(value).length;
  const entries = retainedEntries.map(([key, item]) => {
    const truncatedItem = truncateToolCallArguments(item, depth + 1);
    wasTruncated ||= truncatedItem.was_truncated;
    return [key, truncatedItem.value] as const;
  });
  return { value: Object.fromEntries(entries), was_truncated: wasTruncated };
}

function hasPiMessageContent(message: AgentMessage): message is Message {
  return typeof message === "object" && message !== null &&
    "content" in message && Array.isArray((message as { content?: unknown }).content);
}

function truncatePiMessage(message: AgentMessage): { message: AgentMessage; was_truncated: boolean } {
  const copiedMessage = structuredClone(message);
  if (!hasPiMessageContent(copiedMessage)) {
    return { message: copiedMessage, was_truncated: false };
  }
  const copiedPiMessage = copiedMessage as Message & Record<string, unknown>;
  delete copiedPiMessage.details;
  const originalContent = copiedPiMessage.content;
  if (typeof originalContent === "string") {
    const truncatedContent = truncateText(originalContent, 3_000);
    copiedPiMessage.content = truncatedContent.value as string;
    return { message: copiedPiMessage, was_truncated: truncatedContent.was_truncated };
  }
  if (!Array.isArray(originalContent)) {
    return { message: copiedPiMessage, was_truncated: false };
  }
  const retainedContent = originalContent.slice(-MAXIMUM_TRANSCRIPT_CONTENT_BLOCK_COUNT);
  let wasTruncated = retainedContent.length !== originalContent.length;
  copiedPiMessage.content = retainedContent.map((contentBlock) => {
    const copiedBlock = { ...contentBlock } as Record<string, unknown>;
    for (const fieldName of ["text", "thinking", "textSignature", "thinkingSignature", "thoughtSignature"]) {
      if (typeof copiedBlock[fieldName] !== "string") continue;
      const truncatedField = truncateText(
        copiedBlock[fieldName] as string,
        fieldName.endsWith("Signature") ? 128 : 3_000,
      );
      copiedBlock[fieldName] = truncatedField.value;
      wasTruncated ||= truncatedField.was_truncated;
    }
    if (copiedBlock.type === "image" && typeof copiedBlock.data === "string") {
      const truncatedImage = truncateText(copiedBlock.data, 128);
      copiedBlock.data = truncatedImage.value;
      wasTruncated ||= truncatedImage.was_truncated;
    }
    if (copiedBlock.type === "toolCall") {
      const truncatedArguments = truncateToolCallArguments(copiedBlock.arguments);
      copiedBlock.arguments = truncatedArguments.value;
      wasTruncated ||= truncatedArguments.was_truncated;
    }
    return copiedBlock;
  }) as unknown as typeof originalContent;
  return { message: copiedPiMessage, was_truncated: wasTruncated };
}

function truncatePiToolCall(toolCall: ToolCall): { tool_call: ToolCall; was_truncated: boolean } {
  const copiedToolCall = structuredClone(toolCall);
  const truncatedArguments = truncateToolCallArguments(copiedToolCall.arguments);
  copiedToolCall.arguments = truncatedArguments.value as ToolCall["arguments"];
  return { tool_call: copiedToolCall, was_truncated: truncatedArguments.was_truncated };
}

export function resolveAuthenticatedModel(registry: ModelRegistry, selector: PiModelSelector): Model<any> {
  const model = registry.find(selector.provider, selector.id);
  if (!model || !registry.hasConfiguredAuth(model)) {
    throw new SubagentToolError(
      "model_not_available",
      `Model ${selector.provider}/${selector.id} is not available with configured authentication.`,
    );
  }
  return model;
}

export function validateThinking(model: Model<any>, thinking: ThinkingLevel): void {
  const supported = getSupportedThinkingLevels(model) as ThinkingLevel[];
  if (!supported.includes(thinking)) {
    throw new SubagentToolError(
      "thinking_not_supported_by_model",
      `Model ${model.provider}/${model.id} does not support thinking ${thinking}. Supported levels: ${supported.join(", ")}.`,
    );
  }
}

export function validateContextFiles(paths: string[]): void {
  for (const path of paths) {
    try {
      if (path.startsWith("/") && statSync(path).isFile()) continue;
    } catch {}
    throw new SubagentToolError(
      "context_file_missing",
      `Required context file does not exist or is not a file: ${path}`,
    );
  }
}

function labFor(model: Model<any>): string {
  return MODEL_LABS.find((entry) =>
    entry.provider === model.provider && (!entry.id_prefix || model.id.toLowerCase().startsWith(entry.id_prefix)))?.model_lab
    ?? model.provider;
}

export function groupedAvailableModels(registry: ModelRegistry) {
  const groups = new Map<string, Array<{ model: PiModelSelector; thinking_levels: ThinkingLevel[] }>>();
  for (const model of registry.getAvailable().filter((candidate) => registry.hasConfiguredAuth(candidate))) {
    const modelLab = labFor(model);
    const models = groups.get(modelLab) ?? [];
    models.push({
      model: { provider: model.provider, id: model.id },
      thinking_levels: getSupportedThinkingLevels(model) as ThinkingLevel[],
    });
    groups.set(modelLab, models);
  }
  return [...groups.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([model_lab, models]) => ({
      model_lab,
      models: models.sort((left, right) =>
        `${left.model.provider}/${left.model.id}`.localeCompare(`${right.model.provider}/${right.model.id}`)),
    }));
}

export function boundedTranscriptPayload(
  currentTime: string,
  status: SubagentStatus,
  sessionFile: string,
  newestMessages: AgentMessage[],
): BoundedTranscriptPayload {
  const retainedMessages: AgentMessage[] = [];
  let transcriptTruncated = false;
  for (let index = newestMessages.length - 1; index >= 0; index -= 1) {
    const truncatedMessage = truncatePiMessage(newestMessages[index]);
    const candidatePayload: BoundedTranscriptPayload = {
      current_time: currentTime,
      status,
      session_file: sessionFile,
      transcript_truncated: transcriptTruncated || truncatedMessage.was_truncated,
      messages: [truncatedMessage.message, ...retainedMessages],
    };
    if (JSON.stringify(candidatePayload).length > TRANSCRIPT_PAYLOAD_CHARACTER_CAP) {
      transcriptTruncated = true;
      break;
    }
    retainedMessages.unshift(truncatedMessage.message);
    transcriptTruncated ||= truncatedMessage.was_truncated;
  }
  transcriptTruncated ||= retainedMessages.length !== newestMessages.length;
  return {
    current_time: currentTime,
    status,
    session_file: sessionFile,
    transcript_truncated: transcriptTruncated,
    messages: retainedMessages,
  };
}

export function boundedToolCallPreviews(toolCalls: ToolCall[]): {
  running_tool_calls: ToolCall[];
  running_tool_calls_truncated: boolean;
} {
  const retainedToolCalls: ToolCall[] = [];
  let runningToolCallsTruncated = toolCalls.length > MAXIMUM_RUNNING_TOOL_CALL_COUNT;
  for (const toolCall of toolCalls.slice(-MAXIMUM_RUNNING_TOOL_CALL_COUNT).reverse()) {
    const truncatedToolCall = truncatePiToolCall(toolCall);
    const candidate = [truncatedToolCall.tool_call, ...retainedToolCalls];
    if (JSON.stringify(candidate).length > CURRENT_ACTIVITY_CHARACTER_CAP) {
      runningToolCallsTruncated = true;
      break;
    }
    retainedToolCalls.unshift(truncatedToolCall.tool_call);
    runningToolCallsTruncated ||= truncatedToolCall.was_truncated;
  }
  runningToolCallsTruncated ||= retainedToolCalls.length !== toolCalls.length;
  return {
    running_tool_calls: retainedToolCalls,
    running_tool_calls_truncated: runningToolCallsTruncated,
  };
}

export function successResult<T>(payload: T): AgentToolResult<T> {
  return { content: [{ type: "text", text: JSON.stringify(payload) }], details: payload };
}

export function throwTypedToolError(error: unknown): never {
  const payload: ToolErrorPayload = error instanceof SubagentToolError
    ? { error_code: error.error_code, message: error.message }
    : {
      error_code: "subagent_runtime_failed",
      message: error instanceof Error ? error.message : String(error),
    };
  throw new Error(JSON.stringify(payload));
}
