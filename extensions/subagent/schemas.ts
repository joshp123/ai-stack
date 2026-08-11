import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import type { RoleDefinition } from "./types.js";

const PI_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

const AbsoluteFilePathSchema = Type.String({
  pattern: "^/",
  description: "Absolute path to an existing file the child must read.",
});
const AbsoluteDirectoryPathSchema = Type.String({
  pattern: "^/",
  description: "Absolute existing working directory. Omit to use the parent working directory.",
});
const SubagentNameSchema = Type.String({
  minLength: 2,
  maxLength: 64,
  pattern: "^[a-z0-9-]{2,64}$",
  description: "Unique active-branch child name: 2-64 lowercase letters, digits, and hyphens.",
});
const PiModelSelectorSchema = Type.Object({
  provider: Type.String({ minLength: 1, description: "Exact provider from list_subagent_models." }),
  id: Type.String({ minLength: 1, description: "Exact model id from list_subagent_models." }),
}, {
  additionalProperties: false,
  description: "Exact authenticated Pi model selector.",
});
const PiThinkingLevelSchema = StringEnum(PI_THINKING_LEVELS, {
  description: "Pi thinking level supported by the selected model.",
});
const ColdStartContextSchema = Type.Object({
  files_the_subagent_must_read: Type.Array(Type.Object({
    absolute_path: AbsoluteFilePathSchema,
    why_this_file_matters: Type.String({
      minLength: 1,
      description: "Why this zero-context child must read this exact file.",
    }),
  }, { additionalProperties: false }), {
    description: "Every relevant file the child must read before it works.",
  }),
  facts_verified_by_parent: Type.Array(Type.String({ minLength: 1 }), {
    description: "Facts the parent checked. A reviewer treats them as leads, not human intent.",
  }),
  instructions_to_access_the_work: Type.Array(Type.String({ minLength: 1 }), {
    description: "Commands, URLs, credentials paths, or other access instructions the child needs.",
  }),
  unverified_claims_by_work_author: Type.Array(Type.String({ minLength: 1 }), {
    description: "Claims from the work author that the child must verify rather than trust.",
  }),
}, {
  additionalProperties: false,
  description: "All four cold-start evidence arrays are required; use [] when empty.",
});

export function createSchemas(roles: Map<string, RoleDefinition>) {
  const roleNames = [...roles.keys()] as [string, ...string[]];
  const RoleSchema = StringEnum(roleNames, {
    description: "Installed role whose defaults and guidance apply to this child.",
  });

  return {
    start: Type.Object({
      subagent_name: SubagentNameSchema,
      role: Type.Optional(RoleSchema),
      subagent_mission: Type.String({
        minLength: 1,
        description: "Outcome, important boundaries, success condition, and stopping condition.",
      }),
      context: ColdStartContextSchema,
      model: Type.Optional(PiModelSelectorSchema),
      thinking: Type.Optional(PiThinkingLevelSchema),
      working_directory: Type.Optional(AbsoluteDirectoryPathSchema),
    }, { additionalProperties: false }),
    steer: Type.Object({
      subagent_name: SubagentNameSchema,
      message_to_subagent: Type.String({
        minLength: 1,
        description: "New direction or a wrap-up request. Pi queues it after a running child's current tool batch.",
      }),
    }, { additionalProperties: false }),
    empty: Type.Object({}, { additionalProperties: false }),
    inspect: Type.Object({
      subagent_name: SubagentNameSchema,
      message_count: Type.Optional(Type.Integer({
        minimum: 1,
        default: 20,
        description: "Newest native Pi messages to return. Default: 20. Increase only when more evidence is needed.",
      })),
    }, { additionalProperties: false }),
    cancel: Type.Object({
      subagent_name: SubagentNameSchema,
    }, { additionalProperties: false }),
  };
}
