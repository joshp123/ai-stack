{ inputs }:
final: prev:
let
  lib = prev.lib;
  system = prev.stdenv.hostPlatform.system;
  hasPackages = inputs ? dev-browser && lib.hasAttrByPath [ "packages" system ] inputs.dev-browser;
  devBrowserPkgs = if hasPackages then inputs.dev-browser.packages.${system} else null;
  baseInputs = (prev.inputs or {}) // lib.optionalAttrs (inputs ? dev-browser) { dev-browser = inputs.dev-browser; };
  devBrowser = if devBrowserPkgs != null then (devBrowserPkgs.dev-browser or devBrowserPkgs.default) else null;
  devBrowserDaemon = if devBrowserPkgs != null then (devBrowserPkgs.dev-browser-daemon or devBrowserPkgs.dev-browser or devBrowserPkgs.default) else null;
  devBrowserServer = if devBrowserPkgs != null then (devBrowserPkgs.dev-browser-mcp-server or devBrowserPkgs.dev-browser or devBrowserPkgs.default) else null;
  devBrowserSkill = if devBrowserPkgs != null && devBrowserPkgs ? dev-browser-skill then devBrowserPkgs.dev-browser-skill else null;
in
{
  inputs = baseInputs;
}
// lib.optionalAttrs (devBrowser != null) { dev-browser = devBrowser; }
// lib.optionalAttrs (devBrowserDaemon != null) { dev-browser-daemon = devBrowserDaemon; }
// lib.optionalAttrs (devBrowserServer != null) { dev-browser-mcp-server = devBrowserServer; }
// lib.optionalAttrs (devBrowserSkill != null) { dev-browser-skill = devBrowserSkill; }
