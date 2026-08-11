import type { AgentSessionEvent } from "@earendil-works/pi-coding-agent";
import { readPersistedChildTranscript } from "./child-runner.js";
import type {
  ChildRuntime,
  ChildUserMessagePersistenceWaiter,
  LiveChild,
  PersistedChildTranscript,
  SubagentAdmission,
} from "./types.js";
import { SubagentToolError } from "./types.js";

export interface LaunchedChildTurn {
  liveChild: LiveChild;
  prompt: Promise<void>;
  userMessagePersistence: ChildUserMessagePersistenceWaiter;
}

export function launchChildTurn(
  liveChildren: Map<string, LiveChild>,
  admission: SubagentAdmission,
  runtime: ChildRuntime,
  message: string,
  reachedTerminalState: (admission: SubagentAdmission, transcript: PersistedChildTranscript) => void,
): LaunchedChildTurn {
  if (liveChildren.has(admission.subagent_name)) {
    runtime.dispose();
    throw new SubagentToolError(
      "subagent_name_already_used",
      `Subagent name ${admission.subagent_name} is already running in the active branch.`,
    );
  }
  const liveChild: LiveChild = {
    session: runtime.session,
    last_event_at: Date.now(),
    running_tool_calls: [],
    completion: Promise.resolve(),
  };
  runtime.session.subscribe((event) => recordLiveChildEvent(liveChild, event));
  const userMessagePersistence = runtime.prepareNextUserMessagePersistence();
  liveChildren.set(admission.subagent_name, liveChild);
  const prompt = runtime.session.prompt(message);
  liveChild.completion = (async () => {
    try {
      await prompt;
    } catch {}
    if (liveChildren.get(admission.subagent_name) !== liveChild) return;
    liveChildren.delete(admission.subagent_name);
    try {
      reachedTerminalState(admission, readPersistedChildTranscript(admission.child_session_file));
    } finally {
      runtime.dispose();
    }
  })();
  return { liveChild, prompt, userMessagePersistence };
}

export async function waitForChildTurnAdmission(
  liveChildren: Map<string, LiveChild>,
  runtime: ChildRuntime,
  launchedChildTurn: LaunchedChildTurn,
  subagentName: string,
): Promise<void> {
  try {
    await launchedChildTurn.userMessagePersistence.waitFor(launchedChildTurn.prompt);
  } catch (error) {
    launchedChildTurn.userMessagePersistence.cancel();
    if (liveChildren.get(subagentName) === launchedChildTurn.liveChild) {
      liveChildren.delete(subagentName);
    }
    runtime.dispose();
    await launchedChildTurn.liveChild.completion;
    throw error;
  }
}

function recordLiveChildEvent(liveChild: LiveChild, event: AgentSessionEvent): void {
  liveChild.last_event_at = Date.now();
  if (event.type === "tool_execution_start") {
    liveChild.running_tool_calls.push({
      type: "toolCall",
      id: event.toolCallId,
      name: event.toolName,
      arguments: event.args,
    });
  }
  if (event.type === "tool_execution_end") {
    liveChild.running_tool_calls = liveChild.running_tool_calls.filter((toolCall) => toolCall.id !== event.toolCallId);
  }
}
