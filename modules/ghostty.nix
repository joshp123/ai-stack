{ lib, pkgs, ... }:
let
  ghosttyPkg =
    if builtins.hasAttr "ghostty-bin" pkgs then pkgs.ghostty-bin
    else if builtins.hasAttr "ghostty" pkgs then pkgs.ghostty
    else null;
in
{
  home.packages = lib.optional (ghosttyPkg != null) ghosttyPkg;

  home.file = {
    ".config/ghostty/config".source = ../config/ghostty/config;
    ".config/ghostty/config".force = true;
  };
}
