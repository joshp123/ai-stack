{ lib, pkgs, ... }:
{
  home.file = {
    ".config/ghostty/config".source = ../config/ghostty/config;
    ".config/ghostty/config".force = true;
  };
}
