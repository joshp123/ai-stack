import { statSync } from "node:fs";
import { getSupportedThinkingLevels, type Model } from "@earendil-works/pi-ai";
import type { AgentToolResult, ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { ModelRegistry } from "@earendil-works/pi-coding-agent";
import type { ModelLaboratory, PiModelSelector, SubagentAdmission, ToolErrorPayload } from "./types.js";
import { SubagentToolError } from "./types.js";

const MODEL_LABORATORY_MAPPING_V1: ReadonlyArray<{
  model_laboratory: Exclude<ModelLaboratory, "other">;
  provider: string;
  id_prefix?: string;
}> = [
  { model_laboratory: "openai", provider: "openai" },
  { model_laboratory: "openai", provider: "openai-codex" },
  { model_laboratory: "anthropic", provider: "anthropic" },
  { model_laboratory: "deepseek", provider: "deepseek" },
  { model_laboratory: "zhipu", provider: "zhipu" },
  { model_laboratory: "moonshot", provider: "moonshot" },
  { model_laboratory: "alibaba", provider: "alibaba" },
  { model_laboratory: "minimax", provider: "minimax" },
  { model_laboratory: "deepseek", provider: "ollama", id_prefix: "deepseek" },
  { model_laboratory: "zhipu", provider: "ollama", id_prefix: "glm" },
  { model_laboratory: "moonshot", provider: "ollama", id_prefix: "kimi" },
  { model_laboratory: "alibaba", provider: "ollama", id_prefix: "qwen" },
  { model_laboratory: "minimax", provider: "ollama", id_prefix: "minimax" },
];

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
  const supportedThinkingLevels = getSupportedThinkingLevels(model) as ThinkingLevel[];
  if (!supportedThinkingLevels.includes(thinking)) {
    throw new SubagentToolError(
      "thinking_not_supported_by_model",
      `Model ${model.provider}/${model.id} does not support thinking ${thinking}. Supported levels: ${supportedThinkingLevels.join(", ")}.`,
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

export function validateExistingWorkingDirectory(workingDirectory: string): void {
  try {
    if (workingDirectory.startsWith("/") && statSync(workingDirectory).isDirectory()) return;
  } catch {}
  throw new SubagentToolError(
    "working_directory_missing",
    `Working directory does not exist or is not a directory: ${workingDirectory}`,
  );
}

function modelLaboratoryFor(model: Model<any>): ModelLaboratory {
  const normalizedModelId = model.id.toLowerCase();
  return MODEL_LABORATORY_MAPPING_V1.find((rule) =>
    rule.provider === model.provider && (!rule.id_prefix || normalizedModelId.startsWith(rule.id_prefix)))?.model_laboratory
    ?? "other";
}

export function authenticatedModelsByLaboratory(registry: ModelRegistry): {
  model_laboratories: Array<{
    model_laboratory: ModelLaboratory;
    pi_models: Array<{
      pi_model_selector: PiModelSelector;
      supported_pi_thinking_levels: ThinkingLevel[];
    }>;
  }>;
} {
  const modelsByLaboratory = new Map<ModelLaboratory, Array<{
    pi_model_selector: PiModelSelector;
    supported_pi_thinking_levels: ThinkingLevel[];
  }>>();

  for (const model of registry.getAvailable()) {
    if (!registry.hasConfiguredAuth(model)) continue;
    const modelLaboratory = modelLaboratoryFor(model);
    const models = modelsByLaboratory.get(modelLaboratory) ?? [];
    models.push({
      pi_model_selector: { provider: model.provider, id: model.id },
      supported_pi_thinking_levels: getSupportedThinkingLevels(model) as ThinkingLevel[],
    });
    modelsByLaboratory.set(modelLaboratory, models);
  }

  return {
    model_laboratories: [...modelsByLaboratory.entries()]
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([model_laboratory, pi_models]) => ({
        model_laboratory,
        pi_models: pi_models.sort((left, right) =>
          `${left.pi_model_selector.provider}/${left.pi_model_selector.id}`.localeCompare(
            `${right.pi_model_selector.provider}/${right.pi_model_selector.id}`,
          )),
      })),
  };
}

export function subagentAdmissionToolResult(
  admission: SubagentAdmission,
): AgentToolResult<SubagentAdmission> {
  return { content: [{ type: "text", text: JSON.stringify(admission) }], details: admission };
}

export function modelVisibleToolResult<T>(payload: T): AgentToolResult<undefined> {
  return { content: [{ type: "text", text: JSON.stringify(payload) }], details: undefined };
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
