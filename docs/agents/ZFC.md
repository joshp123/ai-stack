# ZFC

- Read this memo any time you build AI-enabled tools or when the user mentions ZFC.

## Zero Framework Cognition (ZFC)

When building AI-enabled tools or orchestrating AI workers, follow ZFC principles. Full details: `docs/reference/zfc-zero-framework-cognition.md`

**Core principle**: Build a "thin, safe, deterministic shell" around AI reasoning. Delegate ALL cognitive decisions to AI models—never implement local heuristics. Use `pi` libraries for this thinking layer.

### ZFC-Compliant (Do This)
- **IO/Plumbing**: File ops, JSON parsing, persistence, event watching
- **Structural safety**: Schema validation, path traversal prevention, timeouts
- **Policy enforcement**: Budget caps, rate limits, approval gates
- **Mechanical transforms**: Parameter substitution, formatting AI output
- **State management**: Lifecycle tracking, progress monitoring

### ZFC-Violations (Never Do This)
- **Ranking/scoring** with heuristics or weights
- **Keyword-based routing** (e.g., looking for "done", "complete", "finished")
- **Semantic analysis** (inferring complexity, "what to do next")
- **Fallback decision trees** or domain-specific rules
- **Quality judgment** beyond structural validation
