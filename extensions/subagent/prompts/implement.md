---
description: Implementation workflow — scout maps code, worker implements, verifier validates
---
Use the subagent tool with the chain parameter to execute this workflow:

1. Use the "scout" agent to find all code relevant to: $@
2. Use the "worker" agent to implement "$@" using scout findings from {previous}
3. Use the "verifier" agent to validate the worker result from {previous}

Execute as a chain, passing output between steps via {previous}.
