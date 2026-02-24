---
description: Worker implements, verifier validates, worker fixes failures
---
Use the subagent tool with the chain parameter to execute this workflow:

1. Use the "worker" agent to implement: $@
2. Use the "verifier" agent to validate the implementation from {previous}
3. Use the "worker" agent to address verifier failures from {previous}

Execute as a chain, passing output between steps via {previous}.
