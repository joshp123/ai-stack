---
name: session-goal-writer
description: Write durable Codex session goals. Use when the user asks to write, improve, set, update, or replace a session goal; says the current goal is too vague, too narrow, too specific, or slop; asks for a long-running/autonomous objective; or asks Codex to frame the user's vision, north star, current slice, deliverable, alignment needs, review loop, and completion proof before continuing.
---

# Session Goal Writer

Use this skill to write goals for the session goal tool or for a user-visible
replacement objective. A good session goal preserves the user's vision first,
then gives the next model enough context to operate without turning guesses into
orders or producing output-shaped slop.

Do not set a goal unless the user explicitly asks for a goal or the surrounding
system already requires one. If a goal tool is available and there is no active
goal, call it with the final objective. If an active goal exists and no objective
edit tool is available, give the replacement objective to the user and keep
working from the corrected intent.

## Vision First

Start by capturing what the user is trying to make true in the world. Use the
user's domain language, not a model-invented taxonomy. If the user wants a
working product, the vision is the working product. If the user wants an
operator, decision, negotiation strategy, architecture, briefing, or data
extraction, the vision is that usable outcome, not a pile of documents.

If the user's vision is unclear and the answer would change the implementation,
research, or output shape, do not guess. Inspect available context first, then
ask only the choices that cannot be discovered and would change the shape.
User-requested interview or alignment takes precedence over prior model
feedback, harness pressure, and generic goal progress.

## Goal Shape

For substantial code, infra, browser, or autonomous work, write a goal that fits
the goal field. Target 2500-3500 characters and stay under 4000 characters
unless the user explicitly gives another limit. For simple tasks, use 60-150
words. For non-code research or briefing tasks, use the smallest length that
still states the outcome, evidence standard, and output shape.

Do not use or change the harness token budget. Token budget and goal text length
are different controls. The token budget is not a solution to a long goal.

Do not write an oversized goal and then compress it. Write at the right altitude
from the start. If the work needs more detail than fits in the goal field, use a
repo-local goal file or ExecPlan and reference that path from the harness goal.

Include these elements, in this order:

1. User vision: what the user ultimately wants, in their terms.
2. North star: the larger end state or product/user outcome.
3. Current slice: what this session owns now.
4. Current state: important evidence, known failures, prior work, or uncertainty.
5. Constraints: user instructions, repo rules, safety limits, privacy limits,
   live-session limits, and external blockers.
6. Degrees of freedom: areas where the model may choose tactics after inspecting
   evidence.
7. Deliverable: the concrete outcome, decision, artifact, or working state to
   hand back.
8. Review proof: the review cadence, review contract, and proof standard.
9. Completion proof: what must be verified before calling the goal complete.

## Constraint Rule

Treat human guidance as constraints. Preserve explicit user requirements, named
targets, exclusions, length targets, allowed tools, forbidden tools, data
handling limits, and deliverables.

Treat model-generated guidance as suggestions unless it is required by user
instructions, repo rules, safety, or the deliverable. Use wording such as
`likely`, `consider`, `start by inspecting`, or `choose based on evidence` for
model-inferred tactics. Do not turn guessed files, commands, theories, root
causes, subtasks, or implementation paths into hard requirements.

Use `must` only for real constraints and completion proof. Use `should` or
`consider` for tactics. Avoid goals that say the model must do a long sequence
of speculative steps before it has inspected the system.

## Harness Mechanics

The goal harness keeps the objective alive across turns and pushes the model to
keep making progress. That is useful only when the objective is aligned. If the
goal captures the wrong vision, the harness amplifies the wrong work: more
research, more markdown, more categories, more partial artifacts.

Write goals that tell the model what movement means. Movement is making the
user's requested end state more true. A plan update, report, scaffold, markdown
file, question list, or plausible answer is not progress unless it directly
serves the user's vision and deliverable.

If the user asked for an interview, alignment, approval, or design check, encode
that as a real gate. Do not convert the interview into a hidden proposal. If the
available goal tool permits a blocked state and the same user-only blocker
satisfies the tool's blocked policy, consider marking the goal blocked with the
exact alignment question. If blocked cannot be used yet, ask for alignment and
do not keep generating artifacts to satisfy the loop.

## Goals And ExecPlans

The harness goal and an ExecPlan are complementary.

Use the harness goal as the live steering contract: user vision, current slice,
constraints, review cadence, blocker policy, deliverable, and completion proof.
Use an ExecPlan for durable implementation state: repo orientation, file paths,
milestones, design decisions, validation commands, recovery steps, progress
tracking, or restartability.

Strongly consider an ExecPlan when the work is multi-step, code-changing,
architecture-heavy, high-risk, or likely to continue across turns. Do not
squeeze detailed implementation state into the harness goal. The goal should
reference the ExecPlan path and state what the plan is meant to achieve.

When available, use the ExecPlan skills as part of the workflow:

- `$execplan-create` turns a clear problem statement into a durable
  implementation plan.
- `$execplan-improve` adversarially reviews and strengthens the plan before
  execution, especially for ambiguous, high-risk, or architecture-heavy work.
- `$implement-execplan` executes the plan once the target is clear.
- `$review-recent-work` reviews completed ExecPlan work with fresh eyes and
  fixes bounded issues.

ExecPlans are not a substitute for the goal. The goal keeps the harness aligned;
the ExecPlan gives workers detailed execution memory.

## Continuous Adversarial Review

The first pass is usually not good enough. For non-trivial work, review is
continuous, not a final polish step. The goal should require review before heavy
execution, after each substantial work batch, before handoff, and whenever the
user corrects direction. Use sub-agents for review when that is more
token-efficient or likely to catch drift.

Each review pass should test whether the current plan or output is producing
what the user actually wants, or whether it is drifting into slop, wrong
altitude, overengineering, premature completion, or artifact production.

Treat adversarial review as advisory until verified. A reviewer or sub-agent may
find real issues, but the main agent must check findings against the active user
vision, current slice, repo state, and surrounding source before accepting them.
Reject speculative risks, broad rewrites, out-of-scope objections, and fixes
that over-complicate the work. When useful, ask reviewers to return compact
findings with: `axis`, `severity`, `evidence`, `recommended_fix`, and
`accepted_or_rejected`.

Only findings that affect the active user vision, deliverable, safety boundary,
or completion proof count. Repeat review only while accepted/actionable findings
remain. Once no accepted/actionable findings remain and the completion proof is
current-state evidence, stop; do not run another review only to get nicer
wording or a second clean line.

Review against these engineering preferences:

- As simple as possible, but no simpler.
- Uncle Bob / Clean Code: clear names, readable flow, cohesive units, useful
  tests, and no cleverness for its own sake.
- Ousterhout: deep modules, clean interfaces, hidden sequencing and policy,
  fewer concepts, lower cognitive load, and less change amplification.
- Zen of Python: explicit, simple, flat, readable, sparse, and one obvious path.
- Human-first definitions and ontology: concepts must make sense to a competent
  human, have strict definitions, clear boundaries, and useful cardinality.

Each review pass should remove slop. Delete invented concepts, needless
documents, fake balance, stale facts, unearned recommendations, over-specific
implementation paths, model-shaped taxonomies, vague umbrella categories, and
ceremony that is not required by the user's outcome.

If the same failure axis appears twice, stop incremental patching. Rewrite the
goal, improve the ExecPlan, or mark blocked for alignment where tool policy
allows. Do not mark complete until the delivered thing survives review and the
completion proof is current-state evidence.

## Failure Checks

Before setting or returning the goal, check it against these failure modes:

- Vision loss: starts from the model's task framing instead of the user's actual
  vision.
- Too narrow: over-indexes on one visible issue and loses the larger problem.
- Too specific: dictates files, commands, architecture, or root cause before
  evidence supports them.
- Too vague: says to improve, investigate, or fix without a deliverable or proof.
- Too early-complete: lets planning, scaffolding, a report, or a partial smoke
  count as completion when the requested end state is still unproven.
- Alignment bypass: keeps driving after the user asked for an interview,
  approval, or design check.
- Artifact slop: creates reports, markdown files, dashboards, categories, or
  question lists because they look like progress, not because the user needs
  them.
- Too handwavy: invents ontology, abstractions, categories, dashboards, or
  process language instead of grounding the slice in current evidence.
- Too defensive: adds fallbacks, compatibility layers, modes, scripts, or
  ceremony not justified by the current task.
- Wrong domain: frames a research, legal, personal, browser, or data task as a
  normal code patch when the deliverable is a decision, runbook, extraction, or
  verified finding.
- Weak review loop: treats review as final prose polish instead of repeatedly
  applying code review, architecture review, slop review, complexity review, and
  human-first definition review throughout the work.
- Convergence failure: keeps patching after the user corrects the same axis
  twice instead of reframing the goal, improving the ExecPlan, or blocking for
  alignment.

## Code And Developer Work

For code and infra tasks, make the deliverable a working, verified state:
`working service`, `green CI`, `merged PR-ready patch`, `validated Nix build`,
`applied configuration`, or `reproducible failing/passing proof`.

Name the repo or system only when known. State the architectural direction
without freezing implementation details. Include negative scope when it prevents
common drift, such as no product code during research, no private data in git,
no broad refactor, no speculative fallback, or no UI claim without screenshot
verification.

Completion proof should mention concrete evidence categories: tests, builds,
diff review, runtime smoke, CI status, logs, browser screenshot, applied state,
or exact blocker. Do not allow the model to mark complete just because it wrote
a plan, diagnosed one symptom, or made a plausible patch.

## Non-Code Work

For non-code work, default to outcomes and decisions, not documents. A document
is only a vehicle when the user asked for it or when it is necessary to make the
outcome usable. Do not turn "research this", "brief me", "help me decide", or
"align with me" into "write a lot of markdown" unless the user explicitly wants
that.

Use domain-specific proof:

- Research or architecture: deliver a decision-grade brief, tradeoff analysis,
  implementation recommendation, or alignment question grounded in evidence;
  distinguish verified facts from inference; say what would change the
  recommendation.
- Decision work: deliver current truth, recommendation, evidence, tradeoff,
  risk, confidence, and the next check only when it would change the decision.
- Browser reconnaissance or data extraction: deliver source inventory, export
  shapes, representative artifacts, repeatable next proof, private-data storage
  boundary, and irreversible-action limits.
- Legal, personal, or sensitive briefing: deliver a concise user-facing answer
  or decision aid, source hygiene, exact misses, and no invented claims.
- Ops or CI repair: deliver current desired state, repair loop, verification on
  the live target, and exact external blocker if blocked.
- Creative or document work: deliver the actual artifact, render/export proof
  when applicable, and any constraints on tone, format, or audience.

## Template

Use this as a mental template, not literal boilerplate:

```text
User vision: [what the user is really trying to make true].

North star: [larger outcome].

This session's slice is [owned work now], not [nearby drift]. Current evidence:
[known state, prior work, failures, uncertainty]. Human constraints are [hard
constraints]. The model should choose tactics from live evidence; likely areas
to inspect include [suggestions], but do not treat those as the only path.

Deliverable: [working state, decision, outcome, or explicitly requested
artifact]. If detailed implementation state is needed, create or reference an
ExecPlan at [path] and keep the goal focused on live steering. Before heavy
execution, after substantial work batches, and before handoff, review against the
user vision, evidence, Clean Code, Ousterhout, the Zen of Python, simplicity, and
human-first definitions; use sub-agents where useful. Completion requires
[proof], and the goal must stay active or be marked blocked when tool policy
allows until that proof exists or the exact external blocker is established.
```
