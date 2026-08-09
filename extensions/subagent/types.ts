import type { AgentMessage, ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { ToolCall } from "@earendil-works/pi-ai";
import type { AgentSessionEvent, SessionShutdownEvent } from "@earendil-works/pi-coding-agent";

export const SUBAGENT_TOOL_NAMES = [
  "start_subagent",
  "steer_subagent",
  "list_subagents",
  "inspect_subagent_transcript",
  "cancel_subagent",
  "list_subagent_models",
] as const;

export type SubagentStatus = "running" | "finished" | "failed" | "cancelled";
export type TerminalSubagentStatus = Exclude<SubagentStatus, "running">;
export type ParentSessionShutdownReason = SessionShutdownEvent["reason"];
export type SubagentFailureKind =
  | "parent_process_exited_mid_run"
  | "parent_session_ended_mid_run"
  | "model_request_failed"
  | "tool_execution_failed";

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

export interface PersistedNotification {
  notification_id: string;
  subagent_name: string;
  content: string;
}

export interface PersistedSubagentRecord {
  subagent_name: string;
  role?: string;
  subagent_mission: string;
  context: SubagentColdStartContext;
  working_directory: string;
  model: PiModelSelector;
  thinking: ThinkingLevel;
  status: SubagentStatus;
  final_message?: string;
  failure_kind?: SubagentFailureKind;
  failure_detail?: string;
  started_at: string;
  last_event_at: string;
  running_tool_calls: ToolCall[];
  session_file: string;
  active_parent_human_conversation_file?: string;
  terminal_notifications: PersistedNotification[];
}

export interface RoleDefinition {
  name: string;
  model?: PiModelSelector;
  thinking?: ThinkingLevel;
  parentGuidance: string;
  childPrompt: string;
}

export interface TerminalOutcome {
  status: TerminalSubagentStatus;
  final_message: string;
  failure_kind?: SubagentFailureKind;
  failure_detail?: string;
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
  | "reviewer_conversation_file_invalid"
  | "child_resources_failed"
  | "subagent_not_found"
  | "subagent_already_terminal"
  | "subagent_runtime_failed";

export class SubagentToolError extends Error {
  constructor(readonly error_code: ToolErrorCode, message: string) {
    super(message);
    this.name = "SubagentToolError";
  }
}

export interface ChildRuntimeEvents {
  onEvent: (event: AgentSessionEvent) => void;
}

export interface OpenChildRequest {
  record: PersistedSubagentRecord;
  parent_session_file: string;
  child_role_prompt?: string;
}

export interface OpenChildRuntime {
  readonly session_file: string;
  readonly is_streaming: boolean;
  prompt(message: string): Promise<void>;
  steer(message: string): Promise<void>;
  abort(): Promise<void>;
  messages(): AgentMessage[];
  waitForNextUserMessagePersistence(): Promise<void>;
  close(): Promise<void>;
  detachAndAbort(reason: ParentSessionShutdownReason): Promise<void>;
}
