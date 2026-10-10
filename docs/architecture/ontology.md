# ai-stack ontology

`tree` should explain this repo before any implementation is read.

| Path | Owns | Does not own |
| --- | --- | --- |
| `ai-home/` | the bundle definition: which tools, the three skill trees, the `share/` layout | the packages themselves (nix-ai-tools) |
| `modules/home/` | Home Manager modules: pointers into the profile, shell config | secrets, the owner's paths |
| `modules/darwin/` | nix-darwin modules: the nightly updater, Codex's `/etc/codex` | which machine runs them, the repo URL, the mail addresses |
| `skills/` | shareable skills | private workflows, Codex's built-in skills |
| `extensions/` | pi extension source | packaged AI CLIs |
| `docs/agents/` | global prompts and the rules every harness reads | private runbooks, host facts |
| `config/` | zsh, starship, ghostty | machine-specific overrides |

External owners: AI CLI packages are nix-ai-tools; secrets, identity, private
skills and host topology are the private repo; OpenClaw packaging is
nix-openclaw; cloud resources are opentofu-infra.
