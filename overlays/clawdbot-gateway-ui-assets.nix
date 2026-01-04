final: prev:
let
  lib = prev.lib;
  hasGateway = (prev ? clawdbot-gateway);
  needsUiBuild = hasGateway && lib.hasAttrByPath [ "overrideAttrs" ] prev.clawdbot-gateway;
in
{
  clawdbot-gateway = if needsUiBuild then
    prev.clawdbot-gateway.overrideAttrs (old: {
      buildPhase = lib.concatStringsSep "\n" [
        (old.buildPhase or "")
        "pnpm ui:build"
      ];
    })
  else
    prev.clawdbot-gateway;
}
