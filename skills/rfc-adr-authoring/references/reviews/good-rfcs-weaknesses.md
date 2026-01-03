# Good RFCs: Strengths + Known Weaknesses (No RFC is Perfect)

Use these as best-in-class examples while acknowledging they still miss key things.

## Cross-cutting unresolved weaknesses (must be called out)

1) **UI-facing RFCs are still weak**
   - Agents can reach ~80–85% on technical refactors, but UI work requires multiple follow-ups.
   - Even the “good” RFCs here do not solve the UI clarity problem end-to-end.

2) **Foreseeable fidelity gaps**
   - Example: a gohome RFC shipped a solid scaffold but omitted expected metrics for the Tado integration.
   - This is a predictable miss: RFCs often fail to enumerate “must-have” product fidelity details.

3) **Testing pyramid is under-specified**
   - RFCs rarely enforce a progressive testing sequence: API → CLI → UI.
   - UI validation must use `dev-browser` with full screenshots, detailed visual QA, and iterative fixes tied to user intent.

## Per-RFC improvement notes

### 2025-12-29-orchestrator-spec.md
- Missing explicit incremental delivery plan + implementation order.
- Testing/trust gates are implied but not spelled out.

### 2025-12-30-orchestrator-tool-requests.md
- Lacks explicit system interaction diagram + API call flow.
- Status says “needs revision” but no concrete “what remains” checklist.

### 2025-12-30-vault-events-pipeline.md
- Missing explicit incremental delivery plan + implementation order.
- Testing philosophy is implicit; should be codified.

### 2026-01-01-hub-cleanup-unified-ops-ui.md
- “Not applicable” sections (state machine/API flow) should still be explicit.
- Ops/UI testing plan needs concrete steps and verifiable outcomes.

### 2025-11-22-homelab-vision.md
- Strong vision, but lacks inputs/outputs, implementation order, and testing gates.
