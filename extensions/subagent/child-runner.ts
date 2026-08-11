import { mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { AgentMessage, ThinkingLevel } from "@earendil-works/pi-agent-core";
import {
  createAgentSessionFromServices,
  createAgentSessionServices,
  getAgentDir,
  SessionManager,
  type SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { SUBAGENT_TOOL_NAMES, type ChildRuntime, type ChildUserMessagePersistenceWaiter, type PersistedChildTranscript, type PiModelSelector, SubagentToolError } from "./types.js";

const extensionDirectory = dirname(fileURLToPath(import.meta.url));
const childSystemPrompt = readFileSync(join(extensionDirectory, "child-system.md"), "utf8").trim();

export interface OpenChildRuntimeOptions {
  child_session_file?: string;
  working_directory?: string;
  parent_session_file?: string;
  model: PiModelSelector;
  thinking: ThinkingLevel;
  child_role_prompt?: string;
}

function invalidChildSessionFile(sessionFile: string, detail: string): SubagentToolError {
  return new SubagentToolError(
    "child_session_file_invalid",
    `Child session file is missing or invalid: ${sessionFile}. ${detail}`,
  );
}

function openPersistedChildSession(sessionFile: string): SessionManager {
  try {
    if (!statSync(sessionFile).isFile()) throw new Error("Path is not a regular file.");
    const sessionManager = SessionManager.open(sessionFile);
    sessionManager.getBranch();
    return sessionManager;
  } catch (error) {
    throw invalidChildSessionFile(sessionFile, error instanceof Error ? error.message : String(error));
  }
}

function createChildSession(workingDirectory: string, parentSessionFile: string): SessionManager {
  const childSessionDirectory = join(dirname(parentSessionFile), "subagent-sessions");
  const pendingSessionManager = SessionManager.create(workingDirectory, childSessionDirectory, {
    parentSession: parentSessionFile,
  });
  const childSessionFile = pendingSessionManager.getSessionFile();
  const childSessionHeader = pendingSessionManager.getHeader();
  if (!childSessionFile || !childSessionHeader) {
    throw new SubagentToolError("child_session_file_invalid", "Pi did not create a child session header.");
  }
  try {
    mkdirSync(dirname(childSessionFile), { recursive: true, mode: 0o700 });
    writeFileSync(childSessionFile, `${JSON.stringify(childSessionHeader)}\n`, {
      encoding: "utf8",
      flag: "wx",
      mode: 0o600,
    });
  } catch (error) {
    throw invalidChildSessionFile(childSessionFile, error instanceof Error ? error.message : String(error));
  }
  return openPersistedChildSession(childSessionFile);
}

function persistedUserMessageCountOnDisk(sessionManager: SessionManager): number {
  const childSessionFile = sessionManager.getSessionFile();
  if (!childSessionFile) return 0;
  try {
    return readFileSync(childSessionFile, "utf8")
      .split("\n")
      .filter(Boolean)
      .map((line) => JSON.parse(line) as unknown)
      .filter((entry): entry is { type: string; message?: { role?: string } } =>
        typeof entry === "object" && entry !== null)
      .filter((entry) => entry.type === "message" && entry.message?.role === "user")
      .length;
  } catch {
    return 0;
  }
}

function afterCurrentEventLoopTurn(): Promise<void> {
  return new Promise((resolve) => setImmediate(resolve));
}

function prepareNextUserMessagePersistence(
  sessionManager: SessionManager,
  runtime: ChildRuntime["session"],
): ChildUserMessagePersistenceWaiter {
  const userMessageCountBeforePrompt = persistedUserMessageCountOnDisk(sessionManager);
  const hasPersistedNewUserMessage = () =>
    persistedUserMessageCountOnDisk(sessionManager) > userMessageCountBeforePrompt;

  let resolvePersistedUserMessage!: () => void;
  let active = true;
  const persistedUserMessage = new Promise<void>((resolve) => {
    resolvePersistedUserMessage = resolve;
  });
  const unsubscribe = runtime.subscribe((event) => {
    if (event.type !== "message_end" || event.message.role !== "user") return;
    setImmediate(() => {
      if (active && hasPersistedNewUserMessage()) resolvePersistedUserMessage();
    });
  });
  const cancel = () => {
    if (!active) return;
    active = false;
    unsubscribe();
  };

  return {
    async waitFor(prompt: Promise<void>): Promise<void> {
      const promptStoppedBeforeUserMessage = prompt.then(
        async () => {
          await afterCurrentEventLoopTurn();
          if (!hasPersistedNewUserMessage()) {
            throw new Error("Pi did not persist the child user message.");
          }
        },
        async (error: unknown) => {
          await afterCurrentEventLoopTurn();
          if (!hasPersistedNewUserMessage()) throw error;
        },
      );
      try {
        await Promise.race([persistedUserMessage, promptStoppedBeforeUserMessage]);
      } finally {
        cancel();
      }
    },
    cancel,
  };
}

export async function openChildRuntime(options: OpenChildRuntimeOptions): Promise<ChildRuntime> {
  const sessionManager = options.child_session_file
    ? openPersistedChildSession(options.child_session_file)
    : (() => {
      if (!options.working_directory || !options.parent_session_file) {
        throw new SubagentToolError("subagent_runtime_failed", "A new child needs a working directory and parent session file.");
      }
      return createChildSession(options.working_directory, options.parent_session_file);
    })();
  const appendedSystemPrompt = [childSystemPrompt, options.child_role_prompt].filter(
    (value): value is string => Boolean(value),
  );
  const services = await createAgentSessionServices({
    cwd: sessionManager.getCwd(),
    agentDir: getAgentDir(),
    resourceLoaderOptions: {
      appendSystemPrompt: appendedSystemPrompt,
    },
  });
  const diagnostics = services.diagnostics.filter((diagnostic) => diagnostic.type === "error");
  const extensionErrors = services.resourceLoader.getExtensions().errors;
  if (diagnostics.length > 0 || extensionErrors.length > 0) {
    const messages = [
      ...diagnostics.map((diagnostic) => diagnostic.message),
      ...extensionErrors.map((extensionError) => `${extensionError.path}: ${extensionError.error}`),
    ];
    throw new SubagentToolError("child_resources_failed", `Child resources failed to load: ${messages.join("; ")}`);
  }
  const model = services.modelRuntime.getModel(options.model.provider, options.model.id);
  if (!model) {
    throw new SubagentToolError(
      "model_not_available",
      `Model disappeared during child creation: ${options.model.provider}/${options.model.id}`,
    );
  }
  const { session } = await createAgentSessionFromServices({
    services,
    sessionManager,
    model,
    thinkingLevel: options.thinking,
    excludeTools: [...SUBAGENT_TOOL_NAMES],
  });
  try {
    await session.bindExtensions({ mode: "print" });
    if (SUBAGENT_TOOL_NAMES.some((toolName) => session.getActiveToolNames().includes(toolName))) {
      throw new SubagentToolError("child_resources_failed", "Child resource isolation failed: subagent tools are active.");
    }
    const childSessionFile = session.sessionFile;
    if (!childSessionFile) {
      throw new SubagentToolError("child_session_file_invalid", "Child session persistence was not created.");
    }
    return {
      session,
      child_session_file: childSessionFile,
      prepareNextUserMessagePersistence: () =>
        prepareNextUserMessagePersistence(sessionManager, session),
      dispose: () => session.dispose(),
    };
  } catch (error) {
    session.dispose();
    throw error;
  }
}

function messageEntryTimestamp(entry: Extract<SessionEntry, { type: "message" }>): number | undefined {
  const messageTimestamp = entry.message.timestamp;
  if (typeof messageTimestamp === "number" && Number.isFinite(messageTimestamp)) return messageTimestamp;
  const entryTimestamp = Date.parse(entry.timestamp);
  return Number.isFinite(entryTimestamp) ? entryTimestamp : undefined;
}

function sessionHeaderTimestamp(sessionManager: SessionManager): number | undefined {
  const headerTimestamp = sessionManager.getHeader()?.timestamp;
  const parsedTimestamp = headerTimestamp ? Date.parse(headerTimestamp) : Number.NaN;
  return Number.isFinite(parsedTimestamp) ? parsedTimestamp : undefined;
}

function assistantText(message: AgentMessage): string {
  if (message.role !== "assistant") return "";
  return message.content
    .filter((contentBlock) => contentBlock.type === "text")
    .map((contentBlock) => contentBlock.text)
    .join("")
    .trim();
}

function terminalStateFromLastChildMessage(
  lastChildMessageEntry: Extract<SessionEntry, { type: "message" }>,
): Pick<PersistedChildTranscript, "status" | "failure_kind" | "failure_detail" | "handoff"> {
  const lastChildMessage = lastChildMessageEntry.message;
  if (lastChildMessage.role === "assistant") {
    const handoff = assistantText(lastChildMessage);
    if (lastChildMessage.stopReason === "stop") {
      return { status: "finished", handoff };
    }
    if (lastChildMessage.stopReason === "aborted") {
      return { status: "cancelled", handoff };
    }
    if (lastChildMessage.stopReason === "toolUse") {
      return {
        status: "failed",
        failure_kind: "parent_process_exited_mid_run",
        failure_detail: "The parent process exited while the child was still using tools.",
        handoff,
      };
    }
    return {
      status: "failed",
      failure_kind: "model_request_failed",
      failure_detail: lastChildMessage.errorMessage ?? `Child ended with ${lastChildMessage.stopReason}.`,
      handoff,
    };
  }
  if (lastChildMessage.role === "toolResult" && lastChildMessage.isError) {
    return {
      status: "failed",
      failure_kind: "tool_execution_failed",
      failure_detail: "The child ended after a tool execution error.",
      handoff: "",
    };
  }
  return {
    status: "failed",
    failure_kind: "parent_process_exited_mid_run",
    failure_detail: "The parent process exited before the child completed its turn.",
    handoff: "",
  };
}

export function readPersistedChildTranscript(childSessionFile: string): PersistedChildTranscript {
  const sessionManager = openPersistedChildSession(childSessionFile);
  const messageEntries = sessionManager.getBranch().filter(
    (entry): entry is Extract<SessionEntry, { type: "message" }> => entry.type === "message",
  );
  const firstChildMessageEntry = messageEntries.at(0);
  const lastChildMessageEntry = messageEntries.at(-1);
  if (!firstChildMessageEntry || !lastChildMessageEntry) {
    throw invalidChildSessionFile(childSessionFile, "It has no persisted child messages.");
  }
  const startedAt = messageEntryTimestamp(firstChildMessageEntry) ?? sessionHeaderTimestamp(sessionManager);
  const lastEventAt = messageEntryTimestamp(lastChildMessageEntry) ?? startedAt;
  if (startedAt === undefined || lastEventAt === undefined) {
    throw invalidChildSessionFile(childSessionFile, "Its timestamps are invalid.");
  }
  const terminalState = terminalStateFromLastChildMessage(lastChildMessageEntry);
  return {
    messages: messageEntries.map((entry) => entry.message),
    started_at: startedAt,
    last_event_at: lastEventAt,
    terminal_session_entry_id: lastChildMessageEntry.id,
    ...terminalState,
  };
}
