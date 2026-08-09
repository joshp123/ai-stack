import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { parseFrontmatter } from "@earendil-works/pi-coding-agent";
import type { PiModelSelector, RoleDefinition } from "./types.js";

const THINKING_LEVELS = new Set<ThinkingLevel>([
  "off", "minimal", "low", "medium", "high", "xhigh", "max",
]);
const ROLE_NAME_PATTERN = /^[a-z0-9][a-z0-9-]*$/;
const ROLE_FRONTMATTER_FIELDS = new Set(["name", "model", "thinking"]);
const ROLE_MODEL_FIELDS = new Set(["provider", "id"]);

type UnknownRecord = Record<string, unknown>;

function requireRecord(value: unknown, description: string): UnknownRecord {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${description} must be an object.`);
  }
  return value as UnknownRecord;
}

function rejectUnknownFields(record: UnknownRecord, allowedFields: Set<string>, description: string): void {
  const unknownFields = Object.keys(record).filter((field) => !allowedFields.has(field));
  if (unknownFields.length > 0) {
    throw new Error(`${description} has unknown field(s): ${unknownFields.join(", ")}.`);
  }
}

function parseRoleModel(frontmatter: UnknownRecord, filename: string): PiModelSelector | undefined {
  if (frontmatter.model === undefined) return undefined;
  const model = requireRecord(frontmatter.model, `Role ${filename} model`);
  rejectUnknownFields(model, ROLE_MODEL_FIELDS, `Role ${filename} model`);
  if (typeof model.provider !== "string" || model.provider.trim().length === 0) {
    throw new Error(`Role ${filename} model.provider must be a non-empty string.`);
  }
  if (typeof model.id !== "string" || model.id.trim().length === 0) {
    throw new Error(`Role ${filename} model.id must be a non-empty string.`);
  }
  return { provider: model.provider, id: model.id };
}

function parseRoleThinking(frontmatter: UnknownRecord, filename: string): ThinkingLevel | undefined {
  if (frontmatter.thinking === undefined) return undefined;
  if (typeof frontmatter.thinking !== "string" || !THINKING_LEVELS.has(frontmatter.thinking as ThinkingLevel)) {
    throw new Error(`Role ${filename} has invalid thinking level ${JSON.stringify(frontmatter.thinking)}.`);
  }
  return frontmatter.thinking as ThinkingLevel;
}

function requireRoleSection(body: string, heading: "parent" | "child", filename: string): string {
  const roleSectionPattern = new RegExp(
    String.raw`(?:^|\n)## ${heading}\s*\n([\s\S]*?)(?=\n##\s|$)`,
    "i",
  );
  const sectionBody = body.match(roleSectionPattern)?.[1]?.trim() ?? "";
  if (sectionBody.length === 0) {
    throw new Error(`Role ${filename} must have a non-empty ## ${heading} section.`);
  }
  return sectionBody;
}

export function loadRoles(agentsDirectory: string): Map<string, RoleDefinition> {
  const roles = new Map<string, RoleDefinition>();
  const filenames = readdirSync(agentsDirectory).filter((name) => name.endsWith(".md")).sort();
  for (const filename of filenames) {
    const parsedRole = parseFrontmatter<UnknownRecord>(readFileSync(join(agentsDirectory, filename), "utf8"));
    const frontmatter = requireRecord(parsedRole.frontmatter, `Role ${filename} frontmatter`);
    rejectUnknownFields(frontmatter, ROLE_FRONTMATTER_FIELDS, `Role ${filename} frontmatter`);
    const name = frontmatter.name;
    if (typeof name !== "string" || !ROLE_NAME_PATTERN.test(name)) {
      throw new Error(`Role ${filename} name must use lowercase letters, digits, or hyphens.`);
    }
    if (roles.has(name)) throw new Error(`Role name ${name} is duplicated by ${filename}.`);
    roles.set(name, {
      name,
      model: parseRoleModel(frontmatter, filename),
      thinking: parseRoleThinking(frontmatter, filename),
      parentGuidance: requireRoleSection(parsedRole.body, "parent", filename),
      childPrompt: requireRoleSection(parsedRole.body, "child", filename),
    });
  }
  if (roles.size === 0) throw new Error(`No roles were found in ${agentsDirectory}.`);
  return roles;
}

export function parentRoleGuidance(roles: Map<string, RoleDefinition>): string[] {
  return [...roles.values()].map((role) => `${role.name}: ${role.parentGuidance}`);
}
