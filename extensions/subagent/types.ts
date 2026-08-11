import type { AgentMessage, AgentToolCall, ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { AgentSession } from "@earendil-works/pi-coding-agent";

export const SUBAGENT_TOOL_NAMES = [
  "start_subagent",
  "steer_subagent",
  "list_subagents",
  "inspect_subagent_transcript",
  "cancel_subagent",
  "list_subagent_models",
] as const;

export const SUBAGENT_NAME_PATTERN = /^[a-z0-9-]{2,64}$/;

export type SubagentStatus = "running" | "finished" | "failed" | "cancelled";
export type TerminalSubagentStatus = Exclude<SubagentStatus, "running">;
export type SubagentFailureKind =
  | "parent_process_exited_mid_run"
  | "model_request_failed"
  | "tool_execution_failed";
export type ModelLaboratory =
  | "openai"
  | "anthropic"
  | "deepseek"
  | "zhipu"
  | "moonshot"
  | "alibaba"
  | "minimax"
  | "other";

export interface PiModelSelector {
  provider: string;
  id: string;
}

export interface ContextFile {
  absolute_path: string;
  why_this_file_matters: string;
}

export interface SubagentColdStartContext {
  files_the_subagent_must_read: ContextFile[];
  facts_verified_by_parent: string[];
  instructions_to_access_the_work: string[];
  unverified_claims_by_work_author: string[];
}

export interface StartSubagentRequest {
  subagent_name: string;
  role?: string;
  subagent_mission: string;
  context: SubagentColdStartContext;
  model?: PiModelSelector;
  thinking?: ThinkingLevel;
  working_directory?: string;
}

export interface SteerSubagentRequest {
  subagent_name: string;
  message_to_subagent: string;
}

export interface InspectSubagentTranscriptRequest {
  subagent_name: string;
  message_count?: number;
}

export interface CancelSubagentRequest {
  subagent_name: string;
}

export interface SubagentAdmission {
  version: 1;
  subagent_name: string;
  child_session_file: string;
  resolved_role?: string;
  resolved_model: PiModelSelector;
  resolved_thinking: ThinkingLevel;
}

export interface SubagentTerminalResultReceipt {
  child_session_file: string;
  child_terminal_session_entry_id: string;
}

export interface RoleDefinition {
  name: string;
  model?: PiModelSelector;
  thinking?: ThinkingLevel;
  parentGuidance: string;
  childPrompt: string;
}

export interface LiveChild {
  session: AgentSession;
  last_event_at: number;
  running_tool_calls: AgentToolCall[];
  completion: Promise<void>;
}

export interface PersistedChildTranscript {
  messages: AgentMessage[];
  started_at: number;
  last_event_at: number;
  terminal_session_entry_id: string;
  status: TerminalSubagentStatus;
  failure_kind?: SubagentFailureKind;
  failure_detail?: string;
  handoff: string;
}

export interface ChildUserMessagePersistenceWaiter {
  waitFor(prompt: Promise<void>): Promise<void>;
  cancel(): void;
}

export interface ChildRuntime {
  session: AgentSession;
  child_session_file: string;
  prepareNextUserMessagePersistence(): ChildUserMessagePersistenceWaiter;
  dispose(): void;
}

export interface ToolErrorPayload {
  error_code: ToolErrorCode;
  message: string;
}

export type ToolErrorCode =
  | "subagent_name_already_used"
  | "subagent_name_invalid"
  | "role_not_found"
  | "model_required"
  | "model_not_available"
  | "thinking_required"
  | "thinking_not_supported_by_model"
  | "context_file_missing"
  | "working_directory_missing"
  | "parent_session_not_persisted"
  | "child_session_file_invalid"
  | "child_admission_invalid"
  | "reviewer_conversation_file_invalid"
  | "child_resources_failed"
  | "subagent_not_found"
  | "subagent_not_running"
  | "subagent_runtime_failed";

export class SubagentToolError extends Error {
  constructor(readonly error_code: ToolErrorCode, message: string) {
    super(message);
    this.name = "SubagentToolError";
  }
}
