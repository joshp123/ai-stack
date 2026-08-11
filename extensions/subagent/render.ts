import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import { getMarkdownTheme, type MessageRenderer, type Theme } from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Spacer, Text, type Component } from "@earendil-works/pi-tui";
import type { PiModelSelector, SubagentAdmission, SubagentStatus } from "./types.js";

// ============================================================================
// Rendering for the six subagent tools and the terminal-result message.
// Each renderer turns the structured tool payload into a compact, themed TUI
// line. The model still reads the full JSON via the tool content; these
// functions only shape what the human sees in the Pi window.
// ============================================================================

interface StartSubagentCallArgs {
  subagent_name: string;
  role?: string;
  subagent_mission: string;
  context: {
    files_the_subagent_must_read: Array<{ absolute_path: string; why_this_file_matters: string }>;
    facts_verified_by_parent: string[];
    instructions_to_access_the_work: string[];
    unverified_claims_by_work_author: string[];
  };
  model?: PiModelSelector;
  thinking?: string;
  working_directory?: string;
}

interface SteerSubagentCallArgs {
  subagent_name: string;
  message_to_subagent: string;
}

interface InspectTranscriptCallArgs {
  subagent_name: string;
  message_count?: number;
}

interface ListSubagentsResult {
  current_time: number;
  subagents: Array<{
    subagent_name: string;
    status: SubagentStatus;
    model: PiModelSelector;
    last_event_at: number;
  }>;
}

interface InspectTranscriptResult {
  current_time: number;
  child_session_file: string;
  status: SubagentStatus;
  messages: Array<{ role: string; stopReason?: string; content?: unknown }>;
}

interface ListModelsResult {
  model_laboratories: Array<{ model_laboratory: string; pi_models: Array<unknown> }>;
}

// ----------------------------------------------------------------------------
// Small formatting helpers
// ----------------------------------------------------------------------------

function truncateToLine(text: string, maxLength: number): string {
  const singleLine = text.replace(/\s+/g, " ").trim();
  if (singleLine.length <= maxLength) return singleLine;
  return `${singleLine.slice(0, maxLength - 1)}…`;
}

function modelLabel(model: PiModelSelector): string {
  return `${model.provider}/${model.id}`;
}

function statusColored(theme: Theme, status: SubagentStatus): string {
  switch (status) {
    case "running": return theme.fg("accent", status);
    case "finished": return theme.fg("success", status);
    case "cancelled": return theme.fg("warning", status);
    case "failed": return theme.fg("error", status);
  }
}

function ageLabel(nowMs: number, thenMs: number): string {
  const seconds = Math.max(0, Math.round((nowMs - thenMs) / 1000));
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const restSeconds = seconds % 60;
  return restSeconds > 0 ? `${minutes}m ${restSeconds}s` : `${minutes}m`;
}

function latestAssistantText(messages: InspectTranscriptResult["messages"]): string {
  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index];
    if (message.role !== "assistant" || !Array.isArray(message.content)) continue;
    const text = (message.content as Array<{ type?: string; text?: string }>)
      .filter((block) => block.type === "text" && typeof block.text === "string")
      .map((block) => block.text as string)
      .join("")
      .trim();
    if (text) return text;
  }
  return "";
}

// ----------------------------------------------------------------------------
// start_subagent
// ----------------------------------------------------------------------------

export function renderStartSubagentCall(args: StartSubagentCallArgs, theme: Theme, expanded: boolean): Component {
  const role = args.role ? `${args.role} · ` : "";
  const model = args.model ? modelLabel(args.model) : "role default";
  const thinking = args.thinking ? ` [${args.thinking}]` : "";
  const files = args.context.files_the_subagent_must_read;
  const mission = expanded ? args.subagent_mission.trim() : truncateToLine(args.subagent_mission, 96);
  let text =
    theme.fg("toolTitle", theme.bold("subagent ")) +
    theme.fg("accent", args.subagent_name) + "\n" +
    theme.fg("muted", `  ${role}${model}${thinking}`) + "\n" +
    theme.fg("toolOutput", `  ${mission}`);
  if (files.length > 0) {
    text += expanded
      ? "\n" + files.map((file) => theme.fg("dim", `  ${file.absolute_path}`)).join("\n")
      : theme.fg("dim", `\n  ${files.length} file${files.length === 1 ? "" : "s"}`);
  }
  return new Text(text, 0, 0);
}

export function renderStartSubagentResult(result: AgentToolResult<unknown>, theme: Theme): Component {
  const admission = result.details as SubagentAdmission | undefined;
  if (!admission) return new Text("subagent started", 0, 0);
  const role = admission.resolved_role ? `${admission.resolved_role} · ` : "";
  const text =
    theme.fg("success", "✓ ") +
    theme.fg("accent", theme.bold(admission.subagent_name)) +
    theme.fg("muted", ` started · ${role}${modelLabel(admission.resolved_model)} [${admission.resolved_thinking}]`);
  return new Text(text, 0, 0);
}

// ----------------------------------------------------------------------------
// steer_subagent
// ----------------------------------------------------------------------------

export function renderSteerSubagentCall(args: SteerSubagentCallArgs, theme: Theme): Component {
  const text =
    theme.fg("toolTitle", theme.bold("steer ")) +
    theme.fg("accent", args.subagent_name) +
    theme.fg("dim", ` → ${truncateToLine(args.message_to_subagent, 72)}`);
  return new Text(text, 0, 0);
}

export function renderSteerSubagentResult(result: AgentToolResult<unknown>, theme: Theme): Component {
  const details = result.details as { subagent_name?: string } | undefined;
  const text =
    theme.fg("success", "✓ ") +
    theme.fg("accent", details?.subagent_name ?? "subagent") +
    theme.fg("muted", " steered");
  return new Text(text, 0, 0);
}

// ----------------------------------------------------------------------------
// list_subagents
// ----------------------------------------------------------------------------

export function renderListSubagentsCall(_args: unknown, theme: Theme): Component {
  return new Text(theme.fg("toolTitle", theme.bold("subagents")), 0, 0);
}

export function renderListSubagentsResult(result: AgentToolResult<unknown>, theme: Theme): Component {
  const payload = result.details as ListSubagentsResult | undefined;
  if (!payload) return new Text("subagents", 0, 0);
  if (payload.subagents.length === 0) {
    return new Text(theme.fg("muted", "no subagents in this branch"), 0, 0);
  }
  let text = theme.fg("toolTitle", theme.bold(`subagents · ${payload.subagents.length}`));
  for (const subagent of payload.subagents) {
    text +=
      `\n  ${theme.fg("accent", subagent.subagent_name)}` +
      ` ${statusColored(theme, subagent.status)}` +
      ` ${theme.fg("muted", modelLabel(subagent.model))}` +
      ` ${theme.fg("dim", ageLabel(payload.current_time, subagent.last_event_at))}`;
  }
  return new Text(text, 0, 0);
}

// ----------------------------------------------------------------------------
// inspect_subagent_transcript
// ----------------------------------------------------------------------------

export function renderInspectTranscriptCall(args: InspectTranscriptCallArgs, theme: Theme): Component {
  const text =
    theme.fg("toolTitle", theme.bold("inspect ")) +
    theme.fg("accent", args.subagent_name) +
    theme.fg("muted", ` · ${args.message_count ?? 20} messages`);
  return new Text(text, 0, 0);
}

export function renderInspectTranscriptResult(result: AgentToolResult<unknown>, theme: Theme): Component {
  const payload = result.details as InspectTranscriptResult | undefined;
  if (!payload) return new Text("transcript", 0, 0);
  const latest = truncateToLine(latestAssistantText(payload.messages), 96);
  const text =
    theme.fg("muted", "transcript · ") + statusColored(theme, payload.status) +
    theme.fg("muted", ` · ${payload.messages.length} messages`) +
    (latest ? `\n  ${theme.fg("toolOutput", latest)}` : "");
  return new Text(text, 0, 0);
}

// ----------------------------------------------------------------------------
// cancel_subagent
// ----------------------------------------------------------------------------

export function renderCancelSubagentCall(args: { subagent_name: string }, theme: Theme): Component {
  const text = theme.fg("toolTitle", theme.bold("cancel ")) + theme.fg("accent", args.subagent_name);
  return new Text(text, 0, 0);
}

export function renderCancelSubagentResult(result: AgentToolResult<unknown>, theme: Theme): Component {
  const details = result.details as { subagent_name?: string } | undefined;
  const text =
    theme.fg("warning", "✕ ") +
    theme.fg("accent", details?.subagent_name ?? "subagent") +
    theme.fg("muted", " cancelled");
  return new Text(text, 0, 0);
}

// ----------------------------------------------------------------------------
// list_subagent_models
// ----------------------------------------------------------------------------

export function renderListModelsCall(_args: unknown, theme: Theme): Component {
  return new Text(theme.fg("toolTitle", theme.bold("models")), 0, 0);
}

export function renderListModelsResult(result: AgentToolResult<unknown>, theme: Theme): Component {
  const payload = result.details as ListModelsResult | undefined;
  if (!payload) return new Text("models", 0, 0);
  const totalModels = payload.model_laboratories.reduce(
    (sum, lab) => sum + lab.pi_models.length,
    0,
  );
  let text = theme.fg("toolTitle", theme.bold(`models · ${totalModels}`));
  for (const lab of payload.model_laboratories) {
    const modelCount = lab.pi_models.length;
    text += `\n  ${theme.fg("accent", lab.model_laboratory)} ${theme.fg("muted", `· ${modelCount} model${modelCount === 1 ? "" : "s"}`)}`;
  }
  return new Text(text, 0, 0);
}

// ----------------------------------------------------------------------------
// Terminal result message (pushed when a child reaches a terminal state)
// ----------------------------------------------------------------------------

function terminalMessageText(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter((block): block is { type: "text"; text: string } =>
        typeof block === "object" && block !== null && (block as { type?: string }).type === "text")
      .map((block) => block.text)
      .join("\n");
  }
  return "";
}

export const renderTerminalResultMessage: MessageRenderer = (message, _options, theme) => {
  const fullText = terminalMessageText(message.content).trim();
  const [heading, ...bodyLines] = fullText.split("\n");
  const body = bodyLines.join("\n").trim();
  const headingMatch = heading.match(/^Subagent (\S+) (finished|failed|cancelled)\.?$/);
  const subagentName = headingMatch?.[1] ?? "subagent";
  const terminalStatus = headingMatch?.[2] ?? "finished";
  const statusText =
    terminalStatus === "finished"
      ? theme.fg("success", "finished")
      : terminalStatus === "cancelled"
        ? theme.fg("warning", "cancelled")
        : theme.fg("error", "failed");

  const box = new Box(1, 1, (text: string) => theme.bg("customMessageBg", text));
  box.addChild(new Text(
    theme.fg("toolTitle", theme.bold("subagent ")) +
    theme.fg("accent", theme.bold(subagentName)) +
    ` ${statusText}`,
    0,
    0,
  ));
  if (body) {
    box.addChild(new Spacer(1));
    box.addChild(new Markdown(body, 0, 0, getMarkdownTheme(), {
      color: (text: string) => theme.fg("customMessageText", text),
    }));
  }
  return box;
};
