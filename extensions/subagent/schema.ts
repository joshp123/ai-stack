import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";

const ThinkingSchema = StringEnum(
	["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const,
	{
		description: "Required Pi thinking level for this disposable run.",
	},
);

const WorkItemSchema = Type.Object({
	task: Type.String({
		minLength: 1,
		pattern: "\\S",
		description: "Concrete task for the child Pi process.",
	}),
	context: Type.String({
		minLength: 1,
		pattern: "\\S",
		description:
			"Caller-supplied context, constraints, and completion evidence for the task.",
	}),
	model: Type.String({
		minLength: 1,
		pattern: "^\\S+$",
		description:
			"Required Pi model selector. Passed through to pi --model after non-empty validation.",
	}),
	thinking: ThinkingSchema,
	cwd: Type.Optional(
		Type.String({
			minLength: 1,
			description: "Working directory for this child process.",
		}),
	),
});

export const SubagentParams = Type.Object({
	tasks: Type.Array(WorkItemSchema, {
		minItems: 1,
		maxItems: 3,
		description:
			"One to three independent disposable tasks. Tasks never receive output from other tasks.",
	}),
});
