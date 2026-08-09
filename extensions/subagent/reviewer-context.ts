import { randomUUID } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import type { SessionEntry } from "@earendil-works/pi-coding-agent";
import { SubagentToolError } from "./types.js";

export function writeActiveParentHumanConversationFile(
  parentSessionFile: string,
  subagentName: string,
  activeParentBranch: SessionEntry[],
): string {
  const activeBranchUserMessages = activeParentBranch
    .filter((entry) => entry.type === "message" && entry.message.role === "user")
    .map((entry) => entry.type === "message" ? entry.message : undefined)
    .filter((message) => message !== undefined);
  const parentSessionBasename = basename(parentSessionFile, ".jsonl");
  const snapshotFilename = `${parentSessionBasename}.subagent-${subagentName}.${randomUUID()}.active-parent-human-conversation.jsonl`;
  const snapshotDirectory = join(dirname(parentSessionFile), "subagent-reviewer-context");
  const snapshotPath = join(snapshotDirectory, snapshotFilename);
  const jsonLines = activeBranchUserMessages.map((message) => JSON.stringify(message)).join("\n");
  try {
    mkdirSync(snapshotDirectory, { recursive: true, mode: 0o700 });
    writeFileSync(snapshotPath, jsonLines.length > 0 ? `${jsonLines}
` : "", {
      encoding: "utf8",
      flag: "wx",
      mode: 0o600,
    });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new SubagentToolError(
      "reviewer_conversation_file_invalid",
      `Could not persist the reviewer human-conversation snapshot: ${detail}`,
    );
  }
  return snapshotPath;
}
