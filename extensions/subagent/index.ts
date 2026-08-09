import { randomUUID } from "node:crypto";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { createSchemas } from "./schemas.js";
import { loadRoles, parentRoleGuidance } from "./roles.js";
import { requireExistingDirectory, SubagentManager } from "./manager.js";
import { writeActiveParentHumanConversationFile } from "./reviewer-context.js";
import {
  boundedToolCallPreviews,
  boundedTranscriptPayload,
  groupedAvailableModels,
  resolveAuthenticatedModel,
  successResult,
  throwTypedToolError,
  validateContextFiles,
  validateThinking,
} from "./tool-support.js";
import type {
  PersistedNotification,
  PersistedSubagentRecord,
  StartSubagentRequest,
  TerminalOutcome,
} from "./types.js";
import { SubagentToolError } from "./types.js";

const REGISTRY_ENTRY = "subagent-registry-v1";
const RESULT_MESSAGE = "subagent-result-v1";
const FINAL_MESSAGE_CHARACTER_CAP = 8_000;
const extensionDirectory = dirname(fileURLToPath(import.meta.url));

function requireParentSessionFile(ctx: ExtensionContext): string {
  const sessionFile = ctx.sessionManager.getSessionFile();
  if (!sessionFile) {
    throw new SubagentToolError(
      "parent_session_not_persisted",
      "The parent session is not persisted, so it cannot own a resumable child.",
    );
  }
  return sessionFile;
}

function compactTerminalNotification(record: PersistedSubagentRecord, outcome: TerminalOutcome): string {
  const heading = `Subagent ${record.subagent_name} ${outcome.status}`;
  const failure = outcome.failure_kind
    ? `failure_kind: ${outcome.failure_kind}${outcome.failure_detail ? `\nfailure_detail: ${outcome.failure_detail}` : ""}`
    : "";
  const suffix = `transcript: ${record.session_file}`;
  const fixedParts = [heading, failure].filter(Boolean).join("\n\n");
  const availableForMessage = Math.max(0, FINAL_MESSAGE_CHARACTER_CAP - fixedParts.length - suffix.length - 4);
  const finalMessage = outcome.final_message.length > availableForMessage
    ? `${outcome.final_message.slice(0, Math.max(0, availableForMessage - 13))}…[truncated]`
    : outcome.final_message;
  return [fixedParts, finalMessage, suffix].filter(Boolean).join("\n\n");
}

interface RestoredParentSubagentState {
  records: PersistedSubagentRecord[];
  delivered: Set<string>;
}

function latestPersistedState(
  entries: ReturnType<ExtensionContext["sessionManager"]["getBranch"]>,
): RestoredParentSubagentState {
  const records = new Map<string, PersistedSubagentRecord>();
  const delivered = new Set<string>();
  for (const entry of entries) {
    if (entry.type === "custom" && entry.customType === REGISTRY_ENTRY && entry.data) {
      const persistedRecord = entry.data as PersistedSubagentRecord;
      if (persistedRecord.subagent_name) {
        records.set(persistedRecord.subagent_name, {
          ...persistedRecord,
          terminal_notifications: persistedRecord.terminal_notifications ?? [],
        });
      }
    } else if (entry.type === "custom_message" && entry.customType === RESULT_MESSAGE) {
      const notificationId = (entry.details as { notification_id?: string } | undefined)?.notification_id;
      if (notificationId) delivered.add(notificationId);
    }
  }
  return { records: [...records.values()], delivered };
}

export default function subagentExtension(pi: ExtensionAPI) {
  const roles = loadRoles(join(extensionDirectory, "agents"));
  const schemas = createSchemas(roles);
  const deliveredNotificationIds = new Set<string>();

  function deliverNotification(
    notification: PersistedNotification,
    delivery: "normal-completion" | "session-restore",
  ): void {
    if (deliveredNotificationIds.has(notification.notification_id)) return;
    const message = {
      customType: RESULT_MESSAGE,
      content: notification.content,
      display: true,
      details: {
        notification_id: notification.notification_id,
        subagent_name: notification.subagent_name,
      },
    };
    if (delivery === "session-restore") {
      pi.sendMessage(message, { deliverAs: "nextTurn" });
    } else {
      pi.sendMessage(message, { deliverAs: "steer", triggerTurn: true });
    }
    deliveredNotificationIds.add(notification.notification_id);
  }

  function createTerminalNotification(
    record: PersistedSubagentRecord,
    outcome: TerminalOutcome,
  ): PersistedNotification {
    return {
      notification_id: `${record.subagent_name}:${randomUUID()}`,
      subagent_name: record.subagent_name,
      content: compactTerminalNotification(record, outcome),
    };
  }

  const manager = new SubagentManager({
    persist: (record) => pi.appendEntry(REGISTRY_ENTRY, record),
    createTerminalNotification,
    reachedTerminalState: (_record, notification) => {
      deliverNotification(notification, "normal-completion");
    },
  });

  pi.on("session_start", (_event, ctx) => {
    const restored = latestPersistedState(ctx.sessionManager.getBranch());
    deliveredNotificationIds.clear();
    for (const notificationId of restored.delivered) deliveredNotificationIds.add(notificationId);
    manager.restore(restored.records);
    for (const notification of manager.terminalNotifications()) {
      deliverNotification(notification, "session-restore");
    }
  });

  pi.on("session_shutdown", async (event) => {
    await manager.parentSessionEnded(event.reason);
  });

  pi.registerTool({
    name: "start_subagent",
    label: "Start subagent",
    description: "Start one in-process, resumable Pi child. The child has no parent conversation. Put every needed absolute file, verified fact, access method, and work-author claim in the named context fields. For concurrent writers, give each child separate files. Admission means its initial context is persisted and it is running; its terminal result is pushed automatically. After a crash, terminal results use at-least-once delivery.",
    promptGuidelines: parentRoleGuidance(roles),
    parameters: schemas.start,
    executionMode: "sequential",
    async execute(_id, rawRequest, _signal, _update, ctx) {
      try {
        const request = rawRequest as StartSubagentRequest;
        manager.validateNewName(request.subagent_name);
        const role = request.role ? roles.get(request.role) : undefined;
        if (request.role && !role) {
          throw new SubagentToolError("role_not_found", `No role named ${request.role} exists.`);
        }
        const modelSelector = request.model ?? role?.model;
        if (!modelSelector) {
          throw new SubagentToolError("model_required", "Provide a model or choose a role with a model default.");
        }
        const thinking = request.thinking ?? role?.thinking;
        if (!thinking) {
          throw new SubagentToolError(
            "thinking_required",
            "Provide a thinking level or choose a role with a thinking default.",
          );
        }
        const model = resolveAuthenticatedModel(ctx.modelRegistry, modelSelector);
        validateThinking(model, thinking as ThinkingLevel);
        validateContextFiles(request.context.files_the_subagent_must_read.map((file) => file.absolute_path));
        const workingDirectory = request.working_directory ?? ctx.cwd;
        requireExistingDirectory(workingDirectory);
        const parentSessionFile = requireParentSessionFile(ctx);
        const reviewerConversationFile = role?.name === "reviewer"
          ? writeActiveParentHumanConversationFile(
            parentSessionFile,
            request.subagent_name,
            ctx.sessionManager.getBranch(),
          )
          : undefined;
        const record = await manager.start(
          { ...request, working_directory: workingDirectory },
          { model: modelSelector, thinking: thinking as ThinkingLevel, role },
          parentSessionFile,
          reviewerConversationFile,
        );
        return successResult({ subagent_name: record.subagent_name, session_file: record.session_file });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "steer_subagent",
    label: "Steer subagent",
    description: "Queue Pi-native steering for an active child after its current tool calls, or resume a terminal child from the same validated session file. Running tools are not aborted. Do not start message_to_subagent with /: Pi treats it as a command.",
    parameters: schemas.steer,
    executionMode: "sequential",
    async execute(_id, request, _signal, _update, ctx) {
      try {
        const record = manager.require(request.subagent_name);
        const role = record.role ? roles.get(record.role) : undefined;
        if (record.role && !role) {
          throw new SubagentToolError("role_not_found", `Persisted role ${record.role} is not installed.`);
        }
        await manager.steer(record, request.message_to_subagent, role, requireParentSessionFile(ctx));
        return successResult({ subagent_name: record.subagent_name, session_file: record.session_file });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "list_subagents",
    label: "List subagents",
    description: "List every child in this parent session, with timestamps and bounded previews of current tool calls. Use it to diagnose a hang, not to poll for results. Children have no extension timeout.",
    parameters: schemas.empty,
    async execute() {
      const payload = {
        current_time: new Date().toISOString(),
        subagents: manager.all().map((record) => ({
          subagent_name: record.subagent_name,
          status: record.status,
          ...(record.failure_kind ? { failure_kind: record.failure_kind } : {}),
          ...(record.failure_detail ? { failure_detail: record.failure_detail } : {}),
          model: record.model,
          started_at: record.started_at,
          last_event_at: record.last_event_at,
          ...boundedToolCallPreviews(record.running_tool_calls),
          session_file: record.session_file,
        })),
      };
      return successResult(payload);
    },
  });

  pi.registerTool({
    name: "inspect_subagent_transcript",
    label: "Inspect subagent transcript",
    description: "Read a bounded view of the newest messages from a child's real Pi transcript, including provider-exposed thinking and the child session file.",
    parameters: schemas.inspect,
    async execute(_id, request) {
      try {
        const record = manager.require(request.subagent_name);
        const count = request.message_count ?? 20;
        const newestMessages = manager.transcript(record).slice(-count);
        return successResult(boundedTranscriptPayload(
          new Date().toISOString(),
          record.status,
          record.session_file,
          newestMessages,
        ));
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "cancel_subagent",
    label: "Cancel subagent",
    description: "Cancel a running child. Cancellation loses in-progress work. For a changed mission, steer it to report and start a new child instead.",
    parameters: schemas.cancel,
    executionMode: "sequential",
    async execute(_id, request) {
      try {
        const record = manager.require(request.subagent_name);
        await manager.cancel(record);
        return successResult({
          subagent_name: record.subagent_name,
          status: record.status,
          session_file: record.session_file,
        });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "list_subagent_models",
    label: "List subagent models",
    description: "List authenticated Pi registry models by model lab, with exact provider/id selectors and supported thinking levels for start_subagent.",
    parameters: schemas.empty,
    async execute(_id, _request, _signal, _update, ctx) {
      try {
        return successResult({ labs: groupedAvailableModels(ctx.modelRegistry) });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });
}
