# Pi sub-agent API

Status: locked implementation contract.

This file defines the first Pi sub-agent implementation. Do not add a tool,
durable record, retry loop, background service or policy because it looks safer.
A change needs either a user decision or a demonstrated Pi failure that this
contract cannot handle.

## What this extension does

A parent Pi session starts independent child Pi sessions. The parent can keep
working while children run. It can inspect a child, steer it, cancel it and
resume a finished child from the same Pi session file.

Children start with no parent conversation. The parent gives each child a
mission and the files and facts it needs.

The extension has six public tools:

- `start_subagent`
- `steer_subagent`
- `list_subagents`
- `inspect_subagent_transcript`
- `cancel_subagent`
- `list_subagent_models`

Do not add a wait tool, delete tool, workflow tool, worktree tool, team tool,
inter-child messaging tool or recursive sub-agent tool.

## State ownership

Pi owns session storage, session trees, compaction, child transcripts, model
messages and tool calls.

The extension owns only:

- a live in-memory map of running child `AgentSession` objects;
- the child-session factory and reopen seam; and
- the tool logic that reads Pi session entries and sends a terminal result.

A successful `start_subagent` tool result is the durable child admission
record. Its `details` field is the only parent-side child index.

```ts
type SubagentAdmission = {
  version: 1;
  subagent_name: SubagentName;
  child_session_file: AbsoluteFilePath;
  resolved_role?: SubagentRoleName;
  resolved_model: PiModelSelector;
  resolved_thinking: PiThinkingLevel;
};
```

Pi persists tool-result details in the parent session JSONL. On session start,
compaction recovery or tree navigation, `list_subagents` scans the active
parent branch for successful `start_subagent` tool results and validates this
object.

Do not write a custom parent child registry. Do not copy mission, cold-start
context, status, final answer, timestamps, tool calls, steering messages or
notification history into the parent session.

## Child lifecycle

### Start

`start_subagent` creates a child Pi session in the parent session's dedicated
child-session directory. The child session records its parent session file.

The tool succeeds only after Pi has written the child's first user message to
disk. That message contains the mission and cold-start context. A successful
admission therefore always points to a resumable child transcript.

### Running

A running child exists in the extension's in-memory live-child map. This map is
not persisted. It supplies live tool calls and the latest event for
`list_subagents`.

### Finish, failure and cancellation

A terminal child removes itself from the live-child map. Its Pi session file
remains. `list_subagents` derives terminal status, timestamps and failure data
from the child transcript.

If the parent Pi process exits while a child runs, the in-memory child stops.
The transcript remains. A later `steer_subagent` opens the same child session
and starts a new turn. It does not replay a lost in-flight tool call.

### Steering

For a running child, `steer_subagent` uses Pi's native `AgentSession.steer()`.
Pi injects the message after the child's current assistant turn and its whole
tool-call batch finish. It does not interrupt a running tool.

For a terminal child, `steer_subagent` opens the retained child session and
starts a new turn with the message.

Do not persist or replay a queued steer. If Pi exits before Pi writes that
queued user message into the child transcript, it is lost.

### Terminal result

When a child reaches a terminal state, send one Pi custom message into the
owning parent branch. The custom message content is the child handoff. Its
details identify the terminal child result.

```ts
type SubagentTerminalResultReceipt = {
  child_session_file: AbsoluteFilePath;
  child_terminal_session_entry_id: string;
};
```

The persisted custom message is the receipt. On restore, scan the active parent
branch for terminal children without a matching receipt and send the missing
message.

Do not add a notification ledger, attempt set, generation counter, retry queue,
mailbox or bus. Pi cannot make terminal delivery and parent persistence atomic.
A restart can cause one duplicate result message. Prefer that to a second
notification system.

### Tree navigation

Before Pi changes a session tree while the current branch has live children,
the extension must ask:

```text
This will terminate <count> running subagents. Continue? [y/n]
```

`n` leaves the current branch unchanged. `y` asks Pi to abort each live child
and waits for Pi's normal abort operation before tree navigation continues. The
extension must not silently keep a child running after its parent leaves the
branch.

Pi branches share ancestor entries. A selected branch therefore sees every
successful admission on its active root-to-leaf path, including one created
before a later fork. Do not invent an owner-branch field, move a result between
branches, or hide a shared ancestor admission. Pi's tree path is the ownership
rule.

A terminal result created before the tree change remains in the old branch's
history. The destination branch receives no new terminal notification caused by
the tree operation.

## Tool contract

### Shared values

| Value | JSON form | Validation |
| --- | --- | --- |
| `SubagentName` | string | 2 to 64 lowercase letters, digits and hyphens; unique in the active parent branch |
| `AbsoluteFilePath` | string | absolute path; Pi/extension checks that required files exist |
| `AbsoluteDirectoryPath` | string | absolute path to an existing directory |
| `PiModelSelector` | `{ provider, id }` | exact Pi model selector; selected from `list_subagent_models` and checked against Pi's configured authentication |
| `PiThinkingLevel` | Pi's native thinking enum | checked against the selected Pi model |
| `UnixTimeMilliseconds` | number | one comparable time value for live Pi events and persisted Pi session entries |
| `SubagentRoleName` | generated enum | one installed role file name |

```ts
type SubagentStatus = "running" | "finished" | "failed" | "cancelled";

type SubagentFailureKind =
  | "parent_process_exited_mid_run"
  | "model_request_failed"
  | "tool_execution_failed";

type ModelLaboratory =
  | "openai" | "anthropic" | "deepseek" | "zhipu"
  | "moonshot" | "alibaba" | "minimax" | "other";
```

A string remains a string only when its value is prose, an operating-system
path or a Pi identifier. `UnixTimeMilliseconds` is a number because Pi has
both RFC 3339 session-entry timestamps and millisecond message timestamps. The
list API needs one comparable value for live and persisted child activity.
Pi messages returned by transcript inspection keep their native timestamps.

### `start_subagent`

```ts
type StartSubagentRequest = {
  subagent_name: SubagentName;
  role?: SubagentRoleName;
  subagent_mission: string;
  context: SubagentColdStartContext;
  model?: PiModelSelector;
  thinking?: PiThinkingLevel;
  working_directory?: AbsoluteDirectoryPath;
};

type SubagentColdStartContext = {
  files_the_subagent_must_read: Array<{
    absolute_path: AbsoluteFilePath;
    why_this_file_matters: string;
  }>;
  facts_verified_by_parent: string[];
  instructions_to_access_the_work: string[];
  unverified_claims_by_work_author: string[];
};
```

`subagent_mission` states the outcome, important boundaries, success condition
and stopping condition. It does not prescribe a procedure.

The child starts cold. `context` must name every relevant file, fact and access
method the child needs. All four context arrays are required. Use `[]` when one
is empty.

`model` and `thinking` are required unless the selected role supplies defaults.
Use the object returned by `list_subagent_models`; do not pass a `provider/id`
string.

The tool result is `SubagentAdmission` in both the model-visible JSON and the
Pi tool-result `details` field.

Tool guidance must tell the parent model:

- delegate substantial, independent work; do trivial work itself;
- start several children in one model response for parallel work;
- give concurrent writers separate files;
- include every file a zero-context child needs; and
- expect the terminal result as a pushed parent message, not by polling.

### `steer_subagent`

```ts
type SteerSubagentRequest = {
  subagent_name: SubagentName;
  message_to_subagent: string;
};
```

Use this to redirect a child or ask it to wrap up. A changed mission is not a
reason to cancel useful work. Steer the existing child to report what it found,
and start new children for the new work.

The result confirms that Pi accepted the request. It must not claim that the
child already read the message.

### `list_subagents`

This tool has no request fields.

It returns the current active branch's children. It derives every field from one
of three sources: the admission tool result, the child Pi session or the live
child map.

```ts
type RunningSubagent = SubagentAdmission & {
  status: "running";
  started_at: UnixTimeMilliseconds;
  last_event_at: UnixTimeMilliseconds;
  running_tool_calls: PiToolCall[];
};

type FinishedSubagent = SubagentAdmission & {
  status: "finished" | "cancelled";
  started_at: UnixTimeMilliseconds;
  last_event_at: UnixTimeMilliseconds;
};

type FailedSubagent = SubagentAdmission & {
  status: "failed";
  started_at: UnixTimeMilliseconds;
  last_event_at: UnixTimeMilliseconds;
  failure_kind: SubagentFailureKind;
  failure_detail?: string;
};

type ListSubagentsResult = {
  current_time: UnixTimeMilliseconds;
  subagents: Array<RunningSubagent | FinishedSubagent | FailedSubagent>;
};
```

Use `current_time`, `last_event_at`, live tool calls and transcript inspection
to judge whether a child is stuck. Do not use this tool as a tight polling loop.

### `inspect_subagent_transcript`

```ts
type InspectSubagentTranscriptRequest = {
  subagent_name: SubagentName;
  message_count?: number; // default: 20
};

type InspectSubagentTranscriptResult = {
  current_time: UnixTimeMilliseconds;
  child_session_file: AbsoluteFilePath;
  status: SubagentStatus;
  messages: PiAgentMessage[];
};
```

`PiAgentMessage` is Pi's native `AgentMessage` type. Do not create another
transcript message format. It includes provider-exposed thinking, assistant
text, tool calls and tool results. Codex may expose a reasoning summary or no
thinking content.

Return the newest requested messages in their Pi shapes. Do not impose an
arbitrary line, token or character budget. The default message count keeps the
normal call small; callers increase it only when they need more evidence.

### `cancel_subagent`

```ts
type CancelSubagentRequest = {
  subagent_name: SubagentName;
};
```

This asks Pi to abort a running child. It is exceptional. Cancellation loses
work in progress. It does not delete the child transcript. A terminal child can
later receive a new turn through `steer_subagent`.

### `list_subagent_models`

This tool has no request fields.

It returns only Pi models with configured authentication. It groups exact Pi
model selectors by model laboratory.

```ts
type ListSubagentModelsResult = {
  model_laboratories: Array<{
    model_laboratory: ModelLaboratory;
    pi_models: Array<{
      pi_model_selector: PiModelSelector;
      supported_pi_thinking_levels: PiThinkingLevel[];
    }>;
  }>;
};
```

`ModelLaboratory` is an extension-owned presentation enum. Pi owns `provider`
and `id`. Keep the laboratory mapping small, explicit and versioned. Include
`other` for an unclassified Pi model. Do not pretend Pi supplies this category.

## Roles

Roles are tiny installed Markdown files. They are defaults and guidance, not a
workflow framework. V1 has only `scout` and `reviewer`.

### Scout

The parent guidance says: use cheap, fast models for orthogonal research. Fan
out breadth-first, then go deeper. Run two scouts on the same question when a
second result reduces uncertainty. Verify important conclusions with evidence
or a stronger model.

The child guidance says: report findings with sources and state what it could
not verify.

### Reviewer

A reviewer has zero parent-model context.

The parent gives it:

- the work slice under review and the work author's claimed user need;
- every file, command, URL and access method needed to use the product; and
- work-author claims in `unverified_claims_by_work_author`.

The extension gives it a file containing the active parent branch's user
messages. Those messages are the only source of human intent.

For a reviewer, every parent-authored statement is a lead to test. This includes
`facts_verified_by_parent`, the work author's claimed user need and the work
author's scope explanation. Paths and access instructions are logistics. The
mechanical human-message snapshot is the only source of human intent.

The reviewer uses the product as the human will use it, takes its own
screenshots where the human path is visual, and checks for broken, missing and
over-engineered work against Pi's `AGENTS.md`. It reports evidence. It does not
fix the work.

## Validation and errors

TypeBox validates request shape, required fields, generated role enums and path
form. Admission code validates facts that a schema cannot: file existence,
working directory, unique name, model authentication and model thinking level.

Pi reports provider and tool runtime failures. The extension throws one compact
typed semantic error payload where Pi requires a thrown tool error.

Do not add semantic scoring, confidence fields, budgets, extra safety modes or
input sanitizers.

## Explicit exclusions

Do not add:

- a custom parent child registry or mutable lifecycle record;
- copied child mission, context, final answer, timestamps or tool calls;
- durable steering replay;
- notification attempt tracking, retry loops or agent mail;
- a daemon, broker, mailbox, second session store or second backend;
- child-to-child messaging, workflows, chains, teams or worktrees;
- recursive sub-agent tools in children;
- a wait tool, delete tool, garbage collector, timeout or concurrency limit;
- role presets beyond the two small role files without a user decision; or
- a compatibility layer for an older sub-agent API.

## Required proof before release

Prove the human paths below against real Pi before changing this contract:

1. A cold child reads the supplied files and completes its mission.
2. Several independent children start in one parent response.
3. A running child receives a steer only after its current tool batch finishes.
4. A terminal child resumes from the same child session file.
5. Parent restart and compaction still let `list_subagents` and transcript
   inspection find admitted children.
6. A confirmed `/tree` stops live children before branch navigation; `n` does
   not change branch.
7. A reviewer reads the mechanical human-message snapshot and verifies the
   product through the human path.
8. A model selected through `list_subagent_models` starts with its supported
   thinking level.
