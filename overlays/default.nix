{ inputs }:
[
  (import ./60-ghostty-tip.nix)
  (import ./95-dev-browser.nix { inherit inputs; })
  # ubs, cass, cm now come from nix-ai-tools
]
