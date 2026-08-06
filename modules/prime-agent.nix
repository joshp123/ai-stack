{ pkgs, ... }:

{
  home.packages = [ pkgs.prime-agent ];

  home.file.".prime/agent/extensions/responses-v2-compaction" = {
    source = ../extensions/responses-v2-compaction;
    force = true;
  };
}
