{ inputs }:
[
  # cass and cm now come from nix-ai-tools
  (final: _prev: {
    prime-agent = final.callPackage ../packages/prime-agent.nix {
      primeAgentSrc = inputs.prime-agent-src;
    };
  })
]
