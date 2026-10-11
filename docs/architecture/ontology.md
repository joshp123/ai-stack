# ai-stack ontology

`tree` should explain this repo before any implementation is read.

| Path | Owns | Does not own |
| --- | --- | --- |
| `ai-tools/` | the tools bundle: which nix-ai-tools packages, cua-driver's app and skill pack | the packages themselves (nix-ai-tools); anything written by hand |
| `content/` | the written trees: the three skill trees, pi extensions, `CLAUDE.md`, rules and models, linked by Home Manager and `/etc/codex` | package-owned files (only fixed links into the profile) |
| `modules/home/` | Home Manager modules: PATH into the profile, the written files, shell config | secrets, the owner's paths |
| `modules/darwin/` | nix-darwin modules: the nightly updater, Codex's `/etc/codex` | which machine runs them, the repo URL, the mail addresses |
| `skills/` | shareable skills | private workflows, Codex's built-in skills |
| `extensions/` | pi extension source | packaged AI CLIs |
| `docs/agents/` | global prompts and the rules every harness reads | private runbooks, host facts |
| `config/` | zsh, starship, ghostty | machine-specific overrides |

External owners: AI CLI packages are nix-ai-tools; secrets, identity, private
skills and host topology are the private repo; OpenClaw packaging is
nix-openclaw; cloud resources are opentofu-infra.
