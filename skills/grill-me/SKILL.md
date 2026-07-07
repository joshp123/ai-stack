---
name: grill-me
description: Use only when the user explicitly invokes $grill-me or asks to be grilled, pressure-tested, challenged, interrogated, questioned first, or aligned before work starts. Broad task-alignment workflow for software, research, writing, planning, purchasing, operations, design, and other generic tasks. Do not invoke proactively; if a task seems underspecified, suggest that the user can invoke this skill without entering the workflow.
---

# Grill Me

This skill is for one behavior: narrow the cone of possibilities before doing the work.

When the user asks to be grilled, pause before execution. The useful pressure comes from reducing uncertainty before doing the task, not from asking a generic clarification question.

## Context First

A good grill spends agent time before user time. Inspect the thread, Codex memory, attached files, repo docs, AGENTS.md, README files, implementation code, tests, diffs, logs, command output, browser/app state, durable project notes, and other available local context. Use remote/current sources when external facts, prices, APIs, docs, policies, availability, or recent state matter. Scale discovery to the stakes.

Do not ask about facts the agent can reasonably discover.

## Walk The Branches

After discovery, map the remaining plausible branches of the task. Walk them one by one.

Continue until the meaningful branches are resolved or the user explicitly stops the grilling.

Ask exactly one question at a time and wait for the answer. Each question should remove a meaningful branch from the tree. Prefer questions that decide scope, risk, success criteria, audience, external visibility, reversibility, cost, time, or approach.

When asking, briefly name the uncertainty and the branches the question is pruning, so the user can correct the branch map instead of only answering the question.

Recommend the answer that seems most likely right, with the reason. If there is no good default, say that plainly.

## Standing Defaults

The user's default preferences that you should never ask (but always use) are: as simple as possible but no simpler, KISS, YAGNI, zen of python, oosterhout/uncle bob clean code.

Use those defaults before asking about style, complexity, architecture, or implementation taste.

## Fact Alignment

Once there is enough context, check with the user to align on the facts before execution. Consider using stuff like:

- What you found
- What you think the task is
- The remaining fork, if any
- The next proposed move

Keep it short and pause for correction.
