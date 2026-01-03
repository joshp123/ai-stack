---
name: rfc-adr-authoring
description: Create or revise RFCs and ADRs using Lawbot-Hub templates and strong in-repo examples. Use when drafting, reviewing, or tightening RFC/ADR documents, or when assessing RFC/ADR quality.
---

# RFC + ADR Authoring

## Goal

Produce clear, decision-grade RFCs/ADRs that are scoped, testable, and aligned with existing templates and best examples. Avoid ambiguous work by invoking the questioning workflow when requirements are underspecified.

## Always start here

If the request to write or revise an RFC/ADR is underspecified, **invoke** the `ask-questions-if-underspecified` skill before drafting. Do not proceed until must-have questions are answered or the user explicitly approves assumptions.

## Templates (authoritative)

- RFC template: `docs/rfc/RFC_TEMPLATE.md` (from your repo)
- ADR template: `docs/architecture/adr-template.md` (from your repo)
- Opinionated RFC template (use when you need stricter structure): `references/templates/RFC_TEMPLATE.md`
- Opinionated ADR template (use when you need stricter structure): `references/templates/ADR_TEMPLATE.md`

## Workflow

1) **Clarify first (if needed)**
   - If objectives, scope, acceptance criteria, constraints, or risks are unclear, invoke `ask-questions-if-underspecified`.

2) **Select the right template**
   - RFCs: use the Lawbot-Hub RFC template sections and numbering.
   - ADRs: use the ADR template (Context → Decision → Consequences + alternatives).

3) **Draft with explicit decision boundaries**
   - Define objectives and non-goals clearly.
   - Make decisions explicit and testable.
   - Tie to concrete workflows, inputs, and outputs.
   - Include risks, tradeoffs, and rollout/rollback where relevant.

4) **Quality pass (required)**
   - Run the appropriate checklist below.
   - Cross-check against good examples and avoid the bad patterns.
   - Perform a brutal self-review (see below) and iterate until no major gaps remain.

## RFC Quality Checklist (must pass)

- Clear narrative and user problem statement
- Non-negotiables spelled out
- Goals and non-goals separated
- System overview + responsibilities
- Inputs/outputs defined and validated
- State machine and API surface (if applicable)
- Interaction model and concrete workflows
- Determinism + validation rules
- Delivery plan and implementation order
- Testing philosophy and trust gates

## Known Weaknesses (must explicitly mitigate)

These are recurring failure modes. Call them out and fix them in every RFC/ADR:
- **UI-facing RFCs are still weak**: Agents often reach ~80–85% and need follow-up prompts for UI work. Be explicit about UI semantics, flows, states, and visual expectations.
- **Foreseeable fidelity gaps**: RFCs miss obvious requirements (e.g., Tado metrics in a gohome RFC). Enumerate must-have fidelity details.
- **Testing pyramid under-specified**: Require progressive validation (API → CLI → UI). UI testing must include `dev-browser` screenshots, detailed visual QA, and iterative fixes tied to user intent.

## ADR Quality Checklist (must pass)

- Context explains why this decision matters now
- Decision is explicit and unambiguous
- Alternatives considered (with rejections)
- Consequences and follow-ups stated
- References to relevant modules/docs

## Example Library (use as patterns)

Good RFCs (best-in-class):
- `references/examples/good/rfc/2025-12-29-orchestrator-spec.md`
  - Strong narrative anchor, explicit non-negotiables, and a full state machine with formal artifacts.
- `references/examples/good/rfc/2025-12-30-orchestrator-tool-requests.md`
  - Clear UX contract + tool policy; defines model guardrails and deterministic rules.
- `references/examples/good/rfc/2025-12-30-vault-events-pipeline.md`
  - Precise scope boundaries, explicit inputs, and rigorous validation rules.
- `references/examples/good/rfc/2026-01-01-hub-cleanup-unified-ops-ui.md`
  - Crisp goals/non-goals, operational focus, and concrete UI semantics.
- `references/examples/good/rfc/2025-11-22-homelab-vision.md`
  - Strong problem framing, explicit goals/non-goals, and clear architecture.

Good ADRs (best-in-class):
- `references/examples/good/adr/2025-12-29-orchestrator-kernel.md`
  - Decision is explicit and tied to clear constraints and workflow profiles.
- `references/examples/good/adr/2025-12-30-text-extraction-pipeline.md`
  - Concise, crisp decision with clear alternatives and consequences.
- `references/examples/good/adr/adr-0001-overlay-packaging.md`
  - Strong context, explicit decision rules, and consequences.
- `references/examples/good/adr/adr-0002-core-and-stacks.md`
  - Clear structure and rationale; includes consequences and follow-ups.
- `references/examples/good/adr/adr-004-homelab-build-harness.md`
  - Thorough decision framing plus deferred decisions spelled out.

Bad examples (avoid these patterns):
- RFC: `references/examples/bad/rfc/2025-11-23-homeassistant-credentials.md`
  - Underspecified and includes unresolved questions/TODOs inline (e.g., “@Claude …”), missing non-goals and acceptance criteria, and no clear decision boundary.
- ADR: `references/examples/bad/adr/adr-002-homelab-remote-ha-draft.md`
  - No final decision, only open questions; lacks alternatives, consequences, and clear scope/acceptance criteria.

## Example Review Notes

Read these to understand why “good” RFCs are still imperfect:
- `references/reviews/good-rfcs-weaknesses.md`

## Brutal Self-Review (mandatory, iterate until satisfied)

Run a critical review pass and revise the RFC/ADR until it reads cleanly to all personas:
- junior engineer (clarity + missing steps)
- mid-level engineer (implementation detail + scope)
- senior/principal engineer (architecture + tradeoffs)
- PM (user impact + success criteria)
- EM (risk + delivery plan)
- external stakeholder (jargon + context)
- end user (workflow clarity + trust)

If any persona would still be confused or blocked, revise and repeat before finalizing.
