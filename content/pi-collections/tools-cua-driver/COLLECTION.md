# tools/cua-driver

Computer use for native desktop apps through the `cua-driver` CLI, backed by
the CuaDriver.app daemon in /Applications.

Source: the `cua-driver` package in nix-ai-tools, which ships the app and the
matching skill pack. Codex's own computer-use engine (in ChatGPT.app) also
exists; Codex agents use it natively and do not need this skill.
