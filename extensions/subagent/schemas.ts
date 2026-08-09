import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import type { RoleDefinition } from "./types.js";

const THINKING_VALUES = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;
const AbsoluteFilePathSchema = Type.String({
  pattern: "^/",
  description: "Absolute path to an existing file the child must read.",
});
const AbsoluteDirectoryPathSchema = Type.String({
  pattern: "^/",
  description: "Absolute existing working directory for the child. Omit to use the parent's current working directory.",
});
const SubagentNameSchema = Type.String({
  minLength: 2,
  maxLength: 64,
  pattern: "^[a-z0-9][a-z0-9-]{1,63}$",
  description: "Unique name for this child in the parent session. Use 2-64 lowercase letters, digits, or hyphens.",
});
const PiModelSelectorSchema = Type.Object({
  provider: Type.String({
    minLength: 1,
    description: "Exact Pi Model.provider value from list_subagent_models.",
  }),
  id: Type.String({
    minLength: 1,
    description: "Exact Pi Model.id value from list_subagent_models; do not prefix it with the provider.",
  }),
}, {
  additionalProperties: false,
  description: "Exact authenticated Pi model selector. Pi's model registry owns this catalog.",
});
const ThinkingSchema = StringEnum(THINKING_VALUES, {
  description: "Exact Pi thinking level supported by the selected model.",
});
const ColdStartContextSchema = Type.Object({
  files_the_subagent_must_read: Type.Array(Type.Object({
    absolute_path: AbsoluteFilePathSchema,
    why_this_file_matters: Type.String({
      minLength: 1,
      description: "Why this specific file is needed for the mission.",
    }),
  }, { additionalProperties: false }), {
    description: "Every existing file the child must read before it can complete the mission.",
  }),
  facts_verified_by_parent: Type.Array(Type.String({
    minLength: 1,
    description: "One fact the parent personally verified.",
  }), {
    description: "Facts the parent personally verified and the child may rely on.",
  }),
  instructions_to_access_the_work: Type.Array(Type.String({
    minLength: 1,
    description: "One concrete path, command, URL, credential method, or other access instruction.",
  }), {
    description: "Concrete methods the child needs to access and run the work.",
  }),
  unverified_claims_by_work_author: Type.Array(Type.String({
    minLength: 1,
    description: "One work-author claim the child must treat as unverified.",
  }), {
    description: "Claims made by the work author, kept separate from verified facts.",
  }),
}, {
  additionalProperties: false,
  description: "Complete cold-start evidence and access context for a child that has no parent conversation.",
});

export function createSchemas(roles: Map<string, RoleDefinition>) {
  const roleNames = [...roles.keys()] as [string, ...string[]];
  const RoleSchema = StringEnum(roleNames, {
    description: "Optional shipped role. A role supplies parent guidance, a child prompt, and optional model and thinking defaults.",
  });
  return {
    start: Type.Object({
      subagent_name: SubagentNameSchema,
      role: Type.Optional(RoleSchema),
      subagent_mission: Type.String({
        minLength: 1,
        description: "One outcome and its stopping condition. Reviewer: name the work slice and the work author's claimed user need, not human intent.",
      }),
      context: ColdStartContextSchema,
      model: Type.Optional(PiModelSelectorSchema),
      thinking: Type.Optional(ThinkingSchema),
      working_directory: Type.Optional(AbsoluteDirectoryPathSchema),
    }, { additionalProperties: false }),
    steer: Type.Object({
      subagent_name: SubagentNameSchema,
      message_to_subagent: Type.String({
        minLength: 1,
        description: "Guidance queued for an active child, or a new turn that resumes a terminal child in the same session file. Do not start it with /: Pi treats slash-prefixed input as a command.",
      }),
    }, { additionalProperties: false }),
    empty: Type.Object({}, { additionalProperties: false }),
    inspect: Type.Object({
      subagent_name: SubagentNameSchema,
      message_count: Type.Optional(Type.Integer({
        minimum: 1,
        maximum: 100,
        default: 20,
        description: "Number of newest transcript messages to return, from 1 through 100. Omit for 20.",
      })),
    }, { additionalProperties: false }),
    cancel: Type.Object({
      subagent_name: SubagentNameSchema,
    }, { additionalProperties: false }),
  };
}
