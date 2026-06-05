---
name: session-goal-writer
description: Write durable Codex session goals. Use when the user asks to write, improve, set, update, or replace a session goal; says the current session goal is too vague, too narrow, too specific, or slop; asks for a long-running/autonomous objective to be framed as a goal; or asks Codex to encode vision, north star, current slice, success criteria, deliverable, CTO briefing, alignment needs, review loop, and completion proof into a session goal. Do not use for ordinary planning, CTO briefs, reviews, or research unless the user asks to create or revise a session goal.
metadata:
  written_by: ai
---

# Session Goal Writer

Use this skill to write goals for the session goal tool or for a user-visible
replacement objective. A good session goal is a user-intent contract. It
preserves the user's vision first, then gives the next model enough context to
operate without turning guesses into orders, optimizing the wrong proxy, or
producing output-shaped slop.

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
research, measurement, proof, audience, or output shape, do not guess. Inspect
available context first, then run the alignment needed to make the goal correct.
Do not cap alignment to a token-saving number of questions when the work needs a
proper calibration pass. Batch questions coherently around the north star,
current slice, unacceptable drift, success criteria, environment, output shape,
review standard, and completion proof.

User-requested interview or alignment takes precedence over prior model
feedback, harness pressure, and generic goal progress. If the real task is to
define the goal with the user, make that the current slice. If the real work can
start only after alignment, encode alignment as a gate and do not generate
artifacts to satisfy goal progress.

## Goal Shape

Write the goal at the length needed to preserve user intent, not at a fixed
length target. The default bias is to keep more intent, not less. Prefer a
longer goal over an underspecified goal when extra detail preserves the user's
vision, north star, taste, current slice, unacceptable drift, success semantics,
deliverable, review loop, or completion proof. A short goal is bad when it makes
later models infer the intent from stale context, generic heuristics, or the
shape of an artifact.

For simple tasks, use 60-150 words only when that is enough to preserve the
intent. For substantial code, infra, browser, research, briefing, or autonomous
work, use a rich goal. The goal text is both the live steering contract and the
completion contract. Do not strip the user's intent to make the goal look like a
checklist.

A goal is too long only when it is padded with tactical bookkeeping that does
not change steering: speculative commands, guessed file lists, step-by-step
implementation scripts, logs, progress diary detail, or restart state. A goal is
not too long merely because it includes the user's intent, taste, north star,
review standards, unacceptable drift, examples of bad proxies, or proof
semantics. Trim tactical junk, not vision.

Do not use or change the harness token budget unless the user explicitly
instructs Codex to set a token budget. Token budget and goal text length are
different controls. The token budget is not a solution to a long goal.

Do not write an oversized goal and then compress it. Write at the right altitude
from the start. If the work needs more detail than fits in the goal field, keep
the intent in the harness goal and move execution memory to the right artifact:
implementation state to an ExecPlan, architecture rationale to an RFC or ADR,
and executive synthesis to a CTO briefing.

Include these elements, in this order:

1. User vision: what the user ultimately wants, in their terms.
2. North star: the larger end state or product/user outcome.
3. Current slice: what this session owns now.
4. Current state: important evidence, known failures, prior work, or uncertainty.
5. Unacceptable drift: nearby work, proxies, artifacts, or abstractions that
   would look productive but miss the user's intent.
6. Constraints: user instructions, repo rules, safety limits, privacy limits,
   live-session limits, and external blockers.
7. Degrees of freedom: areas where the model may choose tactics after inspecting
   evidence.
8. Success criteria: how success will be recognized from the user's intent,
   including measurable targets, qualitative review bars, or the alignment work
   needed to define them.
9. Deliverable: the concrete outcome, decision, artifact, or working state to
   hand back.
10. CTO briefing: when the work is substantial, whether to maintain a temporary
    CTO brief and the high-level synthesis the user should get at the end.
11. Review proof: the review cadence, review contract, and proof standard.
12. Completion proof: what must be verified before calling the goal complete.

Use enough detail for each element to prevent predictable drift:

- User vision should say what the user is trying to make true, not just the
  immediate command.
- North star should explain the larger outcome or operating model the current
  slice supports.
- Current slice should define what this session owns and what it explicitly does
  not own.
- Current state should include live evidence, known failures, user corrections,
  and uncertainty that would change tactics.
- Unacceptable drift should name bad proxies, artifact churn, overreach,
  underreach, and model-shaped abstractions likely for this task.
- Success criteria should identify the evaluation method, stop condition, and
  what would count as a superficially successful but actually wrong result.
- Review proof should name the review lenses, when they run, how findings are
  accepted or rejected, and when review is done.
- Completion proof should require current-state evidence or an exact blocker,
  not a plausible story that the work is probably done.

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

## Alignment Before Setting

Do not set a durable goal when the durable goal would encode unresolved
ambiguity. First inspect available context, then decide whether to set the goal,
ask for alignment, or make alignment itself the goal.

Set the goal immediately when the user's intent, slice, deliverable, proof, and
review bar are clear enough that more questions would not change the work.

Ask for alignment before setting the execution goal when any of these would
change the work:

- the north star or current slice is ambiguous;
- the user may want a decision, artifact, working state, briefing, or interview;
- success could be measured by several incompatible proxies;
- the audience or taste bar matters;
- the acceptable tradeoff is unknown;
- the environment needed for proof is unavailable;
- the goal might cause broad autonomous work in the wrong direction.

Run alignment as a real protocol:

1. Inspect first: read the user's latest corrections, repo guidance, existing
   plans, active artifacts, and obvious source context before asking.
2. Identify material unknowns: ask only about choices that would change the
   goal, proof, review standard, artifact boundary, or environment.
3. Batch coherently: group questions around north star, current slice,
   unacceptable drift, success criteria, output audience, environment gaps,
   review protocol, and completion proof. Do not force the batch into an
   artificial one-to-three-question cap if that would leave the goal wrong.
   If the active structured input tool caps question count, ask in a normal
   message or staged batches instead of violating the tool schema.
4. Restate the contract: before setting a broad goal, summarize the intended
   goal shape and the bad proxies it must reject.
5. Gate execution: if alignment is the work, set a narrow alignment goal or ask
   for alignment and wait; do not generate implementation artifacts to look
   productive.

If the user explicitly wants help shaping the goal, set a narrow goal whose
deliverable is the aligned goal itself. That goal should complete only when the
user's intent, success criteria, artifact boundaries, and proof standard are
clear enough to start the real work.

## Success From Intent

Define success from the user's intent, not from the easiest metric to measure.
For code and infra, success may be numeric or mechanical: faster builds, green
CI, stricter types, runtime smoke, deploy preview, screenshot diff, or applied
state. For research, strategy, prose, planning, and briefings, success is often
qualitative but still reviewable: a decision-grade answer, verified finding,
usable recommendation, aligned tradeoff, human-facing prose, or no accepted
adversarial findings remaining.

When success criteria are not obvious, the current slice should be to define
them with the user before executing the larger task. Ask what proof would
actually convince the user, what proxy would be misleading, what tradeoffs are
acceptable, what taste or audience bar matters, and what a bad but superficially
successful result would look like.

Use measurement creatively. The right abstraction is an evaluation protocol, not
always a number. For subjective work, a council-style review pass can be the
measurement instrument: ask reviewers to evaluate the output as a principal
engineer, CTO, skeptical maintainer, anti-slop editor, source-discipline
reviewer, naming reviewer, or user-taste reviewer. The main agent must accept
or reject findings against the active goal, explain the rejection when it
matters, revise accepted issues, and repeat only until no accepted severe
findings remain.

Guard against proxy gaming. Do not let the model satisfy a UI goal by embedding
an image, a test goal by deleting coverage, a research goal by producing a long
report, a prose goal by polishing vague claims, or an architecture goal by
creating documents instead of resolving the user's decision.

Write success criteria as an evaluation protocol, not just a slogan. Include:

1. Outcome: what state, decision, answer, or artifact should be true.
2. Evaluator: command, test, source, reviewer role, user approval, or live
   system that can judge it.
3. Evidence: the proof artifact or observation needed.
4. Anti-gaming: the proxy failure the model must not use to call success.
5. Stop condition: what allows the agent to mark complete.
6. Blocker condition: what unresolved external state should stop the loop.

For subjective work, prefer named review lenses over vague quality language.
Examples: "principal engineer review finds no accepted design-simplicity
issues", "anti-slop prose review finds no model-shaped taxonomy or caveat
padding", "source-discipline review finds every risky claim verified or marked
as inference", or "CTO review says the brief explains current truth, how, why,
tradeoffs, risk, and next decision without implementation minutiae."

Do not mistake subjectivity for unmeasurability. Prose, strategy, research, and
planning goals can be measured by whether a chosen expert lens can still find a
severe accepted defect: unclear audience, invented taxonomy, ungrounded claim,
wrong altitude, non-human phrasing, unhelpful tradeoff, missing decision, stale
source, or output that ignores the user's taste. Completion can be "no accepted
severe findings remain after the specified review lenses", not a numeric score.

## Goals, Plans, RFCs, And Briefs

The harness goal, ExecPlan, RFC or ADR, and CTO briefing have different jobs.

Use the harness goal as the live steering contract: user vision, north star,
current slice, unacceptable drift, constraints, success semantics, review
cadence, blocker policy, deliverable, and completion proof. User intent belongs
in the goal even when other artifacts exist.

Use an ExecPlan for durable implementation state: repo orientation, file paths,
milestones, validation commands, recovery steps, progress tracking, rich
implementation notes, or restartability. Use an RFC or ADR for architecture
rationale, options, tradeoffs, and decisions that should survive beyond the
session.

Strongly consider an ExecPlan when the work is multi-step, code-changing,
architecture-heavy, high-risk, or likely to continue across turns. Do not
squeeze detailed implementation state into the harness goal. Do not move user
intent out of the harness goal just because an ExecPlan exists.

Use both an ExecPlan and an RFC or ADR when the work needs executable
restartability and a durable architecture decision. The ExecPlan should carry
current implementation state; the RFC or ADR should carry the rationale that
future maintainers need after the session ends.

Use this boundary:

- Goal: intent, north star, current slice, unacceptable drift, success
  semantics, review standard, completion proof.
- ExecPlan: implementation memory, concrete steps, files, commands, validation
  sequence, restart state, current tactical progress.
- RFC/ADR: architecture problem, options, decision, rationale, rejected
  alternatives, durable tradeoffs.
- CTO briefing: executive synthesis of the result, not the work log.

For substantial work, make a CTO briefing a deliberate output shape and keep it
updated as the work converges. A CTO brief is not an evidence dump, tool log,
quote wall, decision log, or implementation diary. It should tell a technical
executive:

1. Current truth: what is now true, with confidence and important caveats.
2. How it works: the operating model at the right abstraction level.
3. Why it matters: what user, product, maintainer, system, or strategic problem
   this changes.
4. Tradeoffs: what was chosen, what was rejected, and why.
5. Risk or blocker: what could still break, what depends on external state, and
   what requires a decision.
6. Next action: the decision, follow-up, PR, rollout, or alignment needed.

Omit routine activity, raw command output, source inventories, implementation
minutiae, self-justifying evidence walls, and the user's own questions unless
they matter to a decision. If detailed evidence or decision history is useful,
put it in the ExecPlan, appendix, or source-grounded notes, not the CTO brief.

## Temporary CTO Briefing

For substantial goals, maintain a temporary CTO briefing artifact while work is
active when it will improve continuity, synthesis, or handoff. This is most
useful for multi-turn work, broad research, architecture decisions, PR strategy,
incident repair, environment/proof work, or anything with tradeoffs that would
be painful to reconstruct at the end. Do not create one for simple tasks only to
look productive.

Use the repo's existing agent scratch area when available; otherwise use a
clearly named temporary local note, or keep the brief thread-local when
filesystem writes are inappropriate. The goal should say whether the temporary
brief is required and, if written to disk, where it lives.

Update the temporary CTO brief after major findings, review passes, decisions,
blockers, tradeoff changes, and proof milestones. Keep it CTO-shaped throughout:
current truth, how it works, why it matters, tradeoffs, risk or blocker, and
next action. Do not let it become a command log, evidence wall, source map,
implementation diary, or decision-log dump. Those details belong in an
ExecPlan, appendix, or source-grounded notes.

At handoff, either deliver it as the final CTO brief, convert its synthesis into
the final answer, or remove/ignore it as temporary scratch. If a temporary brief
was written to disk, report its path and final disposition.

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

## Environment And Proof

Start from the proof that would actually establish success, then shape the
environment to make that proof possible. Do not lower the proof bar to whatever
the current shell can already check.

Before setting a long-running goal, identify whether proof requires auth,
network access, browser or Chrome state, CI, deploy previews, production-like
data, logs, a database snapshot, a physical device, screenshots, visual diffs,
an eval suite, source corpus access, or reviewer sub-agents. Name the proof
that would convince a skeptical operator before naming the local proxy.

If the environment is missing, encode the gap explicitly:

- repair first: make browser auth, CI wiring, eval fixtures, source access,
  local services, or preview deploys the first milestone;
- align first: ask the user whether the weaker proxy is acceptable;
- block exactly: when tool policy allows, mark blocked on the missing proof,
  not on a vague inability to continue.

Do not call the larger goal complete on a weaker local proxy unless the user
accepted that proxy and the goal records the compromise.

## Continuous Adversarial Review

The first pass is usually not good enough. For non-trivial work, review is a
measurement engine, not a final polish step. The goal should require review
before heavy execution, after each substantial work batch, before handoff, and
whenever the user corrects direction. Use sub-agents for review when that is
more token-efficient or likely to catch drift.

For broad session-history mining, multi-repo search, independent review lenses,
or subjective council-style evaluation, prefer bounded sub-agents when available
instead of one serial main-thread pass. Give each sub-agent a distinct question,
the active goal, relevant evidence, and a compact output schema; reconcile their
findings in the main thread.

Each review pass should test whether the current plan or output is producing
what the user actually wants, or whether it is drifting into slop, wrong
altitude, overengineering, premature completion, artifact production, or a bad
success proxy.

Run review concretely:

1. Select lenses from the task: code, architecture, naming, source discipline,
   CTO usefulness, anti-slop prose, user taste, security, product behavior, or
   domain-specific gates.
2. Give reviewers the active goal, current artifact or diff, relevant standards,
   and exact success criteria. Do not leak the intended fix unless testing it.
3. Ask for compact findings with `axis`, `severity`, `evidence`,
   and `recommended_fix`.
4. Reconcile in the main thread: accept only findings that affect the user
   vision, deliverable, safety boundary, or completion proof.
5. Apply accepted findings or update the goal/ExecPlan/RFC/brief when the
   finding proves the contract is wrong.

Treat adversarial review as advisory until verified. A reviewer or sub-agent may
find real issues, but the main agent must check findings against the active user
vision, current slice, repo state, and surrounding source before accepting them.
Reject speculative risks, broad rewrites, out-of-scope objections, and fixes
that over-complicate the work.

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
- Naming: names should expose the real domain concept, not model-invented
  abstractions, umbrella terms, or vague process language.
- Human-facing prose: concise, direct, source-grounded, and free of AI-shaped
  caveats, fake balance, and committee language.

Each review pass should remove slop. Delete invented concepts, needless
documents, fake balance, stale facts, unearned recommendations, over-specific
implementation paths, model-shaped taxonomies, vague umbrella categories, and
ceremony that is not required by the user's outcome.

## Correction And Convergence

Internal review and user correction have different thresholds.

For internal review findings, if the same failure axis appears twice, stop
incremental patching. Rewrite the goal, improve the ExecPlan, revise the RFC,
repair the CTO brief shape, change the proof environment, or mark blocked for
alignment where tool policy allows.

For explicit user correction that says the work is wrong, slop, worthless, too
narrow, too vague, too constrained, not what was asked for, or optimized for the
wrong proxy, one correction is enough. Stop, restate the correction, explain
what contract changed, update the goal or execution artifact, then continue from
the corrected intent. If the corrected intent is still ambiguous, make alignment
the next slice or block/ask before continuing execution. Do not keep working
under the old goal and do not mark complete until the delivered thing survives
review and the completion proof is current-state evidence.

## Failure Checks

Before setting or returning the goal, check it against these failure modes:

- Vision loss: starts from the model's framing instead of the user's vision.
- Too narrow: over-indexes on one visible issue and loses the larger problem.
- Too specific: dictates files, commands, architecture, or root cause before
  evidence supports them.
- Too vague: says to improve, investigate, or fix without a deliverable or proof.
- Bad proxy: makes an easy metric the target even though it does not prove the
  user's outcome.
- Too early-complete: lets planning, scaffolding, a report, or a partial smoke
  count as completion while the requested state is unproven.
- Alignment bypass: keeps driving after the user asked for an interview,
  approval, or design check.
- Artifact slop: creates reports, markdown files, dashboards, categories, or
  question lists because they look like progress, not because they are needed.
- Handwavy ontology: invents abstractions, categories, dashboards, or process
  language instead of grounding the slice in current evidence.
- Defensive ceremony: adds fallbacks, compatibility layers, modes, scripts, or
  ceremony not justified by the task.
- Wrong domain or artifact: treats decision, briefing, research, browser, data,
  or legal work as a code patch; puts implementation state in the goal,
  architecture rationale in an ExecPlan, or executive synthesis in a log.
- Weak review loop: treats review as final prose polish instead of repeated
  code, architecture, slop, complexity, naming, and definition review.
- Convergence failure: keeps patching after one explicit user correction or two
  internal findings on the same axis instead of reframing or blocking.

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

When the user wants a PR, make the goal require pre-PR review before opening or
updating the PR. The review should run against the same standards that will
judge the remote PR when those standards are known, so the work converges before
external review instead of cycling through predictable review failures.

## OpenClaw PR Review Loop

For OpenClaw ecosystem PR work, make ClawSweeper the domain-specific
adversarial review standard before opening or updating a PR. ClawSweeper changes
often, so do not rely on memory. Refresh or inspect the latest local criteria at
the start of the PR slice. If the run is allowed to mutate that checkout, fetch
or pull first; if the run is read-only, inspect the current local snapshot and
state any staleness risk. Prefer `$CLAWSWEEPER_CHECKOUT` when set; otherwise
discover the local checkout or use the upstream/supplied criteria. Read
`prompts/review-item.md`, `schema/clawsweeper-decision.schema.json`,
`instructions/merge-policy.md`, `instructions/security-boundary.md`, and any
relevant repair prompts or repository profiles.

Encode ClawSweeper-style gates in the goal's success criteria: target
`AGENTS.md` fully read, applied, and statused; intended diff checked against
current `main`; P0/P1/P2-style findings resolved; dedicated security and
supply-chain pass cleared or routed; real after-fix behavior proof supplied for
external or non-docs PRs; merge-risk categories called out; target-repo scope
proven; likely owners identified from public git or PR history when useful; and
upgrade, default, migration, provider, or API safety proven when those surfaces
change.

Before calling an OpenClaw PR merge-ready, require a merge preflight: human and
bot review comments addressed; Codex `/review` clean when available; branch
refreshed against current base; checks accepted; no conflicts; focused diff; no
unrelated generated or lockfile churn; and existing author credit preserved.

Security-sensitive evidence is not ordinary PR cleanup. Boundary bypasses,
credentials, advisories, exploitability findings, or sensitive-data evidence
must route to maintainer security handling with minimal public detail. Do not
continue ordinary PR work as merge-ready while that security route is open.

External non-docs PRs need real after-fix behavior proof or an explicit
maintainer/user override. Tests, mocks, and CI are supplemental when the risk is
real runtime behavior. Browser, network, security, or provider proof should
include useful diagnostics and must redact private data such as keys, private
endpoints, phone numbers, and addresses.

Use the repository profile to prove the target repo is the right home. Optional
integrations, bundled skills, providers, channels, and plugin work should route
to the appropriate hub, plugin, or provider repo unless the PR proves a missing
core surface or has maintainer alignment.

For owner/provenance routing, trace current-main history and public PR history
where useful. Use handles or display names only, never emails, and do not treat
the PR author as the likely owner unless current-main history supports it.

If a ClawSweeper gate would be missing, insufficient, needs attention, patch
incorrect, or unresolved merge risk, the next slice is to fix the branch or get
maintainer alignment, not to open or update the PR as merge-ready. After a PR
exists, use the public ClawSweeper review as the live adversarial loop. The goal
stays active until accepted blocking findings are cleared, intentionally
deferred with maintainer approval, or reduced to an exact maintainer-only
blocker.

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
- CTO briefing: deliver current truth, how the system or proposal works, why it
  matters, important tradeoffs, risks or blockers, what changed, and the next
  decision or action. Omit routine activity, raw evidence, command logs,
  implementation minutiae, and the user's own questions unless they matter to a
  decision.
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
constraints]. Unacceptable drift is [bad proxy/artifact/overreach]. The model
should choose tactics from live evidence; likely areas to inspect include
[suggestions], but do not treat those as the only path.

Success means [criteria derived from intent]: outcome [state], evaluator
[command/source/reviewer/user], evidence [proof], anti-gaming [bad proxy], stop
condition [complete], and blocker condition [external blocker]. If criteria are
not yet known, the first milestone is to define them with the user. Proof
environment: [required access/state], [missing gap], and [accepted weaker proxy
if any]. Deliverable: [working state, decision, outcome, CTO briefing, or
requested artifact]. Temporary CTO brief: [required or not], [path or
thread-local], and [update cadence]. Keep implementation state in an ExecPlan;
keep architecture rationale in an RFC/ADR; keep the CTO brief focused on current
truth, how, why, tradeoffs, risk, and next action. Review before heavy
execution, after substantial batches, and before handoff against the user
vision, evidence, proxy validity, Clean Code, Ousterhout, Zen of Python,
simplicity, naming, anti-slop prose, and human-first definitions; use sub-agents
where useful. Completion requires [proof], and the goal must stay active or
blocked until that proof exists or the exact external blocker is established.
```
