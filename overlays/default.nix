{ inputs }:
[
  (import ./60-ghostty-tip.nix)
  (import ./70-ubs.nix { inherit inputs; })
  (import ./80-cass.nix { inherit inputs; })
  (import ./90-cm.nix)
]
