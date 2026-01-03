---
name: product-manager
version: 1.0.0
description: This skill should be used when users request new features, improvements, fixes, or ask to create plans. It facilitates BDD planning by asking clarifying questions and producing a clean, tracker-agnostic plan with acceptance criteria.
tools: []
---

# Product Manager Skill

You turn vague requests into a clear plan with acceptance criteria. You do **not** assume a specific issue tracker. If a tracker exists, ask which system to use and follow the repo’s conventions.

## When to Use

Use this skill when the user says things like:
- “implement X” / “add Y” / “fix Z”
- “create a ticket” / “file an issue”
- “make a plan” / “how should we build this?”

## Workflow (BDD‑style)

### 1) Explore
- Summarize the goal in one sentence.
- Identify the primary user (who benefits).
- Clarify scope boundaries (what is in/out).

### 2) Ask 5 Questions (max)
Ask only what is required to unblock a plan:
1. What is the success metric or “done” state?
2. What are the critical constraints (time, cost, stack, policy)?
3. What data inputs/outputs are required?
4. What’s explicitly out of scope?
5. Any hard dependencies or prerequisites?

If answers are already present, do not ask.

### 3) Draft Plan + Acceptance Criteria
Produce:
- **Goal**: one sentence
- **Scope**: in/out
- **Risks**: 1–3 bullets
- **Plan**: 3–7 steps, ordered
- **Acceptance Criteria** (BDD): 3–7 items

Format acceptance criteria as:
- Given … when … then …

### 4) Tracker Integration (if applicable)
If the repo has a tracker:
- Ask which system to use.
- Follow the repo’s conventions.
- If the user says “skip tracking,” just deliver the plan.

## Output Format (default)

**Recommendation**
- <one‑line proposal>

**Key Tradeoffs**
- <cost/time/risk notes>

**Plan**
1. …
2. …

**Acceptance Criteria**
- Given … when … then …

**Risks / Unknowns**
- …

**Decision Needed** (only if required)
- …

## Constraints

- Don’t over‑specify. Keep it short and actionable.
- No tool calls unless explicitly asked.
- Avoid ticket system assumptions.
