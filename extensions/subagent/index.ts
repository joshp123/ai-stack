import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { openChildRuntime, readPersistedChildTranscript } from "./child-runner.js";
import { launchChildTurn, waitForChildTurnAdmission } from "./live-children.js";
import {
  currentBranchSubagentAdmissions,
  hasTerminalResultReceipt,
  SUBAGENT_TERMINAL_RESULT_MESSAGE,
} from "./parent-session-admissions.js";
import { writeActiveParentHumanConversationFile } from "./reviewer-context.js";
import { loadRoles, parentRoleGuidance } from "./roles.js";
import { createSchemas } from "./schemas.js";
import {
  authenticatedModelsByLaboratory,
  modelVisibleToolResult,
  resolveAuthenticatedModel,
  subagentAdmissionToolResult,
  throwTypedToolError,
  validateContextFiles,
  validateExistingWorkingDirectory,
  validateThinking,
} from "./tool-support.js";
import {
  SUBAGENT_NAME_PATTERN,
  type CancelSubagentRequest,
  type InspectSubagentTranscriptRequest,
  type LiveChild,
  type PersistedChildTranscript,
  type RoleDefinition,
  type StartSubagentRequest,
  type SteerSubagentRequest,
  type SubagentAdmission,
  type SubagentTerminalResultReceipt,
  SubagentToolError,
} from "./types.js";

const extensionDirectory = dirname(fileURLToPath(import.meta.url));

function requireParentSessionFile(ctx: ExtensionContext): string {
  const parentSessionFile = ctx.sessionManager.getSessionFile();
  if (!parentSessionFile) {
    throw new SubagentToolError(
      "parent_session_not_persisted",
      "The parent session is not persisted, so it cannot own a resumable child.",
    );
  }
  return parentSessionFile;
}

function initialChildMessage(
  request: StartSubagentRequest,
  activeParentHumanConversationFile: string | undefined,
): string {
  const reviewerIntentSource = activeParentHumanConversationFile
    ? [
      "Reviewer intent source:",
      `active_parent_human_conversation_file: ${activeParentHumanConversationFile}`,
      "Read every JSONL line in that file. Only its user-role messages define human intent.",
      "Work-author claims in the context are unverified evidence.",
      "",
    ]
    : [];
  return [
    ...reviewerIntentSource,
    "Subagent mission:",
    request.subagent_mission.trim(),
    "",
    "Context:",
    JSON.stringify(request.context, null, 2),
  ].join("\n");
}

function terminalHandoff(
  admission: SubagentAdmission,
  terminalTranscript: PersistedChildTranscript,
): string {
  const heading = `Subagent ${admission.subagent_name} ${terminalTranscript.status}.`;
  if (terminalTranscript.handoff) return `${heading}\n\n${terminalTranscript.handoff}`;
  if (terminalTranscript.failure_detail) return `${heading}\n\n${terminalTranscript.failure_detail}`;
  return heading;
}

export default function subagentExtension(pi: ExtensionAPI) {
  const roles = loadRoles(join(extensionDirectory, "agents"));
  const installedRoleNames = new Set(roles.keys());
  const schemas = createSchemas(roles);
  const liveChildren = new Map<string, LiveChild>();

  function activeBranchAdmissions(ctx: ExtensionContext): SubagentAdmission[] {
    return currentBranchSubagentAdmissions(ctx.sessionManager.getBranch(), installedRoleNames);
  }

  function requireAdmission(ctx: ExtensionContext, subagentName: string): SubagentAdmission {
    const admission = activeBranchAdmissions(ctx).find((candidate) => candidate.subagent_name === subagentName);
    if (!admission) {
      throw new SubagentToolError("subagent_not_found", `No subagent named ${subagentName} exists in the active branch.`);
    }
    return admission;
  }

  function requireRole(roleName: string | undefined): RoleDefinition | undefined {
    if (!roleName) return undefined;
    const role = roles.get(roleName);
    if (!role) throw new SubagentToolError("role_not_found", `No installed role named ${roleName} exists.`);
    return role;
  }

  function validateUnusedSubagentName(ctx: ExtensionContext, subagentName: string): void {
    if (!SUBAGENT_NAME_PATTERN.test(subagentName)) {
      throw new SubagentToolError(
        "subagent_name_invalid",
        `Subagent name ${JSON.stringify(subagentName)} must contain 2-64 lowercase letters, digits, or hyphens.`,
      );
    }
    if (activeBranchAdmissions(ctx).some((admission) => admission.subagent_name === subagentName) ||
        liveChildren.has(subagentName)) {
      throw new SubagentToolError(
        "subagent_name_already_used",
        `Subagent name ${subagentName} is already used in the active branch.`,
      );
    }
  }

  function sendTerminalResult(
    admission: SubagentAdmission,
    terminalTranscript: PersistedChildTranscript,
    deliveryMode: "live" | "recovery",
  ): void {
    const receipt: SubagentTerminalResultReceipt = {
      child_session_file: admission.child_session_file,
      child_terminal_session_entry_id: terminalTranscript.terminal_session_entry_id,
    };
    // Live delivery: the parent is mid-turn, so steer queues at the next turn
    // boundary (or triggerTurn starts a fresh turn when the parent is idle).
    // Recovery delivery: pi.sendMessage is fire-and-forget, so a triggerTurn
    // races the user's next prompt and can be lost. nextTurn pushes synchronously
    // and injects the result alongside the next user message.
    pi.sendMessage({
      customType: SUBAGENT_TERMINAL_RESULT_MESSAGE,
      content: terminalHandoff(admission, terminalTranscript),
      display: true,
      details: receipt,
    }, deliveryMode === "recovery"
      ? { deliverAs: "nextTurn" }
      : { triggerTurn: true, deliverAs: "steer" });
  }

  async function openAndStartResumedChild(
    ctx: ExtensionContext,
    admission: SubagentAdmission,
    messageToSubagent: string,
  ): Promise<void> {
    const role = requireRole(admission.resolved_role);
    const model = resolveAuthenticatedModel(ctx.modelRegistry, admission.resolved_model);
    validateThinking(model, admission.resolved_thinking);
    const runtime = await openChildRuntime({
      child_session_file: admission.child_session_file,
      model: admission.resolved_model,
      thinking: admission.resolved_thinking,
      child_role_prompt: role?.childPrompt,
    });
    const launchedChildTurn = launchChildTurn(
      liveChildren,
      admission,
      runtime,
      messageToSubagent,
      (childAdmission, childTranscript) => sendTerminalResult(childAdmission, childTranscript, "live"),
    );
    await waitForChildTurnAdmission(liveChildren, runtime, launchedChildTurn, admission.subagent_name);
  }

  function recoverMissingTerminalResults(ctx: ExtensionContext): void {
    const activeBranch = ctx.sessionManager.getBranch();
    for (const admission of currentBranchSubagentAdmissions(activeBranch, installedRoleNames)) {
      if (liveChildren.has(admission.subagent_name)) continue;
      const terminalTranscript = readPersistedChildTranscript(admission.child_session_file);
      const receipt: SubagentTerminalResultReceipt = {
        child_session_file: admission.child_session_file,
        child_terminal_session_entry_id: terminalTranscript.terminal_session_entry_id,
      };
      if (!hasTerminalResultReceipt(activeBranch, receipt)) {
        sendTerminalResult(admission, terminalTranscript, "recovery");
      }
    }
  }

  pi.on("session_start", (_event, ctx) => {
    recoverMissingTerminalResults(ctx);
  });

  pi.on("session_compact", (_event, ctx) => {
    recoverMissingTerminalResults(ctx);
  });

  let pendingTreeTerminations: LiveChild[] = [];

  pi.on("session_before_tree", async (event, ctx) => {
    const liveChildrenInCurrentBranch = activeBranchAdmissions(ctx)
      .map((admission) => liveChildren.get(admission.subagent_name))
      .filter((liveChild): liveChild is LiveChild => Boolean(liveChild));
    if (liveChildrenInCurrentBranch.length === 0) return;
    const confirmationPrompt =
      `This will terminate ${liveChildrenInCurrentBranch.length} running subagents. Continue? [y/n]`;
    const confirmed = await ctx.ui.confirm(confirmationPrompt, "", { signal: event.signal });
    if (!confirmed) return { cancel: true };
    // Terminate only after Pi confirms the branch actually changed (session_tree).
    // A cancelled navigation (e.g. the user aborts branch summarisation) must not
    // kill children: session_tree never fires, and the children keep running.
    pendingTreeTerminations = liveChildrenInCurrentBranch;
  });

  pi.on("session_tree", async () => {
    const childrenToTerminate = pendingTreeTerminations;
    pendingTreeTerminations = [];
    await Promise.all(childrenToTerminate.map(async (liveChild) => {
      await liveChild.session.abort();
      await liveChild.completion;
    }));
  });

  pi.on("session_shutdown", async () => {
    const runningChildren = [...liveChildren.values()];
    liveChildren.clear();
    await Promise.all(runningChildren.map(async (liveChild) => {
      try {
        await liveChild.session.abort();
      } catch {} finally {
        liveChild.session.dispose();
      }
      await liveChild.completion;
    }));
  });

  pi.registerTool({
    name: "start_subagent",
    label: "Start subagent",
    description: "Delegate substantial independent work. Do trivial work yourself. Start several independent children in one response for parallel work, give concurrent writers separate files, and give every cold child every file, fact, and access method it needs. Terminal handoffs are pushed into this parent session; do not poll for them.",
    promptGuidelines: parentRoleGuidance(roles),
    parameters: schemas.start,
    executionMode: "parallel",
    async execute(_id, rawRequest, _signal, _update, ctx) {
      try {
        const request = rawRequest as StartSubagentRequest;
        validateUnusedSubagentName(ctx, request.subagent_name);
        const role = requireRole(request.role);
        const modelSelector = request.model ?? role?.model;
        if (!modelSelector) {
          throw new SubagentToolError("model_required", "Provide a model or choose a role with a model default.");
        }
        const thinking = request.thinking ?? role?.thinking;
        if (!thinking) {
          throw new SubagentToolError("thinking_required", "Provide a thinking level or choose a role with a thinking default.");
        }
        const model = resolveAuthenticatedModel(ctx.modelRegistry, modelSelector);
        validateThinking(model, thinking as ThinkingLevel);
        validateContextFiles(request.context.files_the_subagent_must_read.map((file) => file.absolute_path));
        const workingDirectory = request.working_directory ?? ctx.cwd;
        validateExistingWorkingDirectory(workingDirectory);
        const parentSessionFile = requireParentSessionFile(ctx);
        const activeParentHumanConversationFile = role?.name === "reviewer"
          ? writeActiveParentHumanConversationFile(
            parentSessionFile,
            request.subagent_name,
            ctx.sessionManager.getBranch(),
          )
          : undefined;
        const runtime = await openChildRuntime({
          working_directory: workingDirectory,
          parent_session_file: parentSessionFile,
          model: modelSelector,
          thinking: thinking as ThinkingLevel,
          child_role_prompt: role?.childPrompt,
        });
        const admission: SubagentAdmission = {
          version: 1,
          subagent_name: request.subagent_name,
          child_session_file: runtime.child_session_file,
          ...(role ? { resolved_role: role.name } : {}),
          resolved_model: { ...modelSelector },
          resolved_thinking: thinking as ThinkingLevel,
        };
        const launchedChildTurn = launchChildTurn(
          liveChildren,
          admission,
          runtime,
          initialChildMessage(request, activeParentHumanConversationFile),
          (childAdmission, childTranscript) => sendTerminalResult(childAdmission, childTranscript, "live"),
        );
        await waitForChildTurnAdmission(liveChildren, runtime, launchedChildTurn, admission.subagent_name);
        return subagentAdmissionToolResult(admission);
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "steer_subagent",
    label: "Steer subagent",
    description: "Redirect a useful child or ask it to wrap up. A running child receives native Pi steering after its current assistant turn and whole tool-call batch finish; tools are not interrupted. A terminal child resumes from its retained session file.",
    parameters: schemas.steer,
    executionMode: "parallel",
    async execute(_id, rawRequest, _signal, _update, ctx) {
      try {
        const request = rawRequest as SteerSubagentRequest;
        const admission = requireAdmission(ctx, request.subagent_name);
        const liveChild = liveChildren.get(admission.subagent_name);
        if (liveChild?.session.isStreaming) {
          await liveChild.session.steer(request.message_to_subagent);
        } else {
          if (liveChild) await liveChild.completion;
          await openAndStartResumedChild(ctx, admission, request.message_to_subagent);
        }
        return modelVisibleToolResult({
          subagent_name: admission.subagent_name,
          child_session_file: admission.child_session_file,
        });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "list_subagents",
    label: "List subagents",
    description: "List active-branch children. Use current_time, last_event_at, live tool calls, and transcript inspection to judge whether a child is stuck; do not use this as a tight polling loop.",
    parameters: schemas.empty,
    async execute(_id, _request, _signal, _update, ctx) {
      try {
        const currentTime = Date.now();
        const subagents = activeBranchAdmissions(ctx).map((admission) => {
          const terminalTranscript = readPersistedChildTranscript(admission.child_session_file);
          const liveChild = liveChildren.get(admission.subagent_name);
          if (liveChild) {
            return {
              ...admission,
              status: "running" as const,
              started_at: terminalTranscript.started_at,
              last_event_at: liveChild.last_event_at,
              running_tool_calls: [...liveChild.running_tool_calls],
            };
          }
          return {
            ...admission,
            status: terminalTranscript.status,
            started_at: terminalTranscript.started_at,
            last_event_at: terminalTranscript.last_event_at,
            ...(terminalTranscript.failure_kind ? { failure_kind: terminalTranscript.failure_kind } : {}),
            ...(terminalTranscript.failure_detail ? { failure_detail: terminalTranscript.failure_detail } : {}),
          };
        });
        return modelVisibleToolResult({ current_time: currentTime, subagents });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "inspect_subagent_transcript",
    label: "Inspect subagent transcript",
    description: "Return the newest requested native Pi messages from a child transcript. The default is 20 messages; request more only when more evidence is needed.",
    parameters: schemas.inspect,
    async execute(_id, rawRequest, _signal, _update, ctx) {
      try {
        const request = rawRequest as InspectSubagentTranscriptRequest;
        const admission = requireAdmission(ctx, request.subagent_name);
        const liveChild = liveChildren.get(admission.subagent_name);
        const terminalTranscript = readPersistedChildTranscript(admission.child_session_file);
        const messages = (liveChild ? liveChild.session.messages : terminalTranscript.messages)
          .slice(-(request.message_count ?? 20));
        return modelVisibleToolResult({
          current_time: Date.now(),
          child_session_file: admission.child_session_file,
          status: liveChild ? "running" : terminalTranscript.status,
          messages,
        });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "cancel_subagent",
    label: "Cancel subagent",
    description: "Exceptionally abort a running child. Cancellation loses work in progress and retains its transcript. For a changed mission, steer useful work to report what it found and start another child for the new work.",
    parameters: schemas.cancel,
    executionMode: "parallel",
    async execute(_id, rawRequest, _signal, _update, ctx) {
      try {
        const request = rawRequest as CancelSubagentRequest;
        const admission = requireAdmission(ctx, request.subagent_name);
        const liveChild = liveChildren.get(admission.subagent_name);
        if (!liveChild) {
          throw new SubagentToolError("subagent_not_running", `Subagent ${admission.subagent_name} is not running.`);
        }
        await liveChild.session.abort();
        await liveChild.completion;
        return modelVisibleToolResult({
          subagent_name: admission.subagent_name,
          child_session_file: admission.child_session_file,
        });
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });

  pi.registerTool({
    name: "list_subagent_models",
    label: "List subagent models",
    description: "List only authenticated Pi models, grouped by the extension's model laboratory presentation enum. Use the returned exact selector and supported thinking level with start_subagent.",
    parameters: schemas.empty,
    async execute(_id, _request, _signal, _update, ctx) {
      try {
        return modelVisibleToolResult(authenticatedModelsByLaboratory(ctx.modelRegistry));
      } catch (error) {
        throwTypedToolError(error);
      }
    },
  });
}
