import { statSync } from "node:fs";
import type { AgentMessage } from "@earendil-works/pi-agent-core";
import { openChildRuntime, readChildTranscript } from "./child-runner.js";
import type {
  OpenChildRuntime,
  ParentSessionShutdownReason,
  PersistedNotification,
  PersistedSubagentRecord,
  RoleDefinition,
  StartSubagentRequest,
  SubagentFailureKind,
  TerminalOutcome,
} from "./types.js";
import { SubagentToolError } from "./types.js";

const FAILURE_DETAIL_CHARACTER_CAP = 800;
const FAILURE_DETAIL_TRUNCATION_MARKER = "…[truncated]";
const SUBAGENT_NAME_PATTERN = /^[a-z0-9][a-z0-9-]{1,63}$/;

interface LiveChild {
  runtime: OpenChildRuntime;
  settled: Promise<void>;
  resolveSettled: () => void;
  settledResolved: boolean;
  forcedStatus?: "cancelled";
  hadToolExecutionError: boolean;
  detached: boolean;
}

export interface StartResolvedDefaults {
  model: { provider: string; id: string };
  thinking: PersistedSubagentRecord["thinking"];
  role?: RoleDefinition;
}

export interface ManagerCallbacks {
  persist: (record: PersistedSubagentRecord) => void;
  createTerminalNotification: (
    record: PersistedSubagentRecord,
    outcome: TerminalOutcome,
  ) => PersistedNotification;
  reachedTerminalState: (record: PersistedSubagentRecord, notification: PersistedNotification) => void;
}

function compactFailureDetail(error: unknown): string {
  const message = (error instanceof Error ? error.message : String(error)).replace(/\s+/g, " ").trim();
  if (message.length <= FAILURE_DETAIL_CHARACTER_CAP) return message;
  const prefixLength = FAILURE_DETAIL_CHARACTER_CAP - FAILURE_DETAIL_TRUNCATION_MARKER.length;
  return `${message.slice(0, prefixLength)}${FAILURE_DETAIL_TRUNCATION_MARKER}`;
}

function finalAssistant(messages: AgentMessage[]): AgentMessage | undefined {
  for (let index = messages.length - 1; index >= 0; index -= 1) {
    if (messages[index].role === "assistant") return messages[index];
  }
}

function assistantText(message: AgentMessage | undefined): string {
  if (!message || message.role !== "assistant") return "";
  return message.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("")
    .trim();
}

function terminalOutcome(
  messages: AgentMessage[],
  promptError: string | undefined,
  live: LiveChild,
): TerminalOutcome {
  if (live.forcedStatus === "cancelled") {
    return { status: "cancelled", final_message: "Cancelled by the parent." };
  }
  const assistant = finalAssistant(messages);
  const assistantFailure = assistant?.role === "assistant" &&
    (assistant.stopReason === "error" || assistant.stopReason === "aborted")
    ? compactFailureDetail(assistant.errorMessage || `Child ended with ${assistant.stopReason}.`)
    : undefined;
  const failureDetail = promptError ?? assistantFailure;
  if (failureDetail || !assistant) {
    const failure_kind: SubagentFailureKind = live.hadToolExecutionError
      ? "tool_execution_failed"
      : "model_request_failed";
    return {
      status: "failed",
      final_message: assistantText(assistant),
      failure_kind,
      failure_detail: failureDetail ?? "Child completed without an assistant response.",
    };
  }
  return { status: "finished", final_message: assistantText(assistant) };
}

function outcomeForPersistedTerminalRecord(record: PersistedSubagentRecord): TerminalOutcome {
  if (record.status === "running") throw new Error("A running child has no terminal outcome.");
  return {
    status: record.status,
    final_message: record.final_message ?? "",
    failure_kind: record.failure_kind,
    failure_detail: record.failure_detail,
  };
}

function copyRecord(record: PersistedSubagentRecord): PersistedSubagentRecord {
  return {
    ...record,
    running_tool_calls: [...record.running_tool_calls],
    terminal_notifications: [...record.terminal_notifications],
  };
}

function settleLiveChild(live: LiveChild): void {
  if (live.settledResolved) return;
  live.settledResolved = true;
  live.resolveSettled();
}

export class SubagentManager {
  private readonly records = new Map<string, PersistedSubagentRecord>();
  private readonly liveChildren = new Map<string, LiveChild>();
  private parentSessionActive = true;
  private parentSessionShutdownReason: ParentSessionShutdownReason = "quit";

  constructor(private readonly callbacks: ManagerCallbacks) {}

  restore(records: PersistedSubagentRecord[]): void {
    this.parentSessionActive = true;
    this.parentSessionShutdownReason = "quit";
    this.records.clear();
    for (const persistedRecord of records) {
      const record: PersistedSubagentRecord = {
        ...persistedRecord,
        running_tool_calls: [...persistedRecord.running_tool_calls],
        terminal_notifications: [...(persistedRecord.terminal_notifications ?? [])],
      };
      this.records.set(record.subagent_name, record);
    }
    for (const record of this.records.values()) {
      if (record.status === "running") {
        this.persistTerminalOutcome(record, {
          status: "failed",
          final_message: "",
          failure_kind: "parent_process_exited_mid_run",
          failure_detail: "The parent process exited while this child was running. Steer the child to resume its intact transcript.",
        });
      } else if (record.terminal_notifications.length === 0) {
        this.persistTerminalOutcome(record, outcomeForPersistedTerminalRecord(record));
      }
    }
  }

  all(): PersistedSubagentRecord[] {
    return [...this.records.values()].map(copyRecord);
  }

  terminalNotifications(): PersistedNotification[] {
    return [...this.records.values()].flatMap((record) =>
      record.terminal_notifications.map((notification) => ({ ...notification })));
  }

  require(subagentName: string): PersistedSubagentRecord {
    const record = this.records.get(subagentName);
    if (!record) {
      throw new SubagentToolError(
        "subagent_not_found",
        `No subagent named ${subagentName} exists in this parent session.`,
      );
    }
    return record;
  }

  validateNewName(subagentName: string): void {
    if (!SUBAGENT_NAME_PATTERN.test(subagentName)) {
      throw new SubagentToolError(
        "subagent_name_invalid",
        `Subagent name ${JSON.stringify(subagentName)} must match ^[a-z0-9][a-z0-9-]{1,63}$.`,
      );
    }
    if (this.records.has(subagentName)) {
      throw new SubagentToolError(
        "subagent_name_already_used",
        `Subagent name ${subagentName} was already used in this parent session.`,
      );
    }
  }

  async start(
    request: StartSubagentRequest,
    defaults: StartResolvedDefaults,
    parentSessionFile: string,
    activeParentHumanConversationFile?: string,
  ): Promise<PersistedSubagentRecord> {
    this.validateNewName(request.subagent_name);
    const now = new Date().toISOString();
    const record: PersistedSubagentRecord = {
      subagent_name: request.subagent_name,
      role: request.role,
      subagent_mission: request.subagent_mission,
      context: request.context,
      working_directory: request.working_directory ?? process.cwd(),
      model: defaults.model,
      thinking: defaults.thinking,
      status: "running",
      started_at: now,
      last_event_at: now,
      running_tool_calls: [],
      session_file: "",
      active_parent_human_conversation_file: activeParentHumanConversationFile,
      terminal_notifications: [],
    };
    const opened = await this.open(record, defaults.role, parentSessionFile);
    if (!this.parentSessionActive) {
      await opened.runtime.detachAndAbort(this.parentSessionShutdownReason);
      throw new SubagentToolError("subagent_runtime_failed", "The parent session ended while the child was opening.");
    }
    record.session_file = opened.runtime.session_file;
    const live = this.createLiveChild(record, opened.runtime);
    const initialUserMessagePersistence = opened.runtime.waitForNextUserMessagePersistence();
    const prompt = opened.runtime.prompt(opened.first_user_message);
    try {
      await this.waitForUserMessagePersistence(initialUserMessagePersistence, prompt);
      if (!this.isAttached(record, live)) {
        throw new Error("The parent session ended while the child was starting.");
      }
      this.records.set(record.subagent_name, record);
      this.persist(record);
    } catch (error) {
      this.records.delete(record.subagent_name);
      await this.abandonUnadmittedChild(live);
      throw new SubagentToolError(
        "subagent_runtime_failed",
        `The child could not persist its initial context: ${compactFailureDetail(error)}`,
      );
    }
    void this.finishRun(record, live, prompt);
    return copyRecord(record);
  }

  async steer(
    record: PersistedSubagentRecord,
    message: string,
    role: RoleDefinition | undefined,
    parentSessionFile: string,
  ): Promise<void> {
    const existingLiveChild = this.liveChildren.get(record.subagent_name);
    if (existingLiveChild?.runtime.is_streaming) {
      await existingLiveChild.runtime.steer(message);
      if (this.isAttached(record, existingLiveChild)) this.touch(record);
      return;
    }
    if (existingLiveChild) await existingLiveChild.settled;
    const opened = await this.open(record, role, parentSessionFile);
    if (!this.parentSessionActive) {
      await opened.runtime.detachAndAbort(this.parentSessionShutdownReason);
      throw new SubagentToolError("subagent_runtime_failed", "The parent session ended while the child was opening.");
    }
    const resumed = this.createLiveChild(record, opened.runtime);
    const userMessagePersistence = opened.runtime.waitForNextUserMessagePersistence();
    const prompt = opened.runtime.prompt(message);
    try {
      await this.waitForUserMessagePersistence(userMessagePersistence, prompt);
      if (!this.isAttached(record, resumed)) {
        throw new Error("The parent session ended while the child was resuming.");
      }
      record.status = "running";
      delete record.final_message;
      delete record.failure_kind;
      delete record.failure_detail;
      record.last_event_at = new Date().toISOString();
      record.session_file = opened.runtime.session_file;
      this.persist(record);
    } catch (error) {
      await this.abandonUnadmittedChild(resumed);
      throw new SubagentToolError(
        "subagent_runtime_failed",
        `The child could not persist the steering message: ${compactFailureDetail(error)}`,
      );
    }
    void this.finishRun(record, resumed, prompt);
  }

  async cancel(record: PersistedSubagentRecord): Promise<void> {
    if (record.status !== "running") {
      throw new SubagentToolError(
        "subagent_already_terminal",
        `Subagent ${record.subagent_name} is already ${record.status}.`,
      );
    }
    const live = this.liveChildren.get(record.subagent_name);
    if (!live) {
      throw new SubagentToolError(
        "subagent_already_terminal",
        `Subagent ${record.subagent_name} no longer has an active run.`,
      );
    }
    live.forcedStatus = "cancelled";
    await live.runtime.abort();
    await live.settled;
  }

  transcript(record: PersistedSubagentRecord): AgentMessage[] {
    const live = this.liveChildren.get(record.subagent_name);
    return live ? live.runtime.messages() : readChildTranscript(record.session_file);
  }

  async parentSessionEnded(reason: ParentSessionShutdownReason): Promise<void> {
    if (!this.parentSessionActive) return;
    this.parentSessionActive = false;
    this.parentSessionShutdownReason = reason;
    const childShutdowns: Promise<void>[] = [];
    for (const [subagentName, live] of [...this.liveChildren.entries()]) {
      const record = this.records.get(subagentName);
      if (record?.status === "running") {
        try {
          this.persistTerminalOutcome(record, {
            status: "failed",
            final_message: "",
            failure_kind: "parent_session_ended_mid_run",
            failure_detail: `The parent session ${reason} while this child was running. Steer the child from the persisted parent session to resume its transcript.`,
          });
        } catch {
          // The parent session is closing. Recovery will inspect this child on the next start.
        }
      }
      live.detached = true;
      this.liveChildren.delete(subagentName);
      settleLiveChild(live);
      childShutdowns.push(live.runtime.detachAndAbort(reason).catch(() => {}));
    }
    await Promise.all(childShutdowns);
  }

  private async open(record: PersistedSubagentRecord, role: RoleDefinition | undefined, parentSessionFile: string) {
    return openChildRuntime(
      { record, parent_session_file: parentSessionFile, child_role_prompt: role?.childPrompt },
      {
        onEvent: (event) => {
          const live = this.liveChildren.get(record.subagent_name);
          if (!live || live.detached || !this.parentSessionActive) return;
          switch (event.type) {
            case "tool_execution_start":
              record.running_tool_calls.push({
                type: "toolCall",
                id: event.toolCallId,
                name: event.toolName,
                arguments: event.args,
              });
              break;
            case "tool_execution_end":
              record.running_tool_calls = record.running_tool_calls.filter((call) => call.id !== event.toolCallId);
              if (event.isError) live.hadToolExecutionError = true;
              break;
            case "message_end":
            case "turn_start":
            case "turn_end":
            case "agent_settled":
              break;
            default:
              return;
          }
          this.touch(record);
        },
      },
    );
  }

  private createLiveChild(record: PersistedSubagentRecord, runtime: OpenChildRuntime): LiveChild {
    let resolveSettled!: () => void;
    const settled = new Promise<void>((resolve) => { resolveSettled = resolve; });
    const live: LiveChild = {
      runtime,
      settled,
      resolveSettled,
      settledResolved: false,
      hadToolExecutionError: false,
      detached: false,
    };
    this.liveChildren.set(record.subagent_name, live);
    return live;
  }

  private async waitForUserMessagePersistence(
    userMessagePersistence: Promise<void>,
    prompt: Promise<void>,
  ): Promise<void> {
    await Promise.race([
      userMessagePersistence,
      prompt.then(
        () => { throw new Error("The child prompt ended before Pi persisted its user message."); },
        (error) => { throw error; },
      ),
    ]);
  }

  private async abandonUnadmittedChild(live: LiveChild): Promise<void> {
    live.detached = true;
    for (const [subagentName, candidate] of this.liveChildren.entries()) {
      if (candidate === live) this.liveChildren.delete(subagentName);
    }
    settleLiveChild(live);
    try {
      await live.runtime.detachAndAbort(this.parentSessionShutdownReason);
    } catch {}
  }

  private async finishRun(record: PersistedSubagentRecord, live: LiveChild, prompt: Promise<void>): Promise<void> {
    let promptError: string | undefined;
    try {
      await prompt;
    } catch (error) {
      promptError = compactFailureDetail(error);
    }
    if (!this.isAttached(record, live)) return;
    const outcome = terminalOutcome(live.runtime.messages(), promptError, live);
    const notification = this.persistTerminalOutcome(record, outcome);
    try {
      await live.runtime.close();
    } catch {}
    if (!this.isAttached(record, live)) return;
    this.liveChildren.delete(record.subagent_name);
    settleLiveChild(live);
    try {
      this.callbacks.reachedTerminalState(copyRecord(record), notification);
    } catch {
      // The durable record will redeliver this terminal notification on parent-session restore.
    }
  }

  private persistTerminalOutcome(
    record: PersistedSubagentRecord,
    outcome: TerminalOutcome,
  ): PersistedNotification {
    record.status = outcome.status;
    record.final_message = outcome.final_message;
    record.failure_kind = outcome.failure_kind;
    record.failure_detail = outcome.failure_detail;
    record.running_tool_calls = [];
    record.last_event_at = new Date().toISOString();
    const notification = this.callbacks.createTerminalNotification(copyRecord(record), outcome);
    record.terminal_notifications.push(notification);
    this.persist(record);
    return notification;
  }

  private isAttached(record: PersistedSubagentRecord, live: LiveChild): boolean {
    return this.parentSessionActive && !live.detached && this.liveChildren.get(record.subagent_name) === live;
  }

  private touch(record: PersistedSubagentRecord): void {
    if (!this.parentSessionActive) return;
    record.last_event_at = new Date().toISOString();
  }

  private persist(record: PersistedSubagentRecord): void {
    this.callbacks.persist(copyRecord(record));
  }
}

export function requireExistingDirectory(path: string): void {
  try {
    if (statSync(path).isDirectory()) return;
  } catch {}
  throw new SubagentToolError(
    "working_directory_missing",
    `Working directory does not exist or is not a directory: ${path}`,
  );
}
