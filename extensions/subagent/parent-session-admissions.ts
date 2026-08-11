import type { SessionEntry } from "@earendil-works/pi-coding-agent";
import {
  SUBAGENT_NAME_PATTERN,
  type SubagentAdmission,
  type SubagentTerminalResultReceipt,
  SubagentToolError,
} from "./types.js";

export const SUBAGENT_TERMINAL_RESULT_MESSAGE = "subagent-terminal-result-v1";

const PI_THINKING_LEVELS = new Set([
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
]);
const SUBAGENT_ADMISSION_KEYS = new Set([
  "version",
  "subagent_name",
  "child_session_file",
  "resolved_role",
  "resolved_model",
  "resolved_thinking",
]);
const PI_MODEL_SELECTOR_KEYS = new Set(["provider", "id"]);

function invalidAdmission(detail: string): SubagentToolError {
  return new SubagentToolError("child_admission_invalid", `Invalid start_subagent admission: ${detail}`);
}

function isObject(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function validateSubagentAdmission(
  details: unknown,
  installedRoleNames: ReadonlySet<string>,
): SubagentAdmission {
  if (!isObject(details)) throw invalidAdmission("details must be an object.");
  const unexpectedKeys = Object.keys(details).filter((key) => !SUBAGENT_ADMISSION_KEYS.has(key));
  if (unexpectedKeys.length > 0) throw invalidAdmission(`unexpected field(s): ${unexpectedKeys.join(", ")}.`);
  if (details.version !== 1) throw invalidAdmission("version must be 1.");
  if (typeof details.subagent_name !== "string" || !SUBAGENT_NAME_PATTERN.test(details.subagent_name)) {
    throw invalidAdmission("subagent_name is invalid.");
  }
  if (typeof details.child_session_file !== "string" || !details.child_session_file.startsWith("/")) {
    throw invalidAdmission("child_session_file must be an absolute path.");
  }
  if (details.resolved_role !== undefined &&
      (typeof details.resolved_role !== "string" || !installedRoleNames.has(details.resolved_role))) {
    throw invalidAdmission("resolved_role is not an installed role.");
  }
  if (!isObject(details.resolved_model) ||
      Object.keys(details.resolved_model).some((key) => !PI_MODEL_SELECTOR_KEYS.has(key)) ||
      typeof details.resolved_model.provider !== "string" || details.resolved_model.provider.length === 0 ||
      typeof details.resolved_model.id !== "string" || details.resolved_model.id.length === 0) {
    throw invalidAdmission("resolved_model is invalid.");
  }
  if (typeof details.resolved_thinking !== "string" || !PI_THINKING_LEVELS.has(details.resolved_thinking)) {
    throw invalidAdmission("resolved_thinking is invalid.");
  }

  const resolvedRole = details.resolved_role as string | undefined;
  const resolvedModel = details.resolved_model as { provider: string; id: string };
  return {
    version: 1,
    subagent_name: details.subagent_name,
    child_session_file: details.child_session_file,
    ...(resolvedRole === undefined ? {} : { resolved_role: resolvedRole }),
    resolved_model: {
      provider: resolvedModel.provider,
      id: resolvedModel.id,
    },
    resolved_thinking: details.resolved_thinking as SubagentAdmission["resolved_thinking"],
  };
}

export function currentBranchSubagentAdmissions(
  activeBranch: SessionEntry[],
  installedRoleNames: ReadonlySet<string>,
): SubagentAdmission[] {
  const admissionsByName = new Map<string, SubagentAdmission>();
  for (const entry of activeBranch) {
    if (entry.type !== "message" || entry.message.role !== "toolResult") continue;
    if (entry.message.toolName !== "start_subagent" || entry.message.isError) continue;
    const admission = validateSubagentAdmission(entry.message.details, installedRoleNames);
    if (admissionsByName.has(admission.subagent_name)) {
      throw invalidAdmission(`subagent_name ${admission.subagent_name} appears more than once in the active branch.`);
    }
    admissionsByName.set(admission.subagent_name, admission);
  }
  return [...admissionsByName.values()];
}

export function hasTerminalResultReceipt(
  activeBranch: SessionEntry[],
  expectedReceipt: SubagentTerminalResultReceipt,
): boolean {
  return activeBranch.some((entry) => {
    if (entry.type !== "custom_message" || entry.customType !== SUBAGENT_TERMINAL_RESULT_MESSAGE) return false;
    if (!isObject(entry.details)) return false;
    return entry.details.child_session_file === expectedReceipt.child_session_file &&
      entry.details.child_terminal_session_entry_id === expectedReceipt.child_terminal_session_entry_id;
  });
}
